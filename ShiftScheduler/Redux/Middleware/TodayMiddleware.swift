import Foundation
import OSLog

private let logger = Logger(subsystem: "com.shiftscheduler.redux", category: "TodayMiddleware")

/// Middleware for Today feature side effects
/// Handles shift loading, caching, and shift switching for today view
/// Also handles significant time changes (midnight crossing) to refresh the current day
func todayMiddleware(
    state: AppState,
    action: AppAction,
    services: ServiceContainer,
    dispatch: Dispatcher<AppAction>,
) async {
    // Handle significant time changes to refresh Today view
    if case .appLifecycle(.significantTimeChange) = action {
        logger.debug("Significant time change detected - refreshing Today view")
        await dispatch(.today(.loadShifts))
        return
    }

    guard case .today(let todayAction) = action else { return }

    switch todayAction {
    case .loadShifts:
        // logger.debug("Loading shifts for Today view")
        await loadNext7DaysShifts(services: services, dispatch: dispatch)

    case .switchShiftTapped:
        // logger.debug("Switch shift tapped")
        // No middleware side effects - UI will handle sheet presentation
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

                // Update the calendar event with the new shift type
                try await services.calendarService.updateShiftEvent(
                    eventIdentifier: shift.eventIdentifier,
                    newShiftType: newShiftType,
                    date: shift.date
                )

                // logger.debug("Shift \(shift.eventIdentifier) switched to \(newShiftType.title). Entry \(entry.id) saved.")
                await dispatch(.today(.shiftSwitched(.success(()))))

                // Reload shifts after switch to refresh from calendar
                await dispatch(.today(.loadShifts))

                // Reload change log to show the new entry
                await dispatch(.changeLog(.loadChangeLogEntries))
            } catch {
        // logger.error("Failed to switch shift: \(error.localizedDescription)")
                await dispatch(.today(.shiftSwitched(.failure(error))))
            }

    case .toastMessageCleared:
        // logger.debug("Toast message cleared")
        // No middleware side effects
        break

    case .switchShiftSheetDismissed:
        // logger.debug("Switch shift sheet dismissed")
        // No middleware side effects
        break

    case .updateCachedShifts:
        // logger.debug("Updating cached shifts")
        // No middleware side effects - reducer handles this
        break

    case .updateUndoRedoStates:
        // logger.debug("Updating undo/redo states")
        // No middleware side effects - reducer handles this
        break

    case .shiftsLoaded, .shiftSwitched:
        // logger.debug("No middleware side effects for action: \(String(describing: todayAction))")
        break
        // Handled by reducer only

    // MARK: - Quick Actions

    case .editNotesSheetToggled(let show):
        guard !show else { break }  // Only process when sheet is closing
        logger.debug("Edit notes sheet dismissed - persisting notes changes")

        guard let todayShift = state.today.todayShift else { break }
        let updatedNotes = state.today.quickActionsNotes

        do {
            // Update the shift's notes in the calendar event
            try await services.calendarService.updateShiftNotes(
                eventIdentifier: todayShift.eventIdentifier,
                notes: updatedNotes
            )

            logger.debug("Notes updated for shift \(todayShift.eventIdentifier): \(updatedNotes)")

            // Reload shifts to get the updated notes from calendar
            await dispatch(.today(.loadShifts))
        } catch {
            logger.error("Failed to update shift notes: \(error.localizedDescription)")
        }
        break

    case .quickActionsNotesChanged:
        // logger.debug("Notes changed in quick actions editor")
        // Notes will be persisted when sheet is dismissed
        break

    case .deleteShiftRequested:
        // logger.debug("Delete shift requested")
        // No middleware side effects - reducer handles confirmation state
        break

    case .deleteShiftConfirmed:
        guard let shiftToDelete = state.today.deleteShiftConfirmationShift else { break }
        // logger.debug("Delete shift confirmed for \(shiftToDelete.id)")
        do {
            // Create change log entry for deletion
            let deletionSnapshot = shiftToDelete.shiftType.map { ShiftSnapshot(from: $0) }
            let entry = ChangeLogEntry(
                id: UUID(),
                timestamp: Date(),
                userId: state.userProfile.userId,
                userDisplayName: state.userProfile.displayName,
                changeType: .deleted,
                scheduledShiftDate: shiftToDelete.date,
                oldShiftSnapshot: deletionSnapshot,
                newShiftSnapshot: nil,
                reason: nil
            )

            // Persist the change log entry
            try await services.persistenceService.addChangeLogEntry(entry)

            // Delete the shift from calendar
            try await services.calendarService.deleteShiftEvent(eventIdentifier: shiftToDelete.eventIdentifier)

            // logger.debug("Shift \(shiftToDelete.eventIdentifier) deleted. Entry \(entry.id) saved.")
            await dispatch(.today(.shiftDeleted(.success(()))))

            // Reload shifts to refresh from calendar
            await dispatch(.today(.loadShifts))
        } catch {
            // logger.error("Failed to delete shift: \(error.localizedDescription)")
            await dispatch(.today(.shiftDeleted(.failure(error))))
        }

    case .deleteShiftCancelled:
        // logger.debug("Delete shift cancelled")
        // No middleware side effects - reducer handles cancellation
        break

    case .shiftDeleted:
        // logger.debug("Shift deletion completed")
        // No additional middleware side effects - reducer and middleware dispatch handle it
        break

    // MARK: - Add Shift

    case .addShiftButtonTapped:
        // logger.debug("Add shift button tapped")
        // No middleware side effects - reducer handles sheet presentation
        break

    case .addShiftSheetToggled:
        // logger.debug("Add shift sheet toggled")
        // No middleware side effects - reducer handles sheet state
        break

    case .addShiftSheetDismissed:
        // logger.debug("Add shift sheet dismissed")
        // No middleware side effects - reducer handles cleanup
        break

    case .addShift(let date, let shiftType, let notes):
        // logger.debug("Adding shift from Today view: \(shiftType.title) on \(date.formatted())")
        do {
            let notesForEvent = notes.isEmpty ? nil : notes
            let createdShift = try await services.calendarService.createShiftEvent(
                date: date,
                shiftType: shiftType,
                notes: notesForEvent
            )
            logger.debug("Shift created successfully from Today: \(shiftType.title) on \(date.formatted())")

            // Reload shifts to check for overlaps using proper date-time range intersection
            let shifts = try await services.calendarService.loadShiftsForExtendedRange()

            // Check for overlapping shifts using shared helper (handles multi-day shifts and all-day special case)
            let otherShifts = shifts.filter { $0.eventIdentifier != createdShift.eventIdentifier }
            if let overlappingShift = createdShift.findOverlap(in: otherShifts) {
                // Overlap detected! Rollback by deleting the shift we just created
                logger.warning("Overlap detected after creating shift from Today - rolling back")
                logger.warning("  Created: \(createdShift.shiftType?.title ?? "Unknown") on \(createdShift.date.formatted())")
                logger.warning("  Conflicts with: \(overlappingShift.shiftType?.title ?? "Unknown") on \(overlappingShift.date.formatted())")
                try await services.calendarService.deleteShiftEvent(eventIdentifier: createdShift.eventIdentifier)

                // Create error with existing shift names
                let existingShiftNames = [overlappingShift.shiftType?.title].compactMap { $0 }

                let error = ScheduleError.overlappingShifts(date: date, existingShifts: existingShiftNames)
                await dispatch(.today(.addShiftResponse(.failure(error))))
                return
            }

            // No overlap - success!
            await dispatch(.today(.addShiftResponse(.success(createdShift))))

            // Reload today's shifts to refresh the UI
            await dispatch(.today(.loadShifts))
        } catch let error as ScheduleError {
            logger.error("Failed to create shift from Today: \(error.localizedDescription)")
            await dispatch(.today(.addShiftResponse(.failure(error))))
        } catch {
            logger.error("Failed to create shift from Today: \(error.localizedDescription)")
            let scheduleError = ScheduleError.calendarEventCreationFailed(error.localizedDescription)
            await dispatch(.today(.addShiftResponse(.failure(scheduleError))))
        }

    case .addShiftResponse, .dismissError:
        // logger.debug("No middleware side effects for action: \(String(describing: todayAction))")
        // Handled by reducer only
        break
    }
}

