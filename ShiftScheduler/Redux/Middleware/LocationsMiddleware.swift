import Foundation
import OSLog

private let logger = Logger(subsystem: "com.shiftscheduler.redux", category: "LocationsMiddleware")

/// Middleware for Locations feature side effects
/// Handles loading, saving, and deleting locations
func locationsMiddleware(
    state: AppState,
    action: AppAction,
    dispatch: @escaping (AppAction) -> Void,
    services: ServiceContainer
) {
    guard case .locations(let locationsAction) = action else { return }

    switch locationsAction {
    case .task, .refreshLocations:
        // logger.debug("Loading locations")
        Task {
            do {
                let locations = try await services.persistenceService.loadLocations()
                dispatch(.locations(.locationsLoaded(.success(locations))))
            } catch {
        // logger.error("Failed to load locations: \(error.localizedDescription)")
                dispatch(.locations(.locationsLoaded(.failure(error))))
            }
        }

    case .searchTextChanged(let text):
        // logger.debug("Search text changed: \(text)")
        // No middleware side effects

    break
    case .addButtonTapped:
        // logger.debug("Add location button tapped")
        // No middleware side effects

    break
    case .editLocation(let location):
        // logger.debug("Editing location: \(location.name)")
        // No middleware side effects

    break
    case .saveLocation(let location):
        // logger.debug("Saving location: \(location.name)")
        Task {
            do {
                try await services.persistenceService.saveLocation(location)
        // logger.info("Location \(location.name) saved successfully")
                dispatch(.locations(.locationSaved(.success(()))))
                // Refresh after save
                dispatch(.locations(.refreshLocations))
            } catch {
        // logger.error("Failed to save location: \(error.localizedDescription)")
                dispatch(.locations(.locationSaved(.failure(error))))
            }
        }

    case .deleteLocation(let location):
        // logger.debug("Deleting location: \(location.name)")
        Task {
            do {
                try await services.persistenceService.deleteLocation(id: location.id)
                dispatch(.locations(.locationDeleted(.success(()))))
                // Refresh after delete
                dispatch(.locations(.refreshLocations))
            } catch {
        // logger.error("Failed to delete location: \(error.localizedDescription)")
                dispatch(.locations(.locationDeleted(.failure(error))))
            }
        }

    case .addEditSheetDismissed:
        // logger.debug("Add/edit sheet dismissed")
        // No middleware side effects

    break
    case .locationsLoaded, .locationDeleted, .locationSaved:
        // Handled by reducer only
    break
    }
}
