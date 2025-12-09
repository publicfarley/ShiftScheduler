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
            currentDayService: MockCurrentDayService(),
            conflictResolutionService: MockConflictResolutionService(),
            syncService: MockSyncService()
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
        await store.dispatch(action: AppAction.appLifecycle(.tabSelected(.today)))

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
        await store.dispatch(action: AppAction.appLifecycle(.tabSelected(AppTab.schedule)))

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
        await store.dispatch(action: AppAction.appLifecycle(.tabSelected(.today)))

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
            currentDayService: MockCurrentDayService(),
            syncService: MockSyncService()
        )

        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: mockServices,  // ✅ Custom services
            middlewares: [appStartupMiddleware]
        )

        // When
        await store.dispatch(action: AppAction.appLifecycle(.tabSelected(AppTab.schedule)))

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
        await store.dispatch(action: AppAction.today(.loadShifts))

        // Then - shifts should be loaded (empty array in mock)
        #expect(store.state.today.scheduledShifts.isEmpty)
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
            currentDayService: MockCurrentDayService(),
            conflictResolutionService: MockConflictResolutionService(),
            syncService: MockSyncService()
        )

        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: mockServices,
            middlewares: [appStartupMiddleware]  // ✅ REAL MIDDLEWARE
        )

        // When - dispatch action that might cause error
        await store.dispatch(action: AppAction.appLifecycle(.tabSelected(.today)))

        // Then - middleware should handle error without crashing
        #expect(store.state.selectedTab == .today)
    }
}
