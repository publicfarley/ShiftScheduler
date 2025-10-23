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
}
