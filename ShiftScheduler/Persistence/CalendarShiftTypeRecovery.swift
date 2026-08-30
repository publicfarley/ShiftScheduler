import Foundation

/// Minimal, EventKit-free view of a calendar event, used for recovery parsing.
struct RecoverableCalendarEvent: Sendable, Equatable {
    var title: String
    var location: String?
    var notes: String?
    var startDate: Date
    var endDate: Date
    var isAllDay: Bool
}

/// Rebuilds `ShiftType` / `Location` templates from the app's calendar events when
/// the local JSON cache has been lost.
///
/// Events created by this app encode enough to reconstruct the referenced template:
///   - `title`    — `"SYMBOL: Title"`
///   - `location` — `"Name: address"`
///   - `notes`    — first line is the shift type UUID, optionally followed by
///                  `"|SICK_DAY:…"` and/or a `"\n---\n"` separator + user notes
///   - times      — the event's start/end (or `isAllDay`)
///
/// This is a best-effort recovery: `shiftDescription` cannot be recovered (events
/// never store it) and location addresses come from the flattened event location
/// string. It exists only to re-link orphaned calendar events, not as a substitute
/// for real persistence or CloudKit sync.
enum CalendarShiftTypeRecovery {
    struct Result: Sendable {
        var shiftTypes: [ShiftType]
        var locations: [Location]
    }

    /// Reconstruct unique shift types and locations from the given events.
    /// The first event seen for a given shift-type id wins.
    static func reconstruct(from events: [RecoverableCalendarEvent]) -> Result {
        var locationsByName: [String: Location] = [:]
        var shiftTypesById: [UUID: ShiftType] = [:]

        for event in events {
            guard let id = shiftTypeId(fromNotes: event.notes) else { continue }
            guard shiftTypesById[id] == nil else { continue }

            let (symbol, title) = splitTitle(event.title)
            let location = resolveLocation(from: event.location, cache: &locationsByName)

            shiftTypesById[id] = ShiftType(
                id: id,
                symbol: symbol,
                duration: duration(from: event),
                title: title,
                description: "",
                location: location
            )
        }

        return Result(
            shiftTypes: Array(shiftTypesById.values).sorted { $0.title < $1.title },
            locations: Array(locationsByName.values).sorted { $0.name < $1.name }
        )
    }

    // MARK: - Parsing helpers (internal for testing)

    /// Extract the shift-type UUID from an event's notes field.
    static func shiftTypeId(fromNotes notes: String?) -> UUID? {
        guard let notes else { return nil }

        // The metadata section is everything before the first known separator.
        let separators = ["\n---\n", "---", "\n--\n", " --- "]
        var metadata = notes
        for separator in separators {
            if let range = notes.range(of: separator) {
                metadata = String(notes[..<range.lowerBound])
                break
            }
        }

        // Strip any inline flags ("UUID|SICK_DAY:true|REASON:…").
        if let pipe = metadata.firstIndex(of: "|") {
            metadata = String(metadata[..<pipe])
        }

        return UUID(uuidString: metadata.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    /// Split an event title of the form `"SYMBOL: Title"`.
    static func splitTitle(_ rawTitle: String) -> (symbol: String, title: String) {
        let trimmed = rawTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if let range = trimmed.range(of: ": ") {
            let symbol = String(trimmed[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
            let title = String(trimmed[range.upperBound...]).trimmingCharacters(in: .whitespaces)
            if !symbol.isEmpty && !title.isEmpty {
                return (symbol, title)
            }
        }
        // Fallback: no recognizable symbol prefix.
        return ("📅", trimmed.isEmpty ? "Recovered Shift" : trimmed)
    }

    /// Split an event location of the form `"Name: address"`.
    static func splitLocation(_ raw: String?) -> (name: String, address: String) {
        guard let raw = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return ("Unknown", "")
        }
        if let range = raw.range(of: ": ") {
            let name = String(raw[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
            let address = String(raw[range.upperBound...]).trimmingCharacters(in: .whitespaces)
            if !name.isEmpty {
                return (name, address)
            }
        }
        return (raw, "")
    }

    /// Stable UUID derived from a location name so that re-running recovery does not
    /// create duplicate locations with fresh identifiers.
    static func deterministicLocationID(for name: String) -> UUID {
        var bytes = stableDigest16("ShiftScheduler.Location:\(name)")
        bytes[6] = (bytes[6] & 0x0F) | 0x30 // version 3 (name-based)
        bytes[8] = (bytes[8] & 0x3F) | 0x80 // RFC 4122 variant
        let hex = bytes.map { String(format: "%02x", $0) }.joined()
        let uuidString = "\(hex.prefix(8))-\(hex.dropFirst(8).prefix(4))-\(hex.dropFirst(12).prefix(4))-\(hex.dropFirst(16).prefix(4))-\(hex.dropFirst(20))"
        return UUID(uuidString: uuidString) ?? UUID()
    }

    /// Deterministic 16-byte digest of a string, stable across processes and platforms.
    /// Two independent FNV-1a passes (different offset bases) give 128 bits.
    private static func stableDigest16(_ string: String) -> [UInt8] {
        func fnv1a(_ bytes: [UInt8], offset: UInt64) -> UInt64 {
            var hash = offset
            let prime: UInt64 = 0x0000_0100_0000_01B3
            for byte in bytes {
                hash ^= UInt64(byte)
                hash = hash &* prime
            }
            return hash
        }
        let utf8 = Array(string.utf8)
        let low = fnv1a(utf8, offset: 0xCBF2_9CE4_8422_2325)
        let high = fnv1a(utf8, offset: 0x9E37_79B9_7F4A_7C15)
        var out = [UInt8]()
        out.reserveCapacity(16)
        for shift in stride(from: 56, through: 0, by: -8) { out.append(UInt8((high >> UInt64(shift)) & 0xFF)) }
        for shift in stride(from: 56, through: 0, by: -8) { out.append(UInt8((low >> UInt64(shift)) & 0xFF)) }
        return out
    }

    // MARK: - Private

    private static func resolveLocation(from raw: String?, cache: inout [String: Location]) -> Location {
        let (name, address) = splitLocation(raw)
        if let existing = cache[name] { return existing }
        let location = Location(id: deterministicLocationID(for: name), name: name, address: address)
        cache[name] = location
        return location
    }

    private static func duration(from event: RecoverableCalendarEvent) -> ShiftDuration {
        if event.isAllDay { return .allDay }

        let calendar = Calendar.current
        let start = calendar.dateComponents([.hour, .minute], from: event.startDate)
        let end = calendar.dateComponents([.hour, .minute], from: event.endDate)

        // No usable time information — treat as all-day.
        if start.hour == end.hour && start.minute == end.minute {
            return .allDay
        }

        return .scheduled(
            from: HourMinuteTime(hour: start.hour ?? 0, minute: start.minute ?? 0),
            to: HourMinuteTime(hour: end.hour ?? 0, minute: end.minute ?? 0)
        )
    }
}
