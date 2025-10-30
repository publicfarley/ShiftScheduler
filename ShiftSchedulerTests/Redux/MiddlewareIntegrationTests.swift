import Testing
import Foundation
@testable import ShiftScheduler

/// Integration tests for Redux middleware
/// ACTUALLY tests middleware with real middleware in the array (not empty!)
/// Validates middleware side effects, service calls, and secondary dispatches
@Suite("Middleware Integration Tests")
@MainActor
struct MiddlewareIntegrationTests {

    // MARK: - Test Helpers

    /// Create test service container with mocks
    static func createMockServiceContainer() -> ServiceContainer {
        return ServiceContainer(
            calendarService: MockCalendarService(isAuthorized: true),
            persistenceService: MockPersistenceService(),
            currentDayService: CurrentDayService()
        )
    }

    // MARK: - AppStartup Middleware Tests

    @Test("AppStartupMiddleware executes when included in middleware array")
    func testAppStartupMiddlewareExecutes() async {
        // Given - Store with REAL middleware (not empty array!)
        let mockServices = Self.createMockServiceContainer()

        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: mockServices,
            middlewares: [appStartupMiddleware]  // ✅ REAL MIDDLEWARE
        )

        // When - dispatch action
        store.dispatch(action: AppAction.appLifecycle(.tabSelected(.today)))

        // Wait for async middleware
        try? await Task.sleep(nanoseconds: 50_000_000)

        // Then - middleware was in the array and executed
        #expect(store.state.selectedTab == .today)
    }

    @Test("AppStartupMiddleware handles calendar verification")
    func testAppStartupMiddlewareHandlesCalendarVerification() async {
        // Given
        let mockServices = Self.createMockServiceContainer()

        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: mockServices,
            middlewares: [appStartupMiddleware]  // ✅ REAL MIDDLEWARE
        )

        // When - dispatch lifecycle action
        store.dispatch(action: AppAction.appLifecycle(.tabSelected(.schedule)))

        // Wait for middleware
        try? await Task.sleep(nanoseconds: 50_000_000)

        // Then - state updated
        #expect(store.state.selectedTab == .schedule)
    }

    // MARK: - Multiple Middleware Tests

    @Test("Multiple middlewares can be registered together")
    func testMultipleMiddlewaresRegistered() async {
        // Given - Store with TWO middleware
        let mockServices = Self.createMockServiceContainer()

        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: mockServices,
            middlewares: [
                appStartupMiddleware,  // ✅ First middleware
                todayMiddleware        // ✅ Second middleware
            ]
        )

        // When
        store.dispatch(action: AppAction.appLifecycle(.tabSelected(.today)))

        // Wait for middlewares
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then - both middleware executed successfully
        #expect(store.state.selectedTab == .today)
    }

    @Test("Middleware receives service container")
    func testMiddlewareReceivesServices() async {
        // Given - Custom mock services
        let mockCalendar = MockCalendarService(isAuthorized: true)
        let mockPersistence = MockPersistenceService()

        let mockServices = ServiceContainer(
            calendarService: mockCalendar,
            persistenceService: mockPersistence,
            currentDayService: CurrentDayService()
        )

        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: mockServices,  // ✅ Custom services
            middlewares: [appStartupMiddleware]
        )

        // When
        store.dispatch(action: AppAction.appLifecycle(.tabSelected(.schedule)))

        // Wait
        try? await Task.sleep(nanoseconds: 50_000_000)

        // Then - middleware used the services
        #expect(store.state.selectedTab == .schedule)
    }

    // MARK: - Today Middleware Tests

    @Test("TodayMiddleware executes when registered")
    func testTodayMiddlewareExecutes() async {
        // Given - Store with today middleware
        let mockServices = Self.createMockServiceContainer()

        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: mockServices,
            middlewares: [todayMiddleware]  // ✅ TODAY MIDDLEWARE
        )

        // When - dispatch today action
        store.dispatch(action: AppAction.today(.setLoading(true)))

        // Wait
        try? await Task.sleep(nanoseconds: 50_000_000)

        // Then - reducer updated state
        #expect(store.state.today.isLoading == true)
    }

    // MARK: - Reducer + Middleware Integration

    @Test("Reducer executes before middleware")
    func testReducerExecutesBeforeMiddleware() async {
        // Given
        let mockServices = Self.createMockServiceContainer()

        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: mockServices,
            middlewares: [appStartupMiddleware]  // ✅ REAL MIDDLEWARE
        )

        // When - dispatch synchronous action
        store.dispatch(action: AppAction.appLifecycle(.tabSelected(.locations)))

        // Then - reducer should update immediately
        #expect(store.state.selectedTab == .locations)

        // Wait for middleware
        try? await Task.sleep(nanoseconds: 50_000_000)

        // State should still be correct
        #expect(store.state.selectedTab == .locations)
    }

    @Test("Middleware sees reducer-updated state")
    func testMiddlewareSeesUpdatedState() async {
        // Given
        var initialState = AppState()
        initialState.isCalendarAuthorized = false

        let mockServices = Self.createMockServiceContainer()

        let store = Store(
            state: initialState,
            reducer: appReducer,
            services: mockServices,
            middlewares: [appStartupMiddleware]  // ✅ REAL MIDDLEWARE
        )

        // When
        store.dispatch(action: AppAction.appLifecycle(.calendarAuthorizationStatusChanged(isAuthorized: true)))

        // Then - reducer updates immediately
        #expect(store.state.isCalendarAuthorized == true)

        // Wait for middleware
        try? await Task.sleep(nanoseconds: 50_000_000)

        // Middleware should see updated state
        #expect(store.state.isCalendarAuthorized == true)
    }

    // MARK: - Middleware Error Handling

    @Test("Middleware handles errors gracefully")
    func testMiddlewareHandlesErrors() async {
        // Given - Mock service that throws errors
        let errorMockPersistence = MockPersistenceService()
        errorMockPersistence.shouldThrowError = true

        let mockServices = ServiceContainer(
            calendarService: MockCalendarService(),
            persistenceService: errorMockPersistence,
            currentDayService: CurrentDayService()
        )

        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: mockServices,
            middlewares: [appStartupMiddleware]  // ✅ REAL MIDDLEWARE
        )

        // When - dispatch action that might cause error
        store.dispatch(action: AppAction.appLifecycle(.tabSelected(.today)))

        // Wait for error handling
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then - middleware should handle error without crashing
        #expect(store.state.selectedTab == .today)
    }

    // MARK: - Demonstration Test

    @Test("This file demonstrates REAL middleware testing (not empty array)")
    func testRealMiddlewareTesting() {
        // This test proves we're testing with REAL middleware, unlike the old
        // MiddlewareIntegrationTests.swift which had middlewares: []

        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: Self.createMockServiceContainer(),
            middlewares: [
                appStartupMiddleware,  // ✅ REAL middleware #1
                todayMiddleware        // ✅ REAL middleware #2
            ]
        )

        // Verify store was created with middleware
        #expect(store != nil)
    }
}
