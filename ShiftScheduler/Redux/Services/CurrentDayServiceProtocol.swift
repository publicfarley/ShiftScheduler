import Foundation

/// Protocol for date and time utilities in Redux middleware
/// Provides current date/time operations used throughout the app
protocol CurrentDayServiceProtocol: Sendable {
    /// Get the current date at 00:00:00
    func getCurrentDate() -> Date

    /// Get today's date at 00:00:00
    func getTodayDate() -> Date

    /// Get tomorrow's date at 00:00:00
    func getTomorrowDate() -> Date

    /// Get yesterday's date at 00:00:00
    func getYesterdayDate() -> Date

    /// Check if a date is today
    func isToday(_ date: Date) -> Bool

    /// Check if a date is tomorrow
    func isTomorrow(_ date: Date) -> Bool

    /// Check if a date is yesterday
    func isYesterday(_ date: Date) -> Bool

    /// Get the start of week for a given date
    func getStartOfWeek(for date: Date) -> Date

    /// Get the end of week for a given date
    func getEndOfWeek(for date: Date) -> Date

    /// Get the start of month for a given date
    func getStartOfMonth(for date: Date) -> Date

    /// Get the end of month for a given date
    func getEndOfMonth(for date: Date) -> Date

    /// Calculate days between two dates
    func daysBetween(_ date1: Date, _ date2: Date) -> Int

    /// Get the current time as HourMinuteTime
    func getCurrentTime() -> HourMinuteTime

    /// Format a date for display
    func formatDate(_ date: Date, style: DateFormatter.Style) -> String

    /// Format a time for display
    func formatTime(_ time: HourMinuteTime) -> String
}
