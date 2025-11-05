import Testing
import Foundation
@testable import ShiftScheduler

/// Tests for Change Log feature middleware
/// Validates that ChangeLogMiddleware correctly handles side effects and dispatches secondary actions
@Suite("ChangeLogMiddleware Tests")
@MainActor
struct ChangeLogMiddlewareTests {

    // MARK: - Test Helpers

    /// Create a test service container with mocks
    static func createMockServiceContainer() -> ServiceContainer {
        ServiceContainer(
            calendarService: MockCalendarService(),
            persistenceService: MockPersistenceService(),
            currentDayService: CurrentDayService()
        )
    }

    // MARK: - Load Entries Tests (.task action)

    @Test("task action loads entries and dispatches entriesLoaded success")
    func testTaskActionLoadsEntries() async {
        // Given
        let mockServices = Self.createMockServiceContainer()
        let mockPersistence = mockServices.persistenceService as! MockPersistenceService

        let testEntries = [
            ChangeLogEntryBuilder(userDisplayName: "Alice").build(),
            ChangeLogEntryBuilder(userDisplayName: "Bob").build()
        ]
        mockPersistence.mockChangeLogEntries = testEntries

        var dispatchedAction: AppAction? = nil
        let dispatcher: Dispatcher<AppAction> = { action in
            dispatchedAction = action
        }

        let state = AppState()

        // When
        await changeLogMiddleware(
            state: state,
            action: .changeLog(.task),
            services: mockServices,
            dispatch: dispatcher
        )

        // Then
        #expect(mockPersistence.loadChangeLogEntriesCallCount == 1)

        // Verify correct secondary action was dispatched
        if case .changeLog(.entriesLoaded(.success(let entries))) = dispatchedAction {
            #expect(entries.count == 2)
            #expect(entries[0].userDisplayName == "Alice")
            #expect(entries[1].userDisplayName == "Bob")
        } else {
            #expect(Bool(false), "Expected entriesLoaded success action")
        }
    }

    @Test("task action handles empty entries list")
    func testTaskActionWithEmptyEntries() async {
        // Given
        let mockServices = Self.createMockServiceContainer()
        let mockPersistence = mockServices.persistenceService as! MockPersistenceService

        mockPersistence.mockChangeLogEntries = []

        var dispatchedAction: AppAction? = nil
        let dispatcher: Dispatcher<AppAction> = { action in
            dispatchedAction = action
        }

        let state = AppState()

        // When
        await changeLogMiddleware(
            state: state,
            action: .changeLog(.task),
            services: mockServices,
            dispatch: dispatcher
        )

        // Then
        #expect(mockPersistence.loadChangeLogEntriesCallCount == 1)

        if case .changeLog(.entriesLoaded(.success(let entries))) = dispatchedAction {
            #expect(entries.isEmpty)
        } else {
            #expect(Bool(false), "Expected entriesLoaded success action with empty array")
        }
    }

    @Test("task action dispatches entriesLoaded failure on persistence error")
    func testTaskActionErrorHandling() async {
        // Given
        let mockServices = Self.createMockServiceContainer()
        let mockPersistence = mockServices.persistenceService as! MockPersistenceService

        let testError = NSError(domain: "Test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to load"])
        mockPersistence.shouldThrowError = true
        mockPersistence.throwError = testError

        var dispatchedAction: AppAction? = nil
        let dispatcher: Dispatcher<AppAction> = { action in
            dispatchedAction = action
        }

        let state = AppState()

        // When
        await changeLogMiddleware(
            state: state,
            action: .changeLog(.task),
            services: mockServices,
            dispatch: dispatcher
        )

        // Then
        #expect(mockPersistence.loadChangeLogEntriesCallCount == 1)

