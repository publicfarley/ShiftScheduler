import Foundation

/// Actor-based repository for persisting locations to JSON files
actor LocationRepository: Sendable {
    static let defaultDirectory: URL = {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("ShiftSchedulerData", isDirectory: true)
    }()

    private let fileManager = FileManager.default
    private let directoryURL: URL
    private let fileName = "locations.json"

    init(directoryURL: URL? = nil) {
        self.directoryURL = directoryURL ?? Self.defaultDirectory
    }

    /// Ensure the directory exists
    private func ensureDirectory() throws {
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }

    /// Fetch all locations
    func fetchAll() async throws -> [Location] {
        try ensureDirectory()
        let fileURL = directoryURL.appendingPathComponent(fileName)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return []
        }

        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode([Location].self, from: data)
    }

    /// Fetch a single location by ID
    func fetch(id: UUID) async throws -> Location? {
        let locations = try await fetchAll()
        return locations.first { $0.id == id }
    }

    /// Save a location (create or update)
    func save(_ location: Location) async throws {
        var locations = try await fetchAll()
        if let index = locations.firstIndex(where: { $0.id == location.id }) {
            locations[index] = location
        } else {
            locations.append(location)
        }
        try await saveAll(locations)
    }

    /// Delete a location
    func delete(id: UUID) async throws {
        var locations = try await fetchAll()
        locations.removeAll { $0.id == id }
        try await saveAll(locations)
    }

    /// Save all locations
    private func saveAll(_ locations: [Location]) async throws {
        try ensureDirectory()
        let fileURL = directoryURL.appendingPathComponent(fileName)
        let data = try JSONEncoder().encode(locations)
        try data.write(to: fileURL, options: .atomic)
    }
}
