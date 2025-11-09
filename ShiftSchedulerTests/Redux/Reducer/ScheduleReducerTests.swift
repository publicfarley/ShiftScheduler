import Testing
import Foundation
@testable import ShiftScheduler

/// Tests for the Schedule feature reducer state transitions
@Suite("ScheduleReducer Tests")
@MainActor
struct ScheduleReducerTests {

    // MARK: - Loading State Transitions

    @Test("task action sets isLoading and isRestoringStacks to true")
    func testTaskActionStartsLoadingAndRestoring() {
        var state = ScheduleState()
        state.isLoading = false
        state.isRestoringStacks = false

        let newState = scheduleReducer(state: state, action: .initializeAndLoadScheduleData)

        #expect(newState.isLoading == true)
        #expect(newState.isRestoringStacks == true)
    }

    @Test("shiftsLoaded success clears loading states and updates shifts")
    func testShiftsLoadedSuccessUpdatesState() {
        var state = ScheduleState()
        state.isLoading = true
        state.isRestoringStacks = true
        state.errorMessage = "Previous error"
        state.currentError = nil

        let testShift = createTestShift()

        let newState = scheduleReducer(state: state, action: .shiftsLoaded(.success([testShift])))

        #expect(newState.isLoading == false)
        #expect(newState.isRestoringStacks == false)
        #expect(newState.scheduledShifts.count == 1)
        #expect(newState.errorMessage == nil)
    }

    @Test("shiftsLoaded failure clears loading states and sets error")
    func testShiftsLoadedFailureUpdatesError() {
        var state = ScheduleState()
        state.isLoading = true
        state.isRestoringStacks = true

        let error = NSError(domain: "Test", code: -1)
        let newState = scheduleReducer(state: state, action: .shiftsLoaded(.failure(error)))

        #expect(newState.isLoading == false)
        #expect(newState.isRestoringStacks == false)
        #expect(newState.errorMessage != nil)
    }

    // MARK: - Authorization

    @Test("checkAuthorization action does not change state")
    func testCheckAuthorizationDoesNotChangeState() {
        let state = ScheduleState()

        let newState = scheduleReducer(state: state, action: .checkAuthorization)

        #expect(newState == state)
    }

    @Test("authorizationChecked updates authorization state")
    func testAuthorizationCheckedUpdatesState() {
        var state = ScheduleState()
        state.isCalendarAuthorized = false

        let newState = scheduleReducer(state: state, action: .authorizationChecked(true))

        #expect(newState.isCalendarAuthorized == true)
    }

    // MARK: - Date and Search Selection

    @Test("selectedDateChanged updates selected date and clears search")
    func testSelectedDateChangedUpdatesState() {
        var state = ScheduleState()
        state.searchText = "Morning"
        let newDate = Date()

        let newState = scheduleReducer(state: state, action: .selectedDateChanged(newDate))

        #expect(newState.selectedDate == newDate)
        #expect(newState.searchText == "")
    }

    @Test("searchTextChanged updates search text")
    func testSearchTextChangedUpdatesState() {
        var state = ScheduleState()
        state.searchText = ""

        let newState = scheduleReducer(state: state, action: .searchTextChanged("Morning"))

        #expect(newState.searchText == "Morning")
    }

    // MARK: - Detail View

    @Test("shiftTapped sets selectedShift and shows detail view")
    func testShiftTappedUpdatesState() {
        var state = ScheduleState()
        state.showShiftDetail = false

        let testShift = createTestShift()

        let newState = scheduleReducer(state: state, action: .shiftTapped(testShift))

        #expect(newState.selectedShiftId == testShift.id)
        #expect(newState.selectedShiftForDetail?.id == testShift.id)
        #expect(newState.showShiftDetail == true)
    }

    @Test("shiftDetailDismissed clears detail view state")
    func testShiftDetailDismissedClearsState() {
        var state = ScheduleState()
        state.showShiftDetail = true
        state.selectedShiftId = UUID()
        state.selectedShiftForDetail = createTestShift()
        state.showSwitchShiftSheet = true

        let newState = scheduleReducer(state: state, action: .shiftDetailDismissed)

        #expect(newState.showShiftDetail == false)
        #expect(newState.selectedShiftId == nil)
        #expect(newState.selectedShiftForDetail == nil)
        #expect(newState.showSwitchShiftSheet == false)
    }

    // MARK: - Add Shift Operations

