import Foundation
import OSLog

private nonisolated let logger = Logger(subsystem: "com.shiftscheduler.redux", category: "CalendarAuditMiddleware")

/// Middleware for Calendar Audit side effects
/// Loads calendars, runs the comparison, and applies the fixes the user confirmed
func calendarAuditMiddleware(
    state: AppState,
    action: AppAction,
    services: ServiceContainer,
    dispatch: Dispatcher<AppAction>
) async {
    guard case .settings(.calendarAudit(let auditAction)) = action else { return }

    func send(_ action: CalendarAuditAction) async {
        await dispatch(.settings(.calendarAudit(action)))
    }

    switch auditAction {
    case .sheetOpened:
        do {
            let calendars = try await services.calendarService.availableCalendars()
            await send(.calendarsLoaded(calendars))
        } catch {
            logger.error("Failed to load calendars for audit: \(error.localizedDescription)")
            await send(.calendarsLoadFailed(error.localizedDescription))
        }

    case .runAudit:
        let audit = state.settings.calendarAudit
        guard let calendarId = audit.selectedCalendarId else {
            await send(.auditFailed("Choose a calendar to audit against"))
            return
        }
        guard audit.startDate <= audit.endDate else {
            await send(.auditFailed("Start date must be on or before end date"))
            return
        }

        do {
            let lastDay = Calendar.current.startOfDay(for: audit.endDate)
            let dayAfterEnd = Calendar.current.date(byAdding: .day, value: 1, to: lastDay) ?? lastDay

            let shifts = try await services.calendarService.loadShifts(from: audit.startDate, to: dayAfterEnd)
            let events = try await services.calendarService.loadCalendarEvents(
                calendarIdentifier: calendarId,
                from: audit.startDate,
                through: audit.endDate
            )

            let report = CalendarAudit.audit(
                from: audit.startDate,
                through: audit.endDate,
                shifts: shifts,
                externalEvents: events,
                shiftTypes: state.shiftTypes.shiftTypes
            )
            await send(.auditCompleted(report))
        } catch {
            logger.error("Calendar audit failed: \(error.localizedDescription)")
            await send(.auditFailed(error.localizedDescription))
        }

    case .applyFixes:
        let audit = state.settings.calendarAudit
        guard let report = audit.report else {
            await send(.fixesFailed(applied: 0, message: "No audit results to apply"))
            return
        }

        let days = report.fixableDays.filter { audit.selectedFixDates.contains($0.date) }
        var applied = 0

        do {
            for day in days {
                guard let fix = day.fix else { continue }
                let entry = try await apply(fix, on: day.date, state: state, services: services)
                applied += 1
                try await services.persistenceService.addChangeLogEntry(entry)
            }
            await send(.fixesCompleted(applied: applied))
        } catch {
            logger.error("Calendar audit fix failed after \(applied) change(s): \(error.localizedDescription)")
            await send(.fixesFailed(applied: applied, message: error.localizedDescription))
        }

        // Refresh the app's schedule and re-run so the list reflects what changed
        await dispatch(.schedule(.loadShifts))
        await send(.runAudit)

    case .sheetDismissed, .calendarsLoaded, .calendarsLoadFailed, .calendarSelected,
         .startDateChanged, .endDateChanged, .auditCompleted, .auditFailed, .fixToggled,
         .fixesCompleted, .fixesFailed:
        // Handled by reducer only
        break
    }
}

/// Performs one fix against the app calendar and returns the change log entry describing it
private func apply(
    _ fix: CalendarAudit.Fix,
    on date: Date,
    state: AppState,
    services: ServiceContainer
) async throws -> ChangeLogEntry {
    let reason = "Calendar audit"
    let oldSnapshot: ShiftSnapshot?
    let newSnapshot: ShiftSnapshot?
    let changeType: ChangeType

    switch fix {
    case .create(let shiftType):
        _ = try await services.calendarService.createShiftEvent(date: date, shiftType: shiftType, notes: reason)
        changeType = .created
        oldSnapshot = nil
        newSnapshot = ShiftSnapshot(from: shiftType)

    case .switchTo(let shiftType, let previous, let eventIdentifier):
        try await services.calendarService.updateShiftEvent(eventIdentifier: eventIdentifier, newShiftType: shiftType, date: date)
        changeType = .switched
        oldSnapshot = previous.map(ShiftSnapshot.init(from:))
        newSnapshot = ShiftSnapshot(from: shiftType)

    case .remove(let current, let eventIdentifier):
        try await services.calendarService.deleteShiftEvent(eventIdentifier: eventIdentifier)
        changeType = .deleted
        oldSnapshot = current.map(ShiftSnapshot.init(from:))
        newSnapshot = nil
    }

    return ChangeLogEntry(
        timestamp: Date(),
        userId: state.userProfile.userId,
        userDisplayName: state.userProfile.displayName,
        changeType: changeType,
        scheduledShiftDate: date,
        oldShiftSnapshot: oldSnapshot,
        newShiftSnapshot: newSnapshot,
        reason: reason
    )
}
