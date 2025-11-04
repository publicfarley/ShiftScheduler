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
    case .task:
        // Load auto-purge preference from UserDefaults
        let autoPurgeEnabled = UserDefaults.standard.object(forKey: "autoPurgeEnabled") as? Bool ?? true
        await dispatch(.settings(.autoPurgeToggled(autoPurgeEnabled)))

        // Load last purge date from UserDefaults
        if let lastPurgeTimestamp = UserDefaults.standard.object(forKey: "lastPurgeDate") as? TimeInterval {
            await dispatch(.settings(.lastPurgeDateUpdated(Date(timeIntervalSince1970: lastPurgeTimestamp))))
        }

        // Load purge statistics
        await dispatch(.settings(.loadPurgeStatistics))
        
    case .saveSettings:
        logger.debug("Saving settings")

        do {
            let profile = UserProfile(
                userId: state.userProfile.userId,
                displayName: state.settings.displayName,
                retentionPolicy: state.settings.retentionPolicy
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
        await dispatch(.changeLog(.purgeOldEntries))

        // Wait a moment for purge to complete, then reload statistics
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        await dispatch(.settings(.loadPurgeStatistics))
        await dispatch(.changeLog(.task)) // Reload change log entries

    case .autoPurgeToggled(let enabled):
        logger.debug("Auto-purge toggled: \(enabled)")
        UserDefaults.standard.set(enabled, forKey: "autoPurgeEnabled")

    case .manualPurgeCompleted:
        // Update last purge date
        let now = Date()
        UserDefaults.standard.set(now.timeIntervalSince1970, forKey: "lastPurgeDate")
        await dispatch(.settings(.lastPurgeDateUpdated(now)))

        // Reload statistics after purge
        await dispatch(.settings(.loadPurgeStatistics))

    case .settingsLoaded, .settingsSaved, .clearUnsavedChanges, .displayNameChanged, .retentionPolicyChanged,
         .purgeStatisticsLoaded, .lastPurgeDateUpdated:
        // Handled by reducer only
        break
    }
}
