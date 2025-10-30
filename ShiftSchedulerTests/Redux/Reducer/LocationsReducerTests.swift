import Testing
import Foundation
@testable import ShiftScheduler

/// Tests for the Locations feature reducer state transitions
@Suite("LocationsReducer Tests")
@MainActor
struct LocationsReducerTests {

    // MARK: - Loading State

    @Test("task action sets isLoading to true")
    func testTaskActionStartsLoading() {
        var state = LocationsState()
        state.isLoading = false

        let newState = locationsReducer(state: state, action: .task)

        #expect(newState.isLoading == true)
    }

    @Test("refreshLocations action sets isLoading to true")
    func testRefreshLocationsStartsLoading() {
        var state = LocationsState()
        state.isLoading = false

        let newState = locationsReducer(state: state, action: .refreshLocations)

        #expect(newState.isLoading == true)
    }

    @Test("locationsLoaded success updates locations and clears error")
    func testLocationsLoadedSuccessUpdatesState() {
        var state = LocationsState()
        state.isLoading = true
        state.errorMessage = "Previous error"

        let testLocations = [
            Location(id: UUID(), name: "Office", address: "123 Main St"),
            Location(id: UUID(), name: "Remote", address: "Home")
        ]

        let newState = locationsReducer(state: state, action: .locationsLoaded(.success(testLocations)))

        #expect(newState.isLoading == false)
        #expect(newState.locations.count == 2)
        #expect(newState.errorMessage == nil)
    }

    @Test("locationsLoaded failure sets error message")
    func testLocationsLoadedFailureUpdatesError() {
        var state = LocationsState()
        state.isLoading = true
        state.errorMessage = nil

        let error = NSError(domain: "Test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Load failed"])
        let newState = locationsReducer(state: state, action: .locationsLoaded(.failure(error)))

