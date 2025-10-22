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

/// Manages retention policy persistence and purge operations
final class ChangeLogRetentionManager {
    static let shared = ChangeLogRetentionManager()

    private let userDefaultsKey = "com.workevents.ShiftScheduler.changeLogRetentionPolicy"
    private let lastPurgeDateKey = "com.workevents.ShiftScheduler.lastPurgeDate"
    private let defaults = UserDefaults.standard

    /// Current retention policy
    private(set) var currentPolicy: ChangeLogRetentionPolicy

    /// Last time entries were purged
    private(set) var lastPurgeDate: Date?

    /// Number of entries purged in the last operation
    private(set) var lastPurgedCount: Int = 0

    private init() {
        // Load retention policy
        if let policyString = defaults.string(forKey: userDefaultsKey),
           let policy = ChangeLogRetentionPolicy(rawValue: policyString) {
            self.currentPolicy = policy
        } else {
            // Default to 1 year
            self.currentPolicy = .year1
            save()
        }

        // Load last purge date
        if let lastPurge = defaults.object(forKey: lastPurgeDateKey) as? Date {
            self.lastPurgeDate = lastPurge
        }
    }

    /// Updates the retention policy
    func updatePolicy(_ newPolicy: ChangeLogRetentionPolicy) {
        currentPolicy = newPolicy
        save()
    }

    /// Records a purge operation
    func recordPurge(entriesPurged: Int) {
        lastPurgeDate = Date()
        lastPurgedCount = entriesPurged
        defaults.set(lastPurgeDate, forKey: lastPurgeDateKey)
    }

    // MARK: - Private Methods

    private func save() {
        defaults.set(currentPolicy.rawValue, forKey: userDefaultsKey)
    }
}
