import Testing
import Foundation
@testable import ShiftScheduler

/// Tests for Redux state integration with views
/// Verifies that the Store properly integrates with SwiftUI views and state management
@Suite("View Redux Integration Tests")
@MainActor
struct ViewReduxIntegrationTests {

    // MARK: - Store Initialization Tests

    @Test("Store initializes with correct default state")
    func testStoreInitialization() {
        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: ServiceContainer(),
            middlewares: []
        )

        #expect(store.state.selectedTab == .today)
        #expect(store.state.isCalendarAuthorized == false)
        #expect(store.state.isInitializationComplete == false)
    }

    @Test("Store initializes with custom initial state")
    func testStoreCustomInitialState() {
        var customState = AppState()
        customState.selectedTab = .schedule
        customState.isCalendarAuthorized = true

        let store = Store(
            state: customState,
            reducer: appReducer,
            services: ServiceContainer(),
            middlewares: []
        )

        #expect(store.state.selectedTab == .schedule)
        #expect(store.state.isCalendarAuthorized == true)
    }

    // MARK: - State Update Tests

    @Test("Dispatching tab selection updates state")
    func testTabSelection() {
        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: ServiceContainer(),
            middlewares: []
        )

        #expect(store.state.selectedTab == .today)

        store.dispatch(action: .appLifecycle(.tabSelected(.schedule)))

        #expect(store.state.selectedTab == .schedule)
    }

    @Test("Dispatching calendar authorization updates state")
    func testCalendarAuthorizationUpdate() {
        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: ServiceContainer(),
            middlewares: []
        )

        #expect(store.state.isCalendarAuthorized == false)

        store.dispatch(action: .appLifecycle(.calendarAuthorizationStatusChanged(isAuthorized: true)))

        #expect(store.state.isCalendarAuthorized == true)
    }

    @Test("Dispatching initialization complete updates state")
    func testInitializationComplete() {
        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: ServiceContainer(),
            middlewares: []
        )

        #expect(store.state.isInitializationComplete == false)

        store.dispatch(action: .appLifecycle(.initializationCompleted))

        #expect(store.state.isInitializationComplete == true)
    }

    // MARK: - Feature State Tests

    @Test("Today feature state updates independently")
    func testTodayFeatureStateUpdate() {
        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: ServiceContainer(),
            middlewares: []
        )

        #expect(store.state.today.isLoading == false)

        store.dispatch(action: .today(.setLoading(true)))

        #expect(store.state.today.isLoading == true)
    }

    @Test("Schedule feature state updates independently")
    func testScheduleFeatureStateUpdate() {
        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: ServiceContainer(),
            middlewares: []
        )

        #expect(store.state.schedule.isLoading == false)

        store.dispatch(action: .schedule(.setLoading(true)))

        #expect(store.state.schedule.isLoading == true)
    }

    @Test("Locations feature state updates independently")
    func testLocationsFeatureStateUpdate() {
        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: ServiceContainer(),
            middlewares: []
        )

        let testLocation = Location(
            id: UUID(),
            name: "Test Location",
            address: "123 Test St"
        )

        #expect(store.state.locations.locations.isEmpty)

        store.dispatch(action: .locations(.locationsLoaded([testLocation])))

        #expect(store.state.locations.locations.count == 1)
        #expect(store.state.locations.locations.first?.name == "Test Location")
    }

    @Test("Shift types feature state updates independently")
    func testShiftTypesFeatureStateUpdate() {
        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: ServiceContainer(),
            middlewares: []
        )

        let testShiftType = ShiftType(
            id: UUID(),
            title: "Day Shift",
            symbol: "☀️",
            startTime: HourMinuteTime(hour: 9, minute: 0),
            duration: Duration.hours(8),
            locationId: UUID()
        )

        #expect(store.state.shiftTypes.shiftTypes.isEmpty)

        store.dispatch(action: .shiftTypes(.shiftTypesLoaded([testShiftType])))

        #expect(store.state.shiftTypes.shiftTypes.count == 1)
        #expect(store.state.shiftTypes.shiftTypes.first?.title == "Day Shift")
    }

    // MARK: - Multiple Dispatch Tests

    @Test("Multiple dispatches update state correctly")
    func testMultipleDispatches() {
        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: ServiceContainer(),
            middlewares: []
        )

        // Initial state
        #expect(store.state.selectedTab == .today)
        #expect(store.state.isCalendarAuthorized == false)
        #expect(store.state.isInitializationComplete == false)

        // Dispatch multiple actions
        store.dispatch(action: .appLifecycle(.tabSelected(.schedule)))
        store.dispatch(action: .appLifecycle(.calendarAuthorizationStatusChanged(isAuthorized: true)))
        store.dispatch(action: .appLifecycle(.initializationCompleted))

        // Verify all updates applied
        #expect(store.state.selectedTab == .schedule)
        #expect(store.state.isCalendarAuthorized == true)
        #expect(store.state.isInitializationComplete == true)
    }

    @Test("State updates across multiple features don't interfere")
    func testMultipleFeatureUpdates() {
        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: ServiceContainer(),
            middlewares: []
        )

        let testLocation = Location(id: UUID(), name: "Office", address: "123 Main St")
        let testShiftType = ShiftType(
            id: UUID(),
            title: "Morning",
            symbol: "🌅",
            startTime: HourMinuteTime(hour: 6, minute: 0),
            duration: Duration.hours(8),
            locationId: testLocation.id
        )

        // Update multiple features
        store.dispatch(action: .today(.setLoading(true)))
        store.dispatch(action: .schedule(.setLoading(true)))
        store.dispatch(action: .locations(.locationsLoaded([testLocation])))
        store.dispatch(action: .shiftTypes(.shiftTypesLoaded([testShiftType])))

        // Verify all features updated correctly
        #expect(store.state.today.isLoading == true)
        #expect(store.state.schedule.isLoading == true)
        #expect(store.state.locations.locations.count == 1)
        #expect(store.state.shiftTypes.shiftTypes.count == 1)
    }

    // MARK: - Error State Tests

    @Test("Error messages can be set and cleared")
    func testErrorMessageHandling() {
        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: ServiceContainer(),
            middlewares: []
        )

        #expect(store.state.today.errorMessage == nil)

        store.dispatch(action: .today(.setError("Test error")))
        #expect(store.state.today.errorMessage == "Test error")

        store.dispatch(action: .today(.setError(nil)))
        #expect(store.state.today.errorMessage == nil)
    }
}