        #expect(newState.isLoading == false)
        #expect(newState.errorMessage != nil)
        #expect(newState.errorMessage?.contains("Load failed") ?? false)
    }

    // MARK: - Search

    @Test("searchTextChanged updates search text")
    func testSearchTextChangedUpdatesState() {
        var state = LocationsState()
        state.searchText = ""

        let newState = locationsReducer(state: state, action: .searchTextChanged("Office"))

        #expect(newState.searchText == "Office")
    }

    @Test("filteredLocations filters by name")
    func testFilteredLocationsByName() {
        var state = LocationsState()
        state.locations = [
            LocationBuilder(name: "Office").build(),
            LocationBuilder(name: "Warehouse").build()
        ]
        state.searchText = "Office"

        let filtered = state.filteredLocations

        #expect(filtered.count == 1)
        #expect(filtered.first?.name == "Office")
    }

    @Test("filteredLocations filters by address")
    func testFilteredLocationsByAddress() {
        var state = LocationsState()
        state.locations = [
            LocationBuilder(address: "123 Main St").build(),
            LocationBuilder(address: "456 Oak Ave").build()
        ]
        state.searchText = "Main"

        let filtered = state.filteredLocations

        #expect(filtered.count == 1)
        #expect(filtered.first?.address.contains("Main") ?? false)
    }

    @Test("filteredLocations returns all when search is empty")
    func testFilteredLocationsEmpty() {
        var state = LocationsState()
        state.locations = [
            LocationBuilder().build(),
            LocationBuilder().build()
        ]
        state.searchText = ""

        let filtered = state.filteredLocations

        #expect(filtered.count == 2)
    }

    // MARK: - Add Location

    @Test("addButtonTapped shows sheet without location")
    func testAddButtonTappedShowsSheet() {
        var state = LocationsState()
        state.showAddEditSheet = false
        state.editingLocation = nil

        let newState = locationsReducer(state: state, action: .addButtonTapped)

        #expect(newState.showAddEditSheet == true)
        #expect(newState.editingLocation == nil)
    }

    @Test("saveLocation action sets isLoading")
    func testSaveLocationStartsLoading() {
        var state = LocationsState()
        state.isLoading = false
        state.errorMessage = "Previous"

        let location = LocationBuilder().build()
        let newState = locationsReducer(state: state, action: .saveLocation(location))

        #expect(newState.isLoading == true)
        #expect(newState.errorMessage == nil)
    }

    @Test("locationSaved success closes sheet and clears error")
    func testLocationSavedSuccessUpdatesState() {
        var state = LocationsState()
        state.isLoading = true
        state.showAddEditSheet = true
        state.editingLocation = LocationBuilder().build()

        let newState = locationsReducer(state: state, action: .locationSaved(.success(())))

        #expect(newState.isLoading == false)
        #expect(newState.showAddEditSheet == false)
        #expect(newState.editingLocation == nil)
        #expect(newState.errorMessage == nil)
    }

    @Test("locationSaved failure sets error")
    func testLocationSavedFailureUpdatesError() {
        var state = LocationsState()
        state.isLoading = true

        let error = NSError(domain: "Test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Save failed"])
        let newState = locationsReducer(state: state, action: .locationSaved(.failure(error)))

        #expect(newState.isLoading == false)
        #expect(newState.errorMessage != nil)
        #expect(newState.showAddEditSheet == true)  // Keep sheet open
    }

    // MARK: - Edit Location

    @Test("editLocation shows sheet with location")
    func testEditLocationShowsSheet() {
        var state = LocationsState()
        state.showAddEditSheet = false
        state.editingLocation = nil

        let location = LocationBuilder().build()
        let newState = locationsReducer(state: state, action: .editLocation(location))

        #expect(newState.showAddEditSheet == true)
        #expect(newState.editingLocation?.id == location.id)
    }

    // MARK: - Delete Location

    @Test("deleteLocation action sets isLoading")
    func testDeleteLocationStartsLoading() {
        var state = LocationsState()
        state.isLoading = false

        let location = LocationBuilder().build()
        let newState = locationsReducer(state: state, action: .deleteLocation(location))

        #expect(newState.isLoading == true)
    }

    @Test("locationDeleted success clears loading")
    func testLocationDeletedSuccessUpdatesState() {
        var state = LocationsState()
        state.isLoading = true

        let newState = locationsReducer(state: state, action: .locationDeleted(.success(())))

        #expect(newState.isLoading == false)
        #expect(newState.errorMessage == nil)
    }

    @Test("locationDeleted failure sets error")
    func testLocationDeletedFailureUpdatesError() {
        var state = LocationsState()
        state.isLoading = true

        let error = NSError(domain: "Test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Delete failed"])
        let newState = locationsReducer(state: state, action: .locationDeleted(.failure(error)))

        #expect(newState.isLoading == false)
        #expect(newState.errorMessage != nil)
    }

    // MARK: - Sheet Dismissal

    @Test("addEditSheetDismissed closes sheet and clears location")
    func testAddEditSheetDismissedClearsState() {
        var state = LocationsState()
        state.showAddEditSheet = true
        state.editingLocation = LocationBuilder().build()

        let newState = locationsReducer(state: state, action: .addEditSheetDismissed)

        #expect(newState.showAddEditSheet == false)
        #expect(newState.editingLocation == nil)
    }

    // MARK: - State Isolation

    @Test("loading locations preserves other state")
    func testLoadingPreservesOtherState() {
        var state = LocationsState()
        state.searchText = "Office"
        state.isLoading = false

        let locations = [Location(id: UUID(), name: "Office", address: "123 Main St")]
        let newState = locationsReducer(state: state, action: .locationsLoaded(.success(locations)))

        #expect(newState.locations.count == 1)
        #expect(newState.searchText == "Office")
        #expect(newState.isLoading == false)
    }

    @Test("sequential operations update state correctly")
    func testSequentialOperations() {
        var state = LocationsState()

        // Start loading
        state = locationsReducer(state: state, action: .task)
        #expect(state.isLoading == true)

        // Load locations
        let locations = [
            LocationBuilder(name: "Office").build(),
            LocationBuilder(name: "Warehouse").build()
        ]
        state = locationsReducer(state: state, action: .locationsLoaded(.success(locations)))
        #expect(state.isLoading == false)
        #expect(state.locations.count == 2)

        // Search
        state = locationsReducer(state: state, action: .searchTextChanged("Office"))
        #expect(state.searchText == "Office")
        #expect(state.locations.count == 2)  // Locations not changed

        // Open add sheet
        state = locationsReducer(state: state, action: .addButtonTapped)
        #expect(state.showAddEditSheet == true)
        #expect(state.editingLocation == nil)
        #expect(state.searchText == "Office")  // Search preserved
    }
}
