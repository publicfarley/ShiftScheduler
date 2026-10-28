import Foundation

/// Actions for the Calendar Audit feature
enum CalendarAuditAction: Equatable {
    /// Sheet opened; `now` seeds the default date range
    case sheetOpened(now: Date)
    case sheetDismissed

    case calendarsLoaded([CalendarAudit.AuditCalendar])
    case calendarsLoadFailed(String)
    case calendarSelected(String)
    case startDateChanged(Date)
    case endDateChanged(Date)

    case runAudit
    case auditCompleted(CalendarAudit.Report)
    case auditFailed(String)

    /// Tick/untick a fixable discrepancy for update
    case fixToggled(Date)
    /// User confirmed updating the app calendar for the ticked discrepancies
    case applyFixes
    case fixesCompleted(applied: Int)
    case fixesFailed(applied: Int, message: String)
}
