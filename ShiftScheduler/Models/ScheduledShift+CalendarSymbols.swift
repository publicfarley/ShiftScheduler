import Foundation

extension Array where Element == ScheduledShift {
    /// Symbols for every shift on a calendar day, ordered by start time so a
    /// day with a Day and an Evening shift reads "D E" rather than showing only one.
    var calendarSymbols: [String] {
        sorted { $0.actualStartDateTime() < $1.actualStartDateTime() }
            .compactMap { $0.shiftType?.symbol }
    }
}
