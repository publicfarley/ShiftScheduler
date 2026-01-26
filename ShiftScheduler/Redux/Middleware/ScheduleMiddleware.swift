import Foundation
import OSLog

private let logger = Logger(subsystem: "com.shiftscheduler.redux", category: "ScheduleMiddleware")

/// Middleware for Schedule feature side effects
/// Handles calendar operations, shift loading, and shift switching
/// Also handles significant time changes (midnight crossing) to refresh the schedule
func scheduleMiddleware(
    state: AppState,
    action: AppAction,
    services: ServiceContainer,
    dispatch: @escaping Dispatcher<AppAction>
) async {
    // Handle significant time changes to refresh Schedule view
    if case .appLifecycle(.significantTimeChange) = action {
        logger.debug("Significant time change detected - refreshing Schedule view")
        await dispatch(.schedule(.loadShifts))
        return
    }

    guard case .schedule(let scheduleAction) = action else { return }

    switch scheduleAction {
    case .initializeAndLoadScheduleData:
        logger.debug("Schedule task started")
        // Restore undo/redo stacks first
        await dispatch(.schedule(.restoreUndoRedoStacks))

        // Check authorization
        do {
            let authorized = try await services.calendarService.requestCalendarAccess()
            logger.debug("Calendar access checked: \(authorized)")
            await dispatch(.schedule(.authorizationChecked(authorized)))
        } catch {
            logger.error("Failed to check authorization: \(error.localizedDescription)")
            await dispatch(.schedule(.authorizationChecked(false)))
        }

        // Load shifts around the currently displayed month (which defaults to today's month)
        logger.debug("Dispatching loadShiftsAroundMonth for initial load")
        await dispatch(.schedule(.loadShiftsAroundMonth(state.schedule.displayedMonth, monthOffset: 6)))

    case .checkAuthorization:
        do {
            let authorized = try await services.calendarService.isCalendarAuthorized()
            await dispatch(.schedule(.authorizationChecked(authorized)))
        } catch {
            // logger.error("Failed to check authorization: \(error.localizedDescription)")
            await dispatch(.schedule(.authorizationChecked(false)))
        }

    case .loadShifts:
        logger.debug("Loading shifts for extended range (±6 months)")
        do {
            let shifts = try await services.calendarService.loadShiftsForExtendedRange()
            logger.debug("Successfully loaded \(shifts.count) shifts")

            // Check for overlapping shifts using date-time range intersection
            // This properly handles multi-day shifts (e.g., overnight shifts)
            var foundOverlap = false
            for i in 0..<shifts.count {
                guard !foundOverlap else { break }
                for j in (i+1)..<shifts.count {
                    if shifts[i].overlaps(with: shifts[j]) {
                        let overlappingShifts = [shifts[i], shifts[j]]
                        logger.warning("Found overlapping shifts: \(shifts[i].shiftType?.title ?? "Unknown") and \(shifts[j].shiftType?.title ?? "Unknown")")
                        // Dispatch overlap detection - user must resolve
                        // Use the earlier date for display purposes
                        let earlierDate = min(shifts[i].date, shifts[j].date)
                        await dispatch(.schedule(.overlappingShiftsDetected(date: earlierDate, shifts: overlappingShifts)))
                        foundOverlap = true
                        break
                    }
                }
            }

            await dispatch(.schedule(.shiftsLoaded(.success(shifts))))
        } catch {
            logger.error("Failed to load shifts: \(error.localizedDescription)")
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

    case .addShift(let date, let shiftType, let notes):
        // Create shift event in calendar via CalendarService
        do {
            let notesForEvent = notes.isEmpty ? nil : notes
            let createdShift = try await services.calendarService.createShiftEvent(
                date: date,
                shiftType: shiftType,
                notes: notesForEvent
            )
            logger.debug("Shift created successfully: \(shiftType.title) on \(date.formatted())")

            // Reload shifts to check for overlaps using date-time range intersection
            let shifts = try await services.calendarService.loadShiftsForExtendedRange()

            // Check if newly created shift overlaps with any existing shift
            // This properly handles multi-day shifts (e.g., overnight shifts)
            let conflictingShifts = shifts.filter { existingShift in
                existingShift.eventIdentifier != createdShift.eventIdentifier &&
                existingShift.overlaps(with: createdShift)
            }

            if !conflictingShifts.isEmpty {
                // Overlap detected! Rollback by deleting the shift we just created
                logger.warning("Overlap detected after creating shift - rolling back")
                try await services.calendarService.deleteShiftEvent(eventIdentifier: createdShift.eventIdentifier)

                // Create error with existing shift names
                let existingShiftNames = conflictingShifts.compactMap { $0.shiftType?.title }

                let error = ScheduleError.overlappingShifts(date: date, existingShifts: existingShiftNames)
                await dispatch(.schedule(.addShiftResponse(.failure(error))))
                return
            }

            // No overlap - success!
            await dispatch(.schedule(.addShiftResponse(.success(createdShift))))

            // Reload shifts to refresh the UI (around the displayed month)
            await dispatch(.schedule(.loadShiftsAroundMonth(state.schedule.displayedMonth, monthOffset: 6)))
        } catch let error as ScheduleError {
            logger.error("Failed to create shift: \(error.localizedDescription)")
            await dispatch(.schedule(.addShiftResponse(.failure(error))))
        } catch {
            logger.error("Failed to create shift: \(error.localizedDescription)")
            let scheduleError = ScheduleError.calendarEventCreationFailed(error.localizedDescription)
            await dispatch(.schedule(.addShiftResponse(.failure(scheduleError))))
        }

    case .addShiftResponse:
        // Handled by reducer
        break

    case .addShiftSheetDismissed:
        // No middleware side effects needed
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
        logger.debug("Deleting shift: \(shift.eventIdentifier)")
        do {
            // Create snapshot of the shift being deleted
            let oldSnapshot = shift.shiftType.map { ShiftSnapshot(from: $0) }

            // Create change log entry for deletion
            let entry = ChangeLogEntry(
                id: UUID(),
                timestamp: Date(),
                userId: state.userProfile.userId,
                userDisplayName: state.userProfile.displayName,
                changeType: .deleted,
                scheduledShiftDate: shift.date,
                oldShiftSnapshot: oldSnapshot,
                newShiftSnapshot: nil, // No new shift for deletion
                reason: nil
            )

            // Persist the change log entry
            try await services.persistenceService.addChangeLogEntry(entry)

            // Delete the event from calendar
            try await services.calendarService.deleteShiftEvent(eventIdentifier: shift.eventIdentifier)

            // Save updated undo/redo stacks
            var undoStack = state.schedule.undoStack
            undoStack.append(entry)
            try await services.persistenceService.saveUndoRedoStacks(
                undo: undoStack,
                redo: [] // Clear redo stack on new operation
            )

            logger.debug("Shift deleted successfully")
            await dispatch(.schedule(.shiftDeleted(.success(()))))

            // Reload shifts after deletion to refresh from calendar
            await dispatch(.schedule(.loadShiftsAroundMonth(state.schedule.displayedMonth, monthOffset: 6)))
        } catch {
            logger.error("Failed to delete shift: \(error.localizedDescription)")
            let scheduleError = ScheduleError.calendarEventDeletionFailed(error.localizedDescription)
            await dispatch(.schedule(.shiftDeleted(.failure(scheduleError))))
        }

    case .shiftDeleted:
        // Handled by reducer
        break

    // MARK: - Overlap Resolution

    case .overlappingShiftsDetected:
        // Handled by reducer (shows dialog)
        break

    case .resolveOverlap(let keepShift, let deleteShifts):
        logger.debug("Resolving overlap: keeping \(keepShift.eventIdentifier), deleting \(deleteShifts.count) shifts")
        do {
            // Delete each overlapping shift except the one to keep
            for shift in deleteShifts {
                // Create snapshot of the shift being deleted
                let oldSnapshot = shift.shiftType.map { ShiftSnapshot(from: $0) }

                // Create change log entry for deletion
                let entry = ChangeLogEntry(
                    id: UUID(),
                    timestamp: Date(),
                    userId: state.userProfile.userId,
                    userDisplayName: state.userProfile.displayName,
                    changeType: .deleted,
                    scheduledShiftDate: shift.date,
                    oldShiftSnapshot: oldSnapshot,
                    newShiftSnapshot: nil,
                    reason: "Removed to resolve overlapping shifts"
                )

                // Persist the change log entry
                try await services.persistenceService.addChangeLogEntry(entry)

                // Delete the event from calendar
                try await services.calendarService.deleteShiftEvent(eventIdentifier: shift.eventIdentifier)
            }

            logger.debug("Overlap resolved successfully")
            await dispatch(.schedule(.overlapResolved(.success(()))))

            // Reload shifts after resolution
            await dispatch(.schedule(.loadShiftsAroundMonth(state.schedule.displayedMonth, monthOffset: 6)))
        } catch {
            logger.error("Failed to resolve overlap: \(error.localizedDescription)")
            let scheduleError = ScheduleError.calendarEventDeletionFailed(error.localizedDescription)
            await dispatch(.schedule(.overlapResolved(.failure(scheduleError))))
        }

    case .overlapResolved:
        // Handled by reducer
        break

    case .overlapResolutionDismissed:
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

            // Update the calendar event with the new shift type
            try await services.calendarService.updateShiftEvent(
                eventIdentifier: shift.eventIdentifier,
                newShiftType: newShiftType,
                date: shift.date
            )

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
            await dispatch(.schedule(.loadShiftsAroundMonth(state.schedule.displayedMonth, monthOffset: 6)))

            // Reload change log to show the new entry
            await dispatch(.changeLog(.loadChangeLogEntries))
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
            await dispatch(.schedule(.loadShiftsAroundMonth(state.schedule.displayedMonth, monthOffset: 6)))
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
            await dispatch(.schedule(.loadShiftsAroundMonth(state.schedule.displayedMonth, monthOffset: 6)))
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
        // Reload all shifts around the currently displayed month
        await dispatch(.schedule(.loadShiftsAroundMonth(state.schedule.displayedMonth, monthOffset: 6)))

    case .authorizationChecked:
        // Handled by reducer
        break

    // MARK: - Sliding Window Actions

    case .displayedMonthChanged(let newMonth):
        // Fault detection: Check if we've hit the edge of our loaded range
        guard let rangeStart = state.schedule.loadedRangeStart,
              let rangeEnd = state.schedule.loadedRangeEnd else {
            // No range loaded yet, this must be initial navigation
            logger.debug("No loaded range yet, skipping fault detection")
            break
        }

        // Get the first and last month of loaded range
        let firstLoadedMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: rangeStart)) ?? rangeStart
        let lastLoadedMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: rangeEnd)) ?? rangeEnd
        let displayedMonthStart = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: newMonth)) ?? newMonth

        // Fault triggered if we're viewing the first or last month of loaded range
        if displayedMonthStart <= firstLoadedMonth || displayedMonthStart >= lastLoadedMonth {
            logger.debug("Range fault detected - user navigated to edge month: \(newMonth.formatted(.dateTime.year().month()))")
            logger.debug("Current range: \(rangeStart.formatted()) to \(rangeEnd.formatted())")
            logger.debug("Loading ±6 months around \(newMonth.formatted(.dateTime.year().month()))")
            await dispatch(.schedule(.loadShiftsAroundMonth(newMonth, monthOffset: 6)))
        }

    case .loadShiftsAroundMonth(let pivotMonth, let monthOffset):
        logger.debug("Loading shifts around month: \(pivotMonth.formatted(.dateTime.year().month())) (±\(monthOffset) months)")
        do {
            let result = try await services.calendarService.loadShiftsAroundMonth(pivotMonth, monthOffset: monthOffset)
            logger.debug("Successfully loaded \(result.shifts.count) shifts")
            logger.debug("New range: \(result.rangeStart.formatted()) to \(result.rangeEnd.formatted())")

            // Check for overlapping shifts using shared helper
            // This properly handles multi-day shifts (e.g., overnight shifts)
            if let (shift1, shift2) = ScheduledShift.findOverlappingPair(in: result.shifts) {
                let overlappingShifts = [shift1, shift2]
                logger.warning("Found overlapping shifts: \(shift1.shiftType?.title ?? "Unknown") and \(shift2.shiftType?.title ?? "Unknown")")
                // Dispatch overlap detection - user must resolve
                // Use the earlier date for display purposes
                let earlierDate = min(shift1.date, shift2.date)
                await dispatch(.schedule(.overlappingShiftsDetected(date: earlierDate, shifts: overlappingShifts)))
            }

            await dispatch(.schedule(.shiftsLoadedAroundMonth(.success((shifts: result.shifts, rangeStart: result.rangeStart, rangeEnd: result.rangeEnd)))))
        } catch {
            logger.error("Failed to load shifts around month: \(error.localizedDescription)")
            await dispatch(.schedule(.shiftsLoadedAroundMonth(.failure(error))))
        }

    case .shiftsLoadedAroundMonth:
        // Handled by reducer
        break

    case .jumpToToday:
        // No middleware side effects needed - reducer handles state update
        // Animation is handled by SwiftUI's onChange in ScrollableMonthView
        break

    case .scrollCompleted:
        // No middleware side effects needed - reducer handles state update
        break

    // MARK: - Multi-Select Actions

    case .enterSelectionMode:
        // No middleware side effects needed - reducer handles state update
        break

    case .exitSelectionMode:
        // No middleware side effects needed - reducer handles state update
        break

    case .toggleShiftSelection:
        // No middleware side effects needed - reducer handles state update
        break

    case .selectAllVisible:
        // No middleware side effects needed - reducer handles state update
        break

    case .clearSelection:
        // No middleware side effects needed - reducer handles state update
        break

    case .bulkDeleteRequested:
        // No middleware side effects needed - reducer handles state update
        break

    case .bulkDeleteConfirmed(let shiftIds):
        logger.debug("Bulk delete confirmed for \(shiftIds.count) shifts")
        do {
            // Get the shifts to delete from the state
            let shiftsToDelete = state.schedule.scheduledShifts.filter { shift in
                shiftIds.contains(shift.id)
            }

            guard !shiftsToDelete.isEmpty else {
                logger.warning("No shifts found for bulk delete")
                await dispatch(.schedule(.bulkDeleteCompleted(.success(0))))
                return
            }

            logger.debug("Found \(shiftsToDelete.count) shifts to delete")

            // Create change log entries for each deleted shift
            var changeLogEntries: [ChangeLogEntry] = []
            for shift in shiftsToDelete {
                let oldSnapshot = shift.shiftType.map { ShiftSnapshot(from: $0) }

                let entry = ChangeLogEntry(
                    id: UUID(),
                    timestamp: Date(),
                    userId: state.userProfile.userId,
                    userDisplayName: state.userProfile.displayName,
                    changeType: .deleted,
                    scheduledShiftDate: shift.date,
                    oldShiftSnapshot: oldSnapshot,
                    newShiftSnapshot: nil, // No new shift for deletion
                    reason: "Bulk deleted"
                )
                changeLogEntries.append(entry)
            }

            // Persist all change log entries
            try await services.persistenceService.addMultipleChangeLogEntries(changeLogEntries)
            logger.debug("Persisted \(changeLogEntries.count) change log entries")

            // Delete all shifts from calendar
            let eventIdentifiers = shiftsToDelete.compactMap { $0.eventIdentifier }
            let deletedCount = try await services.calendarService.deleteMultipleShiftEvents(eventIdentifiers)
            logger.debug("Deleted \(deletedCount) shifts from calendar")

            // Update undo/redo stacks
            var undoStack = state.schedule.undoStack
            undoStack.append(contentsOf: changeLogEntries)
            try await services.persistenceService.saveUndoRedoStacks(
                undo: undoStack,
                redo: [] // Clear redo stack on new operation
            )

            logger.debug("Bulk delete completed successfully: \(deletedCount) shifts")
            await dispatch(.schedule(.bulkDeleteCompleted(.success(deletedCount))))

            // Reload shifts after deletion to refresh from calendar
            await dispatch(.schedule(.loadShiftsAroundMonth(state.schedule.displayedMonth, monthOffset: 6)))

            // Reload change log to show new entries
            await dispatch(.changeLog(.loadChangeLogEntries))

        } catch {
            logger.error("Failed to bulk delete shifts: \(error.localizedDescription)")
            let scheduleError = ScheduleError.calendarEventDeletionFailed(error.localizedDescription)
            await dispatch(.schedule(.bulkDeleteCompleted(.failure(scheduleError))))
        }

    case .bulkDeleteCompleted:
        // No middleware side effects needed - reducer handles state update
        break

    // MARK: - Bulk Add Actions

    case .bulkAddRequested:
        // No middleware side effects needed - reducer shows shift type selection sheet
        break

    case let .bulkAddConfirmed(shiftType, notes):
        // Create shifts for all selected dates
        let selectedDates = state.schedule.selectedDates
        let userId = state.userProfile.userId
        let userDisplayName = state.userProfile.displayName

        do {
            var createdShifts: [ScheduledShift] = []
            let calendarService = services.calendarService
            let persistenceService = services.persistenceService

            // Loop through selected dates and create shifts
            for date in selectedDates.sorted() {
                // Create shift event in calendar (returns shift with EventKit identifier)
                let shift = try await calendarService.createShiftEvent(
                    date: date,
                    shiftType: shiftType,
                    notes: notes.isEmpty ? nil : notes
                )
                createdShifts.append(shift)

                // Create audit trail entry for shift creation
                let entry = ChangeLogEntry(
                    id: UUID(),
                    timestamp: Date(),
                    userId: userId,
                    userDisplayName: userDisplayName,
                    changeType: .created,
                    scheduledShiftDate: date,
                    oldShiftSnapshot: nil,
                    newShiftSnapshot: ShiftSnapshot(from: shiftType),
                    reason: notes.isEmpty ? nil : notes
                )

                // Persist change log entry
                try await persistenceService.addChangeLogEntry(entry)
            }

            // Dispatch completion with created shifts
            await dispatch(.schedule(.bulkAddCompleted(.success(createdShifts))))
        } catch {
            let scheduleError = ScheduleError.calendarEventCreationFailed(error.localizedDescription)
            await dispatch(.schedule(.bulkAddCompleted(.failure(scheduleError))))
        }

    case .bulkAddCompleted:
        // Reload shifts to refresh calendar view after bulk add completes
        await dispatch(.schedule(.loadShifts))

    case .toggleDateSelection:
        // No middleware side effects needed - reducer handles state update
        break

    case .clearSelectedDates:
        // No middleware side effects needed - reducer handles state update
        break

    // MARK: - Bulk Add Mode Actions

    case .bulkAddModeChanged:
        // No middleware side effects needed - reducer handles state update
        break

    case .assignShiftToDate:
        // No middleware side effects needed - reducer handles state update
        break

    case .removeShiftAssignment:
        // No middleware side effects needed - reducer handles state update
        break

    case .bulkAddDifferentShiftsConfirmed(let assignments, let notes):
        logger.debug("Bulk add different shifts confirmed with \(assignments.count) assignments")

        let userId = state.userProfile.userId
        let userDisplayName = state.userProfile.displayName

        do {
            // MARK: - Pre-Validation Phase
            // Check all assignments for conflicts BEFORE creating ANY shifts
            var conflicts: [Date: ScheduledShift] = [:]

            for (date, _) in assignments {
                // Check if any existing shift on this date overlaps with the new shift
                if let existingShift = state.schedule.scheduledShifts.first(where: { existingShift in
                    existingShift.occursOn(date: date)
                }) {
                    conflicts[date] = existingShift
                }
            }

            // If conflicts found, fail early without creating any shifts (all-or-nothing)
            if !conflicts.isEmpty {
                logger.warning("Found \(conflicts.count) conflicting shifts during validation")
                let error = ScheduleError.unknown("Cannot add shifts. \(conflicts.count) dates already have shifts scheduled.")
                await dispatch(.schedule(.bulkAddCompleted(.failure(error))))
                return
            }

            // MARK: - Bulk Create Phase
            // Validation passed, create all shifts
            var createdShifts: [ScheduledShift] = []
            let calendarService = services.calendarService
            let persistenceService = services.persistenceService

            // Sort by date for consistent ordering
            let sortedAssignments = assignments.sorted { $0.key < $1.key }

            for (date, shiftType) in sortedAssignments {
                do {
                    // Create shift event in calendar (returns shift with EventKit identifier)
                    let shift = try await calendarService.createShiftEvent(
                        date: date,
                        shiftType: shiftType,
                        notes: notes?.isEmpty ?? true ? nil : notes
                    )
                    createdShifts.append(shift)
                    logger.debug("Created shift: \(shiftType.title) on \(date)")

                    // Create audit trail entry for shift creation
                    let entry = ChangeLogEntry(
                        id: UUID(),
                        timestamp: Date(),
                        userId: userId,
                        userDisplayName: userDisplayName,
                        changeType: .created,
                        scheduledShiftDate: date,
                        oldShiftSnapshot: nil,
                        newShiftSnapshot: ShiftSnapshot(from: shiftType),
                        reason: notes?.isEmpty ?? true ? nil : notes
                    )

                    // Persist change log entry
                    try await persistenceService.addChangeLogEntry(entry)
                } catch {
                    // MARK: - Rollback on Error
                    // If any shift creation fails, we've already created some shifts
                    // Log this state but don't try to rollback (calendar events are already created)
                    logger.error("Failed to create shift on \(date): \(error.localizedDescription)")

                    // Dispatch error indicating partial failure
                    let failureError = ScheduleError.calendarEventCreationFailed(
                        "Failed to add shift on \(date). \(createdShifts.count) shifts were created before this error."
                    )
                    await dispatch(.schedule(.bulkAddCompleted(.failure(failureError))))
                    return
                }
            }

            // MARK: - Success Phase
            logger.debug("Successfully created \(createdShifts.count) shifts")

            // Dispatch completion with all created shifts
            await dispatch(.schedule(.bulkAddCompleted(.success(createdShifts))))
        }
        // Note: We don't catch here because the do block handles all errors internally

    case .switchModeWarningConfirmed:
        // No middleware side effects needed - reducer handles state update
        break
    }
}
