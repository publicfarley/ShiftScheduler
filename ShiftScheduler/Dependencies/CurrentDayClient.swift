import Foundation
import ComposableArchitecture

/// TCA Dependency Client for current day and date utilities
/// Provides date calculations without relying on singleton state
@DependencyClient
struct CurrentDayClient {
    /// Get the current date/time
    var getCurrentDate: @Sendable () -> Date = { Date() }

    /// Get the start of today
    var getTodayDate: @Sendable () -> Date = { Calendar.current.startOfDay(for: Date()) }

    /// Get the start of tomorrow
    var getTomorrowDate: @Sendable () -> Date = {
        Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date())) ?? Date()
    }

    /// Get the start of yesterday
    var getYesterdayDate: @Sendable () -> Date = {
        Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: Date())) ?? Date()
    }

    /// Check if a date falls on today
    var isToday: @Sendable (Date) -> Bool = { date in
        Calendar.current.isDate(date, inSameDayAs: Calendar.current.startOfDay(for: Date()))
    }

    /// Check if a date falls on tomorrow
    var isTomorrow: @Sendable (Date) -> Bool = { date in
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date())) ?? Date()
        return Calendar.current.isDate(date, inSameDayAs: tomorrow)
    }

    /// Check if a date falls on yesterday
    var isYesterday: @Sendable (Date) -> Bool = { date in
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: Date())) ?? Date()
        return Calendar.current.isDate(date, inSameDayAs: yesterday)
    }

    /// Calculate the number of days between two dates
    var daysBetween: @Sendable (Date, Date) -> Int = { from, to in
        Calendar.current.dateComponents([.day], from: from, to: to).day ?? 0
    }
}

extension CurrentDayClient: DependencyKey {
    /// Live implementation using Calendar calculations
    static let liveValue: CurrentDayClient = {
        return CurrentDayClient(
            getCurrentDate: {
                Date()
            },
            getTodayDate: {
                Calendar.current.startOfDay(for: Date())
            },
            getTomorrowDate: {
                Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date())) ?? Date()
            },
            getYesterdayDate: {
                Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: Date())) ?? Date()
            },
            isToday: { date in
                Calendar.current.isDate(date, inSameDayAs: Calendar.current.startOfDay(for: Date()))
            },
            isTomorrow: { date in
                let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date())) ?? Date()
                return Calendar.current.isDate(date, inSameDayAs: tomorrow)
            },
            isYesterday: { date in
                let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: Date())) ?? Date()
                return Calendar.current.isDate(date, inSameDayAs: yesterday)
            },
            daysBetween: { from, to in
                Calendar.current.dateComponents([.day], from: from, to: to).day ?? 0
            }
        )
    }()

    /// Test value with overridable dates (for testing date-specific logic)
    static let testValue = CurrentDayClient()

    /// Preview value with fixed dates
    static let previewValue = CurrentDayClient(
        getCurrentDate: {
            // Fixed date for preview: January 15, 2025, 2:30 PM
            var components = DateComponents()
            components.year = 2025
            components.month = 1
            components.day = 15
            components.hour = 14
            components.minute = 30
            return Calendar.current.date(from: components) ?? Date()
        },
        getTodayDate: {
            // Fixed date for preview: January 15, 2025, 12:00 AM
            var components = DateComponents()
            components.year = 2025
            components.month = 1
            components.day = 15
            return Calendar.current.date(from: components) ?? Date()
        },
        getTomorrowDate: {
            // Fixed date for preview: January 16, 2025, 12:00 AM
            var components = DateComponents()
            components.year = 2025
            components.month = 1
            components.day = 16
            return Calendar.current.date(from: components) ?? Date()
        },
        getYesterdayDate: {
            // Fixed date for preview: January 14, 2025, 12:00 AM
            var components = DateComponents()
            components.year = 2025
            components.month = 1
            components.day = 14
            return Calendar.current.date(from: components) ?? Date()
        },
        isToday: { _ in false },
        isTomorrow: { _ in false },
        isYesterday: { _ in false },
        daysBetween: { _, _ in 0 }
    )
}

extension DependencyValues {
    var currentDayClient: CurrentDayClient {
        get { self[CurrentDayClient.self] }
        set { self[CurrentDayClient.self] = newValue }
    }
}
