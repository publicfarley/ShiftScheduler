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

    // MARK: - Retention Policy Changes

    @Test("retentionPolicyChanged updates policy and marks as unsaved")
    func testRetentionPolicyChangedUpdatesState() {
        var state = SettingsState()
        state.retentionPolicy = .forever
        state.hasUnsavedChanges = false

        let newState = settingsReducer(state: state, action: .retentionPolicyChanged(.days30))

        #expect(newState.retentionPolicy == .days30)
        #expect(newState.hasUnsavedChanges == true)
    }

    @Test("retentionPolicyChanged with same value still marks as changed")
    func testRetentionPolicyChangedWithSameValue() {
        var state = SettingsState()
        state.retentionPolicy = .days30
        state.hasUnsavedChanges = false

        let newState = settingsReducer(state: state, action: .retentionPolicyChanged(.days30))

        #expect(newState.retentionPolicy == .days30)
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

    @Test("settingsLoaded success updates retention policy and clears loading")
    func testSettingsLoadedSuccessUpdatesState() {
        var state = SettingsState()
        state.isLoading = true
        state.retentionPolicy = .forever

        let profile = UserProfile(userId: UUID(), displayName: "John Doe", retentionPolicy: .days30)
        let newState = settingsReducer(state: state, action: .settingsLoaded(.success(profile)))

        #expect(newState.isLoading == false)
        #expect(newState.retentionPolicy == .days30)
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

    @Test("changing retention policy preserves other state")
    func testRetentionPolicyChangePreservesOtherState() {
        var state = SettingsState()
        state.retentionPolicy = .forever
        state.totalChangeLogEntries = 50
        state.isLoading = false
        state.errorMessage = nil

        let newState = settingsReducer(state: state, action: .retentionPolicyChanged(.days30))

        #expect(newState.retentionPolicy == .days30)
        #expect(newState.totalChangeLogEntries == 50)
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
        let profile = UserProfile(userId: UUID(), displayName: "Alice", retentionPolicy: .days90)
        state = settingsReducer(state: state, action: .settingsLoaded(.success(profile)))
        #expect(state.isLoading == false)
        #expect(state.retentionPolicy == .days90)

        // Change retention policy
        state = settingsReducer(state: state, action: .retentionPolicyChanged(.days30))
        #expect(state.retentionPolicy == .days30)
        #expect(state.hasUnsavedChanges == true)

        // Save settings
        state = settingsReducer(state: state, action: .saveSettings)
        #expect(state.isLoading == true)
        #expect(state.retentionPolicy == .days30)  // Still days30
        #expect(state.hasUnsavedChanges == true)  // Still marked unsaved until success

        // Settings saved
        state = settingsReducer(state: state, action: .settingsSaved(.success(())))
        #expect(state.isLoading == false)
        #expect(state.hasUnsavedChanges == false)
        #expect(state.retentionPolicy == .days30)
    }

    @Test("multiple policy changes accumulate unsaved changes")
    func testMultiplePolicyChanges() {
        var state = SettingsState()
        state.retentionPolicy = .forever
        state.hasUnsavedChanges = false

        // First change
        state = settingsReducer(state: state, action: .retentionPolicyChanged(.days90))
        #expect(state.retentionPolicy == .days90)
        #expect(state.hasUnsavedChanges == true)

        // Second change
        state = settingsReducer(state: state, action: .retentionPolicyChanged(.days30))
        #expect(state.retentionPolicy == .days30)
        #expect(state.hasUnsavedChanges == true)

        // Clear unsaved
        state = settingsReducer(state: state, action: .clearUnsavedChanges)
        #expect(state.hasUnsavedChanges == false)
        #expect(state.retentionPolicy == .days30)  // Policy preserved
    }
}
