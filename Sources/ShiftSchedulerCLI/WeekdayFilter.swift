import Foundation

/// Pure helpers for the `--weekday` option of `schedule list`.
enum WeekdayFilter {
    /// Weekday names mapped to `Calendar` weekday numbers (1 = Sunday ... 7 = Saturday).
    private static let numbersByName: [String: Int] = [
        "sunday": 1, "sun": 1,
        "monday": 2, "mon": 2,
        "tuesday": 3, "tue": 3,
        "wednesday": 4, "wed": 4,
        "thursday": 5, "thu": 5,
        "friday": 6, "fri": 6,
        "saturday": 7, "sat": 7
    ]

    /// Parses `--weekday` values into `Calendar` weekday numbers.
    /// Accepts full or three-letter names, case-insensitive. Each value may hold
    /// a comma-separated list, and the option may be repeated.
    /// An empty input yields an empty set, which means "no restriction".
    static func parse(_ inputs: [String]) throws -> Set<Int> {
        var weekdays: Set<Int> = []
        for input in inputs {
            for part in input.split(separator: ",", omittingEmptySubsequences: false) {
                let name = part.trimmingCharacters(in: .whitespaces).lowercased()
                guard let number = numbersByName[name] else {
                    throw CLIError.invalidWeekday(name.isEmpty ? input : name)
                }
                weekdays.insert(number)
            }
        }
        return weekdays
    }

    /// Keeps shifts whose start date falls on one of `weekdays`, preserving order.
    /// An empty set keeps every shift.
    static func apply(
        _ shifts: [ScheduledShift],
        weekdays: Set<Int>,
        calendar: Calendar = .current
    ) -> [ScheduledShift] {
        guard !weekdays.isEmpty else { return shifts }
        return shifts.filter { weekdays.contains(calendar.component(.weekday, from: $0.date)) }
    }
}
