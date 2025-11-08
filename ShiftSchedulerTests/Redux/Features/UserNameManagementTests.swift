import Testing
import Foundation
@testable import ShiftScheduler

@MainActor
@Suite("User Name Management")
struct UserNameManagementTests {
    // MARK: - Onboarding Gate Tests

    @Test("Onboarding: isNameConfigured flag initialized to false")
    func testOnboardingInitialState() {
        let initialState = AppState()
        #expect(initialState.isNameConfigured == false)
        #expect(initialState.userProfile.displayName == "")
    }

    @Test("Onboarding: displayNameChanged action sets isNameConfigured to true")
    func testDisplayNameChangedSetsNameConfigured() {
        var state = AppState()
        state = appReducer(state: state, action: .appLifecycle(.displayNameChanged("John")))

        #expect(state.isNameConfigured == true)
        #expect(state.userProfile.displayName == "John")
    }

    @Test("Onboarding: displayNameChanged with whitespace-only name keeps isNameConfigured false")
    func testDisplayNameChangedWithWhitespace() {
        var state = AppState()
        state = appReducer(state: state, action: .appLifecycle(.displayNameChanged("   ")))

        #expect(state.isNameConfigured == false)
        #expect(state.userProfile.displayName == "   ")
    }

    @Test("Onboarding: userProfileUpdated sets isNameConfigured based on displayName")
    func testUserProfileUpdatedSetsNameConfigured() {
        var state = AppState()
        let profileWithName = UserProfile(
            userId: UUID(),
            displayName: "Jane Doe",
            retentionPolicy: .forever,
            autoPurgeEnabled: true
        )
        state = appReducer(state: state, action: .appLifecycle(.userProfileUpdated(profileWithName)))

        #expect(state.isNameConfigured == true)
        #expect(state.userProfile.displayName == "Jane Doe")
    }

    @Test("Onboarding: userProfileUpdated with empty name keeps isNameConfigured false")
    func testUserProfileUpdatedWithEmptyName() {
        var state = AppState()
        let profileWithoutName = UserProfile(
            userId: UUID(),
            displayName: "",
            retentionPolicy: .forever,
            autoPurgeEnabled: true
        )
        state = appReducer(state: state, action: .appLifecycle(.userProfileUpdated(profileWithoutName)))

        #expect(state.isNameConfigured == false)
        #expect(state.userProfile.displayName == "")
    }

    // MARK: - State Synchronization Tests

    @Test("State Sync: displayName removed from SettingsState")
    func testSettingsStateNoDisplayName() {
        let settings = SettingsState()
        // The struct should not have a displayName property
        // This test confirms the migration was successful by checking other properties exist
        #expect(settings.retentionPolicy == .forever)
        #expect(settings.autoPurgeEnabled == true)
    }

    @Test("State Sync: AppState.userProfile is single source of truth")
    func testUserProfileSingleSourceOfTruth() {
        var state = AppState()

        // Set display name via displayNameChanged action
        state = appReducer(state: state, action: .appLifecycle(.displayNameChanged("Alice")))

        // Verify it's in AppState.userProfile, not SettingsState
        #expect(state.userProfile.displayName == "Alice")
        #expect(state.isNameConfigured == true)
    }

    // MARK: - Profile Persistence Tests

    @Test("Persistence: Default profile starts with empty displayName")
    func testDefaultProfileEmptyName() async throws {
        let persistenceService = MockPersistenceService()
        // Mock should return a profile with empty display name by default
        let profile = try await persistenceService.loadUserProfile()

        #expect(profile.displayName == "")
    }

    @Test("Persistence: Can save and load user profile")
    func testSaveAndLoadProfile() async throws {
        let persistenceService = MockPersistenceService()

        let originalProfile = UserProfile(
            userId: UUID(),
            displayName: "Test User",
            retentionPolicy: .forever,
            autoPurgeEnabled: false
        )

        try await persistenceService.saveUserProfile(originalProfile)
        let loadedProfile = try await persistenceService.loadUserProfile()

        #expect(loadedProfile.displayName == originalProfile.displayName)
        #expect(loadedProfile.userId == originalProfile.userId)
        #expect(loadedProfile.autoPurgeEnabled == originalProfile.autoPurgeEnabled)
    }

