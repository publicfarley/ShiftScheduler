import Foundation

/// Actor-based repository for persisting shift types to JSON files
actor ShiftTypeRepository: Sendable {
    private static let defaultDirectory: URL = {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("ShiftSchedulerData", isDirectory: true)
    }()

    private let fileManager = FileManager.default
    internal let directoryURL: URL
    private let fileName = "shiftTypes.json"

    init(directoryURL: URL? = nil) {
        self.directoryURL = directoryURL ?? Self.defaultDirectory
    }

    /// Ensure the directory exists
    private func ensureDirectory() throws {
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }

    /// Fetch all shift types
    func fetchAll() async throws -> [ShiftType] {
        try ensureDirectory()
        let fileURL = directoryURL.appendingPathComponent(fileName)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return []
        }

        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode([ShiftType].self, from: data)
    }

    /// Fetch a single shift type by ID
    func fetch(id: UUID) async throws -> ShiftType? {
        let shiftTypes = try await fetchAll()
        return shiftTypes.first { $0.id == id }
    }

    /// Save a shift type (create or update)
    func save(_ shiftType: ShiftType) async throws {
        var shiftTypes = try await fetchAll()
        if let index = shiftTypes.firstIndex(where: { $0.id == shiftType.id }) {
            shiftTypes[index] = shiftType
        } else {
            shiftTypes.append(shiftType)
        }
        try await saveAll(shiftTypes)
    }

    /// Delete a shift type
    func delete(id: UUID) async throws {
        var shiftTypes = try await fetchAll()
        shiftTypes.removeAll { $0.id == id }
        try await saveAll(shiftTypes)
    }

    /// Save all shift types
    private func saveAll(_ shiftTypes: [ShiftType]) async throws {
        try ensureDirectory()
        let fileURL = directoryURL.appendingPathComponent(fileName)
        let data = try JSONEncoder().encode(shiftTypes)
        try data.write(to: fileURL, options: .atomic)
    }
}
