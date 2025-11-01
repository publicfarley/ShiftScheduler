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

    /// Load shifts for an extended range (6 months before and after today)
    /// This is useful for calendar views that allow navigation to past/future months
    func loadShiftsForExtendedRange() async throws -> [ScheduledShift]

    /// Load shifts centered around a specific month (for sliding window)
    /// - Parameters:
    ///   - pivotMonth: The month to center the data range around
    ///   - monthOffset: Number of months before and after pivot month to load (default: 6)
    /// - Returns: Tuple of shifts and the actual date range loaded (rangeStart, rangeEnd)
    func loadShiftsAroundMonth(_ pivotMonth: Date, monthOffset: Int) async throws -> (shifts: [ScheduledShift], rangeStart: Date, rangeEnd: Date)

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

    /// Update an existing shift event in the calendar with a new shift type
    /// - Parameters:
    ///   - eventIdentifier: The EventKit event identifier of the shift to update
    ///   - newShiftType: The new shift type to apply
    ///   - date: The date of the shift being updated
    /// - Throws: CalendarError if the event cannot be found or update fails
    func updateShiftEvent(eventIdentifier: String, newShiftType: ShiftType, date: Date) async throws -> Void

    /// Delete a shift event from the calendar
    /// - Parameter eventIdentifier: The EventKit event identifier of the shift to delete
    /// - Throws: ScheduleError if deletion fails
    func deleteShiftEvent(eventIdentifier: String) async throws -> Void

    /// Update shift notes in an existing calendar event
    /// - Parameters:
    ///   - eventIdentifier: The EventKit event identifier of the shift to update
    ///   - notes: The new notes to set (empty string clears notes)
    /// - Throws: CalendarError if the event cannot be found or update fails
    func updateShiftNotes(eventIdentifier: String, notes: String) async throws -> Void
}
