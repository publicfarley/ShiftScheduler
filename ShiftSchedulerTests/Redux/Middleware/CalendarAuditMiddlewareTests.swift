import Testing
import Foundation
@testable import ShiftScheduler

@Suite("CalendarAuditMiddleware")
@MainActor
struct CalendarAuditMiddlewareTests {

    // MARK: - Helpers

    private static func date(_ year: Int, _ month: Int, _ day: Int) throws -> Date {
        try #require(Calendar.current.date(from: DateComponents(year: year, month: month, day: day)))
    }

    private static let day = ShiftTypeBuilder(symbol: "D", title: "Day").build()
    private static let night = ShiftTypeBuilder(symbol: "N", title: "Night").build()

    @MainActor
    private struct Harness {
        let store: Store<AppState, AppAction>
        let calendar: MockCalendarService
        let persistence: MockPersistenceService

        var audit: CalendarAuditState { store.state.settings.calendarAudit }
    }

    private static func makeHarness(configure: (inout AppState, MockCalendarService) throws -> Void) throws -> Harness {
        let calendar = MockCalendarService()
        let persistence = MockPersistenceService()
        let services = ServiceContainer(
            calendarService: calendar,
            persistenceService: persistence,
            currentDayService: CurrentDayService(),
            timeChangeService: MockTimeChangeService()
        )

        var state = AppState()
        state.shiftTypes.shiftTypes = [day, night]
        state.settings.calendarAudit.selectedCalendarId = "c1"
        state.settings.calendarAudit.startDate = try date(2026, 1, 1)
        state.settings.calendarAudit.endDate = try date(2026, 1, 31)
        try configure(&state, calendar)

        let store = Store(
            state: state,
            reducer: appReducer,
            services: services,
            middlewares: [calendarAuditMiddleware]
        )
        return Harness(store: store, calendar: calendar, persistence: persistence)
    }

    // MARK: - Loading calendars

    @Test("Opening the sheet loads the available calendars")
    func sheetOpenedLoadsCalendars() async throws {
        let work = CalendarAudit.AuditCalendar(id: "c1", title: "Work", sourceTitle: "iCloud")
        let harness = try Self.makeHarness { _, calendar in
            calendar.mockAvailableCalendars = [work]
        }

        await harness.store.dispatch(action: .settings(.calendarAudit(.sheetOpened(now: try Self.date(2026, 1, 15)))))

        #expect(harness.audit.availableCalendars == [work])
        #expect(!harness.audit.isLoadingCalendars)
    }

    @Test("A calendar loading failure is surfaced as an error message")
    func calendarLoadFailure() async throws {
        let harness = try Self.makeHarness { _, calendar in
            calendar.mockIsAuthorized = false
        }

        await harness.store.dispatch(action: .settings(.calendarAudit(.sheetOpened(now: try Self.date(2026, 1, 15)))))

        #expect(harness.audit.errorMessage != nil)
        #expect(!harness.audit.isLoadingCalendars)
    }

    // MARK: - Running the audit

    @Test("Running the audit compares the app calendar with the chosen calendar")
    func runAuditProducesReport() async throws {
        let target = try Self.date(2026, 1, 5)
        let harness = try Self.makeHarness { _, calendar in
            calendar.mockShifts = [ScheduledShift(eventIdentifier: "evt-1", shiftType: Self.day, date: target)]
            calendar.mockExternalEvents["c1"] = [CalendarAudit.ExternalEvent(date: target, description: "N: Night")]
        }

        await harness.store.dispatch(action: .settings(.calendarAudit(.runAudit)))

        let report = try #require(harness.audit.report)
        #expect(report.days.count == 1)
        #expect(report.days.first?.outcome == .differs(.switchTo(Self.night, from: Self.day, eventIdentifier: "evt-1")))
        #expect(!harness.audit.isRunning)
        #expect(harness.audit.selectedFixDates == [target])
    }

    @Test("Running the audit with no calendar chosen reports an error")
    func runAuditWithoutCalendar() async throws {
        let harness = try Self.makeHarness { state, _ in
            state.settings.calendarAudit.selectedCalendarId = nil
        }

        await harness.store.dispatch(action: .settings(.calendarAudit(.runAudit)))

        #expect(harness.audit.report == nil)
        #expect(harness.audit.errorMessage != nil)
        #expect(!harness.audit.isRunning)
    }

