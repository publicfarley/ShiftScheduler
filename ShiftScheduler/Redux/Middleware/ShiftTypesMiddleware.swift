import Foundation
import OSLog

private let logger = Logger(subsystem: "com.shiftscheduler.redux", category: "ShiftTypesMiddleware")

/// Middleware for Shift Types feature side effects
/// Handles loading, saving, and deleting shift types
func shiftTypesMiddleware(
    state: AppState,
    action: AppAction,
    services: ServiceContainer,
    dispatch: Dispatcher<AppAction>,
) async {
    guard case .shiftTypes(let shiftTypesAction) = action else { return }

    switch shiftTypesAction {
    case .task, .refreshShiftTypes:
        // logger.debug("Loading shift types")
            do {
                let shiftTypes = try await services.persistenceService.loadShiftTypes()
                await dispatch(.shiftTypes(.shiftTypesLoaded(.success(shiftTypes))))
            } catch {
        // logger.error("Failed to load shift types: \(error.localizedDescription)")
                await dispatch(.shiftTypes(.shiftTypesLoaded(.failure(error))))
            }

    case .searchTextChanged(let text):
        // logger.debug("Search text changed: \(text)")
        // No middleware side effects

    break
    case .addButtonTapped:
        // logger.debug("Add shift type button tapped")
        // No middleware side effects

    break
    case .editShiftType(let shiftType):
        // logger.debug("Editing shift type: \(shiftType.title)")
        // No middleware side effects

    break
    case .saveShiftType(let shiftType):
        // logger.debug("Saving shift type: \(shiftType.title)")

        // Validate symbol uniqueness (case-insensitive)
        let duplicateSymbols = state.shiftTypes.shiftTypes.filter { existing in
            existing.symbol.uppercased() == shiftType.symbol.uppercased() &&
            existing.id != shiftType.id
        }

        if !duplicateSymbols.isEmpty {
            let errorMessage = "A shift type with symbol '\(shiftType.symbol)' already exists."
            let error = NSError(domain: "ValidationError", code: 1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
            await dispatch(.shiftTypes(.shiftTypeSaved(.failure(error))))
            return
        }

        // Validate location exists
        let locationExists = state.locations.locations.contains { location in
            location.id == shiftType.location.id
        }

        if !locationExists {
            let errorMessage = "Selected location no longer exists. Please select another location."
            let error = NSError(domain: "ValidationError", code: 2, userInfo: [NSLocalizedDescriptionKey: errorMessage])
            await dispatch(.shiftTypes(.shiftTypeSaved(.failure(error))))
            return
        }

        // Validate time range (end time must be after start time)
        if case .scheduled(let from, let to) = shiftType.duration {
            if from.toDate() >= to.toDate() {
                let errorMessage = "End time must be after start time."
                let error = NSError(domain: "ValidationError", code: 3, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                await dispatch(.shiftTypes(.shiftTypeSaved(.failure(error))))
                return
            }
        }

        do {
            try await services.persistenceService.saveShiftType(shiftType)
            await dispatch(.shiftTypes(.shiftTypeSaved(.success(()))))
            // Refresh after save
            await dispatch(.shiftTypes(.refreshShiftTypes))
        } catch {
    // logger.error("Failed to save shift type: \(error.localizedDescription)")
            await dispatch(.shiftTypes(.shiftTypeSaved(.failure(error))))
        }

    case .deleteShiftType(let shiftType):
        // logger.debug("Deleting shift type: \(shiftType.title)")
            do {
                try await services.persistenceService.deleteShiftType(id: shiftType.id)
                await dispatch(.shiftTypes(.shiftTypeDeleted(.success(()))))
                // Refresh after delete
                await dispatch(.shiftTypes(.refreshShiftTypes))
            } catch {
        // logger.error("Failed to delete shift type: \(error.localizedDescription)")
                await dispatch(.shiftTypes(.shiftTypeDeleted(.failure(error))))
            }

    case .addEditSheetDismissed:
        // logger.debug("Add/edit sheet dismissed")
        // No middleware side effects

    break
    case .shiftTypesLoaded, .shiftTypeDeleted, .shiftTypeSaved:
        // Handled by reducer only
    break
    }
}
