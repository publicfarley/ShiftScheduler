import Foundation
import Testing

@testable import ShiftScheduler

// MARK: - Bulk Delete Middleware Tests

@MainActor
@Suite("Bulk Delete Middleware")
struct BulkDeleteMiddlewareTests {
    // MARK: - Success Cases

    @Test("bulkDeleteConfirmed deletes all selected shifts")
    func bulkDeleteConfirmedDeletesAllShifts() async throws {
        // Setup
        let mockCalendarService = MockCalendarService()
        let mockPersistenceService = MockPersistenceService()
        let services = ServiceContainer(
            calendarService: mockCalendarService,
            persistenceService: mockPersistenceService,
            currentDayService: MockCurrentDayService()
        )

        let shiftType = ShiftTypeBuilder.nightShift()
        let shift1 = ScheduledShift(id: UUID(), eventIdentifier: "event1", shiftType: shiftType, date: try Date.fixedTestDate_Nov11_2025(), notes: nil)
        let shift2 = ScheduledShift(id: UUID(), eventIdentifier: "event2", shiftType: shiftType, date: try Date.fixedTestDate_Nov11_2025(), notes: nil)
        let shift3 = ScheduledShift(id: UUID(), eventIdentifier: "event3", shiftType: shiftType, date: try Date.fixedTestDate_Nov11_2025(), notes: nil)

        var state = AppState()
        state.schedule.scheduledShifts = [shift1, shift2, shift3]
        state.schedule.undoStack = []

        mockCalendarService.mockShifts = [shift1, shift2, shift3]

        let dispatchedActions = expectAnyDispatch()

        // Execute
        let shiftIds = [shift1.id, shift3.id]
        await scheduleMiddleware(
            state: state,
            action: .schedule(.bulkDeleteConfirmed(shiftIds)),
            services: services,
            dispatch: dispatchedActions.dispatch
        )

        // Verify
        #expect(mockCalendarService.deleteMultipleShiftEventsCallCount == 1)
        #expect(mockPersistenceService.addMultipleChangeLogEntriesCallCount == 1)
        #expect(mockPersistenceService.saveUndoRedoStacksCallCount == 1)

        // Should dispatch bulkDeleteCompleted with success
        let bulkDeleteCompletedAction = dispatchedActions.getActions().first { action in
            if case .schedule(.bulkDeleteCompleted(.success(let count))) = action {
                return count == 2
            }
            return false
        }
        #expect(bulkDeleteCompletedAction != nil)
    }

    @Test("bulkDeleteConfirmed creates change log entries for deleted shifts")
    func bulkDeleteConfirmedCreatesChangeLogEntries() async throws {
        let mockCalendarService = MockCalendarService()
        let mockPersistenceService = MockPersistenceService()
        let services = ServiceContainer(
            calendarService: mockCalendarService,
            persistenceService: mockPersistenceService,
            currentDayService: MockCurrentDayService()
        )

        let shiftType = ShiftTypeBuilder.nightShift()
        let shift1 = ScheduledShift(id: UUID(), eventIdentifier: "event1", shiftType: shiftType, date: try Date.fixedTestDate_Nov11_2025(), notes: nil)
        let shift2 = ScheduledShift(id: UUID(), eventIdentifier: "event2", shiftType: shiftType, date: try Date.fixedTestDate_Nov11_2025(), notes: nil)

        var state = AppState()
        state.schedule.scheduledShifts = [shift1, shift2]
        state.schedule.undoStack = []

        mockCalendarService.mockShifts = [shift1, shift2]

        let dispatchedActions = expectAnyDispatch()

        // Execute
        await scheduleMiddleware(
            state: state,
            action: .schedule(.bulkDeleteConfirmed([shift1.id, shift2.id])),
            services: services,
            dispatch: dispatchedActions.dispatch
        )

        // Verify
        #expect(mockPersistenceService.mockChangeLogEntries.count == 2)
        #expect(mockPersistenceService.mockChangeLogEntries.allSatisfy { $0.changeType == .deleted })
    }

