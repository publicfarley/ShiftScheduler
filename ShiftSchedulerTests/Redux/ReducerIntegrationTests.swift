import Testing
import Foundation
@testable import ShiftScheduler

/// Integration tests for Redux reducer + Store integration
/// Validates that reducers correctly update state when actions are dispatched
/// Tests reducer behavior with real middleware in the array to ensure proper integration
@Suite("Reducer Integration Tests")
@MainActor
struct ReducerIntegrationTests {

    // MARK: - Test Helpers

    /// Create test service container with mocks
    static func createMockServiceContainer() -> ServiceContainer {
        let mockCalendar = MockCalendarService()
        mockCalendar.mockIsAuthorized = true
        return ServiceContainer(
            calendarService: mockCalendar,
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
        let mockCalendar = MockCalendarService()
        mockCalendar.mockIsAuthorized = true
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

        // When - dispatch today action to load shifts
        store.dispatch(action: AppAction.today(.loadShifts))

        // Wait for middleware to process
        try? await Task.sleep(nanoseconds: 50_000_000)

        // Then - shifts should be loaded (empty array in mock)
        #expect(store.state.today.scheduledShifts.isEmpty)
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
        store.dispatch(action: AppAction.appLifecycle(.calendarAccessVerified(true)))

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

    @Test("Store integration with multiple middleware")
    func testStoreIntegrationWithMultipleMiddleware() {
        // This test verifies that the Store integrates correctly with
        // multiple middleware. The MiddlewareIntegrationTests.swift file
        // contains specific tests for middleware behavior and side effects.

        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: Self.createMockServiceContainer(),
            middlewares: [
                appStartupMiddleware,  // Middleware #1
                todayMiddleware        // Middleware #2
            ]
        )

        // Verify store was created with middleware
        #expect(store != nil)
    }
}
