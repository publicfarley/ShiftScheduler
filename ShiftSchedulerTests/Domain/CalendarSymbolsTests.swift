import Testing
import Foundation
@testable import ShiftScheduler

@Suite("Calendar day symbols")
@MainActor
struct CalendarSymbolsTests {

    private static let nov8 = Calendar.current.date(from: DateComponents(year: 2026, month: 11, day: 8))!

    private static func type(_ symbol: String, from start: Int, to end: Int) -> ShiftType {
        ShiftTypeBuilder(
            symbol: symbol,
            duration: .specified(.scheduled(
                from: HourMinuteTime(hour: start, minute: 0),
                to: HourMinuteTime(hour: end, minute: 0)
            )),
            title: symbol
        ).build()
    }

    @Test("A day with two shifts shows both symbols, earliest first")
    func twoShiftsShowBothSymbolsInStartOrder() {
        let evening = ScheduledShift(eventIdentifier: "e", shiftType: Self.type("E", from: 15, to: 23), date: Self.nov8)
        let day = ScheduledShift(eventIdentifier: "d", shiftType: Self.type("D", from: 7, to: 15), date: Self.nov8)

        #expect([evening, day].calendarSymbols == ["D", "E"])
    }

    @Test("A day with one shift shows its symbol")
    func singleShiftShowsItsSymbol() {
        let day = ScheduledShift(eventIdentifier: "d", shiftType: Self.type("WD", from: 7, to: 15), date: Self.nov8)

        #expect([day].calendarSymbols == ["WD"])
    }

    @Test("Shifts with no shift type are skipped")
    func shiftsWithoutTypeAreSkipped() {
        let unknown = ScheduledShift(eventIdentifier: "x", shiftType: nil, date: Self.nov8)

        #expect([unknown].calendarSymbols.isEmpty)
    }
}