    @Test("addShiftButtonTapped shows sheet")
    func testAddShiftButtonTappedShowsSheet() {
        var state = ScheduleState()
        state.showAddShiftSheet = false

        let newState = scheduleReducer(state: state, action: .addShiftButtonTapped)

        #expect(newState.showAddShiftSheet == true)
    }

    @Test("addShiftSheetToggled controls sheet visibility")
    func testAddShiftSheetToggledControlsVisibility() {
        var state = ScheduleState()
        state.showAddShiftSheet = false

        let newState1 = scheduleReducer(state: state, action: .addShiftSheetToggled(true))
        #expect(newState1.showAddShiftSheet == true)

        let newState2 = scheduleReducer(state: newState1, action: .addShiftSheetToggled(false))
        #expect(newState2.showAddShiftSheet == false)
    }

    @Test("addShift action sets isAddingShift to true")
    func testAddShiftStartsLoading() {
        var state = ScheduleState()
        state.isAddingShift = false

        let newState = scheduleReducer(
            state: state,
            action: .addShift(
                date: Date(),
                shiftType: createTestShiftType(),
                notes: ""
            )
        )

        #expect(newState.isAddingShift == true)
        #expect(newState.currentError == nil)
    }

    @Test("addShiftResponse success closes sheet and shows toast")
    func testAddShiftResponseSuccessUpdatesState() {
        var state = ScheduleState()
        state.isAddingShift = true
        state.showAddShiftSheet = true

        let newState = scheduleReducer(state: state, action: .addShiftResponse(.success(createTestShift())))

        #expect(newState.isAddingShift == false)
        #expect(newState.showAddShiftSheet == false)
        #expect(newState.successMessage != nil)
        #expect(newState.showSuccessToast == true)
    }

    @Test("addShiftResponse failure sets error")
    func testAddShiftResponseFailureUpdatesError() {
        var state = ScheduleState()
        state.isAddingShift = true

        let newState = scheduleReducer(state: state, action: .addShiftResponse(.failure(ScheduleError.shiftNotFound)))

        #expect(newState.isAddingShift == false)
        #expect(newState.currentError != nil)
        #expect(newState.showAddShiftSheet == true)  // Keep sheet open
    }

    // MARK: - Delete Shift Operations

    @Test("deleteShiftRequested sets confirmation shift")
    func testDeleteShiftRequestedSetsShift() {
        var state = ScheduleState()
        state.deleteConfirmationShift = nil

        let testShift = createTestShift()
        let newState = scheduleReducer(state: state, action: .deleteShiftRequested(testShift))

        #expect(newState.deleteConfirmationShift?.id == testShift.id)
    }

    @Test("deleteShiftConfirmed starts deletion when shift is set")
    func testDeleteShiftConfirmedStartsDeletion() {
        var state = ScheduleState()
        state.deleteConfirmationShift = createTestShift()
        state.isDeletingShift = false

        let newState = scheduleReducer(state: state, action: .deleteShiftConfirmed)

        #expect(newState.isDeletingShift == true)
    }

    @Test("deleteShiftCancelled clears confirmation shift")
    func testDeleteShiftCancelledClearsShift() {
        var state = ScheduleState()
        state.deleteConfirmationShift = createTestShift()

        let newState = scheduleReducer(state: state, action: .deleteShiftCancelled)

        #expect(newState.deleteConfirmationShift == nil)
    }

    @Test("shiftDeleted success shows toast and clears confirmation")
    func testShiftDeletedSuccessUpdatesState() {
        var state = ScheduleState()
        state.isDeletingShift = true
        state.deleteConfirmationShift = createTestShift()

        let newState = scheduleReducer(state: state, action: .shiftDeleted(.success(())))

        #expect(newState.isDeletingShift == false)
        #expect(newState.deleteConfirmationShift == nil)
        #expect(newState.successMessage != nil)
    }

    // MARK: - Switch Shift Operations

    @Test("switchShiftSheetToggled controls sheet visibility")
    func testSwitchShiftSheetToggledControlsVisibility() {
        var state = ScheduleState()
        state.showSwitchShiftSheet = false

        let newState1 = scheduleReducer(state: state, action: .switchShiftSheetToggled(true))
        #expect(newState1.showSwitchShiftSheet == true)

        let newState2 = scheduleReducer(state: newState1, action: .switchShiftSheetToggled(false))
        #expect(newState2.showSwitchShiftSheet == false)
    }

