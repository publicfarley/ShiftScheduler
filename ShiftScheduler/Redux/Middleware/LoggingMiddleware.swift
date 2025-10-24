import Foundation
import OSLog

private let logger = Logger(subsystem: "com.shiftscheduler.redux", category: "Middleware")

/// Logging middleware that logs all dispatched actions and state changes
/// Useful for debugging Redux flow and understanding action sequences
func loggingMiddleware(
    state: AppState,
    action: AppAction,
    dispatch: @escaping (AppAction) -> Void,
    services: ServiceContainer
) {
    logger.debug("[Middleware] Action dispatched: \(String(describing: action))")
    logger.debug("[Middleware] Selected tab: \(String(describing: state.selectedTab))")

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

    case .schedule:
        logger.debug("[Schedule] Authorized: \(state.schedule.isCalendarAuthorized)")
        logger.debug("[Schedule] Selected date: \(state.schedule.selectedDate.formatted(date: .abbreviated, time: .omitted))")
        logger.debug("[Schedule] Shifts: \(state.schedule.scheduledShifts.count)")
        logger.debug("[Schedule] Undo stack: \(state.schedule.undoStack.count)")
        logger.debug("[Schedule] Redo stack: \(state.schedule.redoStack.count)")

    case .locations:
        logger.debug("[Locations] Total: \(state.locations.locations.count)")
        logger.debug("[Locations] Filtered: \(state.locations.filteredLocations.count)")

    case .shiftTypes:
        logger.debug("[ShiftTypes] Total: \(state.shiftTypes.shiftTypes.count)")
        logger.debug("[ShiftTypes] Filtered: \(state.shiftTypes.filteredShiftTypes.count)")

    case .changeLog:
        logger.debug("[ChangeLog] Entries: \(state.changeLog.entries.count)")
        logger.debug("[ChangeLog] Filtered: \(state.changeLog.filteredEntries.count)")

    case .settings:
        logger.debug("[Settings] User: \(state.settings.displayName)")
        logger.debug("[Settings] Unsaved: \(state.settings.hasUnsavedChanges)")

    case .appLifecycle:
        logger.debug("[AppLifecycle] Selected tab: \(String(describing: state.selectedTab))")
        logger.debug("[AppLifecycle] User: \(state.userProfile.displayName)")
    }
}
