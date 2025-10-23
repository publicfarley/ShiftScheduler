import Foundation
import OSLog

private let logger = os.Logger(subsystem: "com.shiftscheduler.redux", category: "TodayMiddleware")

/// Middleware for Today feature side effects
/// Handles shift loading, caching, and shift switching for today view
func todayMiddleware(
    state: AppState,
    action: AppAction,
    dispatch: @escaping (AppAction) -> Void,
    services: ServiceContainer
) {
    guard case .today(let todayAction) = action else { return }

    switch todayAction {
    case .task:
        logger.debug("Today task started")
        // Load shifts for next 30 days
        Task {
            do {
                let shifts = try await services.calendarService.loadShiftsForNext30Days()
                dispatch(.today(.shiftsLoaded(.success(shifts))))
                // Update cached shifts after loading
                dispatch(.today(.updateCachedShifts))
                dispatch(.today(.updateUndoRedoStates))
            } catch {
                logger.error("Failed to load shifts: \(error.localizedDescription)")
                dispatch(.today(.shiftsLoaded(.failure(error))))
            }
        }

    case .loadShifts:
        logger.debug("Loading shifts for Today view")
        Task {
            do {
                let shifts = try await services.calendarService.loadShiftsForNext30Days()
                dispatch(.today(.shiftsLoaded(.success(shifts))))
                dispatch(.today(.updateCachedShifts))
            } catch {
                logger.error("Failed to load shifts: \(error.localizedDescription)")
                dispatch(.today(.shiftsLoaded(.failure(error))))
            }
        }

    case .switchShiftTapped(let shift):
        logger.debug("Switch shift tapped for: \(shift.eventIdentifier)")
        // No middleware side effects - UI will handle sheet presentation

    case .performSwitchShift(let shift, let newShiftType, let reason):
        logger.debug("Performing shift switch from \(shift.shiftType?.title ?? "unknown") to \(newShiftType.title)")
        // TODO: Implement shift switch via services
        Task {
            do {
                let entry = ChangeLogEntry(
                    id: UUID(),
                    timestamp: Date(),
                    userId: state.userProfile.userId,
                    userDisplayName: state.userProfile.displayName,
                    changeType: .switched,
                    scheduledShiftDate: shift.date,
                    reason: reason
                )
                dispatch(.today(.shiftSwitched(.success(()))))
                // Reload shifts after switch
                dispatch(.today(.loadShifts))
            } catch {
                logger.error("Failed to switch shift: \(error.localizedDescription)")
                dispatch(.today(.shiftSwitched(.failure(error))))
            }
        }

    case .toastMessageCleared:
        logger.debug("Toast message cleared")
        // No middleware side effects

    case .switchShiftSheetDismissed:
        logger.debug("Switch shift sheet dismissed")
        // No middleware side effects

    case .updateCachedShifts:
        logger.debug("Updating cached shifts")
        // No middleware side effects - reducer handles this

    case .updateUndoRedoStates:
        logger.debug("Updating undo/redo states")
        // No middleware side effects - reducer handles this

    case .shiftsLoaded, .shiftSwitched:
        logger.debug("No middleware side effects for action: \(String(describing: todayAction))")
        // Handled by reducer only
    }
}
