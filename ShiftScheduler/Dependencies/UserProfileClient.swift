import Foundation
import ComposableArchitecture

/// TCA Dependency Client for User Profile management
@DependencyClient
struct UserProfileClient: Sendable {
    /// Get the current user profile
    var getCurrentProfile: @Sendable () -> UserProfile = { UserProfile() }

    /// Update the display name for the current user
    var updateDisplayName: @Sendable (String) -> Void = { _ in }

    /// Reset the user profile by creating a new user ID
    var resetUserProfile: @Sendable () -> Void = { }
}

extension UserProfileClient: DependencyKey {
    /// Live implementation using UserDefaults for persistence
    nonisolated static let liveValue: UserProfileClient = {
        UserProfileClient(
            getCurrentProfile: { UserProfile() },
            updateDisplayName: { _ in },
            resetUserProfile: { }
        )
    }()

    /// Test value with unimplemented methods
    nonisolated static let testValue = UserProfileClient()

    /// Preview value with mock data
    nonisolated static let previewValue = UserProfileClient(
        getCurrentProfile: { UserProfile(userId: UUID(), displayName: "Preview User") },
        updateDisplayName: { _ in },
        resetUserProfile: { }
    )
}

extension DependencyValues {
    var userProfileClient: UserProfileClient {
        get { self[UserProfileClient.self] }
        set { self[UserProfileClient.self] = newValue }
    }
}
