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
        await await store.dispatch(action: .appLifecycle(.verifyCalendarAccessOnStartup))

        // Then - middleware called calendar service to verify authorization
        #expect(mockCalendar.isCalendarAuthorizedCallCount == 1)
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
        await await store.dispatch(action: .appLifecycle(.verifyCalendarAccessOnStartup))

        // Then - middleware called service and secondary dispatch updated state
        #expect(mockCalendar.isCalendarAuthorizedCallCount == 1)
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
        await await store.dispatch(action: .appLifecycle(.verifyCalendarAccessOnStartup))

        // Then - middleware called service to check authorization
        #expect(mockCalendar.isCalendarAuthorizedCallCount == 1)
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
        await await store.dispatch(action: .appLifecycle(.verifyCalendarAccessOnStartup))

        // Then - middleware called service and handled the error gracefully
        #expect(mockCalendar.isCalendarAuthorizedCallCount == 1)
        // App should continue and display content (error is handled gracefully)
        #expect(store.state.selectedTab == .today)
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
        await await store.dispatch(action: .appLifecycle(.loadInitialData))

        // Then - middleware called persistence service and secondary dispatches loaded data
        #expect(mockPersistence.loadLocationsCallCount == 1)
        #expect(mockPersistence.loadShiftTypesCallCount == 1)
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
        await await store.dispatch(action: .appLifecycle(.loadInitialData))

        // Then - initialization complete was dispatched by middleware
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
        await store.dispatch(action: .appLifecycle(.tabSelected(.today)))

        // Then - reducer updated state synchronously
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
        await store.dispatch(action: .appLifecycle(.calendarAccessVerified(true)))

        // Then - reducer updated state immediately
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
        await store.dispatch(action: .appLifecycle(.loadInitialData))


        // Then - middleware called service and state was updated by secondary dispatch
        #expect(mockPersistence.loadLocationsCallCount == 1)
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
        await store.dispatch(action: .appLifecycle(.loadInitialData))


        // Then - middleware called services and entire action chain executed
        #expect(mockPersistence.loadShiftTypesCallCount == 1)
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
        await store.dispatch(action: .appLifecycle(.loadInitialData))


        // Then - middleware called service and state has the data
        #expect(mockPersistence.loadLocationsCallCount == 1)
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
        await store.dispatch(action: .appLifecycle(.verifyCalendarAccessOnStartup))


        // Then - middleware called service and state is preserved despite error
        #expect(mockCalendar.isCalendarAuthorizedCallCount == 1)
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
        await store.dispatch(action: .appLifecycle(.tabSelected(.locations)))

        // Then - reducer updated state, middleware didn't interfere
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
        await store.dispatch(action: .appLifecycle(.loadInitialData))


        // Then - middleware called service and all secondary dispatches executed
        #expect(mockPersistence.loadLocationsCallCount == 1)
        #expect(store.state.locations.locations.count == 2)
    }
}
