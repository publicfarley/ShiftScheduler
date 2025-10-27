import Foundation

/// Protocol for calendar operations in Redux middleware
/// Handles loading shifts from EventKit and calendar authorization
protocol CalendarServiceProtocol: Sendable {
    /// Check if app has calendar access authorization
    func isCalendarAuthorized() async throws -> Bool

    /// Request calendar access from user
    func requestCalendarAccess() async throws -> Bool

    /// Load scheduled shifts from calendar for a given date range
    func loadShifts(from startDate: Date, to endDate: Date) async throws -> [ScheduledShift]

    /// Load shifts for the next 30 days from today
    func loadShiftsForNext30Days() async throws -> [ScheduledShift]

    /// Load shifts for the current month
    func loadShiftsForCurrentMonth() async throws -> [ScheduledShift]

    /// Load raw shift data (ScheduledShiftData) from EventKit for a date range
    /// This returns data before conversion to domain objects
    func loadShiftData(from startDate: Date, to endDate: Date) async throws -> [ScheduledShiftData]

    /// Load raw shift data for today only
    func loadShiftDataForToday() async throws -> [ScheduledShiftData]

    /// Load raw shift data for tomorrow only
    func loadShiftDataForTomorrow() async throws -> [ScheduledShiftData]

    /// Create a new all-day shift event in the calendar
    /// - Parameters:
    ///   - date: The date for the shift (all-day event)
    ///   - shiftType: The shift type to create
    ///   - notes: Optional notes for the event
    /// - Returns: ScheduledShift with the EventKit event identifier
    /// - Throws: CalendarError if creation fails or duplicate shift exists
    func createShiftEvent(date: Date, shiftType: ShiftType, notes: String?) async throws -> ScheduledShift
}
