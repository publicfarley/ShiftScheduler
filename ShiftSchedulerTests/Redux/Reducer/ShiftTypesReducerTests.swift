import Testing
import Foundation
@testable import ShiftScheduler

/// Tests for the Shift Types feature reducer state transitions
@Suite("ShiftTypesReducer Tests")
@MainActor
struct ShiftTypesReducerTests {

    // MARK: - Loading State

    @Test("task action sets isLoading to true")
    func testTaskActionStartsLoading() {
        var state = ShiftTypesState()
        state.isLoading = false

        let newState = shiftTypesReducer(state: state, action: .loadShiftTypes)

        #expect(newState.isLoading == true)
    }

    @Test("refreshShiftTypes action sets isLoading to true")
    func testRefreshShiftTypesStartsLoading() {
        var state = ShiftTypesState()
        state.isLoading = false

        let newState = shiftTypesReducer(state: state, action: .refreshShiftTypes)

        #expect(newState.isLoading == true)
    }

    @Test("shiftTypesLoaded success updates shift types and clears error")
    func testShiftTypesLoadedSuccessUpdatesState() {
        var state = ShiftTypesState()
        state.isLoading = true
        state.errorMessage = "Previous error"

        let testShiftTypes = [createTestShiftType(), createTestShiftType()]

        let newState = shiftTypesReducer(state: state, action: .shiftTypesLoaded(.success(testShiftTypes)))

        #expect(newState.isLoading == false)
        #expect(newState.shiftTypes.count == 2)
        #expect(newState.errorMessage == nil)
    }

    @Test("shiftTypesLoaded failure sets error message")
    func testShiftTypesLoadedFailureUpdatesError() {
        var state = ShiftTypesState()
        state.isLoading = true
        state.errorMessage = nil

        let error = NSError(domain: "Test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Load failed"])
        let newState = shiftTypesReducer(state: state, action: .shiftTypesLoaded(.failure(error)))

