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
    func testTabSelection() async {
        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: ServiceContainer(),
            middlewares: []
        )

        #expect(store.state.selectedTab == .today)

        await store.dispatch(action: .appLifecycle(.tabSelected(.schedule)))

        #expect(store.state.selectedTab == .schedule)
    }

    @Test("Dispatching calendar authorization updates state")
    func testCalendarAuthorizationUpdate() async {
        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: ServiceContainer(),
            middlewares: []
        )

        #expect(store.state.isCalendarAuthorized == false)

        await store.dispatch(action: .appLifecycle(.calendarAccessVerified(true)))

        #expect(store.state.isCalendarAuthorized == true)
    }

    @Test("Dispatching initialization complete updates state")
    func testInitializationComplete() async {
        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: ServiceContainer(),
            middlewares: []
        )

        #expect(store.state.isInitializationComplete == false)

        await store.dispatch(action: .appLifecycle(.initializationComplete(.success(()))))

        #expect(store.state.isInitializationComplete == true)
    }

    // MARK: - Feature State Tests

    @Test("Today feature loads shifts successfully")
    func testTodayFeatureShiftsLoaded() async {
        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: ServiceContainer(),
            middlewares: []
        )

        #expect(store.state.today.scheduledShifts.isEmpty)

        // Simulate successful shifts loaded with empty array
        await store.dispatch(action: .today(.shiftsLoaded(.success([]))))

        #expect(store.state.today.scheduledShifts.isEmpty)
        #expect(store.state.today.isLoading == false)
    }

    @Test("Schedule feature loads shifts successfully")
    func testScheduleFeatureShiftsLoaded() async {
        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: ServiceContainer(),
            middlewares: []
        )

        #expect(store.state.schedule.scheduledShifts.isEmpty)

        // Simulate successful shifts loaded with empty array
        await store.dispatch(action: .schedule(.shiftsLoaded(.success([]))))

        #expect(store.state.schedule.scheduledShifts.isEmpty)
        #expect(store.state.schedule.isLoading == false)
    }

    @Test("Locations feature state updates independently")
    func testLocationsFeatureStateUpdate() async {
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

        await store.dispatch(action: .locations(.locationsLoaded(.success([testLocation]))))

        #expect(store.state.locations.locations.count == 1)
        #expect(store.state.locations.locations.first?.name == "Test Location")
    }

    @Test("Shift types feature state updates independently")
    func testShiftTypesFeatureStateUpdate() async {
        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: ServiceContainer(),
            middlewares: []
        )

        let testLocation = Location(id: UUID(), name: "Test Office", address: "123 Main St")
        let testShiftType = ShiftType(
            id: UUID(),
            symbol: "☀️",
            duration: .scheduled(from: HourMinuteTime(hour: 9, minute: 0), to: HourMinuteTime(hour: 17, minute: 0)),
            title: "Day Shift",
            description: "Day shift",
            location: testLocation
        )

        #expect(store.state.shiftTypes.shiftTypes.isEmpty)

        await store.dispatch(action: .shiftTypes(.shiftTypesLoaded(.success([testShiftType]))))

        #expect(store.state.shiftTypes.shiftTypes.count == 1)
        #expect(store.state.shiftTypes.shiftTypes.first?.title == "Day Shift")
    }

    // MARK: - Multiple Dispatch Tests

    @Test("Multiple dispatches update state correctly")
    func testMultipleDispatches() async {
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
        await store.dispatch(action: .appLifecycle(.tabSelected(.schedule)))
        await store.dispatch(action: .appLifecycle(.calendarAccessVerified(true)))
        await store.dispatch(action: .appLifecycle(.initializationComplete(.success(()))))

        // Verify all updates applied
        #expect(store.state.selectedTab == .schedule)
        #expect(store.state.isCalendarAuthorized == true)
        #expect(store.state.isInitializationComplete == true)
    }

    @Test("State updates across multiple features don't interfere")
    func testMultipleFeatureUpdates() async {
        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: ServiceContainer(),
            middlewares: []
        )

        let testLocation = Location(id: UUID(), name: "Office", address: "123 Main St")
        let testShiftType = ShiftType(
            id: UUID(),
            symbol: "🌅",
            duration: .scheduled(from: HourMinuteTime(hour: 6, minute: 0), to: HourMinuteTime(hour: 14, minute: 0)),
            title: "Morning",
            description: "Morning shift",
            location: testLocation
        )

        // Update multiple features
        await store.dispatch(action: .today(.shiftsLoaded(.success([]))))
        await store.dispatch(action: .schedule(.shiftsLoaded(.success([]))))
        await store.dispatch(action: .locations(.locationsLoaded(.success([testLocation]))))
        await store.dispatch(action: .shiftTypes(.shiftTypesLoaded(.success([testShiftType]))))

        // Verify all features updated correctly
        #expect(store.state.today.isLoading == false)
        #expect(store.state.schedule.isLoading == false)
        #expect(store.state.locations.locations.count == 1)
        #expect(store.state.shiftTypes.shiftTypes.count == 1)
    }

    // MARK: - Error State Tests

    @Test("Error messages are set when shifts fail to load")
    func testErrorMessageHandling() async {
        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: ServiceContainer(),
            middlewares: []
        )

        #expect(store.state.today.errorMessage == nil)

        // Simulate a shift loading error
        await store.dispatch(action: .today(.shiftsLoaded(.failure(NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])))))
        #expect(store.state.today.errorMessage == "Test error")

        // Clear error by successfully loading shifts
        await store.dispatch(action: .today(.shiftsLoaded(.success([]))))
        #expect(store.state.today.errorMessage == nil)
    }
}
