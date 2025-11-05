import Foundation

/// Defines how long change log entries should be retained
enum ChangeLogRetentionPolicy: String, Codable, CaseIterable, Identifiable {
    case days30 = "30_days"
    case days90 = "90_days"
    case months6 = "6_months"
    case year1 = "1_year"
    case years2 = "2_years"
    case forever = "forever"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .days30: return "30 Days"
        case .days90: return "90 Days"
        case .months6: return "6 Months"
        case .year1: return "1 Year"
        case .years2: return "2 Years"
        case .forever: return "Forever"
        }
    }

    /// Calculates the cutoff date for this retention policy
    /// - Parameter baseDate: The reference date to calculate from. Defaults to the current date.
    /// - Returns: The cutoff date (entries before this date should be purged), or nil for forever policy
    func cutoffDate(from baseDate: Date = Date()) -> Date? {
        let calendar = Calendar.current

        switch self {
        case .days30:
            return calendar.date(byAdding: .day, value: -30, to: baseDate)
        case .days90:
            return calendar.date(byAdding: .day, value: -90, to: baseDate)
        case .months6:
            return calendar.date(byAdding: .month, value: -6, to: baseDate)
        case .year1:
            return calendar.date(byAdding: .year, value: -1, to: baseDate)
        case .years2:
            return calendar.date(byAdding: .year, value: -2, to: baseDate)
        case .forever:
            return nil // Never purge
        }
    }

    /// Computed property for backward compatibility - returns cutoff date using current date
    var cutoffDate: Date? {
        cutoffDate(from: Date())
    }
}
