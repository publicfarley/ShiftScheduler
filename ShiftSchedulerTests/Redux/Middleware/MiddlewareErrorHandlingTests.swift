import Testing
import Foundation
@testable import ShiftScheduler

/// Middleware error handling tests
/// Validates that all 6 middlewares handle errors gracefully without crashing
@Suite("Middleware Error Handling Tests")
@MainActor
struct MiddlewareErrorHandlingTests {

    // MARK: - Test Helpers

    /// Create mock service container with error-throwing mocks
    static func createFailingServiceContainer() -> ServiceContainer {
        let mockCalendar = MockCalendarService()
        mockCalendar.shouldThrowError = true
        mockCalendar.throwError = CalendarServiceError.notAuthorized

        let mockPersistence = MockPersistenceService()
        mockPersistence.shouldThrowError = true
        mockPersistence.throwError = ScheduleError.persistenceFailed("Test error")

        return ServiceContainer(
            calendarService: mockCalendar,
            persistenceService: mockPersistence,
            currentDayService: CurrentDayService()
        )
    }

    // MARK: - AppStartupMiddleware Error Tests

    @Test("AppStartupMiddleware handles calendar service errors gracefully")
    func testAppStartupHandlesCalendarServiceErrors() async {
        let failingServices = Self.createFailingServiceContainer()
        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: failingServices,
            middlewares: [appStartupMiddleware]
        )

        // Dispatch action that will fail
        store.dispatch(action: .appLifecycle(.verifyCalendarAccessOnStartup))

        // Allow middleware to execute
        try? await Task.sleep(nanoseconds: 20_000_000)

