import Foundation
import ComposableArchitecture

/// TCA Dependency Client for User Profile management
/// Manages user profile persistence and retrieval using UserDefaults
@DependencyClient
struct UserProfileClient {
    /// Get the current user profile
    var getCurrentProfile: @Sendable () -> UserProfile = { UserProfile() }

    /// Update the display name for the current user
    var updateDisplayName: @Sendable (String) -> Void

    /// Reset the user profile by creating a new user ID
    var resetUserProfile: @Sendable () -> Void
}

extension UserProfileClient: DependencyKey {
    /// Live implementation using UserDefaults for persistence
    static let liveValue: UserProfileClient = {
        let userDefaultsKey = "com.workevents.ShiftScheduler.userProfile"
        let defaults = UserDefaults.standard

        let loadProfile = {
            if let data = defaults.data(forKey: userDefaultsKey),
               let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
                return profile
            }
            return UserProfile()
        }

        return UserProfileClient(
            getCurrentProfile: {
                let profile = loadProfile()
                // Save if new
                if defaults.data(forKey: userDefaultsKey) == nil {
                    do {
                        let data = try JSONEncoder().encode(profile)
                        defaults.set(data, forKey: userDefaultsKey)
                    } catch {
                        // Silently fail, will use default
                    }
                }
                return profile
            },
            updateDisplayName: { newName in
                let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                let currentProfile = loadProfile()
                let updatedProfile = UserProfile(
                    userId: currentProfile.userId,
                    displayName: trimmedName.isEmpty ? "User" : trimmedName
                )
                do {
                    let data = try JSONEncoder().encode(updatedProfile)
                    defaults.set(data, forKey: userDefaultsKey)
                } catch {
                    // Silently fail
                }
            },
            resetUserProfile: {
                let newProfile = UserProfile()
                do {
                    let data = try JSONEncoder().encode(newProfile)
                    defaults.set(data, forKey: userDefaultsKey)
                } catch {
                    // Silently fail
                }
            }
        )
    }()

    /// Test value with unimplemented methods
    static let testValue = UserProfileClient()

    /// Preview value with mock data
    static let previewValue = UserProfileClient(
        getCurrentProfile: {
            UserProfile(userId: UUID(), displayName: "Preview User")
        },
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
