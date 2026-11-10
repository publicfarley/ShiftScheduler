import Testing
import Foundation
@testable import ShiftSchedulerCLI

@Suite("WeekdayFilter")
struct WeekdayFilterTests {
    private static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return calendar
    }

    private static func shift(_ year: Int, _ month: Int, _ day: Int) throws -> ScheduledShift {
        let date = try #require(calendar.date(from: DateComponents(year: year, month: month, day: day)))
        return ScheduledShift(
            eventIdentifier: "event-\(year)-\(month)-\(day)",
            shiftType: nil,
            date: date,
            endDate: date
        )
    }

    // 2026-11-13 is a Friday, so 14 = Saturday, 15 = Sunday, 16 = Monday.
    private static func week() throws -> [ScheduledShift] {
        try (13...16).map { try shift(2026, 11, $0) }
    }

    // MARK: - parse

    @Test("Full and three-letter names parse to Calendar weekday numbers, ignoring case")
    func parseNames() throws {
        #expect(try WeekdayFilter.parse(["saturday"]) == [7])
        #expect(try WeekdayFilter.parse(["Sat"]) == [7])
        #expect(try WeekdayFilter.parse(["SUN"]) == [1])
        #expect(try WeekdayFilter.parse(["thu"]) == [5])
    }

    @Test("Repeated and comma-separated values combine into one set")
    func parseMultiple() throws {
        #expect(try WeekdayFilter.parse(["sat", "sun"]) == [1, 7])
        #expect(try WeekdayFilter.parse(["sat,sun"]) == [1, 7])
        #expect(try WeekdayFilter.parse(["sat, mon", "sat"]) == [2, 7])
    }

    @Test("No values means no restriction")
    func parseEmpty() throws {
        #expect(try WeekdayFilter.parse([]).isEmpty)
    }

    @Test("Text that is not a weekday throws invalidWeekday")
    func parseInvalid() {
        #expect(throws: CLIError.self) {
            try WeekdayFilter.parse(["funday"])
        }
        #expect(throws: CLIError.self) {
            try WeekdayFilter.parse(["sat,"])
        }
    }

    // MARK: - apply

    @Test("An empty weekday set keeps every shift")
    func applyEmpty() throws {
        let shifts = try Self.week()
        #expect(WeekdayFilter.apply(shifts, weekdays: [], calendar: Self.calendar) == shifts)
    }

    @Test("Only shifts starting on the requested weekday are kept")
    func applySaturday() throws {
        let kept = WeekdayFilter.apply(try Self.week(), weekdays: [7], calendar: Self.calendar)
        #expect(kept.map(\.eventIdentifier) == ["event-2026-11-14"])
    }

    @Test("Several weekdays keep their shifts in the original order")
    func applyWeekend() throws {
        let kept = WeekdayFilter.apply(try Self.week(), weekdays: [1, 7], calendar: Self.calendar)
        #expect(kept.map(\.eventIdentifier) == ["event-2026-11-14", "event-2026-11-15"])
    }

    @Test("An overnight shift is matched by the weekday it starts on")
    func applyOvernight() throws {
        let start = try #require(Self.calendar.date(from: DateComponents(year: 2026, month: 11, day: 14)))
        let end = try #require(Self.calendar.date(from: DateComponents(year: 2026, month: 11, day: 15)))
        let overnight = ScheduledShift(eventIdentifier: "night", shiftType: nil, date: start, endDate: end)
        #expect(WeekdayFilter.apply([overnight], weekdays: [7], calendar: Self.calendar).count == 1)
        #expect(WeekdayFilter.apply([overnight], weekdays: [1], calendar: Self.calendar).isEmpty)
    }
}