// MARK: - Private Helper Functions

/// Load shifts for the next 7 days from today from EventKit
/// This ensures we always include tomorrow, regardless of current day of week
/// Implements the data transformation pipeline:
/// EventKit events → ScheduledShiftData (reification) → ScheduledShift (domain object)
private func loadNext7DaysShifts(
    services: ServiceContainer,
    dispatch: Dispatcher<AppAction>
) async {
    do {
        // Step 1: Calculate the next 7 days range (today through today + 7 days)
        // This avoids week boundary issues where tomorrow falls into the next calendar week
        let today = Date()
        let calendar = Calendar.current

        // Start from today (not week start)
        let startDate = calendar.startOfDay(for: today)

        // End date is 7 days after today
        guard let endDate = calendar.date(byAdding: .day, value: 7, to: startDate) else {
            throw CalendarServiceError.dateCalculationFailed
        }

        // Step 2: Load raw shift data from EventKit for the next 7 days
        let shiftData = try await services.calendarService.loadShiftData(from: startDate, to: endDate)

        // Step 3: Load ShiftTypes to look up during conversion
        let shiftTypes = try await services.persistenceService.loadShiftTypes()

        // Step 4: Transform ScheduledShiftData → ScheduledShift using ShiftType lookup
        let shifts = shiftData.compactMap { shiftDataItem -> ScheduledShift? in
            // Find matching ShiftType by ID
            let matchingShiftType = shiftTypes.first { $0.id == shiftDataItem.shiftTypeId }

            // Create ScheduledShift from data and ShiftType
            return ScheduledShift(from: shiftDataItem, shiftType: matchingShiftType)
        }

        // logger.debug("Loaded \(shifts.count) shifts for next 7 days (\(startDate.formatted()) to \(endDate.formatted()))")
        await dispatch(.today(.shiftsLoaded(.success(shifts))))

        // Update cached shifts after loading
        await dispatch(.today(.updateCachedShifts))
        await dispatch(.today(.updateUndoRedoStates))
    } catch {
        // logger.error("Failed to load next 7 days shifts: \(error.localizedDescription)")
        await dispatch(.today(.shiftsLoaded(.failure(error))))
    }
}
