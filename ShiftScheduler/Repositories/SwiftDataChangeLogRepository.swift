import Foundation
import SwiftData
import OSLog

nonisolated(unsafe) private let logger = Logger(subsystem: "com.functioncraft.shiftscheduler", category: "ChangeLogRepository")

/// SwiftData implementation of ChangeLogRepository using ModelActor for proper concurrency
@ModelActor
actor SwiftDataChangeLogRepository: ChangeLogRepositoryProtocol {

    func save(_ entry: ChangeLogEntry) async throws {
        logger.debug("Saving change log entry: \(entry.id)")
        modelContext.insert(entry)
        try modelContext.save()
    }

    func fetchAll() async throws -> [ChangeLogEntry] {
        logger.debug("Fetching all change log entries")
        let descriptor = FetchDescriptor<ChangeLogEntry>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetch(from startDate: Date, to endDate: Date) async throws -> [ChangeLogEntry] {
        logger.debug("Fetching change log entries from \(startDate) to \(endDate)")
        let predicate = #Predicate<ChangeLogEntry> { entry in
            entry.timestamp >= startDate && entry.timestamp <= endDate
        }
        let descriptor = FetchDescriptor<ChangeLogEntry>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchRecent(limit: Int) async throws -> [ChangeLogEntry] {
        logger.debug("Fetching \(limit) recent change log entries")
        var descriptor = FetchDescriptor<ChangeLogEntry>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try modelContext.fetch(descriptor)
    }

    func deleteEntriesOlderThan(_ date: Date) async throws {
        logger.debug("Deleting change log entries older than \(date)")
        let predicate = #Predicate<ChangeLogEntry> { entry in
            entry.timestamp < date
        }
        let descriptor = FetchDescriptor<ChangeLogEntry>(predicate: predicate)
        let entriesToDelete = try modelContext.fetch(descriptor)

        for entry in entriesToDelete {
            modelContext.delete(entry)
        }

        try modelContext.save()
        logger.debug("Deleted \(entriesToDelete.count) old entries")
    }

    func deleteAll() async throws {
        logger.debug("Deleting all change log entries")
        let descriptor = FetchDescriptor<ChangeLogEntry>()
        let allEntries = try modelContext.fetch(descriptor)

        for entry in allEntries {
            modelContext.delete(entry)
        }

        try modelContext.save()
        logger.debug("Deleted \(allEntries.count) entries")
    }
}
