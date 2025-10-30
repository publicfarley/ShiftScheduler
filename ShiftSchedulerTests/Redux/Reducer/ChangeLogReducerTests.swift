import Testing
import Foundation
@testable import ShiftScheduler

/// Tests for the Change Log feature reducer state transitions
@Suite("ChangeLogReducer Tests")
@MainActor
struct ChangeLogReducerTests {

    // MARK: - Loading State

    @Test("task action sets isLoading to true")
    func testTaskActionStartsLoading() {
        var state = ChangeLogState()
        state.isLoading = false

        let newState = changeLogReducer(state: state, action: .task)

        #expect(newState.isLoading == true)
    }

    // MARK: - Load Entries

    @Test("entriesLoaded success updates entries and clears error")
    func testEntriesLoadedSuccessUpdatesState() {
        var state = ChangeLogState()
        state.isLoading = true
        state.errorMessage = "Previous error"

        let testEntries = [
            createTestChangeLogEntry(),
            createTestChangeLogEntry()
        ]

        let newState = changeLogReducer(state: state, action: .entriesLoaded(.success(testEntries)))

        #expect(newState.isLoading == false)
        #expect(newState.entries.count == 2)
        #expect(newState.errorMessage == nil)
    }

    @Test("entriesLoaded failure sets error message")
    func testEntriesLoadedFailureUpdatesError() {
        var state = ChangeLogState()
        state.isLoading = true
        state.errorMessage = nil

        let error = NSError(domain: "Test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Load failed"])
        let newState = changeLogReducer(state: state, action: .entriesLoaded(.failure(error)))

