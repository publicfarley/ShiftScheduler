import Foundation
import OSLog

private let logger = Logger(subsystem: "com.shiftscheduler.redux", category: "SettingsMiddleware")

/// Middleware for Settings feature side effects
/// Handles loading and saving user settings
func settingsMiddleware(
    state: AppState,
    action: AppAction,
    services: ServiceContainer,
    dispatch: Dispatcher<AppAction>,
) async {
    guard case .settings(let settingsAction) = action else { return }

    switch settingsAction {
    case .task:
        // logger.debug("Loading user settings")
//        Task {
//            do {
//                let profile = UserProfile(
//                    userId: state.userProfile.userId,
//                    displayName: state.userProfile.displayName
//                )
//                await dispatch(.settings(.settingsLoaded(.success(profile))))
//            } catch {
//                logger.error("Failed to load settings: \(error.localizedDescription)")
//                await dispatch(.settings(.settingsLoaded(.failure(error))))
//            }
//        }

    break
    case .displayNameChanged(let name):
        // logger.debug("Display name changed to: \(name)")
        // No middleware side effects - reducer handles it

    break
    case .saveSettings:
        // logger.debug("Saving settings")
            do {
                let profile = UserProfile(
                    userId: state.userProfile.userId,
                    displayName: state.settings.displayName
                )
                    try await services.persistenceService.saveUserProfile(profile)
                await dispatch(.settings(.settingsSaved(.success(()))))
                // Update app-level user profile
                await dispatch(.appLifecycle(.userProfileUpdated(profile)))
            } catch {
        // logger.error("Failed to save settings: \(error.localizedDescription)")
                await dispatch(.settings(.settingsSaved(.failure(error))))
            }

    case .clearUnsavedChanges:
        // logger.debug("Clearing unsaved changes flag")
        // No middleware side effects

    break
    case .settingsLoaded, .settingsSaved:
        // logger.debug("No middleware side effects for action: \(String(describing: settingsAction))")
        // Handled by reducer only
    break
    }
}
