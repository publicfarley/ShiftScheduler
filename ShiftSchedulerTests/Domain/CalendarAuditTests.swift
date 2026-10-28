import Testing
import Foundation
@testable import ShiftScheduler

@Suite("CalendarAudit")
@MainActor
struct CalendarAuditTests {

    // MARK: - Helpers

    private static func date(_ year: Int, _ month: Int, _ day: Int) throws -> Date {
        try #require(Calendar.current.date(from: DateComponents(year: year, month: month, day: day)))
    }

    private static let day = ShiftTypeBuilder(symbol: "D", title: "Day").build()
    private static let night = ShiftTypeBuilder(symbol: "N", title: "Night").build()
    private static let catalog = [day, night]

    private static func shift(_ type: ShiftType, on date: Date, endDate: Date? = nil, id: String = "evt") -> ScheduledShift {
        ScheduledShift(eventIdentifier: id, shiftType: type, date: date, endDate: endDate)
    }

    private static func external(_ description: String?, on date: Date) -> CalendarAudit.ExternalEvent {
        CalendarAudit.ExternalEvent(date: date, title: description)
    }

    /// Audits a single day and returns its row (nil when the day produced no row)
    private static func auditDay(
        shift: ScheduledShift? = nil,
        external event: CalendarAudit.ExternalEvent? = nil,
        on target: Date
    ) -> CalendarAudit.Day? {
        CalendarAudit.audit(
            from: target,
            through: target,
            shifts: shift.map { [$0] } ?? [],
            externalEvents: event.map { [$0] } ?? [],
            shiftTypes: catalog
        ).days.first
    }

    // MARK: - Symbol parsing

    @Test("Symbol is the text before the first colon")
    func symbolBeforeColon() {
        #expect(CalendarAudit.symbol(fromTitle: "x: Off") == "x")
    }

    @Test("Symbol is trimmed of surrounding whitespace")
    func symbolIsTrimmed() {
        #expect(CalendarAudit.symbol(fromTitle: "  N : Night shift") == "N")
    }

    @Test("Only the first colon counts")
    func onlyFirstColonCounts() {
        #expect(CalendarAudit.symbol(fromTitle: "D: Day: extra") == "D")
    }

    @Test("Tilde is a valid symbol")
    func tildeSymbol() {
        #expect(CalendarAudit.symbol(fromTitle: "~: Nothing") == "~")
    }

    @Test("No symbol when the description is nil, empty, has no colon, or starts with a colon")
    func noSymbol() {
        #expect(CalendarAudit.symbol(fromTitle: nil) == nil)
        #expect(CalendarAudit.symbol(fromTitle: "") == nil)
        #expect(CalendarAudit.symbol(fromTitle: "just words") == nil)
        #expect(CalendarAudit.symbol(fromTitle: ": text") == nil)
        #expect(CalendarAudit.symbol(fromTitle: "   : text") == nil)
    }

    @Test("Text containing whitespace before the colon is not a symbol")
    func prefixWithSpacesIsNotASymbol() {
        #expect(CalendarAudit.symbol(fromTitle: "Meeting with Bob: notes") == nil)
    }

    // MARK: - Per-date comparison

