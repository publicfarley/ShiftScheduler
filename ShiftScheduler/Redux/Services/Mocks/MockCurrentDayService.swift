import Foundation

/// Mock implementation of CurrentDayServiceProtocol for testing
final class MockCurrentDayService: CurrentDayServiceProtocol {
    var mockCurrentDate: Date = Date()
    var mockCurrentTime: HourMinuteTime = HourMinuteTime(hour: 9, minute: 0)

    func getCurrentDate() -> Date {
        Calendar.current.startOfDay(for: mockCurrentDate)
    }

    func getTodayDate() -> Date {
        Calendar.current.startOfDay(for: mockCurrentDate)
    }

    func getTomorrowDate() -> Date {
        Calendar.current.date(byAdding: .day, value: 1, to: getTodayDate()) ?? getTodayDate()
    }

    func getYesterdayDate() -> Date {
        Calendar.current.date(byAdding: .day, value: -1, to: getTodayDate()) ?? getTodayDate()
    }

    func isToday(_ date: Date) -> Bool {
        Calendar.current.isDate(date, inSameDayAs: mockCurrentDate)
    }

    func isTomorrow(_ date: Date) -> Bool {
        Calendar.current.isDate(date, inSameDayAs: getTomorrowDate())
    }

    func isYesterday(_ date: Date) -> Bool {
        Calendar.current.isDate(date, inSameDayAs: getYesterdayDate())
    }

    func getStartOfWeek(for date: Date) -> Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)) ?? date
    }

    func getEndOfWeek(for date: Date) -> Date {
        let startOfWeek = getStartOfWeek(for: date)
        return Calendar.current.date(byAdding: .day, value: 6, to: startOfWeek) ?? startOfWeek
    }

    func getStartOfMonth(for date: Date) -> Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: date)) ?? date
    }

    func getEndOfMonth(for date: Date) -> Date {
        let startOfMonth = getStartOfMonth(for: date)
        guard let endOfMonth = Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            return startOfMonth
        }
        return endOfMonth
    }

    func daysBetween(_ date1: Date, _ date2: Date) -> Int {
        let start = Calendar.current.startOfDay(for: date1)
        let end = Calendar.current.startOfDay(for: date2)
        let components = Calendar.current.dateComponents([.day], from: start, to: end)
        return components.day ?? 0
    }

    func getCurrentTime() -> HourMinuteTime {
        mockCurrentTime
    }

    func formatDate(_ date: Date, style: DateFormatter.Style) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    func formatTime(_ time: HourMinuteTime) -> String {
        "\(time.hour):\(String(format: "%02d", time.minute))"
    }
}
