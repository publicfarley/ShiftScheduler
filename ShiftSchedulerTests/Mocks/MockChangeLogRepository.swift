import Foundation
@testable import ShiftScheduler

/// Mock implementation of ChangeLogRepositoryProtocol for testing
/// Note: This is a basic stub that satisfies the protocol but doesn't actually store data
/// For testing, use MockPersistenceService instead which provides full mock functionality
final class MockChangeLogRepository: ChangeLogRepositoryProtocol {
    private var entries: [ChangeLogEntry] = []
    private(set) var saveCallCount = 0
    private(set) var fetchAllCallCount = 0
    private(set) var deleteEntriesOlderThanCallCount = 0
    private(set) var lastDeleteCutoffDate: Date?

    nonisolated func save(_ entry: ChangeLogEntry) async throws {
        // Note: Can't modify state from nonisolated context
        // This mock is kept for backward compatibility only
    }

    nonisolated func fetchAll() async throws -> [ChangeLogEntry] {
        // Note: Can't access state from nonisolated context
        return []
    }

    nonisolated func fetch(from startDate: Date, to endDate: Date) async throws -> [ChangeLogEntry] {
        return []
    }

    nonisolated func fetchRecent(limit: Int) async throws -> [ChangeLogEntry] {
        return []
    }

    nonisolated func deleteEntriesOlderThan(_ date: Date) async throws {
        // Note: Can't modify state from nonisolated context
    }

    nonisolated func deleteAll() async throws {
        // Note: Can't modify state from nonisolated context
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
