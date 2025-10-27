import Foundation
import OSLog

private let logger = Logger(subsystem: "com.shiftscheduler.redux", category: "TodayMiddleware")

/// Middleware for Today feature side effects
/// Handles shift loading, caching, and shift switching for today view
func todayMiddleware(
    state: AppState,
    action: AppAction,
    services: ServiceContainer,
    dispatch: Dispatcher<AppAction>,
) async {
    guard case .today(let todayAction) = action else { return }

    switch todayAction {
    case .task:
        // logger.debug("Today task started")
        // Load shifts for today and tomorrow from EventKit
        await loadTodayAndTomorrowShifts(services: services, dispatch: dispatch)

    case .loadShifts:
        // logger.debug("Loading shifts for Today view")
        await loadTodayAndTomorrowShifts(services: services, dispatch: dispatch)

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

                // logger.debug("Shift \(shift.eventIdentifier) switched to \(newShiftType.title). Entry \(entry.id) saved.")
                await dispatch(.today(.shiftSwitched(.success(()))))

                // Reload shifts after switch to refresh from calendar
                await dispatch(.today(.loadShifts))
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
    }
}

// MARK: - Private Helper Functions

/// Load shifts for today and tomorrow from EventKit
/// Implements the data transformation pipeline:
/// EventKit events → ScheduledShiftData (reification) → ScheduledShift (domain object)
private func loadTodayAndTomorrowShifts(
    services: ServiceContainer,
    dispatch: Dispatcher<AppAction>
) async {
    do {
        // Step 1: Load raw shift data from EventKit for today and tomorrow
        let todayShiftData = try await services.calendarService.loadShiftDataForToday()
        let tomorrowShiftData = try await services.calendarService.loadShiftDataForTomorrow()

        // Combine today and tomorrow data
        let allShiftData = todayShiftData + tomorrowShiftData

        // Step 2: Load ShiftTypes to look up during conversion
        let shiftTypes = try await services.persistenceService.loadShiftTypes()

        // Step 3: Transform ScheduledShiftData → ScheduledShift using ShiftType lookup
        let shifts = allShiftData.compactMap { shiftData -> ScheduledShift? in
            // Find matching ShiftType by ID
            let matchingShiftType = shiftTypes.first { $0.id == shiftData.shiftTypeId }

            // Create ScheduledShift from data and ShiftType
            return ScheduledShift(from: shiftData, shiftType: matchingShiftType)
        }

        // logger.debug("Loaded \(shifts.count) shifts for today and tomorrow")
        await dispatch(.today(.shiftsLoaded(.success(shifts))))

        // Update cached shifts after loading
        await dispatch(.today(.updateCachedShifts))
        await dispatch(.today(.updateUndoRedoStates))
    } catch {
        // logger.error("Failed to load today/tomorrow shifts: \(error.localizedDescription)")
        await dispatch(.today(.shiftsLoaded(.failure(error))))
    }
}
