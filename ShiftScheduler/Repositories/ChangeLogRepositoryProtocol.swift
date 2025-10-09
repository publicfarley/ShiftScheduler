import Foundation

/// Protocol for change log persistence operations
protocol ChangeLogRepositoryProtocol: Sendable {
    func save(_ entry: ChangeLogEntry) async throws
    func fetchAll() async throws -> [ChangeLogEntry]
    func fetch(from startDate: Date, to endDate: Date) async throws -> [ChangeLogEntry]
    func fetchRecent(limit: Int) async throws -> [ChangeLogEntry]
    func deleteEntriesOlderThan(_ date: Date) async throws
    func deleteAll() async throws
}