    @Test("Same symbol on both calendars is a match")
    func sameSymbolMatches() throws {
        let target = try Self.date(2026, 1, 5)
        let row = try #require(Self.auditDay(
            shift: Self.shift(Self.day, on: target),
            external: Self.external("D: Day", on: target),
            on: target
        ))
        #expect(row.outcome == .match)
        #expect(row.appSymbol == "D")
        #expect(row.externalSymbol == "D")
    }

    @Test("Symbols are compared case-insensitively")
    func caseInsensitiveMatch() throws {
        let target = try Self.date(2026, 1, 5)
        let row = try #require(Self.auditDay(
            shift: Self.shift(Self.day, on: target),
            external: Self.external("d: day", on: target),
            on: target
        ))
        #expect(row.outcome == .match)
    }

    @Test("Empty app day matches x, X and ~ on the chosen calendar", arguments: ["x: Off", "X: Off", "~: Off"])
    func emptyDayMatchesSkipSymbols(description: String) throws {
        let target = try Self.date(2026, 1, 5)
        let row = try #require(Self.auditDay(external: Self.external(description, on: target), on: target))
        #expect(row.outcome == .match)
        #expect(row.appSymbol == nil)
    }

    @Test("Empty app day with a real symbol on the chosen calendar offers to create the shift")
    func missingInAppOffersCreate() throws {
        let target = try Self.date(2026, 1, 5)
        let row = try #require(Self.auditDay(external: Self.external("D: Day", on: target), on: target))
        #expect(row.outcome == .differs(.create(Self.day)))
    }

    @Test("App shift against x, X or ~ offers to remove the shift", arguments: ["x: Off", "X: Off", "~: Off"])
    func appShiftAgainstOffOffersRemove(description: String) throws {
        let target = try Self.date(2026, 1, 5)
        let appShift = Self.shift(Self.day, on: target, id: "evt-1")
        let row = try #require(Self.auditDay(shift: appShift, external: Self.external(description, on: target), on: target))
        #expect(row.outcome == .differs(.remove(current: Self.day, eventIdentifier: "evt-1")))
    }

    @Test("Different symbols offer to switch the app shift")
    func differentSymbolsOfferSwitch() throws {
        let target = try Self.date(2026, 1, 5)
        let appShift = Self.shift(Self.day, on: target, id: "evt-1")
        let row = try #require(Self.auditDay(shift: appShift, external: Self.external("N: Night", on: target), on: target))
        #expect(row.outcome == .differs(.switchTo(Self.night, from: Self.day, eventIdentifier: "evt-1")))
    }

    @Test("App shift with no chosen-calendar entry is reported without a fix")
    func notInExternal() throws {
        let target = try Self.date(2026, 1, 5)
        let row = try #require(Self.auditDay(shift: Self.shift(Self.day, on: target), on: target))
        #expect(row.outcome == .notInExternal)
        #expect(row.fix == nil)
    }

    @Test("Chosen-calendar symbol with no matching shift type is reported without a fix")
    func unknownExternalSymbol() throws {
        let target = try Self.date(2026, 1, 5)
        let row = try #require(Self.auditDay(external: Self.external("Q: Mystery", on: target), on: target))
        #expect(row.outcome == .unknownExternalSymbol("Q"))
        #expect(row.fix == nil)
    }

    @Test("Days with no entry on either calendar produce no row")
    func emptyOnBothSidesProducesNoRow() throws {
        let target = try Self.date(2026, 1, 5)
        #expect(Self.auditDay(on: target) == nil)
    }

    @Test("Chosen-calendar events without a readable symbol are skipped and counted")
    func unreadableEventsAreSkipped() throws {
        let target = try Self.date(2026, 1, 5)
        let report = CalendarAudit.audit(
            from: target,
            through: target,
            shifts: [],
            externalEvents: [Self.external("no colon here", on: target), Self.external(nil, on: target)],
            shiftTypes: Self.catalog
        )
        #expect(report.days.isEmpty)
        #expect(report.skippedEventCount == 2)
    }

    @Test("An overnight app shift counts on its start date only")
    func overnightShiftCountsOnStartDate() throws {
        let start = try Self.date(2026, 1, 5)
        let next = try Self.date(2026, 1, 6)
        let report = CalendarAudit.audit(
            from: start,
            through: next,
            shifts: [Self.shift(Self.night, on: start, endDate: next)],
            externalEvents: [Self.external("N: Night", on: start)],
            shiftTypes: Self.catalog
        )
        #expect(report.days.map(\.date) == [start])
        #expect(report.days.first?.outcome == .match)
    }

    @Test("Entries outside the audited range are ignored")
    func outOfRangeIgnored() throws {
        let inside = try Self.date(2026, 1, 5)
        let outside = try Self.date(2026, 1, 20)
        let report = CalendarAudit.audit(
            from: inside,
            through: inside,
            shifts: [Self.shift(Self.day, on: outside)],
            externalEvents: [Self.external("N: Night", on: outside)],
            shiftTypes: Self.catalog
        )
        #expect(report.days.isEmpty)
    }

    // MARK: - Report

    @Test("Report lists populated days in date order with correct counts")
    func reportOrderAndCounts() throws {
        let d1 = try Self.date(2026, 1, 5)
        let d2 = try Self.date(2026, 1, 6)
        let d3 = try Self.date(2026, 1, 7)
        let d4 = try Self.date(2026, 1, 8)

        let report = CalendarAudit.audit(
            from: d1,
            through: d4,
            shifts: [
                Self.shift(Self.day, on: d3, id: "evt-3"),
                Self.shift(Self.day, on: d1, id: "evt-1")
            ],
            externalEvents: [
                Self.external("N: Night", on: d3),   // differs
                Self.external("x: Off", on: d2),     // match (empty app day)
                Self.external("D: Day", on: d1)      // match
            ],
            shiftTypes: Self.catalog
        )

        #expect(report.days.map(\.date) == [d1, d2, d3])
        #expect(report.matchCount == 2)
        #expect(report.discrepancyCount == 1)
        #expect(report.fixableDays.map(\.date) == [d3])
    }

    // MARK: - Display

    @Test("Each outcome describes what will happen or why nothing can")
    func outcomeDetails() throws {
        let target = try Self.date(2026, 1, 5)
        func row(_ outcome: CalendarAudit.Outcome) -> CalendarAudit.Day {
            CalendarAudit.Day(date: target, appSymbol: nil, externalSymbol: nil, outcome: outcome)
        }

        #expect(row(.match).detail == nil)
        #expect(row(.differs(.create(Self.day))).detail == "Add Day (D)")
        #expect(row(.differs(.switchTo(Self.night, from: Self.day, eventIdentifier: "e"))).detail == "Switch to Night (N)")
        #expect(row(.differs(.remove(current: Self.day, eventIdentifier: "e"))).detail == "Remove shift")
        #expect(row(.notInExternal).detail == "Not on the chosen calendar")
        #expect(row(.unknownExternalSymbol("Q")).detail == "No shift type with symbol \u{201C}Q\u{201D}")
    }
}
