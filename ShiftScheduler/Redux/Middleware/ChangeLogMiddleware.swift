import Foundation
import OSLog

private let logger = os.Logger(subsystem: "com.shiftscheduler.redux", category: "ChangeLogMiddleware")

/// Middleware for Change Log feature side effects
/// Handles loading, displaying, and managing change log entries
func changeLogMiddleware(
    state: AppState,
    action: AppAction,
    dispatch: @escaping (AppAction) -> Void,
    services: ServiceContainer
) {
    guard case .changeLog(let changeLogAction) = action else { return }

    switch changeLogAction {
    case .task:
        logger.debug("Loading change log entries")
        Task {
            do {
                let entries = try await services.persistenceService.loadChangeLogEntries()
                dispatch(.changeLog(.entriesLoaded(.success(entries))))
            } catch {
                logger.error("Failed to load change log entries: \(error.localizedDescription)")
                dispatch(.changeLog(.entriesLoaded(.failure(error))))
            }
        }

    case .searchTextChanged(let text):
        logger.debug("Search text changed: \(text)")
        // No middleware side effects

    case .deleteEntry(let entry):
        logger.debug("Deleting change log entry: \(entry.id)")
        Task {
            do {
                try await services.persistenceService.deleteChangeLogEntry(id: entry.id)
                dispatch(.changeLog(.entryDeleted(.success(()))))
            } catch {
                logger.error("Failed to delete change log entry: \(error.localizedDescription)")
                dispatch(.changeLog(.entryDeleted(.failure(error))))
            }
        }

    case .purgeOldEntries:
        logger.debug("Purging old change log entries")
        Task {
            do {
                let deletedCount = try await services.persistenceService.purgeOldChangeLogEntries(olderThanDays: 30)
                logger.debug("Purged \(deletedCount) old entries")
                dispatch(.changeLog(.purgeCompleted(.success(()))))
            } catch {
                logger.error("Failed to purge old entries: \(error.localizedDescription)")
                dispatch(.changeLog(.purgeCompleted(.failure(error))))
            }
        }

    case .entriesLoaded, .entryDeleted, .purgeCompleted:
        logger.debug("No middleware side effects for action: \(String(describing: changeLogAction))")
        // Handled by reducer only
    }
}
