import Foundation
import OSLog

private let logger = Logger(subsystem: "com.shiftscheduler.redux", category: "ChangeLogMiddleware")

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
    case .task:
        // logger.debug("Loading change log entries")
            do {
                let entries = try await services.persistenceService.loadChangeLogEntries()
                await dispatch(.changeLog(.entriesLoaded(.success(entries))))
            } catch {
//                logger.error("Failed to load change log entries: \(error.localizedDescription)")
                await dispatch(.changeLog(.entriesLoaded(.failure(error))))
            }

    case .searchTextChanged(let text):
         logger.debug("Search text changed: \(text)")
        // No middleware side effects
        break

    case .deleteEntry(let entry):
//         logger.debug("Deleting change log entry: \(entry.id)")
            do {
                try await services.persistenceService.deleteChangeLogEntry(id: entry.id)
                await dispatch(.changeLog(.entryDeleted(.success(()))))
            } catch {
        // logger.error("Failed to delete change log entry: \(error.localizedDescription)")
                await dispatch(.changeLog(.entryDeleted(.failure(error))))
            }

    case .purgeOldEntries:
        // logger.debug("Purging old change log entries")
            do {
                let deletedCount = try await services.persistenceService.purgeOldChangeLogEntries(olderThanDays: 30)
        // logger.debug("Purged \(deletedCount) old entries")
                await dispatch(.changeLog(.purgeCompleted(.success(()))))
            } catch {
        // logger.error("Failed to purge old entries: \(error.localizedDescription)")
                await dispatch(.changeLog(.purgeCompleted(.failure(error))))
            }

    case .entriesLoaded, .entryDeleted, .purgeCompleted:
        // Handled by reducer only
    break
    }
}
