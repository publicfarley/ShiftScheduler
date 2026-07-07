import Foundation

// MARK: - JSON DTOs
//
// Stable, agent-friendly JSON shapes decoupled from the internal Codable
// encodings of the domain models (e.g. ShiftDuration's enum encoding).

struct LocationDTO: Codable {
    let id: String
    let name: String
    let address: String

    init(_ location: Location) {
        id = location.id.uuidString
        name = location.name
        address = location.address
    }
}

struct ShiftTypeDTO: Codable {
    let id: String
    let symbol: String
    let title: String
    let description: String
    let allDay: Bool
    let startTime: String?
    let endTime: String?
    let location: LocationDTO

    init(_ type: ShiftType) {
        id = type.id.uuidString
        symbol = type.symbol
        title = type.title
        description = type.shiftDescription
        allDay = type.isAllDay
        startTime = type.duration.startTime.map(OutputFormatter.hhmm)
        endTime = type.duration.endTime.map(OutputFormatter.hhmm)
        location = LocationDTO(type.location)
    }
}

struct ShiftDTO: Codable {
    let eventId: String
    let date: String
    let endDate: String
    let shiftType: ShiftTypeDTO?
    let notes: String?
    let sickDay: Bool
    let sickReason: String?

    init(_ shift: ScheduledShift) {
        eventId = shift.eventIdentifier
        date = OutputFormatter.dayString(shift.date)
        endDate = OutputFormatter.dayString(shift.endDate)
        shiftType = shift.shiftType.map(ShiftTypeDTO.init)
        notes = shift.notes
        sickDay = shift.isSickDay
        sickReason = shift.reason
    }
}

struct ChangeLogEntryDTO: Codable {
    let id: String
    let timestamp: String
    let user: String
    let changeType: String
    let shiftDate: String
    let from: String?
    let to: String?
    let reason: String?

    init(_ entry: ChangeLogEntry) {
        id = entry.id.uuidString
        timestamp = OutputFormatter.iso8601.string(from: entry.timestamp)
        user = entry.userDisplayName
        changeType = entry.changeType.rawValue
        shiftDate = OutputFormatter.dayString(entry.scheduledShiftDate)
        from = entry.oldShiftSnapshot.map { "\($0.symbol): \($0.title)" }
        to = entry.newShiftSnapshot.map { "\($0.symbol): \($0.title)" }
        reason = entry.reason
    }
}

struct ProfileDTO: Codable {
    let userId: String
    let displayName: String
    let retentionPolicy: String
    let autoPurgeEnabled: Bool
    let lastPurgeDate: String?

    init(_ profile: UserProfile) {
        userId = profile.userId.uuidString
        displayName = profile.displayName
        retentionPolicy = profile.retentionPolicy.rawValue
        autoPurgeEnabled = profile.autoPurgeEnabled
        lastPurgeDate = profile.lastPurgeDate.map { OutputFormatter.iso8601.string(from: $0) }
    }
}

// MARK: - Formatting

enum OutputFormatter {
    static let iso8601 = ISO8601DateFormatter()

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    static func dayString(_ date: Date) -> String {
        dayFormatter.string(from: date)
    }

    static func hhmm(_ time: HourMinuteTime) -> String {
        String(format: "%02d:%02d", time.hour, time.minute)
    }

    static func printJSON<T: Encodable>(_ value: T) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(value)
        print(String(data: data, encoding: .utf8) ?? "")
    }

    /// Renders a simple aligned text table.
    static func table(headers: [String], rows: [[String]]) -> String {
        var widths = headers.map { $0.count }
        for row in rows {
            for (index, cell) in row.enumerated() where index < widths.count {
                widths[index] = max(widths[index], cell.count)
            }
        }
        func line(_ cells: [String]) -> String {
            zip(cells, widths)
                .map { cell, width in cell.padding(toLength: max(width, cell.count), withPad: " ", startingAt: 0) }
                .joined(separator: "  ")
                .trimmingCharacters(in: .whitespaces)
        }
        var lines = [line(headers)]
        lines.append(widths.map { String(repeating: "-", count: $0) }.joined(separator: "  "))
        lines.append(contentsOf: rows.map(line))
        return lines.joined(separator: "\n")
    }

    static func shiftTable(_ shifts: [ScheduledShift]) -> String {
        table(
            headers: ["DATE", "TIME", "SHIFT", "LOCATION", "SICK", "EVENT-ID"],
            rows: shifts.map { shift in
                [
                    dayString(shift.date),
                    shift.shiftType?.timeRangeString ?? "-",
                    shift.shiftType.map { "\($0.symbol): \($0.title)" } ?? "(unknown type)",
                    shift.shiftType?.location.name ?? "-",
                    shift.isSickDay ? "yes" : "",
                    shift.eventIdentifier
                ]
            }
        )
    }

    static func shiftTypeTable(_ types: [ShiftType]) -> String {
        table(
            headers: ["ID", "SYMBOL", "TITLE", "TIME", "LOCATION"],
            rows: types.map { type in
                [
                    type.id.uuidString,
                    type.symbol,
                    type.title,
                    type.timeRangeString,
                    type.location.name
                ]
            }
        )
    }

    static func locationTable(_ locations: [Location]) -> String {
        table(
            headers: ["ID", "NAME", "ADDRESS"],
            rows: locations.map { location in
                [
                    location.id.uuidString,
                    location.name,
                    location.address.replacingOccurrences(of: "\n", with: ", ")
                ]
            }
        )
    }

    static func changeLogTable(_ entries: [ChangeLogEntry]) -> String {
        table(
            headers: ["TIMESTAMP", "USER", "CHANGE", "SHIFT-DATE", "FROM", "TO", "REASON"],
            rows: entries.map { entry in
                [
                    iso8601.string(from: entry.timestamp),
                    entry.userDisplayName,
                    entry.changeType.rawValue,
                    dayString(entry.scheduledShiftDate),
                    entry.oldShiftSnapshot.map { "\($0.symbol): \($0.title)" } ?? "-",
                    entry.newShiftSnapshot.map { "\($0.symbol): \($0.title)" } ?? "-",
                    entry.reason ?? ""
                ]
            }
        )
    }
}