    @Test("bulkDeleteConfirmed updates undo stack with deleted shifts")
    func bulkDeleteConfirmedUpdatesUndoStack() async throws {
        let mockCalendarService = MockCalendarService()
        let mockPersistenceService = MockPersistenceService()
        let services = ServiceContainer(
            calendarService: mockCalendarService,
            persistenceService: mockPersistenceService,
            currentDayService: MockCurrentDayService()
        )

        let shiftType = ShiftTypeBuilder.nightShift()
        let shift1 = ScheduledShift(id: UUID(), eventIdentifier: "event1", shiftType: shiftType, date: try Date.fixedTestDate_Nov11_2025(), notes: nil)

        var state = AppState()
        state.schedule.scheduledShifts = [shift1]
        state.schedule.undoStack = []

        mockCalendarService.mockShifts = [shift1]

        let dispatchedActions = expectAnyDispatch()

        // Execute
        await scheduleMiddleware(
            state: state,
            action: .schedule(.bulkDeleteConfirmed([shift1.id])),
            services: services,
            dispatch: dispatchedActions.dispatch
        )

        // Verify - undo stack should be saved with the deleted shift entry
        #expect(mockPersistenceService.saveUndoRedoStacksCallCount == 1)
    }

    @Test("bulkDeleteConfirmed returns correct count of deleted shifts")
    func bulkDeleteConfirmedReturnsCorrectCount() async throws {
        let mockCalendarService = MockCalendarService()
        let mockPersistenceService = MockPersistenceService()
        let services = ServiceContainer(
            calendarService: mockCalendarService,
            persistenceService: mockPersistenceService,
            currentDayService: MockCurrentDayService()
        )

        let shiftType = ShiftTypeBuilder.nightShift()
        let shifts = (0..<5).map { i in
            ScheduledShift(
                id: UUID(),
                eventIdentifier: "event\(i)",
                shiftType: shiftType,
                date: try Date.fixedTestDate_Nov11_2025(),
                notes: nil
            )
        }

        var state = AppState()
        state.schedule.scheduledShifts = shifts
        state.schedule.undoStack = []

        mockCalendarService.mockShifts = shifts

        let dispatchedActions = expectAnyDispatch()

        // Execute - delete 3 out of 5 shifts
        let shiftIdsToDelete = [shifts[0].id, shifts[2].id, shifts[4].id]
        await scheduleMiddleware(
            state: state,
            action: .schedule(.bulkDeleteConfirmed(shiftIdsToDelete)),
            services: services,
            dispatch: dispatchedActions.dispatch
        )

        // Verify
        let successAction = dispatchedActions.getActions().first { action in
            if case .schedule(.bulkDeleteCompleted(.success(let count))) = action {
                return count == 3
            }
            return false
        }
        #expect(successAction != nil)
    }

    // MARK: - Error Cases

    @Test("bulkDeleteConfirmed handles missing shifts gracefully")
    func bulkDeleteConfirmedHandlesEmptySelection() async throws {
        let mockCalendarService = MockCalendarService()
        let mockPersistenceService = MockPersistenceService()
        let services = ServiceContainer(
            calendarService: mockCalendarService,
            persistenceService: mockPersistenceService,
            currentDayService: MockCurrentDayService()
        )

        var state = AppState()
        state.schedule.scheduledShifts = []
        state.schedule.undoStack = []

        let dispatchedActions = expectAnyDispatch()

        // Execute - try to delete non-existent shifts
        await scheduleMiddleware(
            state: state,
            action: .schedule(.bulkDeleteConfirmed([UUID(), UUID()])),
            services: services,
            dispatch: dispatchedActions.dispatch
        )

        // Verify - should return success with 0 count
        let successAction = dispatchedActions.getActions().first { action in
            if case .schedule(.bulkDeleteCompleted(.success(let count))) = action {
                return count == 0
            }
            return false
        }
        #expect(successAction != nil)
    }

