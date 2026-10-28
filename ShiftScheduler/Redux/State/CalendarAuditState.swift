import Foundation

/// State for the Calendar Audit feature (launched from Settings)
struct CalendarAuditState: Equatable {
    var isSheetPresented: Bool = false

    /// Calendars the user can audit against (excludes the app calendar)
    var availableCalendars: [CalendarAudit.AuditCalendar] = []
    var isLoadingCalendars: Bool = false
    var selectedCalendarId: String? = nil

    /// Audit range; set from the injected clock when the sheet opens
    var startDate: Date = Date(timeIntervalSinceReferenceDate: 0)
    var endDate: Date = Date(timeIntervalSinceReferenceDate: 0)

    var isRunning: Bool = false
    var report: CalendarAudit.Report? = nil

    /// Dates of fixable discrepancies the user has ticked for update
    var selectedFixDates: Set<Date> = []
    var isApplying: Bool = false

    var errorMessage: String? = nil
    var successMessage: String? = nil
}