    @Test("Running the audit with the start after the end reports an error")
    func runAuditWithInvertedRange() async throws {
        let harness = try Self.makeHarness { state, _ in
            state.settings.calendarAudit.startDate = try Self.date(2026, 2, 1)
            state.settings.calendarAudit.endDate = try Self.date(2026, 1, 1)
        }

        await harness.store.dispatch(action: .settings(.calendarAudit(.runAudit)))

        #expect(harness.audit.report == nil)
        #expect(harness.audit.errorMessage != nil)
        #expect(harness.calendar.loadCalendarEventsCallCount == 0)
    }

    // MARK: - Applying fixes

    @Test("Applying fixes creates, switches and removes shifts and logs each change; unticked days are untouched")
    func applyFixesPerformsSelectedChanges() async throws {
        let createDate = try Self.date(2026, 1, 6)
        let switchDate = try Self.date(2026, 1, 5)
        let removeDate = try Self.date(2026, 1, 7)
        let skippedDate = try Self.date(2026, 1, 8)

        let harness = try Self.makeHarness { state, calendar in
            calendar.mockShifts = [
                ScheduledShift(eventIdentifier: "evt-switch", shiftType: Self.day, date: switchDate),
                ScheduledShift(eventIdentifier: "evt-remove", shiftType: Self.day, date: removeDate)
            ]
            calendar.mockExternalEvents["c1"] = [
                CalendarAudit.ExternalEvent(date: switchDate, description: "N: Night"),
                CalendarAudit.ExternalEvent(date: createDate, description: "D: Day"),
                CalendarAudit.ExternalEvent(date: removeDate, description: "x: Off"),
                CalendarAudit.ExternalEvent(date: skippedDate, description: "N: Night")
            ]
            state.settings.calendarAudit.report = CalendarAudit.Report(
                days: [
                    CalendarAudit.Day(date: switchDate, appSymbol: "D", externalSymbol: "N",
                                      outcome: .differs(.switchTo(Self.night, from: Self.day, eventIdentifier: "evt-switch"))),
                    CalendarAudit.Day(date: createDate, appSymbol: nil, externalSymbol: "D",
                                      outcome: .differs(.create(Self.day))),
                    CalendarAudit.Day(date: removeDate, appSymbol: "D", externalSymbol: "x",
                                      outcome: .differs(.remove(current: Self.day, eventIdentifier: "evt-remove"))),
                    CalendarAudit.Day(date: skippedDate, appSymbol: nil, externalSymbol: "N",
                                      outcome: .differs(.create(Self.night)))
                ],
                skippedEventCount: 0
            )
            state.settings.calendarAudit.selectedFixDates = [switchDate, createDate, removeDate]
        }

        await harness.store.dispatch(action: .settings(.calendarAudit(.applyFixes)))

        #expect(harness.calendar.createShiftEventCallCount == 1)
        #expect(harness.calendar.updateShiftEventCallCount == 1)
        #expect(harness.calendar.deleteShiftEventCallCount == 1)

        let logged = harness.persistence.mockChangeLogEntries.sorted { $0.scheduledShiftDate < $1.scheduledShiftDate }
        #expect(logged.map(\.changeType) == [.switched, .created, .deleted])
        #expect(logged.map(\.scheduledShiftDate) == [switchDate, createDate, removeDate])

        #expect(harness.audit.successMessage == "Updated 3 dates")
        #expect(!harness.audit.isApplying)
    }

    @Test("A failure partway through reports how many were applied and keeps the earlier changes")
    func applyFixesPartialFailure() async throws {
        let firstDate = try Self.date(2026, 1, 5)
        let secondDate = try Self.date(2026, 1, 6)

        let harness = try Self.makeHarness { state, calendar in
            calendar.mockShifts = [ScheduledShift(eventIdentifier: "evt-ok", shiftType: Self.day, date: firstDate)]
            state.settings.calendarAudit.report = CalendarAudit.Report(
                days: [
                    CalendarAudit.Day(date: firstDate, appSymbol: "D", externalSymbol: "x",
                                      outcome: .differs(.remove(current: Self.day, eventIdentifier: "evt-ok"))),
                    CalendarAudit.Day(date: secondDate, appSymbol: "D", externalSymbol: "x",
                                      outcome: .differs(.remove(current: Self.day, eventIdentifier: "evt-missing")))
                ],
                skippedEventCount: 0
            )
            state.settings.calendarAudit.selectedFixDates = [firstDate, secondDate]
        }

        await harness.store.dispatch(action: .settings(.calendarAudit(.applyFixes)))

        let message = try #require(harness.audit.errorMessage)
        #expect(message.hasPrefix("Updated 1 date before an error"))
        #expect(harness.persistence.mockChangeLogEntries.count == 1)
        #expect(!harness.audit.isApplying)
    }
}
