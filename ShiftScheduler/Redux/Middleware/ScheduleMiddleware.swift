import Foundation
import OSLog

private let logger = Logger(subsystem: "com.shiftscheduler.redux", category: "ScheduleMiddleware")

/// Middleware for Schedule feature side effects
/// Handles calendar operations, shift loading, and shift switching
func scheduleMiddleware(
    state: AppState,
    action: AppAction,
    services: ServiceContainer,
    dispatch: @escaping Dispatcher<AppAction>
) async {
    guard case .schedule(let scheduleAction) = action else { return }

    switch scheduleAction {
    case .task:
        // logger.debug("Schedule task started")
        // Check authorization
            do {
                let authorized = try await services.calendarService.requestCalendarAccess()
                await dispatch(.schedule(.authorizationChecked(authorized)))
            } catch {
        // logger.error("Failed to check authorization: \(error.localizedDescription)")
                await dispatch(.schedule(.authorizationChecked(false)))
            }

            // Load shifts
            await dispatch(.schedule(.loadShifts))

    case .checkAuthorization:
            do {
                let authorized = try await services.calendarService.isCalendarAuthorized()
                await dispatch(.schedule(.authorizationChecked(authorized)))
            } catch {
        // logger.error("Failed to check authorization: \(error.localizedDescription)")
                await dispatch(.schedule(.authorizationChecked(false)))
            }

    case .loadShifts:
        // logger.debug("Loading shifts for selected date: \(state.schedule.selectedDate.formatted())")
            do {
                let shifts = try await services.calendarService.loadShiftsForCurrentMonth()
                await dispatch(.schedule(.shiftsLoaded(.success(shifts))))
            } catch {
        // logger.error("Failed to load shifts: \(error.localizedDescription)")
                await dispatch(.schedule(.shiftsLoaded(.failure(error))))
            }

    case .selectedDateChanged(let date):
        // logger.debug("Selected date changed to: \(date.formatted())")
        // Load shifts for new date will be handled by the reducer triggering loadShifts

    break
    case .searchTextChanged(let text):
        // logger.debug("Search text changed to: \(text)")
        // No middleware side effects needed

    break
    case .addShiftButtonTapped:
        // logger.debug("Add shift button tapped")
        // No middleware side effects needed

    break
    case .deleteShift(let shift):
        // logger.debug("Deleting shift: \(shift.eventIdentifier)")
        // TODO: Implement shift deletion via calendar service
        // For now, just complete the action
        await dispatch(.schedule(.shiftDeleted(.success(()))))

    case .switchShiftTapped:
        // logger.debug("Switch shift tapped")
        // No middleware side effects needed - handled by reducer

    break
    case .performSwitchShift(let shift, let newShiftType, let reason):
        // logger.debug("Performing shift switch from \(shift.shiftType?.title ?? "unknown") to \(newShiftType.title) on \(shift.date.formatted())")
            do {
                // Create snapshots of old and new shift types
                let oldSnapshot = shift.shiftType.map { ShiftSnapshot(from: $0) }
                let newSnapshot = ShiftSnapshot(from: newShiftType)

                // Create change log entry with full history
                let entry = ChangeLogEntry(
                    id: UUID(),
                    timestamp: Date(),
                    userId: state.userProfile.userId,
                    userDisplayName: state.userProfile.displayName,
                    changeType: .switched,
                    scheduledShiftDate: shift.date,
                    oldShiftSnapshot: oldSnapshot,
                    newShiftSnapshot: newSnapshot,
                    reason: reason
                )

                // Persist the change log entry
                try await services.persistenceService.addChangeLogEntry(entry)

                // Save updated undo/redo stacks
                var undoStack = state.schedule.undoStack
                undoStack.append(entry)
                try await services.persistenceService.saveUndoRedoStacks(
                    undo: undoStack,
                    redo: [] // Clear redo stack on new operation
                )

        // logger.debug("Shift \(shift.eventIdentifier) switched to \(newShiftType.title). Undo stack: \(undoStack.count), Redo stack: 0")
                await dispatch(.schedule(.shiftSwitched(.success(entry))))

                // Reload shifts after switch to refresh from calendar
                await dispatch(.schedule(.loadShifts))
            } catch {
        // logger.error("Failed to switch shift: \(error.localizedDescription)")
                await dispatch(.schedule(.shiftSwitched(.failure(error))))
            }

    case .undo:
        // logger.debug("Undo requested")
        guard !state.schedule.undoStack.isEmpty else {
        // logger.debug("Undo stack is empty")
            await dispatch(.schedule(.undoCompleted(.failure(NSError(domain: "Undo", code: -1, userInfo: [NSLocalizedDescriptionKey: "Nothing to undo"])))))
            return
        }

            do {
                var undoStack = state.schedule.undoStack
                var redoStack = state.schedule.redoStack

                // Pop from undo stack and push to redo stack
                if !undoStack.isEmpty {
                    let operation = undoStack.removeLast()
                    redoStack.append(operation)

                    // Persist the updated stacks
                    try await services.persistenceService.saveUndoRedoStacks(
                        undo: undoStack,
                        redo: redoStack
                    )

//         logger.debug("Undo completed. Operation reversed.")
                }

                // Reload shifts to refresh UI
                await dispatch(.schedule(.loadShifts))
                await dispatch(.schedule(.undoCompleted(.success(()))))
            } catch {
        // logger.error("Failed to undo: \(error.localizedDescription)")
                await dispatch(.schedule(.undoCompleted(.failure(error))))
            }

    case .redo:
        // logger.debug("Redo requested")
        guard !state.schedule.redoStack.isEmpty else {
        // logger.debug("Redo stack is empty")
            await dispatch(.schedule(.redoCompleted(.failure(NSError(domain: "Redo", code: -1, userInfo: [NSLocalizedDescriptionKey: "Nothing to redo"])))))
            return
        }

            do {
                var undoStack = state.schedule.undoStack
                var redoStack = state.schedule.redoStack

                // Pop from redo stack and push to undo stack
                if !redoStack.isEmpty {
                    let operation = redoStack.removeLast()
                    undoStack.append(operation)

                    // Persist the updated stacks
                    try await services.persistenceService.saveUndoRedoStacks(
                        undo: undoStack,
                        redo: redoStack
                    )

        // logger.debug("Redo completed. Operation reapplied.")
                }

                // Reload shifts to refresh UI
                await dispatch(.schedule(.loadShifts))
                await dispatch(.schedule(.redoCompleted(.success(()))))
            } catch {
        // logger.error("Failed to redo: \(error.localizedDescription)")
                await dispatch(.schedule(.redoCompleted(.failure(error))))
            }

    // MARK: - Filter Actions

    case .filterSheetToggled(let show):
        // logger.debug("Filter sheet toggled: \(show)")
        // No middleware side effects - handled by reducer

    break
    case .filterDateRangeChanged(let startDate, let endDate):
        // logger.debug("Date range filter applied: \(String(describing: startDate)) to \(String(describing: endDate))")
        // Load shifts for the selected date range
        if let start = startDate, let end = endDate {
                do {
                    let shifts = try await services.calendarService.loadShifts(from: start, to: end)
                    await dispatch(.schedule(.shiftsLoaded(.success(shifts))))
                } catch {
        // logger.error("Failed to load shifts for date range: \(error.localizedDescription)")
                    await dispatch(.schedule(.shiftsLoaded(.failure(error))))
                }
        } else {
            // If date range is cleared, load current month
            await dispatch(.schedule(.loadShifts))
        }

    case .filterLocationChanged(let location):
        // logger.debug("Location filter changed to: \(location?.name ?? "None")")
        // No middleware side effects - filtering handled in state

    break
    case .filterShiftTypeChanged(let shiftType):
        // logger.debug("Shift type filter changed to: \(shiftType?.title ?? "None")")
        // No middleware side effects - filtering handled in state

    break
    case .clearFilters:
        // logger.debug("Filters cleared - reloading all shifts")
        await dispatch(.schedule(.loadShifts))

    case .authorizationChecked, .shiftDeleted, .shiftSwitched, .shiftsLoaded, .stacksRestored, .undoCompleted, .redoCompleted:
        // These actions are handled by the reducer only
    break
    }
}
