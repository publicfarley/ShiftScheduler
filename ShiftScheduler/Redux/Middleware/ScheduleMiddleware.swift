import Foundation
import OSLog

private let logger = os.Logger(subsystem: "com.shiftscheduler.redux", category: "ScheduleMiddleware")

/// Middleware for Schedule feature side effects
/// Handles calendar operations, shift loading, and shift switching
func scheduleMiddleware(
    state: AppState,
    action: AppAction,
    dispatch: @escaping (AppAction) -> Void,
    services: ServiceContainer
) {
    guard case .schedule(let scheduleAction) = action else { return }

    switch scheduleAction {
    case .task:
        logger.debug("Schedule task started")
        // Check authorization
        Task {
            do {
                let authorized = try await services.calendarService.requestCalendarAccess()
                dispatch(.schedule(.authorizationChecked(authorized)))
            } catch {
                logger.error("Failed to check authorization: \(error.localizedDescription)")
                dispatch(.schedule(.authorizationChecked(false)))
            }
        }
        // Load shifts
        dispatch(.schedule(.loadShifts))

    case .checkAuthorization:
        Task {
            do {
                let authorized = try await services.calendarService.isCalendarAuthorized()
                dispatch(.schedule(.authorizationChecked(authorized)))
            } catch {
                logger.error("Failed to check authorization: \(error.localizedDescription)")
                dispatch(.schedule(.authorizationChecked(false)))
            }
        }

    case .loadShifts:
        logger.debug("Loading shifts for selected date: \(state.schedule.selectedDate.formatted())")
        Task {
            do {
                let shifts = try await services.calendarService.loadShiftsForCurrentMonth()
                dispatch(.schedule(.shiftsLoaded(.success(shifts))))
            } catch {
                logger.error("Failed to load shifts: \(error.localizedDescription)")
                dispatch(.schedule(.shiftsLoaded(.failure(error))))
            }
        }

    case .selectedDateChanged(let date):
        logger.debug("Selected date changed to: \(date.formatted())")
        // Load shifts for new date will be handled by the reducer triggering loadShifts

    case .searchTextChanged(let text):
        logger.debug("Search text changed to: \(text)")
        // No middleware side effects needed

    case .addShiftButtonTapped:
        logger.debug("Add shift button tapped")
        // No middleware side effects needed

    case .deleteShift(let shift):
        logger.debug("Deleting shift: \(shift.eventIdentifier)")
        // TODO: Implement shift deletion via calendar service
        // For now, just complete the action
        dispatch(.schedule(.shiftDeleted(.success(()))))

    case .switchShiftTapped:
        logger.debug("Switch shift tapped")
        // No middleware side effects needed - handled by reducer

    case .performSwitchShift(let shift, let newShiftType, let reason):
        logger.debug("Performing shift switch from \(shift.shiftType?.title ?? "unknown") to \(newShiftType.title)")
        // TODO: Implement shift switch via services
        // For now, create a mock change log entry
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
                dispatch(.schedule(.shiftSwitched(.success(entry))))
            } catch {
                logger.error("Failed to switch shift: \(error.localizedDescription)")
                dispatch(.schedule(.shiftSwitched(.failure(error))))
            }
        }

    case .undo:
        logger.debug("Undo requested")
        // TODO: Implement undo via shift switch service
        dispatch(.schedule(.undoCompleted(.success(()))))

    case .redo:
        logger.debug("Redo requested")
        // TODO: Implement redo via shift switch service
        dispatch(.schedule(.redoCompleted(.success(()))))

    // MARK: - Filter Actions

    case .filterSheetToggled(let show):
        logger.debug("Filter sheet toggled: \(show)")
        // No middleware side effects - handled by reducer

    case .filterDateRangeChanged(let startDate, let endDate):
        logger.debug("Date range filter applied: \(String(describing: startDate)) to \(String(describing: endDate))")
        // Load shifts for the selected date range
        if let start = startDate, let end = endDate {
            Task {
                do {
                    let shifts = try await services.calendarService.loadShifts(from: start, to: end)
                    dispatch(.schedule(.shiftsLoaded(.success(shifts))))
                } catch {
                    logger.error("Failed to load shifts for date range: \(error.localizedDescription)")
                    dispatch(.schedule(.shiftsLoaded(.failure(error))))
                }
            }
        } else {
            // If date range is cleared, load current month
            dispatch(.schedule(.loadShifts))
        }

    case .filterLocationChanged(let location):
        logger.debug("Location filter changed to: \(location?.name ?? "None")")
        // No middleware side effects - filtering handled in state

    case .filterShiftTypeChanged(let shiftType):
        logger.debug("Shift type filter changed to: \(shiftType?.title ?? "None")")
        // No middleware side effects - filtering handled in state

    case .clearFilters:
        logger.debug("Filters cleared - reloading all shifts")
        dispatch(.schedule(.loadShifts))

    case .authorizationChecked, .shiftDeleted, .shiftSwitched, .shiftsLoaded, .stacksRestored, .undoCompleted, .redoCompleted:
        logger.debug("No middleware side effects for action: \(String(describing: scheduleAction))")
        // These actions are handled by the reducer only
    }
}