    @Test("performSwitchShift sets isSwitchingShift to true")
    func testPerformSwitchShiftStartsLoading() {
        var state = ScheduleState()
        state.isSwitchingShift = false

        let newState = scheduleReducer(
            state: state,
            action: .performSwitchShift(createTestShift(), createTestShiftType(), nil)
        )

        #expect(newState.isSwitchingShift == true)
        #expect(newState.currentError == nil)
    }

    @Test("shiftSwitched success appends to undo stack and clears redo")
    func testShiftSwitchedSuccessUpdatesStacks() {
        var state = ScheduleState()
        state.isSwitchingShift = true
        state.showSwitchShiftSheet = true
        state.showShiftDetail = true
        state.undoStack = []
        state.redoStack = [ChangeLogEntryBuilder().build()]

        let entry = ChangeLogEntryBuilder().build()
        let newState = scheduleReducer(state: state, action: .shiftSwitched(.success(entry)))

        #expect(newState.isSwitchingShift == false)
        #expect(newState.showSwitchShiftSheet == false)
        #expect(newState.showShiftDetail == false)
        #expect(newState.undoStack.count == 1)
        #expect(newState.redoStack.count == 0)  // Cleared
        #expect(newState.showSuccessToast == true)
    }

    // MARK: - Undo/Redo Operations

    @Test("undo with empty stack sets error")
    func testUndoWithEmptyStackSetsError() {
        var state = ScheduleState()
        state.undoStack = []

        let newState = scheduleReducer(state: state, action: .undo)

        #expect(newState.currentError == .undoStackEmpty)
        #expect(newState.isLoading == false)
    }

    @Test("undo with non-empty stack starts loading")
    func testUndoWithStackStartsLoading() {
        var state = ScheduleState()
        state.undoStack = [ChangeLogEntryBuilder().build()]
        state.isLoading = false

        let newState = scheduleReducer(state: state, action: .undo)

        #expect(newState.isLoading == true)
    }

    @Test("undoCompleted success moves operation from undo to redo")
    func testUndoCompletedSuccessMovesStack() {
        var state = ScheduleState()
        state.isLoading = true
        state.undoStack = [ChangeLogEntryBuilder().build()]
        state.redoStack = []

        let newState = scheduleReducer(state: state, action: .undoCompleted(.success(())))

        #expect(newState.isLoading == false)
        #expect(newState.undoStack.count == 0)
        #expect(newState.redoStack.count == 1)
        #expect(newState.showSuccessToast == true)
    }

    @Test("redo with empty stack sets error")
    func testRedoWithEmptyStackSetsError() {
        var state = ScheduleState()
        state.redoStack = []

        let newState = scheduleReducer(state: state, action: .redo)

        #expect(newState.currentError == .redoStackEmpty)
    }

    @Test("redoCompleted success moves operation from redo to undo")
    func testRedoCompletedSuccessMovesStack() {
        var state = ScheduleState()
        state.isLoading = true
        state.undoStack = []
        state.redoStack = [ChangeLogEntryBuilder().build()]

        let newState = scheduleReducer(state: state, action: .redoCompleted(.success(())))

        #expect(newState.isLoading == false)
        #expect(newState.redoStack.count == 0)
        #expect(newState.undoStack.count == 1)
    }

    // MARK: - Stack Restoration

    @Test("restoreUndoRedoStacks sets isRestoringStacks to true")
    func testRestoreStacksStartsRestoring() {
        var state = ScheduleState()
        state.isRestoringStacks = false

        let newState = scheduleReducer(state: state, action: .restoreUndoRedoStacks)

        #expect(newState.isRestoringStacks == true)
    }

    @Test("stacksRestored success updates stacks and marks as restored")
    func testStacksRestoredSuccessUpdatesState() {
        var state = ScheduleState()
        state.isRestoringStacks = true

        let undoEntry = ChangeLogEntryBuilder().build()
        let redoEntry = ChangeLogEntryBuilder().build()

        let newState = scheduleReducer(
            state: state,
            action: .stacksRestored(.success((undo: [undoEntry], redo: [redoEntry])))
        )

        #expect(newState.isRestoringStacks == false)
        #expect(newState.undoStack.count == 1)
        #expect(newState.redoStack.count == 1)
        #expect(newState.stacksRestored == true)
    }

    // MARK: - Filters

