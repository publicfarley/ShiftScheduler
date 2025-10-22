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

    var cutoffDate: Date? {
        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .days30:
            return calendar.date(byAdding: .day, value: -30, to: now)
        case .days90:
            return calendar.date(byAdding: .day, value: -90, to: now)
        case .months6:
            return calendar.date(byAdding: .month, value: -6, to: now)
        case .year1:
            return calendar.date(byAdding: .year, value: -1, to: now)
        case .years2:
            return calendar.date(byAdding: .year, value: -2, to: now)
        case .forever:
            return nil // Never purge
        }
    }
}
