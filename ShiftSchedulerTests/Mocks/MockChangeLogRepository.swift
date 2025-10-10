import Foundation
@testable import ShiftScheduler

/// Mock implementation of ChangeLogRepositoryProtocol for testing
actor MockChangeLogRepository: ChangeLogRepositoryProtocol {
    private var entries: [ChangeLogEntry] = []
    private(set) var saveCallCount = 0
    private(set) var fetchAllCallCount = 0
    private(set) var deleteEntriesOlderThanCallCount = 0
    private(set) var lastDeleteCutoffDate: Date?

    func save(_ entry: ChangeLogEntry) async throws {
        saveCallCount += 1
        entries.append(entry)
    }

    func fetchAll() async throws -> [ChangeLogEntry] {
        fetchAllCallCount += 1
        return entries
    }

    func fetch(from startDate: Date, to endDate: Date) async throws -> [ChangeLogEntry] {
        return entries.filter { $0.timestamp >= startDate && $0.timestamp <= endDate }
    }

    func fetchRecent(limit: Int) async throws -> [ChangeLogEntry] {
        return Array(entries.sorted { $0.timestamp > $1.timestamp }.prefix(limit))
    }

    func deleteEntriesOlderThan(_ date: Date) async throws {
        deleteEntriesOlderThanCallCount += 1
        lastDeleteCutoffDate = date
        entries.removeAll { $0.timestamp < date }
    }

    func deleteAll() async throws {
        entries.removeAll()
    }

    // Test helpers
    func addEntry(_ entry: ChangeLogEntry) {
        entries.append(entry)
    }

    func getEntries() -> [ChangeLogEntry] {
        return entries
    }

    func getEntryCount() -> Int {
        return entries.count
    }

    func reset() {
        entries.removeAll()
        saveCallCount = 0
        fetchAllCallCount = 0
        deleteEntriesOlderThanCallCount = 0
        lastDeleteCutoffDate = nil
    }
}
