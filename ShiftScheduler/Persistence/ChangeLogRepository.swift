import Foundation

/// Actor-based repository for persisting change log entries to JSON files
actor ChangeLogRepository: ChangeLogRepositoryProtocol {
    private static let defaultDirectory: URL = {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("ShiftSchedulerData", isDirectory: true)
    }()

    private let fileManager = FileManager.default
    internal let directoryURL: URL
    private let fileName = "changelog.json"

    init(directoryURL: URL? = nil) {
        self.directoryURL = directoryURL ?? Self.defaultDirectory
    }

    /// Ensure the directory exists
    private func ensureDirectory() throws {
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }

    /// Fetch all change log entries
    nonisolated func fetchAll() async throws -> [ChangeLogEntry] {
        let fileManager = FileManager.default
        let directoryURL = self.directoryURL
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let fileURL = directoryURL.appendingPathComponent("changelog.json")

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return []
        }

        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode([ChangeLogEntry].self, from: data)
    }

    /// Fetch entries in a date range
    nonisolated func fetch(from startDate: Date, to endDate: Date) async throws -> [ChangeLogEntry] {
        let all = try await fetchAll()
        return all.filter { $0.timestamp >= startDate && $0.timestamp <= endDate }
    }

    /// Fetch recent entries
    nonisolated func fetchRecent(limit: Int) async throws -> [ChangeLogEntry] {
        let all = try await fetchAll()
        return Array(all.suffix(limit))
    }

    /// Save a change log entry
    nonisolated func save(_ entry: ChangeLogEntry) async throws {
        var entries = try await fetchAll()
        entries.append(entry)

        let fileManager = FileManager.default
        let directoryURL = self.directoryURL
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let fileURL = directoryURL.appendingPathComponent("changelog.json")
        let data = try JSONEncoder().encode(entries)
        try data.write(to: fileURL, options: .atomic)
    }

    /// Delete entries older than a date
    nonisolated func deleteEntriesOlderThan(_ date: Date) async throws {
        var entries = try await fetchAll()
        entries.removeAll { $0.timestamp < date }

        let fileManager = FileManager.default
        let directoryURL = self.directoryURL
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let fileURL = directoryURL.appendingPathComponent("changelog.json")
        let data = try JSONEncoder().encode(entries)
        try data.write(to: fileURL, options: .atomic)
    }

    /// Delete all entries
    nonisolated func deleteAll() async throws {
        let fileManager = FileManager.default
        let directoryURL = self.directoryURL
        let fileURL = directoryURL.appendingPathComponent("changelog.json")

        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
    }
}
