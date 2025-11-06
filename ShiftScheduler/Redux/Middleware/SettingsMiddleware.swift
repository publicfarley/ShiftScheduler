import Foundation
import OSLog

private nonisolated let logger = Logger(subsystem: "com.shiftscheduler.redux", category: "SettingsMiddleware")

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
    case .loadSettings:
        // Load user profile (includes auto-purge settings and last purge date)
        do {
            let profile = try await services.persistenceService.loadUserProfile()
            await dispatch(.settings(.autoPurgeToggled(profile.autoPurgeEnabled)))
            if let lastPurgeDate = profile.lastPurgeDate {
                await dispatch(.settings(.lastPurgeDateUpdated(lastPurgeDate)))
            }
        } catch {
            logger.error("Failed to load user profile: \(error.localizedDescription)")
            // Use defaults on error
            await dispatch(.settings(.autoPurgeToggled(true)))
        }

        // Load purge statistics
        await dispatch(.settings(.loadPurgeStatistics))
        
    case .saveSettings:
        logger.debug("Saving settings")

        do {
            let profile = UserProfile(
                userId: state.userProfile.userId,
                displayName: state.userProfile.displayName,
                retentionPolicy: state.settings.retentionPolicy,
                autoPurgeEnabled: state.settings.autoPurgeEnabled,
                lastPurgeDate: state.settings.lastPurgeDate
            )

            try await services.persistenceService.saveUserProfile(profile)
            await dispatch(.settings(.settingsSaved(.success(()))))

            // Update app-level user profile
            await dispatch(.appLifecycle(.userProfileUpdated(profile)))
        } catch {
            logger.error("Failed to save settings: \(error.localizedDescription)")
            await dispatch(.settings(.settingsSaved(.failure(error))))
        }

    // MARK: - Purge Statistics Actions

    case .loadPurgeStatistics:
        logger.debug("Loading purge statistics")
        do {
            // Load all change log entries
            let entries = try await services.persistenceService.loadChangeLogEntries()
            let total = entries.count

            // Find oldest entry
            let oldestDate = entries.map { $0.timestamp }.min()

            // Calculate how many would be purged with current policy
            var toBePurged = 0
            if let cutoffDate = state.settings.retentionPolicy.cutoffDate {
                toBePurged = entries.filter { $0.timestamp < cutoffDate }.count
            }

            await dispatch(.settings(.purgeStatisticsLoaded(total: total, toBePurged: toBePurged, oldestDate: oldestDate)))
        } catch {
            logger.error("Failed to load purge statistics: \(error.localizedDescription)")
        }

    case .manualPurgeTriggered:
        logger.debug("Manual purge triggered from Settings")
        // Dispatch purge action to ChangeLogMiddleware
        // Completion will be handled when ChangeLogMiddleware dispatches purgeCompleted
        await dispatch(.changeLog(.purgeOldEntries))

    case .autoPurgeToggled(let enabled):
        logger.debug("Auto-purge toggled: \(enabled)")
        // Update will be saved when user saves settings
        // For now, just update reducer state - no direct UserDefaults access

    case .manualPurgeCompleted(.success(let deletedCount)):
        logger.debug("Manual purge completed: deleted \(deletedCount) entries")
        // Update last purge date in user profile
        let now = Date()
        do {
            var profile = try await services.persistenceService.loadUserProfile()
            profile.lastPurgeDate = now
            try await services.persistenceService.saveUserProfile(profile)
            await dispatch(.settings(.lastPurgeDateUpdated(now)))
        } catch {
            logger.error("Failed to save last purge date: \(error.localizedDescription)")
        }

        // Reload statistics after purge
        await dispatch(.settings(.loadPurgeStatistics))

    case .manualPurgeCompleted(.failure(let error)):
        logger.error("Manual purge failed: \(error.localizedDescription)")
        // Error already handled and logged by ChangeLogMiddleware

    case .settingsLoaded, .settingsSaved, .clearUnsavedChanges, .displayNameChanged, .retentionPolicyChanged,
         .purgeStatisticsLoaded, .lastPurgeDateUpdated:
        // Handled by reducer only
        break
    }
}