        #expect(newState.isLoading == false)
        #expect(newState.errorMessage != nil)
        #expect(newState.errorMessage?.contains("Load failed") ?? false)
    }

    // MARK: - Search

    @Test("searchTextChanged updates search text")
    func testSearchTextChangedUpdatesState() {
        var state = ChangeLogState()
        state.searchText = ""

        let newState = changeLogReducer(state: state, action: .searchTextChanged("Alice"))

        #expect(newState.searchText == "Alice")
    }

    @Test("filteredEntries filters by user display name")
    func testFilteredEntriesByUserName() {
        var state = ChangeLogState()
        let entry1 = ChangeLogEntryBuilder(userDisplayName: "Alice").build()
        let entry2 = ChangeLogEntryBuilder(userDisplayName: "Bob").build()
        state.entries = [entry1, entry2]
        state.searchText = "Alice"

        let filtered = state.filteredEntries

        #expect(filtered.count == 1)
        #expect(filtered.first?.userDisplayName == "Alice")
    }

    @Test("filteredEntries returns all when search is empty")
    func testFilteredEntriesEmpty() {
        var state = ChangeLogState()
        state.entries = [
            createTestChangeLogEntry(),
            createTestChangeLogEntry()
        ]
        state.searchText = ""

        let filtered = state.filteredEntries

        #expect(filtered.count == 2)
    }

    // MARK: - Delete Entry

    @Test("deleteEntry action sets isLoading to true")
    func testDeleteEntryStartsLoading() {
        var state = ChangeLogState()
        state.isLoading = false

        let entry = createTestChangeLogEntry()
        let newState = changeLogReducer(state: state, action: .deleteEntry(entry))

        #expect(newState.isLoading == true)
    }

    @Test("entryDeleted success clears loading")
    func testEntryDeletedSuccessUpdatesState() {
        var state = ChangeLogState()
        state.isLoading = true

        let newState = changeLogReducer(state: state, action: .entryDeleted(.success(())))

        #expect(newState.isLoading == false)
        #expect(newState.errorMessage == nil)
    }

    @Test("entryDeleted failure sets error")
    func testEntryDeletedFailureUpdatesError() {
        var state = ChangeLogState()
        state.isLoading = true

        let error = NSError(domain: "Test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Delete failed"])
        let newState = changeLogReducer(state: state, action: .entryDeleted(.failure(error)))

        #expect(newState.isLoading == false)
        #expect(newState.errorMessage != nil)
    }

    // MARK: - Purge Old Entries

    @Test("purgeOldEntries action sets isLoading to true")
    func testPurgeOldEntriesStartsLoading() {
        var state = ChangeLogState()
        state.isLoading = false

        let newState = changeLogReducer(state: state, action: .purgeOldEntries)

        #expect(newState.isLoading == true)
    }

    @Test("purgeCompleted success clears loading")
    func testPurgeCompletedSuccessUpdatesState() {
        var state = ChangeLogState()
        state.isLoading = true

        let newState = changeLogReducer(state: state, action: .purgeCompleted(.success(())))

        #expect(newState.isLoading == false)
    }

    @Test("purgeCompleted failure sets error")
    func testPurgeCompletedFailureUpdatesError() {
        var state = ChangeLogState()
        state.isLoading = true

        let error = NSError(domain: "Test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Purge failed"])
        let newState = changeLogReducer(state: state, action: .purgeCompleted(.failure(error)))

        #expect(newState.isLoading == false)
        #expect(newState.errorMessage != nil)
    }

    // MARK: - State Isolation

    @Test("loading entries preserves other state")
    func testLoadingPreservesOtherState() {
        var state = ChangeLogState()
        state.searchText = "Alice"
        state.isLoading = false

        let entries = [createTestChangeLogEntry()]
        let newState = changeLogReducer(state: state, action: .entriesLoaded(.success(entries)))

        #expect(newState.entries.count == 1)
        #expect(newState.searchText == "Alice")
        #expect(newState.isLoading == false)
    }

    @Test("sequential operations update state correctly")
    func testSequentialOperations() {
        var state = ChangeLogState()

        // Start loading
        state = changeLogReducer(state: state, action: .task)
        #expect(state.isLoading == true)

        // Load entries
        let entries = [
            createTestChangeLogEntry(),
            createTestChangeLogEntry()
        ]
        state = changeLogReducer(state: state, action: .entriesLoaded(.success(entries)))
        #expect(state.isLoading == false)
        #expect(state.entries.count == 2)

        // Search
        state = changeLogReducer(state: state, action: .searchTextChanged("Alice"))
        #expect(state.searchText == "Alice")
        #expect(state.entries.count == 2)  // Entries not changed

        // Purge old entries
        state = changeLogReducer(state: state, action: .purgeOldEntries)
        #expect(state.isLoading == true)
        #expect(state.searchText == "Alice")  // Search preserved

        // Purge completed
        state = changeLogReducer(state: state, action: .purgeCompleted(.success(())))
        #expect(state.isLoading == false)
    }

    @Test("deleting entry preserves search text")
    func testDeleteEntryPreservesSearchText() {
        var state = ChangeLogState()
        state.searchText = "Alice"
        state.isLoading = false

        let entry = createTestChangeLogEntry()
        state = changeLogReducer(state: state, action: .deleteEntry(entry))

        #expect(state.isLoading == true)
        #expect(state.searchText == "Alice")

        state = changeLogReducer(state: state, action: .entryDeleted(.success(())))

        #expect(state.isLoading == false)
        #expect(state.searchText == "Alice")
    }

    @Test("multiple sequential deletes work correctly")
    func testMultipleDeletions() {
        var state = ChangeLogState()

        let entry1 = createTestChangeLogEntry()
        let entry2 = createTestChangeLogEntry()

        // Delete first entry
        state = changeLogReducer(state: state, action: .deleteEntry(entry1))
        #expect(state.isLoading == true)

        state = changeLogReducer(state: state, action: .entryDeleted(.success(())))
        #expect(state.isLoading == false)

        // Delete second entry
        state = changeLogReducer(state: state, action: .deleteEntry(entry2))
        #expect(state.isLoading == true)

        state = changeLogReducer(state: state, action: .entryDeleted(.success(())))
        #expect(state.isLoading == false)
    }

    @Test("empty state operations work correctly")
    func testEmptyStateOperations() {
        var state = ChangeLogState()
        #expect(state.entries.count == 0)
        #expect(state.searchText == "")
        #expect(state.isLoading == false)

        // Load empty entries
        state = changeLogReducer(state: state, action: .entriesLoaded(.success([])))

        #expect(state.entries.count == 0)
        #expect(state.isLoading == false)

        // Search on empty entries
        state = changeLogReducer(state: state, action: .searchTextChanged("something"))

        #expect(state.searchText == "something")
        #expect(state.filteredEntries.count == 0)
    }
}

// MARK: - Test Helpers

extension ChangeLogReducerTests {
    private func createTestChangeLogEntry() -> ChangeLogEntry {
        ChangeLogEntryBuilder(userDisplayName: "Test User").build()
    }
}
