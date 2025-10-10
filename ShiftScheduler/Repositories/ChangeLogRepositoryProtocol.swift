import Foundation

/// Protocol for change log persistence operations
protocol ChangeLogRepositoryProtocol: Sendable {
    nonisolated func save(_ entry: ChangeLogEntry) async throws
    nonisolated func fetchAll() async throws -> [ChangeLogEntry]
    nonisolated func fetch(from startDate: Date, to endDate: Date) async throws -> [ChangeLogEntry]
    nonisolated func fetchRecent(limit: Int) async throws -> [ChangeLogEntry]
    nonisolated func deleteEntriesOlderThan(_ date: Date) async throws
    nonisolated func deleteAll() async throws
}
