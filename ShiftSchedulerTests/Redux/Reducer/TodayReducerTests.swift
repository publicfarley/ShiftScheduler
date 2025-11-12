import Testing
import Foundation
@testable import ShiftScheduler

/// Tests for the Today feature reducer state transitions
@Suite("TodayReducer Tests")
@MainActor
struct TodayReducerTests {

    // MARK: - Loading State Transitions

    @Test("task action sets isLoading to true")
    func testTaskActionStartsLoading() {
        var state = TodayState()
        state.isLoading = false

        let newState = todayReducer(state: state, action: .loadShifts)

        #expect(newState.isLoading == true)
    }

    @Test("loadShifts action sets isLoading to true")
    func testLoadShiftsActionStartsLoading() {
        var state = TodayState()
        state.isLoading = false

        let newState = todayReducer(state: state, action: .loadShifts)

        #expect(newState.isLoading == true)
    }

    @Test("shiftsLoaded success clears isLoading and updates shifts")
    func testShiftsLoadedSuccessUpdatesState() {
        var state = TodayState()
        state.isLoading = true
        state.errorMessage = "Previous error"

        let testShift = createTestShift()

        let newState = todayReducer(state: state, action: .shiftsLoaded(.success([testShift])))

        #expect(newState.isLoading == false)
        #expect(newState.scheduledShifts.count == 1)
        #expect(newState.errorMessage == nil)
    }

    @Test("shiftsLoaded failure clears isLoading and sets error message")
    func testShiftsLoadedFailureUpdatesError() {
        var state = TodayState()
        state.isLoading = true
        state.errorMessage = nil

        let error = NSError(domain: "TestError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        let newState = todayReducer(state: state, action: .shiftsLoaded(.failure(error)))

        #expect(newState.isLoading == false)
        #expect(newState.errorMessage != nil)
        #expect(newState.errorMessage?.contains("Test error") ?? false)
    }

    // MARK: - Shift Switching

    @Test("switchShiftTapped sets selectedShift and shows sheet")
    func testSwitchShiftTappedUpdatesState() {
        var state = TodayState()
        state.selectedShift = nil
        state.showSwitchShiftSheet = false

        let testShift = createTestShift()

        let newState = todayReducer(state: state, action: .switchShiftTapped(testShift))

        #expect(newState.selectedShift?.id == testShift.id)
        #expect(newState.showSwitchShiftSheet == true)
    }

    @Test("performSwitchShift action sets isLoading to true")
    func testPerformSwitchShiftStartsLoading() {
        var state = TodayState()
        state.isLoading = false

        let testShift = createTestShift()
        let testShiftType = createTestShiftType()

        let newState = todayReducer(state: state, action: .performSwitchShift(testShift, testShiftType, nil))

        #expect(newState.isLoading == true)
    }

    @Test("shiftSwitched success closes sheet and clears state")
    func testShiftSwitchedSuccessUpdatesState() {
        var state = TodayState()
        state.isLoading = true
        state.showSwitchShiftSheet = true
        state.selectedShift = createTestShift()

        let newState = todayReducer(state: state, action: .shiftSwitched(.success(())))

        #expect(newState.isLoading == false)
        #expect(newState.showSwitchShiftSheet == false)
        #expect(newState.selectedShift == nil)
    }

    @Test("shiftSwitched failure keeps sheet open")
    func testShiftSwitchedFailureKeepsSheetOpen() {
        var state = TodayState()
        state.isLoading = true
        state.showSwitchShiftSheet = true

        let error = NSError(domain: "Test", code: -1)
        let newState = todayReducer(state: state, action: .shiftSwitched(.failure(error)))

        #expect(newState.isLoading == false)
        #expect(newState.showSwitchShiftSheet == true)
    }

    @Test("switchShiftSheetDismissed clears selected shift and hides sheet")
    func testSwitchShiftSheetDismissedClearsState() {
        var state = TodayState()
        state.showSwitchShiftSheet = true
        state.selectedShift = createTestShift()

        let newState = todayReducer(state: state, action: .switchShiftSheetDismissed)

        #expect(newState.showSwitchShiftSheet == false)
        #expect(newState.selectedShift == nil)
    }

    // MARK: - Toast Notifications

    @Test("toastMessageCleared removes toast message")
    func testToastMessageCleared() {
        var state = TodayState()
        state.toastMessage = .success("Test message")

        let newState = todayReducer(state: state, action: .toastMessageCleared)

        #expect(newState.toastMessage == nil)
    }

    // MARK: - Cached Shifts Computation

    @Test("updateCachedShifts correctly caches today and tomorrow shifts")
    func testUpdateCachedShiftsComputesDates() {
        var state = TodayState()

        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today

        let todayShift = ScheduledShiftBuilder(date: today).build()
        let tomorrowShift = ScheduledShiftBuilder(date: tomorrow).build()

        state.scheduledShifts = [todayShift, tomorrowShift]
        state.todayShift = nil
        state.tomorrowShift = nil

        let newState = todayReducer(state: state, action: .updateCachedShifts)

        #expect(newState.todayShift?.id == todayShift.id)
        #expect(newState.tomorrowShift?.id == tomorrowShift.id)
    }

    // MARK: - Undo/Redo State

    @Test("updateUndoRedoStates disables undo and redo buttons")
    func testUpdateUndoRedoStatesDisablesButtons() {
        var state = TodayState()
        state.canUndo = true
        state.canRedo = true

        let newState = todayReducer(state: state, action: .updateUndoRedoStates)

        #expect(newState.canUndo == false)
        #expect(newState.canRedo == false)
    }

    // MARK: - State Isolation

    @Test("shift loading preserves other state properties")
    func testShiftLoadingPreservesOtherState() {
        var state = TodayState()
        state.showSwitchShiftSheet = true

        #expect(state.scheduledShifts.count == 0)

        state.selectedShift = createTestShift()
        state.isLoading = false

        let testShift = createTestShift()
        let newState = todayReducer(state: state, action: .shiftsLoaded(.success([testShift])))

        // Verify other properties preserved
        #expect(newState.showSwitchShiftSheet == true)
        #expect(newState.selectedShift?.id == state.selectedShift?.id)
        // Only isLoading and shifts changed
        #expect(newState.isLoading == false)
        #expect(newState.scheduledShifts.count == 1)
    }

    @Test("multiple sequential actions update state correctly")
    func testSequentialActions() {
        var state = TodayState()

        // Action 1: Start loading
        state = todayReducer(state: state, action: .loadShifts)
        #expect(state.isLoading == true)

        // Action 2: Shifts loaded
        let testShift = createTestShift()
        state = todayReducer(state: state, action: .shiftsLoaded(.success([testShift])))
        #expect(state.isLoading == false)
        #expect(state.scheduledShifts.count == 1)

        // Action 3: Tap to switch
        state = todayReducer(state: state, action: .switchShiftTapped(testShift))
        #expect(state.showSwitchShiftSheet == true)
        #expect(state.selectedShift?.id == testShift.id)
        #expect(state.scheduledShifts.count == 1)  // Shifts preserved
    }
}

// MARK: - Test Helpers

extension TodayReducerTests {
    private func createTestShift() -> ScheduledShift {
        ScheduledShiftBuilder().build()
    }

    private func createTestShiftType() -> ShiftType {
        ShiftTypeBuilder().build()
    }
}