        if case .changeLog(.entriesLoaded(.failure)) = dispatchedAction {
            // Success - error was dispatched correctly
        } else {
            #expect(Bool(false), "Expected entriesLoaded failure action")
        }
    }

    // MARK: - Delete Entry Tests (.deleteEntry action)

    @Test("deleteEntry action deletes entry and dispatches entryDeleted success")
    func testDeleteEntrySuccess() async {
        // Given
        let mockServices = Self.createMockServiceContainer()
        let mockPersistence = mockServices.persistenceService as! MockPersistenceService

        let entry = ChangeLogEntryBuilder(userDisplayName: "Alice").build()
        mockPersistence.mockChangeLogEntries = [entry]

        var dispatchedAction: AppAction? = nil
        let dispatcher: Dispatcher<AppAction> = { action in
            dispatchedAction = action
        }

        let state = AppState()

        // When
        await changeLogMiddleware(
            state: state,
            action: .changeLog(.deleteEntry(entry)),
            services: mockServices,
            dispatch: dispatcher
        )

        // Then
        #expect(mockPersistence.deleteChangeLogEntryCallCount == 1)
        #expect(mockPersistence.lastDeletedChangeLogEntryId == entry.id)

        if case .changeLog(.entryDeleted(.success)) = dispatchedAction {
            // Success - correct action dispatched
        } else {
            #expect(Bool(false), "Expected entryDeleted success action")
        }
    }

    @Test("deleteEntry action dispatches entryDeleted failure on error")
    func testDeleteEntryFailure() async {
        // Given
        let mockServices = Self.createMockServiceContainer()
        let mockPersistence = mockServices.persistenceService as! MockPersistenceService

        let testError = NSError(domain: "Test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Delete failed"])
        mockPersistence.shouldThrowError = true
        mockPersistence.throwError = testError

        let entry = ChangeLogEntryBuilder(userDisplayName: "Alice").build()

        var dispatchedAction: AppAction? = nil
        let dispatcher: Dispatcher<AppAction> = { action in
            dispatchedAction = action
        }

        let state = AppState()

        // When
        await changeLogMiddleware(
            state: state,
            action: .changeLog(.deleteEntry(entry)),
            services: mockServices,
            dispatch: dispatcher
        )

        // Then
        #expect(mockPersistence.deleteChangeLogEntryCallCount == 1)
        #expect(mockPersistence.lastDeletedChangeLogEntryId == entry.id)

        if case .changeLog(.entryDeleted(.failure)) = dispatchedAction {
            // Success - error was dispatched correctly
        } else {
            #expect(Bool(false), "Expected entryDeleted failure action")
        }
    }

    @Test("deleteEntry passes correct entry ID to service")
    func testDeleteEntryPassesCorrectId() async {
        // Given
        let mockServices = Self.createMockServiceContainer()
        let mockPersistence = mockServices.persistenceService as! MockPersistenceService

        let entry = ChangeLogEntryBuilder(userDisplayName: "Test").build()

        var dispatchedActions: [AppAction] = []
        let dispatcher: Dispatcher<AppAction> = { action in
            dispatchedActions.append(action)
        }

        let state = AppState()

        // When
        await changeLogMiddleware(
            state: state,
            action: .changeLog(.deleteEntry(entry)),
            services: mockServices,
            dispatch: dispatcher
        )

        // Then
        #expect(mockPersistence.lastDeletedChangeLogEntryId == entry.id)
    }

    // MARK: - Purge Old Entries Tests (.purgeOldEntries action)

    @Test("purgeOldEntries with 30-day policy purges correctly")
    func testPurgeOldEntriesWith30DayPolicy() async {
        // Given
        let mockServices = Self.createMockServiceContainer()
        let mockPersistence = mockServices.persistenceService as! MockPersistenceService

        // Create entries - some old, some recent
        let now = Date()
        let fiftyDaysAgo = Calendar.current.date(byAdding: .day, value: -50, to: now)!
        let tenDaysAgo = Calendar.current.date(byAdding: .day, value: -10, to: now)!

        mockPersistence.mockChangeLogEntries = [
            ChangeLogEntryBuilder(timestamp: fiftyDaysAgo).build(),
            ChangeLogEntryBuilder(timestamp: tenDaysAgo).build()
        ]

        var dispatchedAction: AppAction? = nil
        let dispatcher: Dispatcher<AppAction> = { action in
            dispatchedAction = action
        }

        var state = AppState()
        state.settings.retentionPolicy = .days30

        // When
        await changeLogMiddleware(
            state: state,
            action: .changeLog(.purgeOldEntries),
            services: mockServices,
            dispatch: dispatcher
        )

        // Then
        #expect(mockPersistence.purgeOldChangeLogEntriesCallCount == 1)
        #expect(mockPersistence.lastPurgeOldEntriesCutoffDate != nil)

        if case .changeLog(.purgeCompleted(.success)) = dispatchedAction {
            // Success - correct action dispatched
        } else {
            #expect(Bool(false), "Expected purgeCompleted success action")
        }
    }

    @Test("purgeOldEntries with Forever policy skips purge")
    func testPurgeOldEntriesWithForeverPolicy() async {
        // Given
        let mockServices = Self.createMockServiceContainer()
        let mockPersistence = mockServices.persistenceService as! MockPersistenceService

        // Create old entries that would normally be purged
        let fiftyDaysAgo = Calendar.current.date(byAdding: .day, value: -50, to: Date())!
        mockPersistence.mockChangeLogEntries = [
            ChangeLogEntryBuilder(timestamp: fiftyDaysAgo).build()
        ]

        var dispatchedAction: AppAction? = nil
        let dispatcher: Dispatcher<AppAction> = { action in
            dispatchedAction = action
        }

        var state = AppState()
        state.settings.retentionPolicy = .forever

        // When
        await changeLogMiddleware(
            state: state,
            action: .changeLog(.purgeOldEntries),
            services: mockServices,
            dispatch: dispatcher
        )

        // Then
        // Should NOT call purge when policy is forever
        #expect(mockPersistence.purgeOldChangeLogEntriesCallCount == 0)

        if case .changeLog(.purgeCompleted(.success)) = dispatchedAction {
            // Success - skipped purge correctly
        } else {
            #expect(Bool(false), "Expected purgeCompleted success action even when skipping")
        }
    }

    @Test("purgeOldEntries with 90-day policy")
    func testPurgeOldEntriesWith90DayPolicy() async {
        // Given
        let mockServices = Self.createMockServiceContainer()
        let mockPersistence = mockServices.persistenceService as! MockPersistenceService

        var dispatchedAction: AppAction? = nil
        let dispatcher: Dispatcher<AppAction> = { action in
            dispatchedAction = action
        }

        var state = AppState()
        state.settings.retentionPolicy = .days90

        // When
        await changeLogMiddleware(
            state: state,
            action: .changeLog(.purgeOldEntries),
            services: mockServices,
            dispatch: dispatcher
        )

        // Then
        #expect(mockPersistence.purgeOldChangeLogEntriesCallCount == 1)

        if case .changeLog(.purgeCompleted(.success)) = dispatchedAction {
            // Success
        } else {
            #expect(Bool(false), "Expected purgeCompleted success action")
        }
    }

    @Test("purgeOldEntries with 6-month policy")
    func testPurgeOldEntriesWith6MonthPolicy() async {
        // Given
        let mockServices = Self.createMockServiceContainer()
        let mockPersistence = mockServices.persistenceService as! MockPersistenceService

        var dispatchedAction: AppAction? = nil
        let dispatcher: Dispatcher<AppAction> = { action in
            dispatchedAction = action
        }

        var state = AppState()
        state.settings.retentionPolicy = .months6

        // When
        await changeLogMiddleware(
            state: state,
            action: .changeLog(.purgeOldEntries),
            services: mockServices,
            dispatch: dispatcher
        )

        // Then
        #expect(mockPersistence.purgeOldChangeLogEntriesCallCount == 1)

        if case .changeLog(.purgeCompleted(.success)) = dispatchedAction {
            // Success
        } else {
            #expect(Bool(false), "Expected purgeCompleted success action")
        }
    }

    @Test("purgeOldEntries dispatches purgeCompleted failure on error")
    func testPurgeOldEntriesErrorHandling() async {
        // Given
        let mockServices = Self.createMockServiceContainer()
        let mockPersistence = mockServices.persistenceService as! MockPersistenceService

        let testError = NSError(domain: "Test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Purge failed"])
        mockPersistence.shouldThrowError = true
        mockPersistence.throwError = testError

        var dispatchedAction: AppAction? = nil
        let dispatcher: Dispatcher<AppAction> = { action in
            dispatchedAction = action
        }

        var state = AppState()
        state.settings.retentionPolicy = .days30

        // When
        await changeLogMiddleware(
            state: state,
            action: .changeLog(.purgeOldEntries),
            services: mockServices,
            dispatch: dispatcher
        )

        // Then
        #expect(mockPersistence.purgeOldChangeLogEntriesCallCount == 1)

        if case .changeLog(.purgeCompleted(.failure)) = dispatchedAction {
            // Success - error was dispatched correctly
        } else {
            #expect(Bool(false), "Expected purgeCompleted failure action")
        }
    }

    // MARK: - Non-Middleware Actions (should be ignored)

    @Test("entriesLoaded action is ignored by middleware")
    func testEntriesLoadedActionIgnored() async {
        // Given
        let mockServices = Self.createMockServiceContainer()
        let mockPersistence = mockServices.persistenceService as! MockPersistenceService

        var dispatchedAction: AppAction? = nil
        let dispatcher: Dispatcher<AppAction> = { action in
            dispatchedAction = action
        }

        let state = AppState()
        let entries = [ChangeLogEntryBuilder().build()]

        // When
        await changeLogMiddleware(
            state: state,
            action: .changeLog(.entriesLoaded(.success(entries))),
            services: mockServices,
            dispatch: dispatcher
        )

        // Then
        #expect(dispatchedAction == nil, "Middleware should not dispatch for entriesLoaded")
        #expect(mockPersistence.loadChangeLogEntriesCallCount == 0)
    }

    @Test("searchTextChanged action is ignored by middleware")
    func testSearchTextChangedActionIgnored() async {
        // Given
        let mockServices = Self.createMockServiceContainer()
        let mockPersistence = mockServices.persistenceService as! MockPersistenceService

        var dispatchedAction: AppAction? = nil
        let dispatcher: Dispatcher<AppAction> = { action in
            dispatchedAction = action
        }

        let state = AppState()

        // When
        await changeLogMiddleware(
            state: state,
            action: .changeLog(.searchTextChanged("test")),
            services: mockServices,
            dispatch: dispatcher
        )

        // Then
        #expect(dispatchedAction == nil, "Middleware should not dispatch for searchTextChanged")
        #expect(mockPersistence.loadChangeLogEntriesCallCount == 0)
    }

    // MARK: - Non-ChangeLog Actions

    @Test("non-ChangeLog actions are ignored")
    func testNonChangeLogActionsIgnored() async {
        // Given
        let mockServices = Self.createMockServiceContainer()
        let mockPersistence = mockServices.persistenceService as! MockPersistenceService

        var dispatchedAction: AppAction? = nil
        let dispatcher: Dispatcher<AppAction> = { action in
            dispatchedAction = action
        }

        let state = AppState()

        // When
        await changeLogMiddleware(
            state: state,
            action: .appLifecycle(.onAppear),
            services: mockServices,
            dispatch: dispatcher
        )

        // Then
        #expect(dispatchedAction == nil)
        #expect(mockPersistence.loadChangeLogEntriesCallCount == 0)
    }

    // MARK: - Sequential Operations

    @Test("multiple sequential operations work correctly")
    func testSequentialOperations() async {
        // Given
        let mockServices = Self.createMockServiceContainer()
        let mockPersistence = mockServices.persistenceService as! MockPersistenceService

        let entry1 = ChangeLogEntryBuilder(userDisplayName: "Alice").build()
        let entry2 = ChangeLogEntryBuilder(userDisplayName: "Bob").build()
        mockPersistence.mockChangeLogEntries = [entry1, entry2]

        var dispatchedActions: [AppAction] = []
        let dispatcher: Dispatcher<AppAction> = { action in
            dispatchedActions.append(action)
        }

        let state = AppState()

        // When - Task (load entries)
        await changeLogMiddleware(
            state: state,
            action: .changeLog(.task),
            services: mockServices,
            dispatch: dispatcher
        )

        // Then - Should have dispatched entriesLoaded
        #expect(dispatchedActions.count == 1)
        #expect(mockPersistence.loadChangeLogEntriesCallCount == 1)

        // When - Delete entry
        dispatchedActions.removeAll()
        await changeLogMiddleware(
            state: state,
            action: .changeLog(.deleteEntry(entry1)),
            services: mockServices,
            dispatch: dispatcher
        )

        // Then - Should have dispatched entryDeleted
        #expect(dispatchedActions.count == 1)
        #expect(mockPersistence.deleteChangeLogEntryCallCount == 1)
    }

    @Test("task action with store integration")
    func testTaskActionWithStore() async {
        // Given - Create store with real middleware
        let mockServices = Self.createMockServiceContainer()
        let mockPersistence = mockServices.persistenceService as! MockPersistenceService

        let testEntries = [
            ChangeLogEntryBuilder(userDisplayName: "Test User").build()
        ]
        mockPersistence.mockChangeLogEntries = testEntries

        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: mockServices,
            middlewares: [changeLogMiddleware]
        )

        // When
        store.dispatch(action: .changeLog(.task))

        // Wait for async middleware
        try? await Task.sleep(nanoseconds: 50_000_000)

        // Then - entries should be loaded into state
        #expect(mockPersistence.loadChangeLogEntriesCallCount == 1)
        #expect(store.state.changeLog.entries.count == 1)
    }

    @Test("deleteEntry action with store integration")
    func testDeleteEntryWithStore() async {
        // Given
        let mockServices = Self.createMockServiceContainer()
        let mockPersistence = mockServices.persistenceService as! MockPersistenceService

        let entry = ChangeLogEntryBuilder(userDisplayName: "Test User").build()
        mockPersistence.mockChangeLogEntries = [entry]

        var state = AppState()
        state.changeLog.entries = [entry]

        let store = Store(
            state: state,
            reducer: appReducer,
            services: mockServices,
            middlewares: [changeLogMiddleware]
        )

        // When
        store.dispatch(action: .changeLog(.deleteEntry(entry)))

        // Wait for async middleware
        try? await Task.sleep(nanoseconds: 50_000_000)

        // Then
        #expect(mockPersistence.deleteChangeLogEntryCallCount == 1)
        #expect(mockPersistence.lastDeletedChangeLogEntryId == entry.id)
    }

    @Test("purgeOldEntries action with store integration")
    func testPurgeOldEntriesWithStore() async {
        // Given
        let mockServices = Self.createMockServiceContainer()
        let mockPersistence = mockServices.persistenceService as! MockPersistenceService

        var state = AppState()
        state.settings.retentionPolicy = .days30

        let store = Store(
            state: state,
            reducer: appReducer,
            services: mockServices,
            middlewares: [changeLogMiddleware]
        )

        // When
        store.dispatch(action: .changeLog(.purgeOldEntries))

        // Wait for async middleware
        try? await Task.sleep(nanoseconds: 50_000_000)

        // Then
        #expect(mockPersistence.purgeOldChangeLogEntriesCallCount == 1)
    }
}
