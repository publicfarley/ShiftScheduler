import Testing
import Foundation
@testable import ShiftScheduler

/// Tests for the root app reducer composing all feature reducers
@Suite("AppReducer Tests")
@MainActor
struct AppReducerTests {

    // MARK: - App Lifecycle Actions

    @Test("appReducer delegates appLifecycle actions to appLifecycleReducer")
    func testAppLifecycleActionDelegation() {
        var state = AppState()
        state.selectedTab = .today

        let newState = appReducer(state: state, action: .appLifecycle(.tabSelected(.schedule)))

        #expect(newState.selectedTab == .schedule)
    }

    @Test("appReducer delegates today actions to todayReducer")
    func testTodayActionDelegation() {
        var state = AppState()
        state.today.isLoading = false

        let newState = appReducer(state: state, action: .today(.task))

        #expect(newState.today.isLoading == true)
    }

    @Test("appReducer delegates schedule actions to scheduleReducer")
    func testScheduleActionDelegation() {
        var state = AppState()
        state.schedule.showAddShiftSheet = false

        let newState = appReducer(state: state, action: .schedule(.addShiftButtonTapped))

        #expect(newState.schedule.showAddShiftSheet == true)
    }

    @Test("appReducer delegates shiftTypes actions to shiftTypesReducer")
    func testShiftTypesActionDelegation() {
        var state = AppState()
        state.shiftTypes.isLoading = false

        let newState = appReducer(state: state, action: .shiftTypes(.task))

        #expect(newState.shiftTypes.isLoading == true)
    }

    @Test("appReducer delegates locations actions to locationsReducer")
    func testLocationsActionDelegation() {
        var state = AppState()
        state.locations.isLoading = false

        let newState = appReducer(state: state, action: .locations(.task))

        #expect(newState.locations.isLoading == true)
    }

    @Test("appReducer delegates changeLog actions to changeLogReducer")
    func testChangeLogActionDelegation() {
        var state = AppState()
        state.changeLog.isLoading = false

        let newState = appReducer(state: state, action: .changeLog(.task))

        #expect(newState.changeLog.isLoading == true)
    }

    @Test("appReducer delegates settings actions to settingsReducer")
    func testSettingsActionDelegation() {
        var state = AppState()
        state.settings.isLoading = false

        let newState = appReducer(state: state, action: .settings(.task))

        #expect(newState.settings.isLoading == true)
    }

    // MARK: - Multi-Feature State Transitions

    @Test("appReducer handles tab selection while preserving other feature states")
    func testTabSelectionPreservesOtherStates() {
        var state = AppState()
        state.selectedTab = .today
        state.schedule.selectedDate = Date()
        state.locations.searchText = "Office"

        let newState = appReducer(state: state, action: .appLifecycle(.tabSelected(.locations)))

        #expect(newState.selectedTab == .locations)
        #expect(newState.schedule.selectedDate == state.schedule.selectedDate)
        #expect(newState.locations.searchText == "Office")
    }

    @Test("appReducer preserves all other states when updating a single feature")
    func testStateIsolationBetweenFeatures() {
        var state = AppState()
        state.selectedTab = .today
        state.userProfile.displayName = "Alice"
        state.today.isLoading = false
        state.schedule.searchText = "test"
        state.shiftTypes.isLoading = false
        state.locations.isLoading = false
        state.changeLog.isLoading = false
        state.settings.isLoading = false

        let newState = appReducer(state: state, action: .today(.task))

        // Verify other states unchanged
        #expect(newState.selectedTab == .today)
        #expect(newState.userProfile.displayName == "Alice")
        #expect(newState.schedule.searchText == "test")
        #expect(newState.shiftTypes.isLoading == false)
        #expect(newState.locations.isLoading == false)
        #expect(newState.changeLog.isLoading == false)
        #expect(newState.settings.isLoading == false)

        // Verify only today state changed
        #expect(newState.today.isLoading == true)
    }

    @Test("appReducer correctly combines multiple sequential feature actions")
    func testSequentialFeatureActions() {
        var state = AppState()

        // First action: load today's shifts
        state = appReducer(state: state, action: .today(.task))
        #expect(state.today.isLoading == true)

        // Second action: open locations add sheet
        state = appReducer(state: state, action: .locations(.addButtonTapped))
        #expect(state.locations.showAddEditSheet == true)
        #expect(state.today.isLoading == true)  // Still loading

        // Third action: search in shift types
        state = appReducer(state: state, action: .shiftTypes(.searchTextChanged("Morning")))
        #expect(state.shiftTypes.searchText == "Morning")
        #expect(state.locations.showAddEditSheet == true)
        #expect(state.today.isLoading == true)
    }
}
