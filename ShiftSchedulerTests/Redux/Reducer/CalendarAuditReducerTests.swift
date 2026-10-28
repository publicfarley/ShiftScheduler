import Testing
import Foundation
@testable import ShiftScheduler

@Suite("CalendarAuditReducer")
@MainActor
struct CalendarAuditReducerTests {

    private static func date(_ year: Int, _ month: Int, _ day: Int) throws -> Date {
        try #require(Calendar.current.date(from: DateComponents(year: year, month: month, day: day)))
    }

    private static let day = ShiftTypeBuilder(symbol: "D", title: "Day").build()

    /// A report with one fixable day (`fixable`) and one match (`matched`)
    private static func report(fixable: Date, matched: Date) -> CalendarAudit.Report {
        CalendarAudit.Report(
            days: [
                CalendarAudit.Day(date: matched, appSymbol: nil, externalSymbol: "x", outcome: .match),
                CalendarAudit.Day(date: fixable, appSymbol: nil, externalSymbol: "D", outcome: .differs(.create(day)))
            ],
            skippedEventCount: 0
        )
    }

    @Test("Opening the sheet presents it, loads calendars, and defaults the range to this month through next month")
    func sheetOpened() throws {
        let now = try Self.date(2026, 3, 15)

        let state = calendarAuditReducer(state: CalendarAuditState(), action: .sheetOpened(now: now))

        #expect(state.isSheetPresented)
        #expect(state.isLoadingCalendars)
        #expect(state.startDate == (try Self.date(2026, 3, 1)))
        #expect(state.endDate == (try Self.date(2026, 4, 30)))
    }

    @Test("Loaded calendars replace the list and stop loading")
    func calendarsLoaded() {
        let calendar = CalendarAudit.AuditCalendar(id: "c1", title: "Work", sourceTitle: "iCloud")
        var initial = CalendarAuditState()
        initial.isLoadingCalendars = true

        let state = calendarAuditReducer(state: initial, action: .calendarsLoaded([calendar]))

        #expect(state.availableCalendars == [calendar])
        #expect(!state.isLoadingCalendars)
    }

    @Test("Selecting a different calendar clears the previous report")
    func selectingCalendarClearsReport() throws {
        var initial = CalendarAuditState()
        initial.report = Self.report(fixable: try Self.date(2026, 1, 2), matched: try Self.date(2026, 1, 1))
        initial.selectedFixDates = [try Self.date(2026, 1, 2)]

        let state = calendarAuditReducer(state: initial, action: .calendarSelected("c2"))

        #expect(state.selectedCalendarId == "c2")
        #expect(state.report == nil)
        #expect(state.selectedFixDates.isEmpty)
    }

    @Test("Running the audit sets the running flag")
    func runAuditSetsRunning() {
        let state = calendarAuditReducer(state: CalendarAuditState(), action: .runAudit)
        #expect(state.isRunning)
    }

    @Test("A completed audit stores the report and preselects every fixable day")
    func auditCompletedPreselectsFixes() throws {
        let fixable = try Self.date(2026, 1, 2)
        let matched = try Self.date(2026, 1, 1)
        var initial = CalendarAuditState()
        initial.isRunning = true

        let state = calendarAuditReducer(
            state: initial,
            action: .auditCompleted(Self.report(fixable: fixable, matched: matched))
        )

        #expect(!state.isRunning)
        #expect(state.report?.days.count == 2)
        #expect(state.selectedFixDates == [fixable])
    }

    @Test("A failed audit stores the error and stops running")
    func auditFailed() {
        var initial = CalendarAuditState()
        initial.isRunning = true

        let state = calendarAuditReducer(state: initial, action: .auditFailed("boom"))

        #expect(!state.isRunning)
        #expect(state.errorMessage == "boom")
    }

    @Test("Toggling a fixable day removes then restores its selection")
    func toggleFix() throws {
        let fixable = try Self.date(2026, 1, 2)
        var initial = CalendarAuditState()
        initial.report = Self.report(fixable: fixable, matched: try Self.date(2026, 1, 1))
        initial.selectedFixDates = [fixable]

        let off = calendarAuditReducer(state: initial, action: .fixToggled(fixable))
        #expect(off.selectedFixDates.isEmpty)

        let on = calendarAuditReducer(state: off, action: .fixToggled(fixable))
        #expect(on.selectedFixDates == [fixable])
    }

    @Test("Toggling a day that is not fixable does nothing")
    func toggleNonFixableIgnored() throws {
        let matched = try Self.date(2026, 1, 1)
        var initial = CalendarAuditState()
        initial.report = Self.report(fixable: try Self.date(2026, 1, 2), matched: matched)

        let state = calendarAuditReducer(state: initial, action: .fixToggled(matched))

        #expect(state.selectedFixDates.isEmpty)
    }

    @Test("Applying fixes sets the applying flag; completion reports the count")
    func applyAndComplete() {
        let applying = calendarAuditReducer(state: CalendarAuditState(), action: .applyFixes)
        #expect(applying.isApplying)

        let done = calendarAuditReducer(state: applying, action: .fixesCompleted(applied: 3))
        #expect(!done.isApplying)
        #expect(done.successMessage == "Updated 3 dates")
    }

    @Test("A failure before anything was applied reports just the error")
    func fixesFailedWithNothingApplied() {
        let state = calendarAuditReducer(state: CalendarAuditState(), action: .fixesFailed(applied: 0, message: "boom"))
        #expect(state.errorMessage == "boom")
    }

    @Test("A partial failure reports how many were applied and the error")
    func fixesFailed() {
        var initial = CalendarAuditState()
        initial.isApplying = true

        let state = calendarAuditReducer(state: initial, action: .fixesFailed(applied: 2, message: "boom"))

        #expect(!state.isApplying)
        #expect(state.errorMessage == "Updated 2 dates before an error: boom")
    }
}