    @Test("bulkDeleteConfirmed handles calendar service failure")
    func bulkDeleteConfirmedHandlesCalendarServiceError() async throws {
        let mockCalendarService = MockCalendarService()
        mockCalendarService.shouldThrowError = true
        mockCalendarService.throwError = ScheduleError.calendarEventDeletionFailed("Test error")

        let mockPersistenceService = MockPersistenceService()
        let services = ServiceContainer(
            calendarService: mockCalendarService,
            persistenceService: mockPersistenceService,
            currentDayService: MockCurrentDayService()
        )

        let shiftType = ShiftTypeBuilder.nightShift()
        let shift1 = ScheduledShift(id: UUID(), eventIdentifier: "event1", shiftType: shiftType, date: try Date.fixedTestDate_Nov11_2025(), notes: nil)

        var state = AppState()
        state.schedule.scheduledShifts = [shift1]
        state.schedule.undoStack = []

        mockCalendarService.mockShifts = [shift1]

        let dispatchedActions = expectAnyDispatch()

        // Execute
        await scheduleMiddleware(
            state: state,
            action: .schedule(.bulkDeleteConfirmed([shift1.id])),
            services: services,
            dispatch: dispatchedActions.dispatch
        )

        // Verify - should dispatch failure
        let failureAction = dispatchedActions.getActions().first { action in
            if case .schedule(.bulkDeleteCompleted(.failure)) = action {
                return true
            }
            return false
        }
        #expect(failureAction != nil)
    }

    @Test("bulkDeleteConfirmed handles persistence service failure")
    func bulkDeleteConfirmedHandlesPersistenceError() async throws {
        let mockCalendarService = MockCalendarService()
        let mockPersistenceService = MockPersistenceService()
        mockPersistenceService.shouldThrowError = true
        mockPersistenceService.throwError = PersistenceError.saveFailed("Test error")

        let services = ServiceContainer(
            calendarService: mockCalendarService,
            persistenceService: mockPersistenceService,
            currentDayService: MockCurrentDayService()
        )

        let shiftType = ShiftTypeBuilder.nightShift()
        let shift1 = ScheduledShift(id: UUID(), eventIdentifier: "event1", shiftType: shiftType, date: try Date.fixedTestDate_Nov11_2025(), notes: nil)

        var state = AppState()
        state.schedule.scheduledShifts = [shift1]
        state.schedule.undoStack = []

        mockCalendarService.mockShifts = [shift1]

        let dispatchedActions = expectAnyDispatch()

        // Execute
        await scheduleMiddleware(
            state: state,
            action: .schedule(.bulkDeleteConfirmed([shift1.id])),
            services: services,
            dispatch: dispatchedActions.dispatch
        )

        // Verify - should dispatch failure
        let failureAction = dispatchedActions.getActions().first { action in
            if case .schedule(.bulkDeleteCompleted(.failure)) = action {
                return true
            }
            return false
        }
        #expect(failureAction != nil)
    }

    // MARK: - Side Effects

    @Test("bulkDeleteConfirmed triggers shift reload after deletion")
    func bulkDeleteConfirmedTriggersShiftReload() async throws {
        let mockCalendarService = MockCalendarService()
        let mockPersistenceService = MockPersistenceService()
        let services = ServiceContainer(
            calendarService: mockCalendarService,
            persistenceService: mockPersistenceService,
            currentDayService: MockCurrentDayService()
        )

        let shiftType = ShiftTypeBuilder.nightShift()
        let shift1 = ScheduledShift(id: UUID(), eventIdentifier: "event1", shiftType: shiftType, date: try Date.fixedTestDate_Nov11_2025(), notes: nil)

        var state = AppState()
        state.schedule.scheduledShifts = [shift1]
        state.schedule.undoStack = []

        mockCalendarService.mockShifts = [shift1]

        let dispatchedActions = expectAnyDispatch()

        // Execute
        await scheduleMiddleware(
            state: state,
            action: .schedule(.bulkDeleteConfirmed([shift1.id])),
            services: services,
            dispatch: dispatchedActions.dispatch
        )

        // Verify - should dispatch loadShiftsAroundMonth
        let reloadAction = dispatchedActions.getActions().first { action in
            if case .schedule(.loadShiftsAroundMonth) = action {
                return true
            }
            return false
        }
        #expect(reloadAction != nil)
    }

