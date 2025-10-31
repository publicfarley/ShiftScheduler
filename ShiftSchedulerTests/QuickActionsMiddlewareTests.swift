import Foundation
import Testing

@testable import ShiftScheduler

// MARK: - Quick Actions Middleware Tests

/// Tests for Quick Actions middleware side effects (delete, notes persistence)
@MainActor
struct QuickActionsMiddlewareTests {

    // MARK: - Delete Shift Middleware Tests

    @Test
    func deleteShiftSuccessfully() async {
        let testShift = makeTestShift(date: Date())
        var dispatchedActions: [TodayAction] = []

        let mockServices = ServiceContainer(
            calendarService: MockCalendarService(),
            persistenceService: MockPersistenceService(),
            shiftSwitchService: MockShiftSwitchService(),
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

        // Verify middleware dispatched success action
        #expect(dispatchedActions.contains { action in
            if case .shiftDeleted(.success) = action {
                return true
            }
            return false
        })

        // Verify reload shifts was dispatched
        #expect(dispatchedActions.contains { action in
            if case .loadShifts = action {
                return true
            }
            return false
        })
    }

    @Test
    func deleteWithoutConfirmationShift() async {
        var dispatchedActions: [TodayAction] = []

        let mockServices = ServiceContainer(
            calendarService: MockCalendarService(),
            persistenceService: MockPersistenceService(),
            shiftSwitchService: MockShiftSwitchService(),
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
            shiftSwitchService: MockShiftSwitchService(),
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
        let savedEntries = mockPersistence.allSavedChangeLogEntries()
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
            shiftSwitchService: MockShiftSwitchService(),
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
            shiftSwitchService: MockShiftSwitchService(),
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

    // MARK: - State Transitions

    @Test
    func deleteFollowedByNotesEdit() async {
        let testShift = makeTestShift(date: Date())
        let mockServices = ServiceContainer(
            calendarService: MockCalendarService(),
            persistenceService: MockPersistenceService(),
            shiftSwitchService: MockShiftSwitchService(),
            currentDayService: MockCurrentDayService()
        )

        var state = makeAppStateWithShift(testShift)
        state.today.deleteShiftConfirmationShift = testShift

        var dispatchedActions: [AppAction] = []
        let dispatcher: Dispatcher<AppAction> = { action in
            dispatchedActions.append(action)
        }

        // Delete shift
        await todayMiddleware(
            state: state,
            action: .today(.deleteShiftConfirmed),
            services: mockServices,
            dispatch: dispatcher
        )

        // Verify delete actions were dispatched
        #expect(dispatchedActions.count >= 2) // At least shiftDeleted + loadShifts
    }
}

// MARK: - Test Helpers

private func makeAppState() -> AppState {
    AppState()
}

private func makeAppStateWithShift(_ shift: ScheduledShift) -> AppState {
    var state = AppState()
    state.today.scheduledShifts = [shift]
    state.today.todayShift = shift
    return state
}

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
