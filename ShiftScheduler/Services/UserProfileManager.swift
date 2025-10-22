import Foundation
import OSLog

private let logger = Logger(subsystem: "com.workevents.ShiftScheduler", category: "UserProfileManager")

/// Manages user profile persistence and retrieval using UserDefaults
/// DEPRECATED: Use UserProfileManagerClient TCA dependency instead.
/// This class is maintained only for backward compatibility with pre-TCA code.
final class UserProfileManager {
    @available(*, deprecated, message: "Use UserProfileManagerClient TCA dependency instead. This singleton will be removed in a future version.")
    static let shared = UserProfileManager()

    private let userDefaultsKey = "com.workevents.ShiftScheduler.userProfile"
    private let defaults = UserDefaults.standard

    /// Current user profile
    private(set) var currentProfile: UserProfile

    private init() {
        // Load existing profile or create new one
        if let data = defaults.data(forKey: userDefaultsKey),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            self.currentProfile = profile
            logger.debug("Loaded existing user profile: \(profile.userId)")
        } else {
            // Create new profile on first launch
            self.currentProfile = UserProfile()
            logger.debug("Created new user profile: \(self.currentProfile.userId)")
            save()
        }
    }

    /// Updates the display name for the current user
    func updateDisplayName(_ newName: String) {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        currentProfile = UserProfile(
            userId: currentProfile.userId,
            displayName: trimmedName.isEmpty ? "User" : trimmedName
        )
        save()
        logger.debug("Updated display name to: \(self.currentProfile.displayName)")
    }

    /// Resets the user profile by creating a new user ID
    func resetUserProfile() {
        currentProfile = UserProfile()
        save()
        logger.debug("Reset user profile, new userId: \(self.currentProfile.userId)")
    }

    /// Returns the current user profile
    func getCurrentProfile() -> UserProfile {
        currentProfile
    }

    // MARK: - Private Methods

    private func save() {
        do {
            let data = try JSONEncoder().encode(currentProfile)
            defaults.set(data, forKey: userDefaultsKey)
            logger.debug("User profile saved successfully")
        } catch {
            logger.error("Failed to save user profile: \(error.localizedDescription)")
        }
    }
}
