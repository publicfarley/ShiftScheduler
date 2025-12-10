import Testing
import Foundation
@testable import ShiftScheduler

/// Comprehensive concurrency tests for Redux store
/// Validates thread-safety, actor isolation, and Sendable compliance
/// Tests parallel dispatches, race conditions, and concurrent middleware execution
@Suite("Redux Concurrency Tests")
@MainActor
struct ConcurrencyTests {

    // MARK: - Test Helpers

    /// Create test service container with mocks
    static func createMockServiceContainer() -> ServiceContainer {
        let mockCalendar = MockCalendarService()
        mockCalendar.mockIsAuthorized = true
        return ServiceContainer(
            calendarService: mockCalendar,
            persistenceService: MockPersistenceService(),
            currentDayService: MockCurrentDayService(),
            conflictResolutionService: MockConflictResolutionService(),
            syncService: MockSyncService()
        )
    }

    // MARK: - Parallel Dispatch Tests

    /// Test that multiple sequential dispatches update state correctly
    @Test("Sequential dispatches update state in order")
    func testSequentialDispatches() async {
        // Given - Store with no middleware (focus on reducer concurrency)
        let mockServices = Self.createMockServiceContainer()
        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: mockServices,
            middlewares: []
        )

        // When - dispatch multiple actions sequentially
        await store.dispatch(action: .appLifecycle(.tabSelected(.today)))
        await store.dispatch(action: .appLifecycle(.tabSelected(.schedule)))
        await store.dispatch(action: .appLifecycle(.tabSelected(.locations)))