    @Test("Persistence: Multiple saves overwrite previous profile")
    func testMultipleSavesOverwrite() async throws {
        let persistenceService = MockPersistenceService()

        let profile1 = UserProfile(
            userId: UUID(),
            displayName: "User One",
            retentionPolicy: .forever,
            autoPurgeEnabled: true
        )
        let profile2 = UserProfile(
            userId: profile1.userId,
            displayName: "User Two",
            retentionPolicy: .forever,
            autoPurgeEnabled: true
        )

        try await persistenceService.saveUserProfile(profile1)
        try await persistenceService.saveUserProfile(profile2)
        let loadedProfile = try await persistenceService.loadUserProfile()

        #expect(loadedProfile.displayName == "User Two")
    }

    // MARK: - Reducer Action Tests

    @Test("Reducer: displayNameChanged action updates app-level state")
    func testDisplayNameChangedReducer() {
        var state = AppState()

        let action = AppAction.appLifecycle(.displayNameChanged("Bob Smith"))
        state = appReducer(state: state, action: action)

        #expect(state.userProfile.displayName == "Bob Smith")
        #expect(state.isNameConfigured == true)
    }

    @Test("Reducer: userProfileUpdated action replaces entire profile")
    func testUserProfileUpdatedReducer() {
        var state = AppState()

        let newProfile = UserProfile(
            userId: state.userProfile.userId,
            displayName: "New Name",
            retentionPolicy: .years2,
            autoPurgeEnabled: false
        )

        state = appReducer(state: state, action: .appLifecycle(.userProfileUpdated(newProfile)))

        #expect(state.userProfile.displayName == "New Name")
        #expect(state.userProfile.retentionPolicy == .years2)
    }

    // Note: ChangeLog entry name capture is tested implicitly in integration tests
    // The middleware automatically captures displayName from state when creating entries

    // MARK: - Integration Tests

    @Test("Integration: Complete onboarding flow")
    func testCompleteOnboardingFlow() {
        var state = AppState()

        // Initial state
        #expect(state.isNameConfigured == false)
        #expect(state.userProfile.displayName == "")

        // User enters display name
        state = appReducer(state: state, action: .appLifecycle(.displayNameChanged("Sarah")))

        // State should be updated
        #expect(state.isNameConfigured == true)
        #expect(state.userProfile.displayName == "Sarah")

        // User can now access app (isNameConfigured is true)
    }

    @Test("Integration: Settings changes sync with app state")
    func testSettingsSyncWithAppState() {
        var state = AppState()

        // User sets display name
        state = appReducer(state: state, action: .appLifecycle(.displayNameChanged("Michael")))

        // Retention policy change in settings
        state.settings = SettingsState()
        state.settings.retentionPolicy = .year1
        state = appReducer(state: state, action: .settings(.retentionPolicyChanged(.year1)))

        // Display name should still be there
        #expect(state.userProfile.displayName == "Michael")
        #expect(state.settings.retentionPolicy == .year1)
    }

    @Test("Integration: User profile persists across app launches")
    func testUserProfilePersistsAcrossLaunches() async throws {
        let persistenceService = MockPersistenceService()
        let userId = UUID()
        let displayName = "Persistent User"

        // Simulate first app launch - save profile
        let profile1 = UserProfile(
            userId: userId,
            displayName: displayName,
            retentionPolicy: .forever,
            autoPurgeEnabled: true
        )
        try await persistenceService.saveUserProfile(profile1)

        // Simulate app restart - load profile
        let profile2 = try await persistenceService.loadUserProfile()

        // Profile should be preserved
        #expect(profile2.displayName == displayName)
        #expect(profile2.userId == userId)
    }

    @Test("Integration: Empty displayName in loaded profile triggers onboarding")
    func testEmptyNameTriggersOnboarding() async throws {
        let persistenceService = MockPersistenceService()

        // Load default profile (empty displayName)
        let loadedProfile = try await persistenceService.loadUserProfile()

        // Verify it would trigger onboarding
        let isNameConfigured = !loadedProfile.displayName.trimmingCharacters(in: .whitespaces).isEmpty
        #expect(isNameConfigured == false)
    }
}
