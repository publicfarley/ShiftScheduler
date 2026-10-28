import Foundation

/// Pure reducer for the Calendar Audit feature
func calendarAuditReducer(state: CalendarAuditState, action: CalendarAuditAction) -> CalendarAuditState {
    var state = state

    switch action {
    case .sheetOpened(let now):
        let calendar = Calendar.current
        let monthStart = calendar.dateInterval(of: .month, for: now)?.start ?? calendar.startOfDay(for: now)
        state.isSheetPresented = true
        state.isLoadingCalendars = true
        state.startDate = monthStart
        // Last day of next month
        state.endDate = calendar.date(byAdding: DateComponents(month: 2, day: -1), to: monthStart) ?? monthStart
        clearResults(&state)
        state.errorMessage = nil
        state.successMessage = nil

    case .sheetDismissed:
        state.isSheetPresented = false
        state.isRunning = false
        state.isApplying = false
        clearResults(&state)
        state.errorMessage = nil
        state.successMessage = nil

    case .calendarsLoaded(let calendars):
        state.availableCalendars = calendars
        state.isLoadingCalendars = false
        if let selected = state.selectedCalendarId, !calendars.contains(where: { $0.id == selected }) {
            state.selectedCalendarId = nil
        }

    case .calendarsLoadFailed(let message):
        state.isLoadingCalendars = false
        state.errorMessage = message

    case .calendarSelected(let id):
        state.selectedCalendarId = id
        clearResults(&state)
        state.errorMessage = nil
        state.successMessage = nil

    case .startDateChanged(let date):
        state.startDate = date
        clearResults(&state)

    case .endDateChanged(let date):
        state.endDate = date
        clearResults(&state)

    case .runAudit:
        state.isRunning = true

    case .auditCompleted(let report):
        state.isRunning = false
        state.report = report
        state.selectedFixDates = Set(report.fixableDays.map(\.date))

    case .auditFailed(let message):
        state.isRunning = false
        state.errorMessage = message

    case .fixToggled(let date):
        guard state.report?.fixableDays.contains(where: { $0.date == date }) == true else { break }
        if state.selectedFixDates.contains(date) {
            state.selectedFixDates.remove(date)
        } else {
            state.selectedFixDates.insert(date)
        }

    case .applyFixes:
        state.isApplying = true
        state.errorMessage = nil
        state.successMessage = nil

    case .fixesCompleted(let applied):
        state.isApplying = false
        state.successMessage = "Updated \(dateCount(applied))"

    case .fixesFailed(let applied, let message):
        state.isApplying = false
        state.errorMessage = applied == 0
            ? message
            : "Updated \(dateCount(applied)) before an error: \(message)"
    }

    return state
}

private func clearResults(_ state: inout CalendarAuditState) {
    state.report = nil
    state.selectedFixDates = []
}

private func dateCount(_ count: Int) -> String {
    "\(count) date\(count == 1 ? "" : "s")"
}
