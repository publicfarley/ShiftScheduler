import Foundation
import ComposableArchitecture

/// TCA Dependency Client for User Profile management
/// Wraps the existing UserProfileManager for use within TCA reducers
@DependencyClient
struct UserProfileManagerClient {
    /// Get the current user profile
    var getCurrentProfile: @Sendable () -> UserProfile = { UserProfile() }

    /// Update the display name for the current user
    var updateDisplayName: @Sendable (String) -> Void

    /// Reset the user profile by creating a new user ID
    var resetUserProfile: @Sendable () -> Void
}

extension UserProfileManagerClient: DependencyKey {
    /// Live implementation using the real UserProfileManager
    static let liveValue: UserProfileManagerClient = {
        // Note: We suppress the deprecation warning here because the client is the proper TCA
        // abstraction that wraps the singleton. The singleton itself is deprecated, but
        // its usage within the client is acceptable during the transition period.
        nonisolated(unsafe) var manager: UserProfileManager {
            @available(*, deprecated)
            get { UserProfileManager.shared }
        }

        return UserProfileManagerClient(
            getCurrentProfile: {
                manager.getCurrentProfile()
            },
            updateDisplayName: { newName in
                manager.updateDisplayName(newName)
            },
            resetUserProfile: {
                manager.resetUserProfile()
            }
        )
    }()

    /// Test value with unimplemented methods
    static let testValue = UserProfileManagerClient()

    /// Preview value with mock data
    static let previewValue = UserProfileManagerClient(
        getCurrentProfile: {
            UserProfile(userId: UUID(), displayName: "Preview User")
        },
        updateDisplayName: { _ in },
        resetUserProfile: { }
    )
}

extension DependencyValues {
    var userProfileManagerClient: UserProfileManagerClient {
        get { self[UserProfileManagerClient.self] }
        set { self[UserProfileManagerClient.self] = newValue }
    }
}
