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
    func testTaskActionLoadsEntries() async throws {
        // Given
        let mockServices = Self.createMockServiceContainer()
        let mockPersistence = try #require(mockServices.persistenceService as? MockPersistenceService)

        let testEntries = [
            ChangeLogEntryBuilder(userDisplayName: "Alice").build(),
            ChangeLogEntryBuilder(userDisplayName: "Bob").build()
        ]
        mockPersistence.mockChangeLogEntries = testEntries

        var isEntriesLoaded = false
        var loadedEntries: [ChangeLogEntry] = []

        func mockTrackingMiddleware(
            state: AppState,
            action: AppAction,
            services: ServiceContainer,
            dispatch: @escaping Dispatcher<AppAction>
        ) async {
            switch action {
            case .changeLog(.entriesLoaded(.success(let entries))):
                isEntriesLoaded = true
                loadedEntries = entries
            case .changeLog(.entriesLoaded(.failure)):
                Issue.record("Should not get failure when loading entries")
            default:
                break
            }
        }

        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: mockServices,
            middlewares: [changeLogMiddleware, mockTrackingMiddleware]
        )

        // When
        await store.dispatch(action: .changeLog(.loadChangeLogEntries))

        // Then
        #expect(mockPersistence.loadChangeLogEntriesCallCount == 1)
        #expect(isEntriesLoaded)
        #expect(loadedEntries.count == 2)
        #expect(loadedEntries[0].userDisplayName == "Alice")
        #expect(loadedEntries[1].userDisplayName == "Bob")
    }

    @Test("task action handles empty entries list")
    func testTaskActionWithEmptyEntries() async throws {
        // Given
        let mockServices = Self.createMockServiceContainer()
        let mockPersistence = try #require(mockServices.persistenceService as? MockPersistenceService)

        mockPersistence.mockChangeLogEntries = []

        var isEntriesLoaded = false
        var loadedEntries: [ChangeLogEntry] = []

        func mockTrackingMiddleware(
            state: AppState,
            action: AppAction,
            services: ServiceContainer,
            dispatch: @escaping Dispatcher<AppAction>
        ) async {
            switch action {
            case .changeLog(.entriesLoaded(.success(let entries))):
                isEntriesLoaded = true
                loadedEntries = entries
            case .changeLog(.entriesLoaded(.failure)):
                Issue.record("Should not get failure when loading entries")
            default:
                break
            }
        }

        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: mockServices,
            middlewares: [changeLogMiddleware, mockTrackingMiddleware]
        )

        // When
        await store.dispatch(action: .changeLog(.loadChangeLogEntries))

        // Then
        #expect(mockPersistence.loadChangeLogEntriesCallCount == 1)
        #expect(isEntriesLoaded)
        #expect(loadedEntries.isEmpty)
    }

    @Test("task action dispatches entriesLoaded failure on persistence error")
    func testTaskActionErrorHandling() async throws {
        // Given
        let mockServices = Self.createMockServiceContainer()
        let mockPersistence = try #require(mockServices.persistenceService as? MockPersistenceService)

        let testError = NSError(domain: "Test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to load"])
        mockPersistence.shouldThrowError = true
        mockPersistence.throwError = testError

        var isEntriesLoadedFailure = false

        func mockTrackingMiddleware(
            state: AppState,
            action: AppAction,
            services: ServiceContainer,
            dispatch: @escaping Dispatcher<AppAction>
        ) async {
            switch action {
            case .changeLog(.entriesLoaded(.failure)):
                isEntriesLoadedFailure = true
            case .changeLog(.entriesLoaded(.success)):
                Issue.record("Should not succeed when persistence error occurs")
            default:
                break
            }
        }

        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: mockServices,
            middlewares: [changeLogMiddleware, mockTrackingMiddleware]
        )

        // When
        await store.dispatch(action: .changeLog(.loadChangeLogEntries))

        // Then
        #expect(mockPersistence.loadChangeLogEntriesCallCount == 1)
        #expect(isEntriesLoadedFailure)
    }

    // MARK: - Delete Entry Tests (.deleteEntry action)

    @Test("deleteEntry action deletes entry and dispatches entryDeleted success")
    func testDeleteEntrySuccess() async throws {
        // Given
        let mockServices = Self.createMockServiceContainer()
        let mockPersistence = try #require(mockServices.persistenceService as? MockPersistenceService)

        let entry = ChangeLogEntryBuilder(userDisplayName: "Alice").build()
        mockPersistence.mockChangeLogEntries = [entry]

        var isEntryDeletedSuccess = false

        func mockTrackingMiddleware(
            state: AppState,
            action: AppAction,
            services: ServiceContainer,
            dispatch: @escaping Dispatcher<AppAction>
        ) async {
            switch action {
            case .changeLog(.entryDeleted(.success)):
                isEntryDeletedSuccess = true
            case .changeLog(.entryDeleted(.failure)):
                Issue.record("Should not get failure when deleting entry")
            default:
                break
            }
        }

        var state = AppState()
        state.changeLog.entries = [entry]

        let store = Store(
            state: state,
            reducer: appReducer,
            services: mockServices,
            middlewares: [changeLogMiddleware, mockTrackingMiddleware]
        )

        // When
        await store.dispatch(action: .changeLog(.deleteEntry(entry)))

        // Then
        #expect(mockPersistence.deleteChangeLogEntryCallCount == 1)
        #expect(mockPersistence.lastDeletedChangeLogEntryId == entry.id)
        #expect(isEntryDeletedSuccess)
    }

    @Test("deleteEntry action dispatches entryDeleted failure on error")
    func testDeleteEntryFailure() async throws {
        // Given
        let mockServices = Self.createMockServiceContainer()
        let mockPersistence = try #require(mockServices.persistenceService as? MockPersistenceService)

        let testError = NSError(domain: "Test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Delete failed"])
        mockPersistence.shouldThrowError = true
        mockPersistence.throwError = testError

        let entry = ChangeLogEntryBuilder(userDisplayName: "Alice").build()

        var isEntryDeletedFailure = false

        func mockTrackingMiddleware(
            state: AppState,
            action: AppAction,
            services: ServiceContainer,
            dispatch: @escaping Dispatcher<AppAction>
        ) async {
            switch action {
            case .changeLog(.entryDeleted(.failure)):
                isEntryDeletedFailure = true
            case .changeLog(.entryDeleted(.success)):
                Issue.record("Should not succeed when persistence error occurs")
            default:
                break
            }
        }

        var state = AppState()
        state.changeLog.entries = [entry]

        let store = Store(
            state: state,
            reducer: appReducer,
            services: mockServices,
            middlewares: [changeLogMiddleware, mockTrackingMiddleware]
        )

        // When
        await store.dispatch(action: .changeLog(.deleteEntry(entry)))

        // Then
        #expect(mockPersistence.deleteChangeLogEntryCallCount == 1)
        #expect(mockPersistence.lastDeletedChangeLogEntryId == entry.id)
        #expect(isEntryDeletedFailure)
    }

    @Test("deleteEntry passes correct entry ID to service")
    func testDeleteEntryPassesCorrectId() async throws {
        // Given
        let mockServices = Self.createMockServiceContainer()
        let mockPersistence = try #require(mockServices.persistenceService as? MockPersistenceService)

        let entry = ChangeLogEntryBuilder(userDisplayName: "Test").build()

        var state = AppState()
        state.changeLog.entries = [entry]

        let store = Store(
            state: state,
            reducer: appReducer,
            services: mockServices,
            middlewares: [changeLogMiddleware]
        )

        // When
        await store.dispatch(action: .changeLog(.deleteEntry(entry)))

        // Then
        #expect(mockPersistence.lastDeletedChangeLogEntryId == entry.id)
    }

    // MARK: - Purge Old Entries Tests (.purgeOldEntries action)

    @Test("purgeOldEntries with 30-day policy purges correctly")
    func testPurgeOldEntriesWith30DayPolicy() async throws {
        // Given
        let mockServices = Self.createMockServiceContainer()
        let mockPersistence = try #require(mockServices.persistenceService as? MockPersistenceService)

        // Create entries - some old, some recent
        let now = Date()
        let fiftyDaysAgo = try #require(Calendar.current.date(byAdding: .day, value: -50, to: now))
        let tenDaysAgo = try #require(Calendar.current.date(byAdding: .day, value: -10, to: now))

        mockPersistence.mockChangeLogEntries = [
            ChangeLogEntryBuilder(timestamp: fiftyDaysAgo).build(),
            ChangeLogEntryBuilder(timestamp: tenDaysAgo).build()
        ]

        var isPurgeCompleted = false

        func mockTrackingMiddleware(
            state: AppState,
            action: AppAction,
            services: ServiceContainer,
            dispatch: @escaping Dispatcher<AppAction>
        ) async {
            switch action {
            case .changeLog(.purgeCompleted(.success)):
                isPurgeCompleted = true
            case .changeLog(.purgeCompleted(.failure)):
                Issue.record("Should not get failure when purging entries")
            default:
                break
            }
        }

        var state = AppState()
        state.settings.retentionPolicy = .days30

        let store = Store(
            state: state,
            reducer: appReducer,
            services: mockServices,
            middlewares: [changeLogMiddleware, mockTrackingMiddleware]
        )

        // When
        await store.dispatch(action: .changeLog(.purgeOldEntries))

        // Then
        #expect(mockPersistence.purgeOldChangeLogEntriesCallCount == 1)
        #expect(mockPersistence.lastPurgeOldEntriesCutoffDate != nil)
        #expect(isPurgeCompleted)
    }

    @Test("purgeOldEntries with Forever policy skips purge")
    func testPurgeOldEntriesWithForeverPolicy() async throws {
        // Given
        let mockServices = Self.createMockServiceContainer()
        let mockPersistence = try #require(mockServices.persistenceService as? MockPersistenceService)

        // Create old entries that would normally be purged
        let fiftyDaysAgo = try #require(Calendar.current.date(byAdding: .day, value: -50, to: Date()))
        mockPersistence.mockChangeLogEntries = [
            ChangeLogEntryBuilder(timestamp: fiftyDaysAgo).build()
        ]

        var isPurgeCompleted = false

        func mockTrackingMiddleware(
            state: AppState,
            action: AppAction,
            services: ServiceContainer,
            dispatch: @escaping Dispatcher<AppAction>
        ) async {
            switch action {
            case .changeLog(.purgeCompleted(.success)):
                isPurgeCompleted = true
            case .changeLog(.purgeCompleted(.failure)):
                Issue.record("Should not get failure when skipping purge")
            default:
                break
            }
        }

        var state = AppState()
        state.settings.retentionPolicy = .forever

        let store = Store(
            state: state,
            reducer: appReducer,
            services: mockServices,
            middlewares: [changeLogMiddleware, mockTrackingMiddleware]
        )

        // When
        await store.dispatch(action: .changeLog(.purgeOldEntries))

        // Then
        // Should NOT call purge when policy is forever
        #expect(mockPersistence.purgeOldChangeLogEntriesCallCount == 0)
        #expect(isPurgeCompleted)
    }

    @Test("purgeOldEntries with 90-day policy")
    func testPurgeOldEntriesWith90DayPolicy() async throws {
        // Given
        let mockServices = Self.createMockServiceContainer()
        let mockPersistence = try #require(mockServices.persistenceService as? MockPersistenceService)

        var isPurgeCompleted = false

        func mockTrackingMiddleware(
            state: AppState,
            action: AppAction,
            services: ServiceContainer,
            dispatch: @escaping Dispatcher<AppAction>
        ) async {
            switch action {
            case .changeLog(.purgeCompleted(.success)):
                isPurgeCompleted = true
            case .changeLog(.purgeCompleted(.failure)):
                Issue.record("Should not get failure when purging entries")
            default:
                break
            }
        }

        var state = AppState()
        state.settings.retentionPolicy = .days90

        let store = Store(
            state: state,
            reducer: appReducer,
            services: mockServices,
            middlewares: [changeLogMiddleware, mockTrackingMiddleware]
        )

        // When
        await store.dispatch(action: .changeLog(.purgeOldEntries))

        // Then
        #expect(mockPersistence.purgeOldChangeLogEntriesCallCount == 1)
        #expect(isPurgeCompleted)
    }

    @Test("purgeOldEntries with 6-month policy")
    func testPurgeOldEntriesWith6MonthPolicy() async throws {
        // Given
        let mockServices = Self.createMockServiceContainer()
        let mockPersistence = try #require(mockServices.persistenceService as? MockPersistenceService)

        var isPurgeCompleted = false

        func mockTrackingMiddleware(
            state: AppState,
            action: AppAction,
            services: ServiceContainer,
            dispatch: @escaping Dispatcher<AppAction>
        ) async {
            switch action {
            case .changeLog(.purgeCompleted(.success)):
                isPurgeCompleted = true
            case .changeLog(.purgeCompleted(.failure)):
                Issue.record("Should not get failure when purging entries")
            default:
                break
            }
        }

        var state = AppState()
        state.settings.retentionPolicy = .months6

        let store = Store(
            state: state,
            reducer: appReducer,
            services: mockServices,
            middlewares: [changeLogMiddleware, mockTrackingMiddleware]
        )

        // When
        await store.dispatch(action: .changeLog(.purgeOldEntries))

        // Then
        #expect(mockPersistence.purgeOldChangeLogEntriesCallCount == 1)
        #expect(isPurgeCompleted)
    }

    @Test("purgeOldEntries dispatches purgeCompleted failure on error")
    func testPurgeOldEntriesErrorHandling() async throws {
        // Given
        let mockServices = Self.createMockServiceContainer()
        let mockPersistence = try #require(mockServices.persistenceService as? MockPersistenceService)

        let testError = NSError(domain: "Test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Purge failed"])
        mockPersistence.shouldThrowError = true
        mockPersistence.throwError = testError

        var isPurgeCompletedFailure = false

        func mockTrackingMiddleware(
            state: AppState,
            action: AppAction,
            services: ServiceContainer,
            dispatch: @escaping Dispatcher<AppAction>
        ) async {
            switch action {
            case .changeLog(.purgeCompleted(.failure)):
                isPurgeCompletedFailure = true
            case .changeLog(.purgeCompleted(.success)):
                Issue.record("Should not succeed when persistence error occurs")
            default:
                break
            }
        }

        var state = AppState()
        state.settings.retentionPolicy = .days30

        let store = Store(
            state: state,
            reducer: appReducer,
            services: mockServices,
            middlewares: [changeLogMiddleware, mockTrackingMiddleware]
        )

        // When
        await store.dispatch(action: .changeLog(.purgeOldEntries))

        // Then
        #expect(mockPersistence.purgeOldChangeLogEntriesCallCount == 1)
        #expect(isPurgeCompletedFailure)
    }

    // MARK: - Non-Middleware Actions (should be ignored)

    @Test("entriesLoaded action is ignored by middleware")
    func testEntriesLoadedActionIgnored() async throws {
        // Given
        let mockServices = Self.createMockServiceContainer()
        let mockPersistence = try #require(mockServices.persistenceService as? MockPersistenceService)

        func mockTrackingMiddleware(
            state: AppState,
            action: AppAction,
            services: ServiceContainer,
            dispatch: @escaping Dispatcher<AppAction>
        ) async {
            // If middleware is ignoring the action, it should not dispatch secondary actions
            switch action {
            case .changeLog(.loadChangeLogEntries):
                Issue.record("Should not dispatch loadChangeLogEntries when entriesLoaded is received")
            case .changeLog(.deleteEntry):
                Issue.record("Should not dispatch deleteEntry when entriesLoaded is received")
            case .changeLog(.purgeOldEntries):
                Issue.record("Should not dispatch purgeOldEntries when entriesLoaded is received")
            default:
                break
            }
        }

        let state = AppState()
        let entries = [ChangeLogEntryBuilder().build()]

        let store = Store(
            state: state,
            reducer: appReducer,
            services: mockServices,
            middlewares: [changeLogMiddleware, mockTrackingMiddleware]
        )

        // When
        await store.dispatch(action: .changeLog(.entriesLoaded(.success(entries))))

        // Then
        #expect(mockPersistence.loadChangeLogEntriesCallCount == 0, "Middleware should not call services for entriesLoaded")
    }

    @Test("searchTextChanged action is ignored by middleware")
    func testSearchTextChangedActionIgnored() async throws {
        // Given
        let mockServices = Self.createMockServiceContainer()
        let mockPersistence = try #require(mockServices.persistenceService as? MockPersistenceService)

        func mockTrackingMiddleware(
            state: AppState,
            action: AppAction,
            services: ServiceContainer,
            dispatch: @escaping Dispatcher<AppAction>
        ) async {
            // If middleware is ignoring the action, it should not dispatch secondary actions
            switch action {
            case .changeLog(.loadChangeLogEntries):
                Issue.record("Should not dispatch loadChangeLogEntries when searchTextChanged is received")
            case .changeLog(.deleteEntry):
                Issue.record("Should not dispatch deleteEntry when searchTextChanged is received")
            case .changeLog(.purgeOldEntries):
                Issue.record("Should not dispatch purgeOldEntries when searchTextChanged is received")
            default:
                break
            }
        }

        let state = AppState()

        let store = Store(
            state: state,
            reducer: appReducer,
            services: mockServices,
            middlewares: [changeLogMiddleware, mockTrackingMiddleware]
        )

        // When
        await store.dispatch(action: .changeLog(.searchTextChanged("test")))

        // Then
        #expect(mockPersistence.loadChangeLogEntriesCallCount == 0, "Middleware should not call services for searchTextChanged")
    }

    // MARK: - Non-ChangeLog Actions

    @Test("non-ChangeLog actions are ignored")
    func testNonChangeLogActionsIgnored() async throws {
        // Given
        let mockServices = Self.createMockServiceContainer()
        let mockPersistence = try #require(mockServices.persistenceService as? MockPersistenceService)

        func mockTrackingMiddleware(
            state: AppState,
            action: AppAction,
            services: ServiceContainer,
            dispatch: @escaping Dispatcher<AppAction>
        ) async {
            // If middleware is ignoring the action, it should not dispatch any changeLog secondary actions
            if case .changeLog = action {
                Issue.record("changeLogMiddleware should not dispatch any ChangeLog actions for non-ChangeLog input actions")
            }
        }

        let state = AppState()

        let store = Store(
            state: state,
            reducer: appReducer,
            services: mockServices,
            middlewares: [changeLogMiddleware, mockTrackingMiddleware]
        )

        // When
        await store.dispatch(action: .appLifecycle(.onAppAppear))

        // Then
        #expect(mockPersistence.loadChangeLogEntriesCallCount == 0)
    }

    // MARK: - Sequential Operations

    @Test("multiple sequential operations work correctly")
    func testSequentialOperations() async throws {
        // Given
        let mockServices = Self.createMockServiceContainer()
        let mockPersistence = try #require(mockServices.persistenceService as? MockPersistenceService)

        let entry1 = ChangeLogEntryBuilder(userDisplayName: "Alice").build()
        let entry2 = ChangeLogEntryBuilder(userDisplayName: "Bob").build()
        mockPersistence.mockChangeLogEntries = [entry1, entry2]

        var isEntriesLoaded = false
        var isEntryDeleted = false

        func mockTrackingMiddleware(
            state: AppState,
            action: AppAction,
            services: ServiceContainer,
            dispatch: @escaping Dispatcher<AppAction>
        ) async {
            switch action {
            case .changeLog(.entriesLoaded(.success)):
                isEntriesLoaded = true
            case .changeLog(.entryDeleted(.success)):
                isEntryDeleted = true
            default:
                break
            }
        }

        var state = AppState()
        state.changeLog.entries = [entry1, entry2]

        let store = Store(
            state: state,
            reducer: appReducer,
            services: mockServices,
            middlewares: [changeLogMiddleware, mockTrackingMiddleware]
        )

        // When - Task (load entries)
        await store.dispatch(action: .changeLog(.loadChangeLogEntries))

        // Then - Should have dispatched entriesLoaded
        #expect(isEntriesLoaded)
        #expect(mockPersistence.loadChangeLogEntriesCallCount == 1)

        // When - Delete entry
        isEntryDeleted = false
        await store.dispatch(action: .changeLog(.deleteEntry(entry1)))

        // Then - Should have dispatched entryDeleted
        #expect(isEntryDeleted)
        #expect(mockPersistence.deleteChangeLogEntryCallCount == 1)
    }

    @Test("task action with store integration")
    func testTaskActionWithStore() async throws {
        // Given - Create store with real middleware
        let mockServices = Self.createMockServiceContainer()
        let mockPersistence = try #require(mockServices.persistenceService as? MockPersistenceService)

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
        await store.dispatch(action: .changeLog(.loadChangeLogEntries))

        // Then - entries should be loaded into state
        #expect(mockPersistence.loadChangeLogEntriesCallCount == 1)
        #expect(store.state.changeLog.entries.count == 1)
    }

    @Test("deleteEntry action with store integration")
    func testDeleteEntryWithStore() async throws {
        // Given
        let mockServices = Self.createMockServiceContainer()
        let mockPersistence = try #require(mockServices.persistenceService as? MockPersistenceService)

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
        await store.dispatch(action: .changeLog(.deleteEntry(entry)))

        // Then
        #expect(mockPersistence.deleteChangeLogEntryCallCount == 1)
        #expect(mockPersistence.lastDeletedChangeLogEntryId == entry.id)
    }

    @Test("purgeOldEntries action with store integration")
    func testPurgeOldEntriesWithStore() async throws {
        // Given
        let mockServices = Self.createMockServiceContainer()
        let mockPersistence = try #require(mockServices.persistenceService as? MockPersistenceService)

        var state = AppState()
        state.settings.retentionPolicy = .days30

        let store = Store(
            state: state,
            reducer: appReducer,
            services: mockServices,
            middlewares: [changeLogMiddleware]
        )

        // When
        await store.dispatch(action: .changeLog(.purgeOldEntries))

        // Then
        #expect(mockPersistence.purgeOldChangeLogEntriesCallCount == 1)
    }
}