        #expect(newState.isLoading == false)
        #expect(newState.errorMessage != nil)
        #expect(newState.errorMessage?.contains("Load failed") ?? false)
    }

    // MARK: - Search

    @Test("searchTextChanged updates search text")
    func testSearchTextChangedUpdatesState() {
        var state = ShiftTypesState()
        state.searchText = ""

        let newState = shiftTypesReducer(state: state, action: .searchTextChanged("Morning"))

        #expect(newState.searchText == "Morning")
    }

    @Test("filteredShiftTypes filters by title")
    func testFilteredShiftTypesByTitle() {
        var state = ShiftTypesState()
        let morning = createTestShiftTypeWithTitle("Morning Shift")
        let evening = createTestShiftTypeWithTitle("Evening Shift")
        state.shiftTypes = [morning, evening]
        state.searchText = "Morning"

        let filtered = state.filteredShiftTypes

        #expect(filtered.count == 1)
        #expect(filtered.first?.title == "Morning Shift")
    }

    @Test("filteredShiftTypes filters by symbol")
    func testFilteredShiftTypesBySymbol() {
        var state = ShiftTypesState()
        let morning = createTestShiftTypeWithSymbol("🌅")
        let evening = createTestShiftTypeWithSymbol("🌙")
        state.shiftTypes = [morning, evening]
        state.searchText = "🌅"

        let filtered = state.filteredShiftTypes

        #expect(filtered.count == 1)
        #expect(filtered.first?.symbol == "🌅")
    }

    @Test("filteredShiftTypes filters by location name")
    func testFilteredShiftTypesByLocation() {
        var state = ShiftTypesState()
        let office = ShiftTypeBuilder(location: LocationBuilder(name: "Office").build()).build()
        let remote = ShiftTypeBuilder(location: LocationBuilder(name: "Remote").build()).build()
        state.shiftTypes = [office, remote]
        state.searchText = "Office"

        let filtered = state.filteredShiftTypes

        #expect(filtered.count == 1)
        #expect(filtered.first?.location.name == "Office")
    }

    @Test("filteredShiftTypes returns all when search is empty")
    func testFilteredShiftTypesEmpty() {
        var state = ShiftTypesState()
        state.shiftTypes = [createTestShiftType(), createTestShiftType()]
        state.searchText = ""

        let filtered = state.filteredShiftTypes

        #expect(filtered.count == 2)
    }

    // MARK: - Add Shift Type

    @Test("addButtonTapped shows sheet without shift type")
    func testAddButtonTappedShowsSheet() {
        var state = ShiftTypesState()
        state.showAddEditSheet = false
        state.editingShiftType = nil

        let newState = shiftTypesReducer(state: state, action: .addButtonTapped)

        #expect(newState.showAddEditSheet == true)
        #expect(newState.editingShiftType == nil)
    }

    @Test("saveShiftType action sets isLoading")
    func testSaveShiftTypeStartsLoading() {
        var state = ShiftTypesState()
        state.isLoading = false
        state.errorMessage = "Previous"

        let shiftType = createTestShiftType()
        let newState = shiftTypesReducer(state: state, action: .saveShiftType(shiftType))

        #expect(newState.isLoading == true)
        #expect(newState.errorMessage == nil)
    }

    @Test("shiftTypeSaved success closes sheet and clears error")
    func testShiftTypeSavedSuccessUpdatesState() {
        var state = ShiftTypesState()
        state.isLoading = true
        state.showAddEditSheet = true
        state.editingShiftType = createTestShiftType()

        let newState = shiftTypesReducer(state: state, action: .shiftTypeSaved(.success(())))

        #expect(newState.isLoading == false)
        #expect(newState.showAddEditSheet == false)
        #expect(newState.editingShiftType == nil)
        #expect(newState.errorMessage == nil)
    }

    @Test("shiftTypeSaved failure sets error")
    func testShiftTypeSavedFailureUpdatesError() {
        var state = ShiftTypesState()
        state.isLoading = true

        let error = NSError(domain: "Test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Save failed"])
        let newState = shiftTypesReducer(state: state, action: .shiftTypeSaved(.failure(error)))

        #expect(newState.isLoading == false)
        #expect(newState.errorMessage != nil)
        #expect(newState.showAddEditSheet == true)  // Keep sheet open
    }

    // MARK: - Edit Shift Type

    @Test("editShiftType shows sheet with shift type")
    func testEditShiftTypeShowsSheet() {
        var state = ShiftTypesState()
        state.showAddEditSheet = false
        state.editingShiftType = nil

        let shiftType = createTestShiftType()
        let newState = shiftTypesReducer(state: state, action: .editShiftType(shiftType))

        #expect(newState.showAddEditSheet == true)
        #expect(newState.editingShiftType?.id == shiftType.id)
    }

    // MARK: - Delete Shift Type

    @Test("deleteShiftType action sets isLoading")
    func testDeleteShiftTypeStartsLoading() {
        var state = ShiftTypesState()
        state.isLoading = false

        let shiftType = createTestShiftType()
        let newState = shiftTypesReducer(state: state, action: .deleteShiftType(shiftType))

        #expect(newState.isLoading == true)
    }

    @Test("shiftTypeDeleted success clears loading")
    func testShiftTypeDeletedSuccessUpdatesState() {
        var state = ShiftTypesState()
        state.isLoading = true

        let newState = shiftTypesReducer(state: state, action: .shiftTypeDeleted(.success(())))

        #expect(newState.isLoading == false)
        #expect(newState.errorMessage == nil)
    }

    @Test("shiftTypeDeleted failure sets error")
    func testShiftTypeDeletedFailureUpdatesError() {
        var state = ShiftTypesState()
        state.isLoading = true

        let error = NSError(domain: "Test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Delete failed"])
        let newState = shiftTypesReducer(state: state, action: .shiftTypeDeleted(.failure(error)))

        #expect(newState.isLoading == false)
        #expect(newState.errorMessage != nil)
    }

    // MARK: - Sheet Dismissal

    @Test("addEditSheetDismissed closes sheet and clears shift type")
    func testAddEditSheetDismissedClearsState() {
        var state = ShiftTypesState()
        state.showAddEditSheet = true
        state.editingShiftType = createTestShiftType()

        let newState = shiftTypesReducer(state: state, action: .addEditSheetDismissed)

        #expect(newState.showAddEditSheet == false)
        #expect(newState.editingShiftType == nil)
    }

    // MARK: - State Isolation

    @Test("loading shift types preserves other state")
    func testLoadingPreservesOtherState() {
        var state = ShiftTypesState()
        state.searchText = "Morning"
        state.isLoading = false

        let shiftTypes = [createTestShiftType()]
        let newState = shiftTypesReducer(state: state, action: .shiftTypesLoaded(.success(shiftTypes)))

        #expect(newState.shiftTypes.count == 1)
        #expect(newState.searchText == "Morning")
        #expect(newState.isLoading == false)
    }

    @Test("sequential operations update state correctly")
    func testSequentialOperations() {
        var state = ShiftTypesState()

        // Start loading
        state = shiftTypesReducer(state: state, action: .loadShiftTypes)
        #expect(state.isLoading == true)

        // Load shift types
        let shiftTypes = [
            createTestShiftTypeWithTitle("Morning"),
            createTestShiftTypeWithTitle("Evening")
        ]
        state = shiftTypesReducer(state: state, action: .shiftTypesLoaded(.success(shiftTypes)))
        #expect(state.isLoading == false)
        #expect(state.shiftTypes.count == 2)

        // Search
        state = shiftTypesReducer(state: state, action: .searchTextChanged("Morning"))
        #expect(state.searchText == "Morning")
        #expect(state.shiftTypes.count == 2)  // Shift types not changed

        // Open add sheet
        state = shiftTypesReducer(state: state, action: .addButtonTapped)
        #expect(state.showAddEditSheet == true)
        #expect(state.editingShiftType == nil)
        #expect(state.searchText == "Morning")  // Search preserved

        // Open edit sheet
        let shiftType = createTestShiftTypeWithTitle("Edit Test")
        state = shiftTypesReducer(state: state, action: .editShiftType(shiftType))
        #expect(state.showAddEditSheet == true)
        #expect(state.editingShiftType?.id == shiftType.id)
    }
}

// MARK: - Test Helpers

extension ShiftTypesReducerTests {
    private func createTestShiftType() -> ShiftType {
        ShiftTypeBuilder().build()
    }

    private func createTestShiftTypeWithTitle(_ title: String) -> ShiftType {
        ShiftTypeBuilder(title: title).build()
    }

    private func createTestShiftTypeWithSymbol(_ symbol: String) -> ShiftType {
        ShiftTypeBuilder(symbol: symbol).build()
    }
}
