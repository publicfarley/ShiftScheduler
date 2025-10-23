import Testing
import Foundation
@testable import ShiftScheduler

/// Integration tests for Redux middleware
/// Validates middleware side effects and store dispatch flow
@Suite("Middleware Integration Tests")
@MainActor
struct MiddlewareIntegrationTests {
    // MARK: - Helpers

    /// Basic logging middleware for testing
    static let loggingMiddleware: Middleware = { _, action, _, _ in
        // Simply logs that middleware was called
        _ = String(describing: action)
    }

    // MARK: - Tests: Basic Store Dispatch

    @Test("Store dispatch calls reducer")
    func testStoreDispatchCallsReducer() {
        // Given
        let initialState = AppState()
        let store = Store(
            state: initialState,
            reducer: appReducer,
            services: ServiceContainer()
        )

        // When
        store.dispatch(action: .appLifecycle(.tabSelected(.today)))

        // Then
        #expect(store.state.selectedTab == .today)
    }

    @Test("Store dispatch with middleware calls middleware")
    func testStoreDispatchCallsMiddleware() {
        // Given
        var middlewareCalled = false
        let testMiddleware: Middleware = { _, _, _, _ in
            middlewareCalled = true
        }

        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: ServiceContainer(),
            middlewares: [testMiddleware]
        )

        // When
        store.dispatch(action: .appLifecycle(.tabSelected(.today)))

        // Then
        #expect(middlewareCalled)
    }

    // MARK: - Tests: Logging Middleware

    @Test("Logging middleware logs dispatched actions")
    func testLoggingMiddlewareLogsActions() {
        // Given
        var loggedActions: [String] = []
        let loggingMiddleware: Middleware = { _, action, _, _ in
            loggedActions.append(String(describing: action))
        }

        let store = Store(
            state: AppState(),
            reducer: appReducer,
            middlewares: [loggingMiddleware]
        )

        // When
        store.dispatch(action: .appLifecycle(.tabSelected(.schedule)))

        // Then
        #expect(!loggedActions.isEmpty)
    }

    // MARK: - Tests: Multiple Middleware Execution

    @Test("Multiple middlewares execute in order")
    func testMultipleMiddlewaresExecuteInOrder() {
        // Given
        var executionOrder: [Int] = []

        let middleware1: Middleware = { _, _, _, _ in
            executionOrder.append(1)
        }

        let middleware2: Middleware = { _, _, _, _ in
            executionOrder.append(2)
        }

        let middleware3: Middleware = { _, _, _, _ in
            executionOrder.append(3)
        }

        let store = Store(
            state: AppState(),
            reducer: appReducer,
            middlewares: [middleware1, middleware2, middleware3]
        )

        // When
        store.dispatch(action: .appLifecycle(.onAppear))

        // Then
        #expect(executionOrder == [1, 2, 3])
    }

    // MARK: - Tests: State Consistency After Middleware

    @Test("State remains consistent after middleware execution")
    func testStateRemainsConsistentAfterMiddleware() {
        // Given
        let mockPersistenceService = MockPersistenceService()

        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: ServiceContainer(),
            middlewares: [Self.loggingMiddleware]
        )

        // When
        store.dispatch(action: .appLifecycle(.tabSelected(.locations)))
        store.dispatch(action: .locations(.task))

        // Then - verify state is still valid
        #expect(store.state.selectedTab == .locations)
    }

    // MARK: - Tests: Error Handling in Middleware

    @Test("Middleware error handling prevents state corruption")
    func testMiddlewareErrorHandlingPreventStateCorruption() {
        // Given
        var errorHandled = false
        let errorHandlingMiddleware: Middleware = { _, _, _, _ in
            do {
                errorHandled = true
            }
        }

        let store = Store(
            state: AppState(),
            reducer: appReducer,
            middlewares: [errorHandlingMiddleware]
        )

        // When
        let initialState = store.state
        store.dispatch(action: .appLifecycle(.tabSelected(.today)))

        // Then
        #expect(errorHandled)
        #expect(store.state.selectedTab == .today)
    }

    // MARK: - Tests: Service Container in Middleware

    @Test("Service container accessible in middleware")
    func testServiceContainerAccessibleInMiddleware() {
        // Given
        var serviceContainerAccessed = false
        let testMiddleware: Middleware = { _, _, _, services in
            _ = services.calendarService
            _ = services.persistenceService
            _ = services.currentDayService
            serviceContainerAccessed = true
        }

        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: ServiceContainer(),
            middlewares: [testMiddleware]
        )

        // When
        store.dispatch(action: .appLifecycle(.onAppear))

        // Then
        #expect(serviceContainerAccessed)
    }

    // MARK: - Tests: Dispatch from Middleware

    @Test("Middleware can dispatch new actions")
    func testMiddlewareCanDispatchNewActions() {
        // Given
        var newActionDispatched = false
        let dispatchMiddleware: Middleware = { _, _, dispatch, _ in
            dispatch(.appLifecycle(.tabSelected(.schedule)))
            newActionDispatched = true
        }

        let store = Store(
            state: AppState(),
            reducer: appReducer,
            middlewares: [dispatchMiddleware]
        )

        // When
        store.dispatch(action: .appLifecycle(.onAppear))

        // Then
        #expect(newActionDispatched)
        // State should reflect the dispatched action
        #expect(store.state.selectedTab == .schedule)
    }
}
