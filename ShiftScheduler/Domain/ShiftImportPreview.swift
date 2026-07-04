import Foundation

/// Resolves parsed import entries against the shift type catalog and any
/// already-scheduled shifts, producing a preview the user can confirm.
struct ShiftImportPreview: Equatable, Sendable {
    enum DayStatus: Equatable, Sendable {
        case willImport(ShiftType)
        case skipped
        case unknownSymbol(String)
        case conflict(ShiftType, existingEventIdentifier: String)
    }

    struct Day: Equatable, Sendable {
        let date: Date
        let symbol: String
        let status: DayStatus
    }

    let days: [Day]

    var importableCount: Int {
        days.filter {
            if case .willImport = $0.status { return true }
            return false
        }.count
    }

    var conflictCount: Int {
        days.filter {
            if case .conflict = $0.status { return true }
            return false
        }.count
    }

    var hasBlockingErrors: Bool {
        days.contains {
            if case .unknownSymbol = $0.status { return true }
            return false
        }
    }

    static func build(
        entries: [ShiftImportParser.ParsedEntry],
        shiftTypes: [ShiftType],
        existingShifts: [ScheduledShift]
    ) -> ShiftImportPreview {
        let symbolLookup: [String: ShiftType] = Dictionary(
            shiftTypes.map { ($0.symbol.lowercased(), $0) },
            uniquingKeysWith: { first, _ in first }
        )

        let days: [Day] = entries.map { entry in
            if ShiftImportParser.isSkipToken(entry.symbol) {
                return Day(date: entry.date, symbol: entry.symbol, status: .skipped)
            }

            guard let shiftType = symbolLookup[entry.symbol.lowercased()] else {
                return Day(date: entry.date, symbol: entry.symbol, status: .unknownSymbol(entry.symbol))
            }

            if let existing = existingShifts.first(where: { $0.occursOn(date: entry.date) }) {
                return Day(date: entry.date, symbol: entry.symbol, status: .conflict(shiftType, existingEventIdentifier: existing.eventIdentifier))
            }

            return Day(date: entry.date, symbol: entry.symbol, status: .willImport(shiftType))
        }

        return ShiftImportPreview(days: days)
    }
}