    @Test("filterSheetToggled controls visibility")
    func testFilterSheetToggledControlsVisibility() {
        var state = ScheduleState()
        state.showFilterSheet = false

        let newState1 = scheduleReducer(state: state, action: .filterSheetToggled(true))
        #expect(newState1.showFilterSheet == true)

        let newState2 = scheduleReducer(state: newState1, action: .filterSheetToggled(false))
        #expect(newState2.showFilterSheet == false)
    }

    @Test("filterDateRangeChanged updates filter dates")
    func testFilterDateRangeChangedUpdatesState() {
        let state = ScheduleState()
        let startDate = Date()
        let endDate = Date().addingTimeInterval(86400)

        let newState = scheduleReducer(
            state: state,
            action: .filterDateRangeChanged(startDate: startDate, endDate: endDate)
        )

        #expect(newState.filterDateRangeStart == startDate)
        #expect(newState.filterDateRangeEnd == endDate)
    }

    @Test("filterLocationChanged updates location filter")
    func testFilterLocationChangedUpdatesState() {
        let state = ScheduleState()
        let location = LocationBuilder().build()

        let newState = scheduleReducer(state: state, action: .filterLocationChanged(location))

        #expect(newState.filterSelectedLocation?.id == location.id)
    }

    @Test("filterShiftTypeChanged updates shift type filter")
    func testFilterShiftTypeChangedUpdatesState() {
        let state = ScheduleState()
        let shiftType = createTestShiftType()

        let newState = scheduleReducer(state: state, action: .filterShiftTypeChanged(shiftType))

        #expect(newState.filterSelectedShiftType?.id == shiftType.id)
    }

    @Test("clearFilters resets all filter state")
    func testClearFiltersResetsAll() {
        var state = ScheduleState()
        state.filterDateRangeStart = Date()
        state.filterDateRangeEnd = Date()
        state.filterSelectedLocation = LocationBuilder().build()
        state.filterSelectedShiftType = ShiftTypeBuilder().build()
        state.searchText = "Morning"
        state.showFilterSheet = true

        let newState = scheduleReducer(state: state, action: .clearFilters)

        #expect(newState.filterDateRangeStart == nil)
        #expect(newState.filterDateRangeEnd == nil)
        #expect(newState.filterSelectedLocation == nil)
        #expect(newState.filterSelectedShiftType == nil)
        #expect(newState.searchText == "")
        #expect(newState.showFilterSheet == false)
    }

    // MARK: - Error Handling

    @Test("dismissError clears error state")
    func testDismissErrorClearsError() {
        var state = ScheduleState()
        state.currentError = .shiftNotFound

        let newState = scheduleReducer(state: state, action: .dismissError)

        #expect(newState.currentError == nil)
    }

    @Test("dismissSuccessToast clears success state")
    func testDismissSuccessToastClearsSuccess() {
        var state = ScheduleState()
        state.showSuccessToast = true
        state.successMessage = "Success"

        let newState = scheduleReducer(state: state, action: .dismissSuccessToast)

        #expect(newState.showSuccessToast == false)
        #expect(newState.successMessage == nil)
    }

    // MARK: - Computed Properties

    @Test("canUndo computes correctly based on undoStack")
    func testCanUndoComputedProperty() {
        var state = ScheduleState()
        state.undoStack = []

        #expect(state.canUndo == false)

        state.undoStack = [ChangeLogEntryBuilder().build()]

        #expect(state.canUndo == true)
    }

    @Test("canRedo computes correctly based on redoStack")
    func testCanRedoComputedProperty() {
        var state = ScheduleState()
        state.redoStack = []

        #expect(state.canRedo == false)

        state.redoStack = [ChangeLogEntryBuilder().build()]

        #expect(state.canRedo == true)
    }

    @Test("hasActiveFilters computes correctly")
    func testHasActiveFiltersComputedProperty() {
        var state = ScheduleState()

        #expect(state.hasActiveFilters == false)

        state.filterSelectedLocation = Location(id: UUID(), name: "Office", address: "123 Main St")

        #expect(state.hasActiveFilters == true)
    }
}

// MARK: - Test Helpers

extension ScheduleReducerTests {
    private func createTestShift() -> ScheduledShift {
        ScheduledShiftBuilder().build()
    }

    private func createTestShiftType() -> ShiftType {
        ShiftTypeBuilder().build()
    }

    private func createTestChangeLogEntry() -> ChangeLogEntry {
        ChangeLogEntryBuilder().build()
    }
}
