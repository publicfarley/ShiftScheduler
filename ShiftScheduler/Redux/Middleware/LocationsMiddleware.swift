import Foundation
import OSLog

private let logger = Logger(subsystem: "com.shiftscheduler.redux", category: "LocationsMiddleware")

/// Middleware for Locations feature side effects
/// Handles loading, saving, and deleting locations
func locationsMiddleware(
    state: AppState,
    action: AppAction,
    services: ServiceContainer,
    dispatch: Dispatcher<AppAction>,
) async {
    guard case .locations(let locationsAction) = action else { return }

    switch locationsAction {
    case .task, .refreshLocations:
        // logger.debug("Loading locations")
            do {
                let locations = try await services.persistenceService.loadLocations()
                await dispatch(.locations(.locationsLoaded(.success(locations))))
            } catch {
        // logger.error("Failed to load locations: \(error.localizedDescription)")
                await dispatch(.locations(.locationsLoaded(.failure(error))))
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
            do {
                try await services.persistenceService.saveLocation(location)
        // logger.info("Location \(location.name) saved successfully")
                await dispatch(.locations(.locationSaved(.success(()))))
                // Refresh after save
                await dispatch(.locations(.refreshLocations))
            } catch {
        // logger.error("Failed to save location: \(error.localizedDescription)")
                await dispatch(.locations(.locationSaved(.failure(error))))
            }

    case .deleteLocation(let location):
        // logger.debug("Deleting location: \(location.name)")

        // Check if location is used by any shift types
        let shiftTypesUsingLocation = state.shiftTypes.shiftTypes.filter { shiftType in
            shiftType.location.id == location.id
        }

        if !shiftTypesUsingLocation.isEmpty {
            let count = shiftTypesUsingLocation.count
            let message = "This location is used by \(count) shift type\(count == 1 ? "" : "s"). Remove those shift types first, then delete this location."
            let error = NSError(domain: "LocationDeletionError", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
            await dispatch(.locations(.locationDeleted(.failure(error))))
            return
        }

        do {
            try await services.persistenceService.deleteLocation(id: location.id)
            await dispatch(.locations(.locationDeleted(.success(()))))
            // Refresh after delete
            await dispatch(.locations(.refreshLocations))
        } catch {
    // logger.error("Failed to delete location: \(error.localizedDescription)")
            await dispatch(.locations(.locationDeleted(.failure(error))))
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
