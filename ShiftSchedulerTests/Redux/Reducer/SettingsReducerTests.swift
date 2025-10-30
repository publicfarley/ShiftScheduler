import Testing
import Foundation
@testable import ShiftScheduler

/// Tests for the Settings feature reducer state transitions
@Suite("SettingsReducer Tests")
@MainActor
struct SettingsReducerTests {

    // MARK: - Loading State

    @Test("task action sets isLoading to true")
    func testTaskActionStartsLoading() {
        var state = SettingsState()
        state.isLoading = false

        let newState = settingsReducer(state: state, action: .task)

        #expect(newState.isLoading == true)
    }

    // MARK: - Display Name Changes

    @Test("displayNameChanged updates display name and marks as unsaved")
    func testDisplayNameChangedUpdatesState() {
        var state = SettingsState()
        state.displayName = "Alice"
        state.hasUnsavedChanges = false

        let newState = settingsReducer(state: state, action: .displayNameChanged("Bob"))

        #expect(newState.displayName == "Bob")
        #expect(newState.hasUnsavedChanges == true)
    }

    @Test("displayNameChanged with same value still marks as changed")
    func testDisplayNameChangedWithSameValue() {
        var state = SettingsState()
        state.displayName = "Alice"
        state.hasUnsavedChanges = false

        let newState = settingsReducer(state: state, action: .displayNameChanged("Alice"))

        #expect(newState.displayName == "Alice")
        #expect(newState.hasUnsavedChanges == true)
    }

    // MARK: - Save Settings

    @Test("saveSettings action sets isLoading to true")
    func testSaveSettingsStartsLoading() {
        var state = SettingsState()
        state.isLoading = false

        let newState = settingsReducer(state: state, action: .saveSettings)

        #expect(newState.isLoading == true)
    }

    @Test("settingsSaved success clears loading and unsaved flag")
    func testSettingsSavedSuccessUpdatesState() {
        var state = SettingsState()
        state.isLoading = true
        state.hasUnsavedChanges = true

        let newState = settingsReducer(state: state, action: .settingsSaved(.success(())))

        #expect(newState.isLoading == false)
        #expect(newState.hasUnsavedChanges == false)
    }

    @Test("settingsSaved failure clears loading but keeps unsaved flag")
    func testSettingsSavedFailureKeepsUnsavedFlag() {
        var state = SettingsState()
        state.isLoading = true
        state.hasUnsavedChanges = true

        let error = NSError(domain: "Test", code: -1)
        let newState = settingsReducer(state: state, action: .settingsSaved(.failure(error)))

        #expect(newState.isLoading == false)
        #expect(newState.hasUnsavedChanges == true)  // Still unsaved
    }

    // MARK: - Load Settings

    @Test("settingsLoaded success updates user info and clears loading")
    func testSettingsLoadedSuccessUpdatesState() {
        var state = SettingsState()
        state.isLoading = true
        state.displayName = ""
        state.userId = UUID()

        let userId = UUID()
        let profile = UserProfile(userId: userId, displayName: "John Doe")
        let newState = settingsReducer(state: state, action: .settingsLoaded(.success(profile)))

        #expect(newState.isLoading == false)
        #expect(newState.userId == userId)
        #expect(newState.displayName == "John Doe")
    }

    @Test("settingsLoaded failure sets error message")
    func testSettingsLoadedFailureUpdatesError() {
        var state = SettingsState()
        state.isLoading = true
        state.errorMessage = nil

        let error = NSError(domain: "Test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Load failed"])
        let newState = settingsReducer(state: state, action: .settingsLoaded(.failure(error)))

        #expect(newState.isLoading == false)
        #expect(newState.errorMessage != nil)
        #expect(newState.errorMessage?.contains("Load failed") ?? false)
    }

    // MARK: - Clear Unsaved Changes

    @Test("clearUnsavedChanges sets hasUnsavedChanges to false")
    func testClearUnsavedChanges() {
        var state = SettingsState()
        state.hasUnsavedChanges = true

        let newState = settingsReducer(state: state, action: .clearUnsavedChanges)

        #expect(newState.hasUnsavedChanges == false)
    }

    // MARK: - State Isolation

    @Test("changing display name preserves other state")
    func testDisplayNameChangePreservesOtherState() {
        var state = SettingsState()
        state.displayName = "Alice"
        state.userId = UUID()
        state.isLoading = false
        state.errorMessage = nil

        let newState = settingsReducer(state: state, action: .displayNameChanged("Bob"))

        #expect(newState.displayName == "Bob")
        #expect(newState.userId == state.userId)
        #expect(newState.isLoading == false)
        #expect(newState.errorMessage == nil)
    }

    @Test("sequential operations update state correctly")
    func testSequentialOperations() {
        var state = SettingsState()

        // Start loading
        state = settingsReducer(state: state, action: .task)
        #expect(state.isLoading == true)

        // Load settings
        let userId = UUID()
        let profile = UserProfile(userId: userId, displayName: "Alice")
        state = settingsReducer(state: state, action: .settingsLoaded(.success(profile)))
        #expect(state.isLoading == false)
        #expect(state.displayName == "Alice")
        #expect(state.userId == userId)

        // Change display name
        state = settingsReducer(state: state, action: .displayNameChanged("Bob"))
        #expect(state.displayName == "Bob")
        #expect(state.hasUnsavedChanges == true)
        #expect(state.userId == userId)  // Preserved

        // Save settings
        state = settingsReducer(state: state, action: .saveSettings)
        #expect(state.isLoading == true)
        #expect(state.displayName == "Bob")  // Still Bob
        #expect(state.hasUnsavedChanges == true)  // Still marked unsaved until success

        // Settings saved
        state = settingsReducer(state: state, action: .settingsSaved(.success(())))
        #expect(state.isLoading == false)
        #expect(state.hasUnsavedChanges == false)
        #expect(state.displayName == "Bob")
    }

    @Test("multiple display name changes accumulate unsaved changes")
    func testMultipleDisplayNameChanges() {
        var state = SettingsState()
        state.displayName = "Alice"
        state.hasUnsavedChanges = false

        // First change
        state = settingsReducer(state: state, action: .displayNameChanged("Bob"))
        #expect(state.displayName == "Bob")
        #expect(state.hasUnsavedChanges == true)

        // Second change
        state = settingsReducer(state: state, action: .displayNameChanged("Charlie"))
        #expect(state.displayName == "Charlie")
        #expect(state.hasUnsavedChanges == true)

        // Clear unsaved
        state = settingsReducer(state: state, action: .clearUnsavedChanges)
        #expect(state.hasUnsavedChanges == false)
        #expect(state.displayName == "Charlie")  // Name preserved
    }
}