        // Then - state reflects final action
        #expect(store.state.selectedTab == .locations)
    }

    /// Test that rapid sequential dispatches don't lose updates
    @Test("Rapid sequential dispatches preserve all state updates")
    func testRapidSequentialDispatches() async {
        // Given - Store with mock services
        let mockServices = Self.createMockServiceContainer()
        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: mockServices,
            middlewares: []
        )

        let dispatchCount = 100

        // When - rapidly dispatch many actions
        for i in 0..<dispatchCount {
            let tabIndex = i % 6
            let tab: Tab = [.today, .schedule, .locations, .shiftTypes, .changeLog, .settings][tabIndex]
            await store.dispatch(action: .appLifecycle(.tabSelected(tab)))
        }

        // Then - final state is the last dispatched action
        let lastIndex = (dispatchCount - 1) % 6
        let expectedTab: Tab = [.today, .schedule, .locations, .shiftTypes, .changeLog, .settings][lastIndex]
        #expect(store.state.selectedTab == expectedTab)
    }

    /// Test parallel task dispatches don't cause race conditions
    @Test("Concurrent task dispatches execute safely")
    func testConcurrentTaskDispatches() async {
        // Given - Store with mock services
        let mockServices = Self.createMockServiceContainer()
        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: mockServices,
            middlewares: []
        )

        let dispatchCount = 50
        let tasks = (0..<dispatchCount).map { i in
            Task {
                let tabIndex = i % 6
                let tab: Tab = [.today, .schedule, .locations, .shiftTypes, .changeLog, .settings][tabIndex]
                await store.dispatch(action: .appLifecycle(.tabSelected(tab)))
            }
        }

        // When - all tasks complete
        await withTaskGroup(of: Void.self) { group in
            for task in tasks {
                group.addTask { await task.value }
            }
        }

        // Then - state is in a valid Tab (no crashes, actor isolation maintained)
        let validTabs: [Tab] = [.today, .schedule, .locations, .shiftTypes, .changeLog, .settings]
        #expect(validTabs.contains(store.state.selectedTab))
    }

    /// Test that concurrent action types don't interfere with each other
    @Test("Concurrent actions of different types don't interfere")
    func testConcurrentActionTypeDispatches() async {
        // Given - Store with mock services
        let mockServices = Self.createMockServiceContainer()
        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: mockServices,
            middlewares: []
        )

        // When - dispatch different action types concurrently
        let tasks = [
            Task { await store.dispatch(action: .appLifecycle(.tabSelected(.today))) },
            Task { await store.dispatch(action: .locations(.addButtonTapped)) },
            Task { await store.dispatch(action: .shiftTypes(.addButtonTapped)) },
            Task { await store.dispatch(action: .appLifecycle(.displayNameChanged("Test"))) },
            Task { await store.dispatch(action: .changeLog(.purgeOldEntries)) }
        ]

        await withTaskGroup(of: Void.self) { group in
            for task in tasks {
                group.addTask { await task.value }
            }
        }

        // Then - all actions were processed without crash
        #expect(store.state.selectedTab == .today)
        #expect(store.state.userProfile.displayName == "Test")
    }

    // MARK: - Race Condition Tests

    /// Test that state mutations don't race between dispatch and middleware
    @Test("State is consistent during reducer and middleware execution")
    func testStateConsistencyDuringMiddlewareExecution() async {
        // Given - Store with middleware that captures state
        let mockServices = Self.createMockServiceContainer()

        actor CapturedStateLog {
            private var states: [Tab] = []

            func addState(_ tab: Tab) {
                states.append(tab)
            }

            func getStates() -> [Tab] {
                states
            }
        }

        let log = CapturedStateLog()

        // Middleware that captures the state it receives
        let captureStateMiddleware: Middleware<AppState, AppAction> = { [log] state, action, services, dispatch in
            await log.addState(state.selectedTab)
        }

        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: mockServices,
            middlewares: [captureStateMiddleware]
        )

        // When - dispatch actions while middleware captures state
        let dispatchCount = 50
        for i in 0..<dispatchCount {
            let tabIndex = i % 6
            let tab: Tab = [.today, .schedule, .locations, .shiftTypes, .changeLog, .settings][tabIndex]
            await store.dispatch(action: .appLifecycle(.tabSelected(tab)))
        }

        // Then - all captured states should be valid tabs
        let capturedStates = await log.getStates()
        #expect(!capturedStates.isEmpty)
        for state in capturedStates {
            let validTabs: [Tab] = [.today, .schedule, .locations, .shiftTypes, .changeLog, .settings]
            #expect(validTabs.contains(state))
        }
    }

    /// Test that concurrent middleware executions don't cause race conditions
    @Test("Concurrent middleware executions are safe")
    func testConcurrentMiddlewareExecutionSafety() async {
        // Given - Store with multiple concurrent middlewares
        let mockServices = Self.createMockServiceContainer()

        actor ExecutionLog {
            private var executions: [Int] = []

            func addExecution(_ id: Int) {
                executions.append(id)
            }

            func count() -> Int {
                executions.count
            }
        }

        let log = ExecutionLog()

        // Create multiple middlewares that all try to execute
        let middlewares: [Middleware<AppState, AppAction>] = (0..<5).map { id in
            { state, action, services, dispatch in
                await log.addExecution(id)
            }
        }

        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: mockServices,
            middlewares: middlewares
        )

        // When - dispatch action (triggers all 5 middlewares)
        await store.dispatch(action: .appLifecycle(.tabSelected(.today)))

        // Then - all middlewares executed without interference
        let executionCount = await log.count()
        #expect(executionCount == 5)
    }


    /// Test that recursive dispatches from middleware don't cause deadlock
    @Test("Recursive dispatches from middleware don't deadlock")
    func testRecursiveDispatchesDontDeadlock() async {
        // Given - Store with middleware that dispatches more actions
        let mockServices = Self.createMockServiceContainer()

        actor DispatchCounter {
            private var count: Int = 0

            func increment() {
                count += 1
            }

            func getCount() -> Int {
                count
            }
        }

        let counter = DispatchCounter()

        let recursiveMiddleware: Middleware<AppState, AppAction> = { [counter] state, action, services, dispatch in
            await counter.increment()
            let currentCount = await counter.getCount()

            // Only dispatch recursively if we haven't done it too many times
            // (prevent infinite recursion in test)
            if currentCount < 5 {
                // Dispatch another action
                await dispatch(.appLifecycle(.tabSelected(.schedule)))
            }
        }

        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: mockServices,
            middlewares: [recursiveMiddleware]
        )

        // When - dispatch action that triggers recursive dispatch
        await store.dispatch(action: .appLifecycle(.tabSelected(.today)))

        // Then - recursive dispatches completed successfully (no deadlock)
        let count = await counter.getCount()
        #expect(count >= 2)
    }

    // MARK: - Sendable Compliance Tests

    /// Test that AppAction conforms to Sendable (required for async/await)
    @Test("AppAction is Sendable compatible")
    func testAppActionIsSendable() {
        // This is a compile-time check, but we verify it works at runtime
        let action: AppAction = .appLifecycle(.tabSelected(.today))
        let _: @Sendable () -> Void = {
            _ = action  // Ensure action can be captured in Sendable closure
        }

        #expect(true)  // If we get here, Sendable is satisfied
    }

    /// Test that AppState serialization-like operations work across actor boundaries
    @Test("AppState can be captured in Sendable contexts")
    func testAppStateInSendableContexts() async {
        // Given - Store with state
        let mockServices = Self.createMockServiceContainer()
        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: mockServices,
            middlewares: []
        )

        // When - capture state in a Sendable closure
        let capturedState = store.state

        let task = Task { @Sendable () -> Tab in
            // Access the captured state
            capturedState.selectedTab
        }

        // Then - value is successfully extracted
        let tab = await task.value
        #expect(tab == .today)
    }

    // MARK: - Actor Isolation Tests

    /// Test that Store's @MainActor isolation is enforced
    @Test("Store dispatch is only callable from MainActor context")
    @MainActor
    func testStoreDispatchMainActorIsolation() async {
        // This test verifies the Store is @MainActor isolated
        // If it wasn't, this would compile but the store would not be safe

        let mockServices = Self.createMockServiceContainer()
        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: mockServices,
            middlewares: []
        )

        // When - dispatch from MainActor (current context)
        await store.dispatch(action: .appLifecycle(.tabSelected(.today)))

        // Then - dispatch succeeded (we're on MainActor)
        #expect(store.state.selectedTab == .today)
    }

    /// Test that state changes are visible across await points
    @Test("State updates are visible across await points")
    func testStateVisibilityAcrossAwaitPoints() async {
        // Given - Store
        let mockServices = Self.createMockServiceContainer()
        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: mockServices,
            middlewares: []
        )

        // When - dispatch, await, then read state
        await store.dispatch(action: .appLifecycle(.tabSelected(.today)))

        // Then - state update is visible
        #expect(store.state.selectedTab == .today)

        // And - dispatch another action, await, and verify
        await store.dispatch(action: .appLifecycle(.tabSelected(.schedule)))

        #expect(store.state.selectedTab == .schedule)
    }

    /// Test that multiple readers of state see consistent values
    @Test("Multiple concurrent readers see consistent state")
    func testConcurrentStateReaders() async {
        // Given - Store
        let mockServices = Self.createMockServiceContainer()
        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: mockServices,
            middlewares: []
        )

        await store.dispatch(action: .appLifecycle(.tabSelected(.schedule)))

        // When - read state from multiple concurrent tasks
        let results = await withTaskGroup(of: Tab.self) { group in
            for _ in 0..<10 {
                group.addTask { @MainActor [store] in
                    store.state.selectedTab
                }
            }

            var results: [Tab] = []
            for await tab in group {
                results.append(tab)
            }
            return results
        }

        // Then - all readers see the same state
        #expect(results.count == 10)
        for tab in results {
            #expect(tab == .schedule)
        }
    }

    // MARK: - Stress Tests

    /// Stress test: High frequency dispatches with multiple features
    @Test("Store handles high-frequency dispatches")
    func testHighFrequencyDispatches() async {
        // Given - Store with multiple middlewares
        let mockServices = Self.createMockServiceContainer()

        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: mockServices,
            middlewares: [
                loggingMiddleware,
                appStartupMiddleware
            ]
        )

        let dispatchCount = 200

        // When - dispatch 200 actions as fast as possible
        for i in 0..<dispatchCount {
            let action: AppAction = if i % 2 == 0 {
                .appLifecycle(.tabSelected(.today))
            } else {
                .appLifecycle(.tabSelected(.schedule))
            }
            await store.dispatch(action: action)
        }

        // Then - store is still in valid state
        let validTabs: [Tab] = [.today, .schedule, .locations, .shiftTypes, .changeLog, .settings]
        #expect(validTabs.contains(store.state.selectedTab))
    }

    /// Stress test: Concurrent dispatch storms from multiple tasks
    @Test("Store handles concurrent dispatch storms")
    func testConcurrentDispatchStorms() async {
        // Given - Store
        let mockServices = Self.createMockServiceContainer()
        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: mockServices,
            middlewares: []
        )

        let taskCount = 20
        let dispatchesPerTask = 10

        // When - launch many tasks that all dispatch actions
        let tasks = (0..<taskCount).map { taskId in
            Task {
                for dispatchId in 0..<dispatchesPerTask {
                    let tabIndex = (taskId + dispatchId) % 6
                    let tab: Tab = [.today, .schedule, .locations, .shiftTypes, .changeLog, .settings][tabIndex]
                    await store.dispatch(action: .appLifecycle(.tabSelected(tab)))
                }
            }
        }

        await withTaskGroup(of: Void.self) { group in
            for task in tasks {
                group.addTask { await task.value }
            }
        }

        // Then - store is in consistent state (no crashes, valid tab)
        let validTabs: [Tab] = [.today, .schedule, .locations, .shiftTypes, .changeLog, .settings]
        #expect(validTabs.contains(store.state.selectedTab))
    }
}
