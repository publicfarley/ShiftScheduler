import Testing
import Foundation
@testable import ShiftSchedulerCLI

@Suite("DateParsing")
struct DateParsingTests {
    private static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return calendar
    }

    private static func date(_ year: Int, _ month: Int, _ day: Int) throws -> Date {
        try #require(calendar.date(from: DateComponents(year: year, month: month, day: day)))
    }

    @Test("An ISO date parses to the start of that day")
    func isoDate() throws {
        let now = try Self.date(2026, 10, 28)
        let parsed = try DateParsing.parseDate("2026-10-05", calendar: Self.calendar, now: now)
        #expect(parsed == (try Self.date(2026, 10, 5)))
    }

    @Test("today, tomorrow and yesterday are relative to the injected clock")
    func keywords() throws {
        let now = try Self.date(2026, 10, 28)
        #expect(try DateParsing.parseDate("today", calendar: Self.calendar, now: now) == now)
        #expect(try DateParsing.parseDate("tomorrow", calendar: Self.calendar, now: now) == (try Self.date(2026, 10, 29)))
        #expect(try DateParsing.parseDate("yesterday", calendar: Self.calendar, now: now) == (try Self.date(2026, 10, 27)))
    }

    @Test("Relative offsets count days and weeks from the injected clock")
    func relative() throws {
        let now = try Self.date(2026, 10, 28)
        #expect(try DateParsing.parseDate("+3d", calendar: Self.calendar, now: now) == (try Self.date(2026, 10, 31)))
        #expect(try DateParsing.parseDate("-1w", calendar: Self.calendar, now: now) == (try Self.date(2026, 10, 21)))
    }

    @Test("Text that is not a date throws invalidDate")
    func invalid() throws {
        let now = try Self.date(2026, 10, 28)
        #expect(throws: CLIError.self) {
            try DateParsing.parseDate("someday", calendar: Self.calendar, now: now)
        }
    }
}
