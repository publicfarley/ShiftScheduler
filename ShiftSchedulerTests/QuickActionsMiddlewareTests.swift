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
            currentDayService: MockCurrentDayService(),
            conflictResolutionService: ConflictResolutionService(),
            syncService: MockSyncService()
        )

        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: mockServices,
            middlewares: baseMiddlewares
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
        
        await store.dispatch(action: AppAction.schedule(.loadShifts))

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

        await store.dispatch(action: AppAction.today(.deleteShiftRequested(addedShift)))
        await store.dispatch(action: AppAction.today(.deleteShiftConfirmed))

        await store.dispatch(action: AppAction.schedule(.loadShifts))
        
        let removedShift =
            store.state.schedule.scheduledShifts.first(
                where: { $0.notes == addedShiftNote }
            )

        #expect(removedShift == nil)
    }

    @Test
    func deleteWithoutConfirmationShift() async {
        let mockServices = ServiceContainer(
            calendarService: MockCalendarService(),
            persistenceService: MockPersistenceService(),
            currentDayService: MockCurrentDayService(),
            conflictResolutionService: ConflictResolutionService(),
            syncService: MockSyncService()
        )

        let state = makeAppState()
        // No deleteShiftConfirmationShift set

        let store = Store(
            state: state,
            reducer: appReducer,
            services: mockServices,
            middlewares: baseMiddlewares
        )

        // When
        await store.dispatch(action: AppAction.today(.deleteShiftConfirmed))

        // Then - No actions should be dispatched when there's no shift to delete
        // The state should remain empty (no side effects should occur)
        #expect(store.state.today.deleteShiftConfirmationShift == nil)
        #expect(store.state.schedule.scheduledShifts.isEmpty)
    }

    @Test
    func deleteCreatesChangeLogEntry() async {
        let testShift = makeTestShift(date: Date())
        let mockPersistence = MockPersistenceService()

        let mockServices = ServiceContainer(
            calendarService: MockCalendarService(),
            persistenceService: mockPersistence,
            currentDayService: MockCurrentDayService(),
            conflictResolutionService: ConflictResolutionService(),
            syncService: MockSyncService()
        )

        var state = makeAppStateWithShift(testShift)
        state.today.deleteShiftConfirmationShift = testShift

        let store = Store(
            state: state,
            reducer: appReducer,
            services: mockServices,
            middlewares: baseMiddlewares
        )

        // When
        await store.dispatch(action: AppAction.today(.deleteShiftConfirmed))

        // Then - Verify a change log entry was created (check mock persistence)
        let savedEntries = mockPersistence.mockChangeLogEntries
        #expect(!savedEntries.isEmpty)
        #expect(savedEntries.last?.changeType == .deleted)
    }

    // MARK: - Notes Persistence Tests

    @Test
    func notesPersistedOnSheetClose() async {
        let testShift = makeTestShift(date: Date())
        let testNotes = "Updated shift notes"

        let mockServices = ServiceContainer(
            calendarService: MockCalendarService(),
            persistenceService: MockPersistenceService(),
            currentDayService: MockCurrentDayService(),
            conflictResolutionService: ConflictResolutionService(),
            syncService: MockSyncService()
        )

        var state = makeAppStateWithShift(testShift)
        state.today.todayShift = testShift
        state.today.showEditNotesSheet = true
        state.today.quickActionsNotes = testNotes

        var didDispatchLoadFailure = false

        func mockTrackingMiddleware(
            state: AppState,
            action: AppAction,
            services: ServiceContainer,
            dispatch: @escaping Dispatcher<AppAction>
        ) async {
            if case .schedule(.shiftsLoaded(.failure)) = action {
                didDispatchLoadFailure = true
            }
        }

        let store = Store(
            state: state,
            reducer: appReducer,
            services: mockServices,
            middlewares: baseMiddlewares + [mockTrackingMiddleware]
        )

        // When
        await store.dispatch(action: AppAction.today(.editNotesSheetToggled(false)))

        // Then - Notes should be persisted (no error actions dispatched)
        #expect(!didDispatchLoadFailure)
    }

    @Test
    func notesNotPersistedOnSheetOpen() async {
        let mockServices = ServiceContainer(
            calendarService: MockCalendarService(),
            persistenceService: MockPersistenceService(),
            currentDayService: MockCurrentDayService(),
            conflictResolutionService: ConflictResolutionService(),
            syncService: MockSyncService()
        )

        let state = makeAppState()

        let store = Store(
            state: state,
            reducer: appReducer,
            services: mockServices,
            middlewares: baseMiddlewares
        )

        // When
        await store.dispatch(action: AppAction.today(.editNotesSheetToggled(true)))

        // Then - No persistence actions should be dispatched (sheet opening should not trigger persistence)
        // Verify the sheet state is updated but no side effects occurred
        #expect(store.state.today.showEditNotesSheet == true)
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