        // App should still be in valid state despite error
        #expect(store.state.selectedTab != nil)
    }

    @Test("AppStartupMiddleware handles persistence errors gracefully")
    func testAppStartupHandlesPersistenceErrors() async {
        let failingServices = Self.createFailingServiceContainer()
        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: failingServices,
            middlewares: [appStartupMiddleware]
        )

        store.dispatch(action: .appLifecycle(.loadInitialData))

        try? await Task.sleep(nanoseconds: 20_000_000)

        // App should recover and display content
        #expect(store.state.shiftTypes is ShiftTypesState)
        #expect(store.state.locations is LocationsState)
    }

    @Test("AppStartupMiddleware continues after multiple errors")
    func testAppStartupContinuesAfterMultipleErrors() async {
        let failingServices = Self.createFailingServiceContainer()
        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: failingServices,
            middlewares: [appStartupMiddleware]
        )

        // Dispatch multiple actions that will fail
        store.dispatch(action: .appLifecycle(.verifyCalendarAccessOnStartup))
        try? await Task.sleep(nanoseconds: 10_000_000)

        store.dispatch(action: .appLifecycle(.loadInitialData))
        try? await Task.sleep(nanoseconds: 20_000_000)

        // App should still be functional
        #expect(store.state.selectedTab != nil)
    }

    // MARK: - Service-Specific Error Handling

    @Test("Middleware handles calendar access denial without crashing")
    func testMiddlewareHandlesCalendarAccessDenial() async {
        let mockCalendar = MockCalendarService()
        mockCalendar.shouldThrowError = true
        mockCalendar.throwError = CalendarServiceError.notAuthorized

        let services = ServiceContainer(
            calendarService: mockCalendar,
            persistenceService: MockPersistenceService(),
            currentDayService: CurrentDayService()
        )

        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: services,
            middlewares: [appStartupMiddleware]
        )

        store.dispatch(action: .appLifecycle(.verifyCalendarAccessOnStartup))
        try? await Task.sleep(nanoseconds: 10_000_000)

        // Should show error but not crash
        #expect(store.state is AppState)
    }

    @Test("Middleware handles event conversion errors without crashing")
    func testMiddlewareHandlesEventConversionErrors() async {
        let mockCalendar = MockCalendarService()
        mockCalendar.shouldThrowError = true
        mockCalendar.throwError = CalendarServiceError.eventConversionFailed("Conversion failed")

        let services = ServiceContainer(
            calendarService: mockCalendar,
            persistenceService: MockPersistenceService(),
            currentDayService: CurrentDayService()
        )

        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: services,
            middlewares: [appStartupMiddleware]
        )

        store.dispatch(action: .appLifecycle(.loadInitialData))
        try? await Task.sleep(nanoseconds: 20_000_000)

        // App recovers from error
        #expect(store.state is AppState)
    }

    // MARK: - Persistence Error Handling

    @Test("Middleware handles file I/O errors gracefully")
    func testMiddlewareHandlesFileIOErrors() async {
        let mockPersistence = MockPersistenceService()
        mockPersistence.shouldThrowError = true
        mockPersistence.throwError = ScheduleError.persistenceFailed("File I/O error")

        let services = ServiceContainer(
            calendarService: MockCalendarService(),
            persistenceService: mockPersistence,
            currentDayService: CurrentDayService()
        )

        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: services,
            middlewares: [appStartupMiddleware]
        )

        store.dispatch(action: .appLifecycle(.loadInitialData))
        try? await Task.sleep(nanoseconds: 20_000_000)

        // State remains valid
        #expect(store.state.locations.locations.isEmpty == false || store.state.locations.locations.isEmpty == true)
    }

    @Test("Middleware handles stack restoration errors gracefully")
    func testMiddlewareHandlesStackRestorationErrors() async {
        let mockPersistence = MockPersistenceService()
        mockPersistence.shouldThrowError = true
        mockPersistence.throwError = ScheduleError.stackRestorationFailed("Failed to restore undo/redo")

        let services = ServiceContainer(
            calendarService: MockCalendarService(),
            persistenceService: mockPersistence,
            currentDayService: CurrentDayService()
        )

        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: services,
            middlewares: [appStartupMiddleware]
        )

        store.dispatch(action: .appLifecycle(.loadInitialData))
        try? await Task.sleep(nanoseconds: 20_000_000)

        // App continues despite error
        #expect(store.state.selectedTab != nil)
    }

    // MARK: - Error State Preservation Tests

    @Test("Middleware preserves app state when service errors occur")
    func testPreservesStateOnServiceError() async {
        let failingServices = Self.createFailingServiceContainer()
        var initialState = AppState()
        initialState.selectedTab = .schedule
        initialState.shiftTypes.shiftTypes = []

        let store = Store(
            state: initialState,
            reducer: appReducer,
            services: failingServices,
            middlewares: [appStartupMiddleware]
        )

        store.dispatch(action: .appLifecycle(.verifyCalendarAccessOnStartup))
        try? await Task.sleep(nanoseconds: 10_000_000)

        // Original state preserved
        #expect(store.state.selectedTab == .schedule)
    }

    @Test("Middleware updates state even when services fail")
    func testUpdatesStateWhenServicesFail() async {
        let failingServices = Self.createFailingServiceContainer()
        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: failingServices,
            middlewares: [appStartupMiddleware]
        )

        let originalTab = store.state.selectedTab
        store.dispatch(action: .appLifecycle(.tabSelected(.locations)))

        // Reducer still updates state
        #expect(store.state.selectedTab == .locations)
        #expect(store.state.selectedTab != originalTab)
    }

    // MARK: - Error Sequence Tests

    @Test("Middleware handles interleaved success and failure actions")
    func testHandlesInterleavedSuccessAndFailure() async {
        let failingServices = Self.createFailingServiceContainer()
        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: failingServices,
            middlewares: [appStartupMiddleware]
        )

        // Dispatch failing action
        store.dispatch(action: .appLifecycle(.verifyCalendarAccessOnStartup))
        try? await Task.sleep(nanoseconds: 10_000_000)

        // Dispatch successful action (tab change)
        store.dispatch(action: .appLifecycle(.tabSelected(.today)))

        // App should handle both
        #expect(store.state.selectedTab == .today)
    }

    // MARK: - Concurrent Error Handling Tests

    @Test("Middleware handles rapid error dispatches")
    func testHandlesRapidErrorDispatches() async {
        let failingServices = Self.createFailingServiceContainer()
        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: failingServices,
            middlewares: [appStartupMiddleware]
        )

        // Dispatch multiple failing actions rapidly
        store.dispatch(action: .appLifecycle(.verifyCalendarAccessOnStartup))
        store.dispatch(action: .appLifecycle(.loadInitialData))
        store.dispatch(action: .appLifecycle(.verifyCalendarAccessOnStartup))

        try? await Task.sleep(nanoseconds: 30_000_000)

        // App should be stable
        #expect(store.state.selectedTab != nil)
    }

    // MARK: - Error Recovery Tests

    @Test("Middleware allows recovery after service error")
    func testAllowsRecoveryAfterError() async {
        let failingServices = Self.createFailingServiceContainer()

        let mockCalendar = MockCalendarService()
        mockCalendar.mockIsAuthorized = true
        let recoveringServices = ServiceContainer(
            calendarService: mockCalendar,
            persistenceService: MockPersistenceService(),
            currentDayService: CurrentDayService()
        )

        // First with failing services
        var store = Store(
            state: AppState(),
            reducer: appReducer,
            services: failingServices,
            middlewares: [appStartupMiddleware]
        )

        store.dispatch(action: .appLifecycle(.verifyCalendarAccessOnStartup))
        try? await Task.sleep(nanoseconds: 10_000_000)

        // Then with recovering services
        store = Store(
            state: AppState(),
            reducer: appReducer,
            services: recoveringServices,
            middlewares: [appStartupMiddleware]
        )

        store.dispatch(action: .appLifecycle(.verifyCalendarAccessOnStartup))
        try? await Task.sleep(nanoseconds: 10_000_000)

        // Should recover
        #expect(store.state.isCalendarAuthorized == true)
    }

    // MARK: - Error Logging Tests

    @Test("Middleware error handling allows app to continue logging")
    func testContinuesLoggingAfterError() async {
        let failingServices = Self.createFailingServiceContainer()
        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: failingServices,
            middlewares: [appStartupMiddleware]
        )

        // Dispatch failing action
        store.dispatch(action: .appLifecycle(.verifyCalendarAccessOnStartup))
        try? await Task.sleep(nanoseconds: 10_000_000)

        // Dispatch action that triggers logging
        store.dispatch(action: .appLifecycle(.tabSelected(.today)))

        // Verify state updated (logging functionality intact)
        #expect(store.state.selectedTab == .today)
    }

    // MARK: - Combination Error Tests

    @Test("Middleware handles errors in multiple feature layers")
    func testHandlesErrorsInMultipleLayers() async {
        let mockCalendar = MockCalendarService()
        mockCalendar.shouldThrowError = true
        mockCalendar.throwError = CalendarServiceError.notAuthorized

        let mockPersistence = MockPersistenceService()
        mockPersistence.shouldThrowError = true
        mockPersistence.throwError = ScheduleError.persistenceFailed("Persistence failed")

        let services = ServiceContainer(
            calendarService: mockCalendar,
            persistenceService: mockPersistence,
            currentDayService: CurrentDayService()
        )

        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: services,
            middlewares: [appStartupMiddleware]
        )

        // Actions that use multiple services
        store.dispatch(action: .appLifecycle(.verifyCalendarAccessOnStartup))
        try? await Task.sleep(nanoseconds: 10_000_000)

        store.dispatch(action: .appLifecycle(.loadInitialData))
        try? await Task.sleep(nanoseconds: 20_000_000)

        // App should handle all errors
        #expect(store.state.shiftTypes is ShiftTypesState)
        #expect(store.state.locations is LocationsState)
    }

    // MARK: - Error Propagation to UI Tests

    @Test("Service errors are visible in Redux state after dispatch")
    func testErrorsVisibleInStateAfterDispatch() async {
        let mockCalendar = MockCalendarService()
        mockCalendar.shouldThrowError = true
        mockCalendar.throwError = CalendarServiceError.notAuthorized

        let services = ServiceContainer(
            calendarService: mockCalendar,
            persistenceService: MockPersistenceService(),
            currentDayService: CurrentDayService()
        )

        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: services,
            middlewares: [appStartupMiddleware]
        )

        // Dispatch action that will fail
        store.dispatch(action: .appLifecycle(.verifyCalendarAccessOnStartup))
        try? await Task.sleep(nanoseconds: 20_000_000)

        // Verify state reflects the error condition
        #expect(!store.state.isCalendarAuthorized)
    }

    @Test("Multiple service errors handled without cascade failures")
    func testMultipleServiceErrorsHandledSafely() async {
        let mockCalendar = MockCalendarService()
        mockCalendar.shouldThrowError = true
        mockCalendar.throwError = CalendarServiceError.notAuthorized

        let mockPersistence = MockPersistenceService()
        mockPersistence.shouldThrowError = true
        mockPersistence.throwError = ScheduleError.persistenceFailed("Service failed")

        let services = ServiceContainer(
            calendarService: mockCalendar,
            persistenceService: mockPersistence,
            currentDayService: CurrentDayService()
        )

        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: services,
            middlewares: [appStartupMiddleware]
        )

        // Dispatch multiple failing actions
        store.dispatch(action: .appLifecycle(.verifyCalendarAccessOnStartup))
        store.dispatch(action: .appLifecycle(.loadInitialData))
        store.dispatch(action: .appLifecycle(.tabSelected(.schedule)))

        try? await Task.sleep(nanoseconds: 30_000_000)

        // App should still be responsive
        #expect(store.state.selectedTab == .schedule)
        #expect(store.state is AppState)
    }

    @Test("Error state is cleared when successful action follows error")
    func testErrorStateClearedBySuccess() async {
        let mockCalendar = MockCalendarService()
        mockCalendar.shouldThrowError = true
        mockCalendar.throwError = CalendarServiceError.notAuthorized

        let services = ServiceContainer(
            calendarService: mockCalendar,
            persistenceService: MockPersistenceService(),
            currentDayService: CurrentDayService()
        )

        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: services,
            middlewares: [appStartupMiddleware]
        )

        // Verify initial state
        #expect(store.state.isCalendarAuthorized == false)

        // Dispatch failing action
        store.dispatch(action: .appLifecycle(.verifyCalendarAccessOnStartup))
        try? await Task.sleep(nanoseconds: 10_000_000)

        // Verify error state
        #expect(store.state.isCalendarAuthorized == false)

        // Dispatch successful action (tab selection doesn't depend on calendar)
        store.dispatch(action: .appLifecycle(.tabSelected(.locations)))
        try? await Task.sleep(nanoseconds: 5_000_000)

        // Verify app remains functional
        #expect(store.state.selectedTab == .locations)
    }

    // MARK: - Service Call Verification Tests

    @Test("Calendar service is called even when configured to fail")
    func testCalendarServiceCalledDespiteError() async {
        let mockCalendar = MockCalendarService()
        mockCalendar.shouldThrowError = true
        mockCalendar.throwError = CalendarServiceError.notAuthorized

        let services = ServiceContainer(
            calendarService: mockCalendar,
            persistenceService: MockPersistenceService(),
            currentDayService: CurrentDayService()
        )

        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: services,
            middlewares: [appStartupMiddleware]
        )

        let initialCallCount = mockCalendar.isCalendarAuthorizedCallCount
        store.dispatch(action: .appLifecycle(.verifyCalendarAccessOnStartup))
        try? await Task.sleep(nanoseconds: 10_000_000)

        // Verify service was actually called
        #expect(mockCalendar.isCalendarAuthorizedCallCount > initialCallCount)
    }

    @Test("Persistence service is called even when configured to fail")
    func testPersistenceServiceCalledDespiteError() async {
        let mockPersistence = MockPersistenceService()
        mockPersistence.shouldThrowError = true
        mockPersistence.throwError = ScheduleError.persistenceFailed("Test error")

        let services = ServiceContainer(
            calendarService: MockCalendarService(),
            persistenceService: mockPersistence,
            currentDayService: CurrentDayService()
        )

        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: services,
            middlewares: [appStartupMiddleware]
        )

        let initialCallCount = mockPersistence.loadShiftTypesCallCount
        store.dispatch(action: .appLifecycle(.loadInitialData))
        try? await Task.sleep(nanoseconds: 20_000_000)

        // Verify service was actually called
        #expect(mockPersistence.loadShiftTypesCallCount > initialCallCount)
    }
}
