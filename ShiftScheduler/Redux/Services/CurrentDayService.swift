import Foundation
import OSLog

private let logger = Logger(subsystem: "com.shiftscheduler.redux.services", category: "CurrentDayService")

/// Production implementation of CurrentDayServiceProtocol
/// Provides date and time utilities for the Redux store
final class CurrentDayService: CurrentDayServiceProtocol {
    private let calendar: Calendar

    init(calendar: Calendar = Calendar.current) {
        self.calendar = calendar
    }

    // MARK: - CurrentDayServiceProtocol Implementation

    func getCurrentDate() -> Date {
        calendar.startOfDay(for: Date())
    }

    func getTodayDate() -> Date {
        calendar.startOfDay(for: Date())
    }

    func getTomorrowDate() -> Date {
        calendar.date(byAdding: .day, value: 1, to: getTodayDate()) ?? getTodayDate()
    }

    func getYesterdayDate() -> Date {
        calendar.date(byAdding: .day, value: -1, to: getTodayDate()) ?? getTodayDate()
    }

    func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    func isTomorrow(_ date: Date) -> Bool {
        calendar.isDateInTomorrow(date)
    }

    func isYesterday(_ date: Date) -> Bool {
        calendar.isDateInYesterday(date)
    }

    func getStartOfWeek(for date: Date) -> Date {
        calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)) ?? date
    }

    func getEndOfWeek(for date: Date) -> Date {
        let startOfWeek = getStartOfWeek(for: date)
        return calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? startOfWeek
    }

    func getStartOfMonth(for date: Date) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
    }

    func getEndOfMonth(for date: Date) -> Date {
        let startOfMonth = getStartOfMonth(for: date)
        guard let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            return startOfMonth
        }
        return endOfMonth
    }

    func daysBetween(_ date1: Date, _ date2: Date) -> Int {
        let start = calendar.startOfDay(for: date1)
        let end = calendar.startOfDay(for: date2)
        let components = calendar.dateComponents([.day], from: start, to: end)
        return components.day ?? 0
    }

    func getCurrentTime() -> HourMinuteTime {
        let now = Date()
        let components = calendar.dateComponents([.hour, .minute], from: now)
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        return HourMinuteTime(hour: hour, minute: minute)
    }

    func formatDate(_ date: Date, style: DateFormatter.Style) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    func formatTime(_ time: HourMinuteTime) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short

        let components = DateComponents(hour: Int(time.hour), minute: Int(time.minute))
        guard let date = calendar.date(from: components) else {
            return "\(time.hour):\(String(format: "%02d", time.minute))"
        }

        return formatter.string(from: date)
    }
}
