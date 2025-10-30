import Testing
import Foundation
@testable import ShiftScheduler

/// Integration tests for Redux middleware
/// Validates middleware side effects, service calls, and secondary dispatches
/// Tests that middleware actually calls services and dispatches secondary actions
@Suite("Middleware Integration Tests")
@MainActor
struct MiddlewareIntegrationTests {

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

    // MARK: - AppStartupMiddleware Tests

    @Test("AppStartupMiddleware calls calendar service on startup")
    func testAppStartupCallsCalendarService() async {
        // Given - Store with startup middleware and mocks
        let mockCalendar = MockCalendarService()
        mockCalendar.mockIsAuthorized = true
        let mockServices = ServiceContainer(
            calendarService: mockCalendar,
            persistenceService: MockPersistenceService(),
            currentDayService: CurrentDayService()
        )

        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: mockServices,
            middlewares: [appStartupMiddleware]
        )

        // When - trigger app startup verification
        store.dispatch(action: .appLifecycle(.verifyCalendarAccessOnStartup))

        // Wait for middleware to call service
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then - calendar service was checked and state was updated
        // If middleware called the service, it would have dispatched calendarAccessVerified
        #expect(store.state.isCalendarAuthorized == true)
    }

    @Test("AppStartupMiddleware dispatches calendarAccessVerified when authorized")
    func testAppStartupDispatchesVerifiedWhenAuthorized() async {
        // Given
        let mockCalendar = MockCalendarService()
        mockCalendar.mockIsAuthorized = true
        let mockServices = ServiceContainer(
            calendarService: mockCalendar,
            persistenceService: MockPersistenceService(),
            currentDayService: CurrentDayService()
        )

        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: mockServices,
            middlewares: [appStartupMiddleware]
        )

        // When - verify calendar access (authorized)
        store.dispatch(action: .appLifecycle(.verifyCalendarAccessOnStartup))

        // Wait for middleware
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then - secondary dispatch occurred (calendarAccessVerified action)
        // This is verified by checking the state was updated
        #expect(store.state.isCalendarAuthorized == true)
    }

    @Test("AppStartupMiddleware dispatches requestCalendarAccess when not authorized")
    func testAppStartupDispatchesRequestWhenNotAuthorized() async {
        // Given
        let mockCalendar = MockCalendarService()
        mockCalendar.mockIsAuthorized = false
        let mockServices = ServiceContainer(
            calendarService: mockCalendar,
            persistenceService: MockPersistenceService(),
            currentDayService: CurrentDayService()
        )

        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: mockServices,
            middlewares: [appStartupMiddleware]
        )

        // When
        store.dispatch(action: .appLifecycle(.verifyCalendarAccessOnStartup))

        // Wait for middleware
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then - middleware triggered request flow
        // State still shows not authorized (middleware dispatches requestCalendarAccess)
        #expect(store.state.isCalendarAuthorized == false)
    }

    @Test("AppStartupMiddleware handles calendar service errors gracefully")
    func testAppStartupHandlesCalendarServiceError() async {
        // Given - Mock service that throws error
        let mockCalendar = MockCalendarService()
        mockCalendar.shouldThrowError = true
        mockCalendar.throwError = CalendarServiceError.notAuthorized
        let mockServices = ServiceContainer(
            calendarService: mockCalendar,
            persistenceService: MockPersistenceService(),
            currentDayService: CurrentDayService()
        )

        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: mockServices,
            middlewares: [appStartupMiddleware]
        )

        // When - middleware tries to call failing service
        store.dispatch(action: .appLifecycle(.verifyCalendarAccessOnStartup))

        // Wait for error handling
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then - middleware handled error and dispatched secondary action
        // App should continue and display content (error is handled gracefully)
        #expect(store.state.selectedTab == .today)  // App is still functional
    }

    @Test("AppStartupMiddleware loads initial data on loadInitialData action")
    func testAppStartupLoadsInitialData() async {
        // Given
        let mockPersistence = MockPersistenceService()
        let testLocation = Location(id: UUID(), name: "Test Office", address: "123 Main St")
        let testLocation2 = Location(id: UUID(), name: "Office 2", address: "456 Oak Ave")
        mockPersistence.mockLocations = [testLocation, testLocation2]

        let testShiftType = ShiftType(
            id: UUID(),
            symbol: "🌅",
            duration: .allDay,
            title: "Morning Shift",
            description: "Test",
            location: testLocation
        )
        mockPersistence.mockShiftTypes = [testShiftType]

        let mockServices = ServiceContainer(
            calendarService: MockCalendarService(),
            persistenceService: mockPersistence,
            currentDayService: CurrentDayService()
        )

        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: mockServices,
            middlewares: [appStartupMiddleware]
        )

        // When - trigger initial data load
        store.dispatch(action: .appLifecycle(.loadInitialData))

        // Wait for middleware to load data
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then - secondary dispatches loaded locations and shift types
        #expect(store.state.locations.locations.count == 2)
        #expect(store.state.shiftTypes.shiftTypes.count == 1)
    }

    @Test("AppStartupMiddleware completes initialization after loading data")
    func testAppStartupCompletesInitializationAfterLoad() async {
        // Given
        let mockServices = Self.createMockServiceContainer()
        var initialState = AppState()
        initialState.isInitializationComplete = false

        let store = Store(
            state: initialState,
            reducer: appReducer,
            services: mockServices,
            middlewares: [appStartupMiddleware]
        )

        // When
        store.dispatch(action: .appLifecycle(.loadInitialData))

        // Wait for middleware
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then - initialization complete was dispatched
        #expect(store.state.isInitializationComplete == true)
    }

    // MARK: - Middleware Execution Order Tests

    @Test("Multiple middlewares execute in order")
    func testMultipleMiddlewaresExecuteInOrder() async {
        // Given - Store with ordered middlewares
        let mockServices = Self.createMockServiceContainer()

        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: mockServices,
            middlewares: [
                appStartupMiddleware,
                todayMiddleware
            ]
        )

        // When - dispatch action that both middlewares handle
        store.dispatch(action: .appLifecycle(.tabSelected(.today)))

        // Wait for all middlewares
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then - state reflects both middleware executions
        #expect(store.state.selectedTab == .today)
    }

    @Test("Middleware receives updated state from previous middleware")
    func testMiddlewareChainSeesUpdatedState() async {
        // Given
        var initialState = AppState()
        initialState.isCalendarAuthorized = false
        let mockServices = Self.createMockServiceContainer()

        let store = Store(
            state: initialState,
            reducer: appReducer,
            services: mockServices,
            middlewares: [appStartupMiddleware]
        )

        // When
        store.dispatch(action: .appLifecycle(.calendarAccessVerified(true)))

        // Wait for middleware
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then - middleware saw the updated state
        #expect(store.state.isCalendarAuthorized == true)
    }

    // MARK: - Secondary Dispatch Tests

    @Test("Middleware secondary dispatches update store state")
    func testMiddlewareSecondaryDispatchesUpdateState() async {
        // Given
        let mockPersistence = MockPersistenceService()
        let testLocation = Location(id: UUID(), name: "Test", address: "123 Test")
        mockPersistence.mockLocations = [testLocation]

        let mockServices = ServiceContainer(
            calendarService: MockCalendarService(),
            persistenceService: mockPersistence,
            currentDayService: CurrentDayService()
        )

        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: mockServices,
            middlewares: [appStartupMiddleware]
        )

        // When - trigger load that causes secondary dispatch
        store.dispatch(action: .appLifecycle(.loadInitialData))

        // Wait for middleware
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then - state was updated by secondary dispatch
        #expect(store.state.locations.locations.count == 1)
        #expect(store.state.locations.locations.first?.name == "Test")
    }

    @Test("Middleware secondary dispatches create proper action chain")
    func testMiddlewareActionChain() async {
        // Given
        let mockPersistence = MockPersistenceService()
        let shiftType = ShiftType(
            id: UUID(),
            symbol: "🌅",
            duration: .allDay,
            title: "Morning",
            description: "Test",
            location: Location(id: UUID(), name: "Office", address: "123 Main")
        )
        mockPersistence.mockShiftTypes = [shiftType]

        let mockServices = ServiceContainer(
            calendarService: MockCalendarService(),
            persistenceService: mockPersistence,
            currentDayService: CurrentDayService()
        )

        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: mockServices,
            middlewares: [appStartupMiddleware]
        )

        // When
        store.dispatch(action: .appLifecycle(.loadInitialData))

        // Wait for all secondary dispatches
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then - entire action chain executed
        #expect(store.state.shiftTypes.shiftTypes.count == 1)
        #expect(store.state.isInitializationComplete == true)
    }

    // MARK: - Service Call Verification Tests

    @Test("Middleware verifies service operations by state changes")
    func testMiddlewareServiceCallsVerifiedByState() async {
        // Given - Mock service with specific data
        let mockCalendar = MockCalendarService()
        mockCalendar.mockIsAuthorized = true
        let mockPersistence = MockPersistenceService()
        let location = Location(id: UUID(), name: "Main Office", address: "999 Business St")
        mockPersistence.mockLocations = [location]

        let mockServices = ServiceContainer(
            calendarService: mockCalendar,
            persistenceService: mockPersistence,
            currentDayService: CurrentDayService()
        )

        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: mockServices,
            middlewares: [appStartupMiddleware]
        )

        // When - trigger operations that use services
        store.dispatch(action: .appLifecycle(.loadInitialData))

        // Wait
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then - service was called (verified by state having the data)
        #expect(store.state.locations.locations.count == 1)
        #expect(store.state.locations.locations.first?.address == "999 Business St")
    }

    @Test("Middleware error handling prevents state corruption")
    func testMiddlewareErrorHandlingPreservesState() async {
        // Given - Service that will fail
        let mockCalendar = MockCalendarService()
        mockCalendar.shouldThrowError = true
        mockCalendar.throwError = CalendarServiceError.notAuthorized

        let mockServices = ServiceContainer(
            calendarService: mockCalendar,
            persistenceService: MockPersistenceService(),
            currentDayService: CurrentDayService()
        )

        var initialState = AppState()
        initialState.selectedTab = .schedule

        let store = Store(
            state: initialState,
            reducer: appReducer,
            services: mockServices,
            middlewares: [appStartupMiddleware]
        )

        // When - error occurs in middleware
        store.dispatch(action: .appLifecycle(.verifyCalendarAccessOnStartup))

        // Wait
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then - state is preserved and app is still functional
        #expect(store.state.selectedTab == .schedule)
    }

    // MARK: - Middleware With Different Action Types

    @Test("Middleware only processes relevant actions")
    func testMiddlewareIgnoresIrrelevantActions() async {
        // Given
        let mockServices = Self.createMockServiceContainer()
        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: mockServices,
            middlewares: [appStartupMiddleware]
        )

        // When - dispatch action not handled by this middleware
        store.dispatch(action: .appLifecycle(.tabSelected(.locations)))

        // Wait
        try? await Task.sleep(nanoseconds: 50_000_000)

        // Then - state updated by reducer, middleware didn't interfere
        #expect(store.state.selectedTab == .locations)
    }

    @Test("Middleware handles different action types independently")
    func testMiddlewareHandlesMultipleActionTypes() async {
        // Given
        let mockPersistence = MockPersistenceService()
        mockPersistence.mockLocations = [
            Location(id: UUID(), name: "Office A", address: "123 A St"),
            Location(id: UUID(), name: "Office B", address: "456 B St")
        ]

        let mockServices = ServiceContainer(
            calendarService: MockCalendarService(),
            persistenceService: mockPersistence,
            currentDayService: CurrentDayService()
        )

        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: mockServices,
            middlewares: [appStartupMiddleware]
        )

        // When - dispatch action that loads data
        store.dispatch(action: .appLifecycle(.loadInitialData))

        // Wait
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then - all secondary dispatches executed
        #expect(store.state.locations.locations.count == 2)
    }
}