    @Test("bulkDeleteConfirmed triggers change log reload")
    func bulkDeleteConfirmedTriggersChangeLogReload() async throws {
        let mockCalendarService = MockCalendarService()
        let mockPersistenceService = MockPersistenceService()
        let services = ServiceContainer(
            calendarService: mockCalendarService,
            persistenceService: mockPersistenceService,
            currentDayService: MockCurrentDayService()
        )

        let shiftType = ShiftTypeBuilder.nightShift()
        let shift1 = ScheduledShift(id: UUID(), eventIdentifier: "event1", shiftType: shiftType, date: try Date.fixedTestDate_Nov11_2025(), notes: nil)

        var state = AppState()
        state.schedule.scheduledShifts = [shift1]
        state.schedule.undoStack = []

        mockCalendarService.mockShifts = [shift1]

        let dispatchedActions = expectAnyDispatch()

        // Execute
        await scheduleMiddleware(
            state: state,
            action: .schedule(.bulkDeleteConfirmed([shift1.id])),
            services: services,
            dispatch: dispatchedActions.dispatch
        )

        // Verify - should dispatch changeLog.loadChangeLogEntries
        let changeLogAction = dispatchedActions.getActions().first { action in
            if case .changeLog(.loadChangeLogEntries) = action {
                return true
            }
            return false
        }
        #expect(changeLogAction != nil)
    }

    // MARK: - Multiple Shift Operations

    @Test("bulkDeleteConfirmed handles large batch of shifts")
    func bulkDeleteConfirmedHandlesLargeBatch() async throws {
        let mockCalendarService = MockCalendarService()
        let mockPersistenceService = MockPersistenceService()
        let services = ServiceContainer(
            calendarService: mockCalendarService,
            persistenceService: mockPersistenceService,
            currentDayService: MockCurrentDayService()
        )

        let shiftType = ShiftTypeBuilder.nightShift()
        let shifts = (0..<20).map { i in
            ScheduledShift(
                id: UUID(),
                eventIdentifier: "event\(i)",
                shiftType: shiftType,
                date: try Date.fixedTestDate_Nov11_2025(),
                notes: nil
            )
        }

        var state = AppState()
        state.schedule.scheduledShifts = shifts
        state.schedule.undoStack = []

        mockCalendarService.mockShifts = shifts

        let dispatchedActions = expectAnyDispatch()

        // Execute - delete all 20 shifts
        let shiftIds = shifts.map { $0.id }
        await scheduleMiddleware(
            state: state,
            action: .schedule(.bulkDeleteConfirmed(shiftIds)),
            services: services,
            dispatch: dispatchedActions.dispatch
        )

        // Verify
        let successAction = dispatchedActions.getActions().first { action in
            if case .schedule(.bulkDeleteCompleted(.success(let count))) = action {
                return count == 20
            }
            return false
        }
        #expect(successAction != nil)
        #expect(mockPersistenceService.mockChangeLogEntries.count == 20)
    }

    // MARK: - Helper Functions

    private func expectAnyDispatch() -> (getActions: () -> [AppAction], dispatch: @Sendable (AppAction) async -> Void) {
        final class ActionCapture: @unchecked Sendable {
            var actions: [AppAction] = []
            let lock = NSLock()

            func append(_ action: AppAction) {
                lock.lock()
                defer { lock.unlock() }
                actions.append(action)
            }

            func getActions() -> [AppAction] {
                lock.lock()
                defer { lock.unlock() }
                return actions
            }
        }

        let capture = ActionCapture()
        let dispatch: @Sendable (AppAction) async -> Void = { action in
            capture.append(action)
        }
        return (capture.getActions, dispatch)
    }
}
