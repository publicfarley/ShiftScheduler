import Foundation
import OSLog

private let logger = Logger(subsystem: "com.workevents.ShiftScheduler", category: "ChangeLogPurgeService")

/// Service responsible for purging expired change log entries based on retention policy
actor ChangeLogPurgeService {
    private let repository: ChangeLogRepositoryProtocol
    private let retentionManager: ChangeLogRetentionManager

    init(
        repository: ChangeLogRepositoryProtocol,
        retentionManager: ChangeLogRetentionManager = .shared
    ) {
        self.repository = repository
        self.retentionManager = retentionManager
    }

    /// Performs a purge operation based on the current retention policy
    /// Returns the number of entries purged
    @discardableResult
    func purgeExpiredEntries() async throws -> Int {
        let policy = retentionManager.currentPolicy

        logger.debug("Starting purge operation with policy: \(policy.displayName)")

        // If policy is "forever", no purging needed
        guard let cutoffDate = policy.cutoffDate else {
            logger.debug("Retention policy is 'forever', skipping purge")
            return 0
        }

        // First, count entries that will be purged
        let allEntries = try await repository.fetchAll()
        let entriesToPurge = allEntries.filter { $0.timestamp < cutoffDate }

        guard !entriesToPurge.isEmpty else {
            logger.debug("No entries to purge")
            return 0
        }

        let purgedCount = entriesToPurge.count
        logger.debug("Found \(purgedCount) entries to purge (older than \(cutoffDate))")

        // Delete expired entries
        try await repository.deleteEntriesOlderThan(cutoffDate)

        // Record the purge operation
        retentionManager.recordPurge(entriesPurged: purgedCount)

        logger.debug("Purge completed: removed \(purgedCount) entries")

        return purgedCount
    }

    /// Checks if a purge is needed based on the last purge date
    /// Purges are recommended daily
    func shouldPerformPurge() -> Bool {
        guard let lastPurge = retentionManager.lastPurgeDate else {
            // Never purged before
            return true
        }

        let calendar = Calendar.current
        let now = Date()

        // Check if it's been at least 1 day since last purge
        if let daysSinceLastPurge = calendar.dateComponents([.day], from: lastPurge, to: now).day,
           daysSinceLastPurge >= 1 {
            return true
        }

        return false
    }

    /// Performs a purge only if needed (checks shouldPerformPurge first)
    @discardableResult
    func purgeIfNeeded() async throws -> Int {
        guard shouldPerformPurge() else {
            logger.debug("Purge not needed yet")
            return 0
        }

        return try await purgeExpiredEntries()
    }
}
