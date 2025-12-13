import Foundation
import OSLog

private nonisolated let logger = Logger(subsystem: "com.shiftscheduler.redux", category: "Middleware")

/// Logging middleware that logs all dispatched actions and state changes
/// Useful for debugging Redux flow and understanding action sequences
func loggingMiddleware(
    state: AppState,
    action: AppAction,
    services: ServiceContainer,
    dispatch: @escaping Dispatcher<AppAction>
) async {
    logger.debug("[Middleware] Action dispatched: \(condensedActionDescription(for: action))")

    // Log feature-specific state for debugging
    logFeatureState(state: state, action: action)
}

// MARK: - Helper Functions

/// Log relevant feature state based on action type
private func logFeatureState(state: AppState, action: AppAction) {
    switch action {
    case .today:
        logger.debug("[Today] Shifts loaded: \(state.today.scheduledShifts.count)")
        logger.debug("[Today] Loading: \(state.today.isLoading)")
        
        break
        
    case .schedule:
        logger.debug("[Schedule] Authorized: \(state.schedule.isCalendarAuthorized)")
        logger.debug("[Schedule] Selected date: \(state.schedule.selectedDate.formatted(date: .abbreviated, time: .omitted))")
        logger.debug("[Schedule] Shifts: \(state.schedule.scheduledShifts.count)")
        logger.debug("[Schedule] Undo stack: \(state.schedule.undoStack.count)")
        logger.debug("[Schedule] Redo stack: \(state.schedule.redoStack.count)")
        
        break
        
    case .locations:
        logger.debug("[Locations] Total: \(state.locations.locations.count)")
        logger.debug("[Locations] Filtered: \(state.locations.filteredLocations.count)")
        
        break
        
    case .shiftTypes:
        logger.debug("[ShiftTypes] Total: \(state.shiftTypes.shiftTypes.count)")
        logger.debug("[ShiftTypes] Filtered: \(state.shiftTypes.filteredShiftTypes.count)")
        
        break
        
    case .changeLog:
        logger.debug("[ChangeLog] Entries: \(state.changeLog.entries.count)")
        logger.debug("[ChangeLog] Filtered: \(state.changeLog.filteredEntries.count)")
        
        break
        
    case .settings:
        logger.debug("[Settings] Policy: \(state.settings.retentionPolicy.displayName)")
        logger.debug("[Settings] Auto-purge: \(state.settings.autoPurgeEnabled)")

        break

    case .sync:
        logger.debug("[Sync] Status: \(String(describing: state.sync.status))")
        logger.debug("[Sync] Available: \(state.sync.isAvailable)")
        logger.debug("[Sync] Pending conflicts: \(state.sync.pendingConflicts.count)")

        break

    case .appLifecycle:
        logger.debug("[AppLifecycle] Selected tab: \(String(describing: state.selectedTab))")
        logger.debug("[AppLifecycle] User: \(state.userProfile.displayName)")
        break
    }
}

/// Condense action logging to show IDs/counts instead of full data structures
/// Reduces log noise for actions that carry arrays of objects
private func condensedActionDescription(for action: AppAction) -> String {
    switch action {
    // Today feature actions
    case .today(let todayAction):
        switch todayAction {
        case .shiftsLoaded(let result):
            switch result {
            case .success(let shifts):
                return "today(.shiftsLoaded(success: \(shifts.count) shifts))"
            case .failure(let error):
                return "today(.shiftsLoaded(failure: \(type(of: error))))"
            }
        case .switchShiftTapped(let shift):
            return "today(.switchShiftTapped(id: \(shift.id.uuidString.prefix(8))))"
        case .performSwitchShift(let shift, let shiftType, let reason):
            return "today(.performSwitchShift(shiftId: \(shift.id.uuidString.prefix(8)), typeId: \(shiftType.id.uuidString.prefix(8)), reason: \(reason != nil ? "provided" : "none")))"
        default:
            return "today(\(String(describing: todayAction)))"
        }

    // Schedule feature actions
    case .schedule(let scheduleAction):
        switch scheduleAction {
        case .shiftsLoaded(let result):
            switch result {
            case .success(let shifts):
                return "schedule(.shiftsLoaded(success: \(shifts.count) shifts))"
            case .failure(let error):
                return "schedule(.shiftsLoaded(failure: \(type(of: error))))"
            }
        case .shiftsLoadedAroundMonth(let result):
            switch result {
            case .success(let data):
                return "schedule(.shiftsLoadedAroundMonth(success: \(data.shifts.count) shifts))"
            case .failure(let error):
                return "schedule(.shiftsLoadedAroundMonth(failure: \(type(of: error))))"
            }
        case .overlappingShiftsDetected(let date, let shifts):
            return "schedule(.overlappingShiftsDetected(date: \(date.formatted(date: .abbreviated, time: .omitted)), count: \(shifts.count)))"
        case .resolveOverlap(let keepShift, let deleteShifts):
            return "schedule(.resolveOverlap(keep: \(keepShift.id.uuidString.prefix(8)), delete: \(deleteShifts.count)))"
        case .performSwitchShift(let shift, let shiftType, let reason):
            return "schedule(.performSwitchShift(shiftId: \(shift.id.uuidString.prefix(8)), typeId: \(shiftType.id.uuidString.prefix(8)), reason: \(reason != nil ? "provided" : "none")))"
        default:
            return "schedule(\(String(describing: scheduleAction)))"
        }

    // ChangeLog feature actions
    case .changeLog(let changeLogAction):
        switch changeLogAction {
        case .entriesLoaded(let result):
            switch result {
            case .success(let entries):
                return "changeLog(.entriesLoaded(success: \(entries.count) entries))"
            case .failure(let error):
                return "changeLog(.entriesLoaded(failure: \(type(of: error))))"
            }
        default:
            return "changeLog(\(String(describing: changeLogAction)))"
        }

    // Locations feature actions
    case .locations(let locationsAction):
        switch locationsAction {
        case .locationsLoaded(let result):
            switch result {
            case .success(let locations):
                return "locations(.locationsLoaded(success: \(locations.count) locations))"
            case .failure(let error):
                return "locations(.locationsLoaded(failure: \(type(of: error))))"
            }
        case .saveLocation(let location):
            return "locations(.saveLocation(id: \(location.id.uuidString.prefix(8))))"
        case .deleteLocation(let location):
            return "locations(.deleteLocation(id: \(location.id.uuidString.prefix(8))))"
        default:
            return "locations(\(String(describing: locationsAction)))"
        }

    // ShiftTypes feature actions
    case .shiftTypes(let shiftTypesAction):
        switch shiftTypesAction {
        case .shiftTypesLoaded(let result):
            switch result {
            case .success(let shiftTypes):
                return "shiftTypes(.shiftTypesLoaded(success: \(shiftTypes.count) types))"
            case .failure(let error):
                return "shiftTypes(.shiftTypesLoaded(failure: \(type(of: error))))"
            }
        case .saveShiftType(let shiftType):
            return "shiftTypes(.saveShiftType(id: \(shiftType.id.uuidString.prefix(8))))"
        case .deleteShiftType(let shiftType):
            return "shiftTypes(.deleteShiftType(id: \(shiftType.id.uuidString.prefix(8))))"
        default:
            return "shiftTypes(\(String(describing: shiftTypesAction)))"
        }

    // Other features use default description
    case .appLifecycle, .settings, .sync:
        return String(describing: action)
    }
}
