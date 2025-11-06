import Foundation
import OSLog

private nonisolated let logger = Logger(subsystem: "com.shiftscheduler.redux", category: "ChangeLogMiddleware")

/// Middleware for Change Log feature side effects
/// Handles loading, displaying, and managing change log entries
func changeLogMiddleware(
    state: AppState,
    action: AppAction,
    services: ServiceContainer,
    dispatch: Dispatcher<AppAction>
) async {
    guard case .changeLog(let changeLogAction) = action else { return }
    
    switch changeLogAction {
    case .loadChangeLogEntries:
        logger.debug("Loading change log entries")
        do {
            let entries = try await services.persistenceService.loadChangeLogEntries()
            await dispatch(.changeLog(.entriesLoaded(.success(entries))))
        } catch {
            logger.error("Failed to load change log entries: \(error.localizedDescription)")
            await dispatch(.changeLog(.entriesLoaded(.failure(error))))
        }
        
    case .deleteEntry(let entry):
        logger.debug("Deleting change log entry: \(entry.id)")
        do {
            try await services.persistenceService.deleteChangeLogEntry(id: entry.id)
            await dispatch(.changeLog(.entryDeleted(.success(()))))
        } catch {
            logger.error("Failed to delete change log entry: \(error.localizedDescription)")
            await dispatch(.changeLog(.entryDeleted(.failure(error))))
        }
        
    case .purgeOldEntries:
        logger.debug("Purging old change log entries based on retention policy: \(state.settings.retentionPolicy.displayName)")

        // Check if retention policy is "Forever" - skip purge
        guard let cutoffDate = state.settings.retentionPolicy.cutoffDate else {
            logger.debug("Retention policy is Forever - skipping purge")
            await dispatch(.changeLog(.purgeCompleted(.success(0))))
            return
        }

        do {
            // Pass cutoff date directly to avoid double calculation
            let deletedCount = try await services.persistenceService.purgeOldChangeLogEntries(olderThan: cutoffDate)
            logger.debug("Purged \(deletedCount) old entries (policy: \(state.settings.retentionPolicy.displayName))")
            await dispatch(.changeLog(.purgeCompleted(.success(deletedCount))))
        } catch {
            logger.error("Failed to purge old entries: \(error.localizedDescription)")
            await dispatch(.changeLog(.purgeCompleted(.failure(error))))
        }
        
    case .purgeCompleted(.success(let deletedCount)):
        logger.debug("Purge completed: deleted \(deletedCount) entries")
        // Forward completion to settings if manual purge was triggered
        await dispatch(.settings(.manualPurgeCompleted(.success(deletedCount))))
        // Reload change log entries to refresh UI
        await dispatch(.changeLog(.loadChangeLogEntries))

    case .purgeCompleted(.failure(let error)):
        logger.error("Purge failed: \(error.localizedDescription)")
        // Forward error to settings
        await dispatch(.settings(.manualPurgeCompleted(.failure(error))))

    case .entriesLoaded, .entryDeleted, .searchTextChanged:
        // Handled by reducer only
        break
    }
}
