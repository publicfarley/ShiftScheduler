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
        // Restore undo/redo stacks first
        await dispatch(.schedule(.restoreUndoRedoStacks))

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
        // logger.debug("Loading shifts for current month")
        do {
            let shifts = try await services.calendarService.loadShiftsForCurrentMonth()
            await dispatch(.schedule(.shiftsLoaded(.success(shifts))))
        } catch {
            // logger.error("Failed to load shifts: \(error.localizedDescription)")
            await dispatch(.schedule(.shiftsLoaded(.failure(error))))
        }

    case .selectedDateChanged:
        // No middleware side effects needed
        break

    case .searchTextChanged:
        // No middleware side effects needed
        break

    // MARK: - Detail View

    case .shiftTapped:
        // No middleware side effects needed
        break

    case .shiftDetailDismissed:
        // No middleware side effects needed
        break

    // MARK: - Add Shift

    case .addShiftSheetToggled:
        // No middleware side effects needed
        break

    case .addShiftButtonTapped:
        // No middleware side effects needed
        break

    case .addShift(let date, let shiftType, let location, let startTime, let notes):
        // TODO: Implement add shift via calendar service
        // For now, dispatch success
        let newShift = ScheduledShift(
            id: UUID(),
            eventIdentifier: UUID().uuidString,
            shiftType: shiftType,
            date: date
        )
        await dispatch(.schedule(.addShiftResponse(.success(newShift))))

    case .addShiftResponse:
        // Handled by reducer
        break

    // MARK: - Delete Shift

    case .deleteShiftRequested:
        // No middleware side effects needed
        break

    case .deleteShiftConfirmed:
        // Middleware will handle actual deletion via .deleteShift action
        // triggered by the reducer
        break

    case .deleteShiftCancelled:
        // No middleware side effects needed
        break

    case .deleteShift(let shift):
        // logger.debug("Deleting shift: \(shift.eventIdentifier)")
        // TODO: Implement shift deletion via calendar service
        // For now, just complete the action
        await dispatch(.schedule(.shiftDeleted(.success(()))))

    case .shiftDeleted:
        // Handled by reducer
        break

    // MARK: - Switch Shift

    case .switchShiftSheetToggled:
        // No middleware side effects needed
        break

    case .switchShiftTapped:
        // No middleware side effects needed
        break

    case .performSwitchShift(let shift, let newShiftType, let reason):
        // logger.debug("Performing shift switch")
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

            // logger.debug("Shift switched successfully")
            await dispatch(.schedule(.shiftSwitched(.success(entry))))

            // Reload shifts after switch to refresh from calendar
            await dispatch(.schedule(.loadShifts))
        } catch {
            // logger.error("Failed to switch shift: \(error.localizedDescription)")
            let scheduleError = ScheduleError.shiftSwitchFailed(error.localizedDescription)
            await dispatch(.schedule(.shiftSwitched(.failure(scheduleError))))
        }

    case .shiftSwitched:
        // Handled by reducer
        break

    // MARK: - Load Shifts

    case .shiftsLoaded:
        // Handled by reducer
        break

    // MARK: - Stack Restoration

    case .restoreUndoRedoStacks:
        // logger.debug("Restoring undo/redo stacks from persistence")
        do {
            let undoStack = try await services.persistenceService.loadUndoRedoStacks().0
            let redoStack = try await services.persistenceService.loadUndoRedoStacks().1
            await dispatch(.schedule(.stacksRestored(.success((undo: undoStack, redo: redoStack)))))
        } catch {
            // logger.error("Failed to restore stacks: \(error.localizedDescription)")
            let scheduleError = ScheduleError.stackRestorationFailed(error.localizedDescription)
            await dispatch(.schedule(.undoRedoStackRestoreFailed(scheduleError)))
        }

    case .stacksRestored:
        // Handled by reducer
        break

    case .undoRedoStackRestoreFailed:
        // Handled by reducer
        break

    // MARK: - Undo/Redo

    case .undo:
        // logger.debug("Undo requested")
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
            }

            // Reload shifts to refresh UI
            await dispatch(.schedule(.loadShifts))
            await dispatch(.schedule(.redoCompleted(.success(()))))
        } catch {
            // logger.error("Failed to redo: \(error.localizedDescription)")
            await dispatch(.schedule(.redoCompleted(.failure(error))))
        }

    case .undoCompleted, .redoCompleted:
        // Handled by reducer
        break

    // MARK: - Feedback

    case .dismissError, .dismissSuccessToast:
        // No middleware side effects needed
        break

    // MARK: - Filter Actions

    case .filterSheetToggled:
        // No middleware side effects needed
        break

    case .filterDateRangeChanged(let startDate, let endDate):
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

    case .filterLocationChanged:
        // No middleware side effects - filtering handled in state
        break

    case .filterShiftTypeChanged:
        // No middleware side effects - filtering handled in state
        break

    case .clearFilters:
        // Reload all shifts
        await dispatch(.schedule(.loadShifts))

    case .authorizationChecked:
        // Handled by reducer
        break
    }
}
