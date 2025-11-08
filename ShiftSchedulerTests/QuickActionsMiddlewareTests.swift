import Foundation
import Testing

@testable import ShiftScheduler

// MARK: - Quick Actions Middleware Tests

/// Tests for Quick Actions middleware side effects (delete, notes persistence)
@MainActor
struct QuickActionsMiddlewareTests {

    // MARK: - Delete Shift Middleware Tests

    @Test
    func deleteShiftSuccessfully() async throws {
        
        let mockCalendar = MockCalendarService()
        mockCalendar.mockIsAuthorized = true
        let mockServices = ServiceContainer(
            calendarService: mockCalendar,
            persistenceService: MockPersistenceService(),
            currentDayService: MockCurrentDayService()
        )

        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: mockServices,
            middlewares: [todayMiddleware, scheduleMiddleware]
        )

        let addedShiftNote = "Added Shift"
        
        await store.dispatch(
            action: AppAction.schedule(
                .addShift(
                    date: .distantFuture,
                    shiftType: ShiftTypeBuilder.afternoonShift(),
                    notes: addedShiftNote
                )
            )
        )
        
        await store.dispatch(action: .schedule(.loadShifts))
        
        #expect(
            store.state.schedule.scheduledShifts.contains(
                where: { $0.notes == addedShiftNote }
            )
        )
        
        let addedShift = try #require(
            store.state.schedule.scheduledShifts.first(
                where: { $0.notes == addedShiftNote }
            )
        )

        await store.dispatch(action: .today(.deleteShiftRequested(addedShift)))
        
        await store.dispatch(action: .schedule(.loadShifts))

        #expect(store.state.schedule.scheduledShifts.isEmpty)
    }

    @Test
    func deleteWithoutConfirmationShift() async {
        var dispatchedActions: [TodayAction] = []

        let mockServices = ServiceContainer(
            calendarService: MockCalendarService(),
            persistenceService: MockPersistenceService(),
            currentDayService: MockCurrentDayService()
        )

        let state = makeAppState()
        // No deleteShiftConfirmationShift set

        let dispatcher: Dispatcher<AppAction> = { action in
            if case .today(let todayAction) = action {
                dispatchedActions.append(todayAction)
            }
        }

        let appAction = AppAction.today(.deleteShiftConfirmed)
        await todayMiddleware(state: state, action: appAction, services: mockServices, dispatch: dispatcher)

        // No actions should be dispatched when there's no shift to delete
        #expect(dispatchedActions.isEmpty)
    }

    @Test
    func deleteCreatesChangeLogEntry() async {
        let testShift = makeTestShift(date: Date())
        let mockPersistence = MockPersistenceService()
        var dispatchedActions: [TodayAction] = []

        let mockServices = ServiceContainer(
            calendarService: MockCalendarService(),
            persistenceService: mockPersistence,
            currentDayService: MockCurrentDayService()
        )

        var state = makeAppStateWithShift(testShift)
        state.today.deleteShiftConfirmationShift = testShift

        let dispatcher: Dispatcher<AppAction> = { action in
            if case .today(let todayAction) = action {
                dispatchedActions.append(todayAction)
            }
        }

        let appAction = AppAction.today(.deleteShiftConfirmed)
        await todayMiddleware(state: state, action: appAction, services: mockServices, dispatch: dispatcher)

        // Verify a change log entry was created (check mock persistence)
        let savedEntries = mockPersistence.mockChangeLogEntries
        #expect(!savedEntries.isEmpty)
        #expect(savedEntries.last?.changeType == .deleted)
    }

    // MARK: - Notes Persistence Tests

    @Test
    func notesPersistedOnSheetClose() async {
        let testShift = makeTestShift(date: Date())
        let testNotes = "Updated shift notes"
        var dispatchedActions: [TodayAction] = []

        let mockServices = ServiceContainer(
            calendarService: MockCalendarService(),
            persistenceService: MockPersistenceService(),
            currentDayService: MockCurrentDayService()
        )

        var state = makeAppStateWithShift(testShift)
        state.today.todayShift = testShift
        state.today.showEditNotesSheet = true
        state.today.quickActionsNotes = testNotes

        let dispatcher: Dispatcher<AppAction> = { action in
            if case .today(let todayAction) = action {
                dispatchedActions.append(todayAction)
            }
        }

        let appAction = AppAction.today(.editNotesSheetToggled(false))
        await todayMiddleware(state: state, action: appAction, services: mockServices, dispatch: dispatcher)

        // Notes should be persisted (no error actions dispatched)
        #expect(!dispatchedActions.contains { action in
            if case .shiftsLoaded(.failure) = action {
                return true
            }
            return false
        })
    }

    @Test
    func notesNotPersistedOnSheetOpen() async {
        var dispatchedActions: [TodayAction] = []

        let mockServices = ServiceContainer(
            calendarService: MockCalendarService(),
            persistenceService: MockPersistenceService(),
            currentDayService: MockCurrentDayService()
        )

        let state = makeAppState()

        let dispatcher: Dispatcher<AppAction> = { action in
            if case .today(let todayAction) = action {
                dispatchedActions.append(todayAction)
            }
        }

        let appAction = AppAction.today(.editNotesSheetToggled(true))
        await todayMiddleware(state: state, action: appAction, services: mockServices, dispatch: dispatcher)

        // No persistence actions should be dispatched
        #expect(dispatchedActions.isEmpty)
    }
}

// MARK: - Test Helpers
@MainActor
private func makeAppState() -> AppState {
    AppState()
}

@MainActor
private func makeAppStateWithShift(_ shift: ScheduledShift) -> AppState {
    var state = AppState()
    state.today.scheduledShifts = [shift]
    state.today.todayShift = shift
    return state
}

@MainActor
private func makeTestShift(date: Date = Date()) -> ScheduledShift {
    ScheduledShift(
        id: UUID(),
        eventIdentifier: "test-event-\(UUID().uuidString)",
        shiftType: ShiftType(
            id: UUID(),
            symbol: "sun.max.fill",
            duration: .scheduled(
                from: HourMinuteTime(hour: 9, minute: 0),
                to: HourMinuteTime(hour: 17, minute: 0)
            ),
            title: "Test Shift",
            description: "A test shift",
            location: Location(id: UUID(), name: "Test Office", address: "123 Main St")
        ),
        date: date,
        notes: nil
    )
}
