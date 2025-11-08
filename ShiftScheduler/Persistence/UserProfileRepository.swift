import Foundation

/// Actor-based repository for persisting user profile to JSON file
actor UserProfileRepository: Sendable {
    private static let defaultDirectory: URL = {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("ShiftSchedulerData", isDirectory: true)
    }()

    private let fileManager = FileManager.default
    internal let directoryURL: URL
    private let fileName = "userProfile.json"

    init(directoryURL: URL? = nil) {
        self.directoryURL = directoryURL ?? Self.defaultDirectory
    }

    /// Ensure the directory exists
    private func ensureDirectory() throws {
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }

    /// Fetch user profile
    func fetch() async throws -> UserProfile? {
        try ensureDirectory()
        let fileURL = directoryURL.appendingPathComponent(fileName)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        let data = try Data(contentsOf: fileURL)
        return try await MainActor.run {
            try JSONDecoder().decode(UserProfile.self, from: data)
        }
    }

    /// Save user profile
    func save(_ profile: UserProfile) async throws {
        try ensureDirectory()
        let fileURL = directoryURL.appendingPathComponent(fileName)
        let data = try await MainActor.run {
            try JSONEncoder().encode(profile)
        }
        try data.write(to: fileURL, options: .atomic)
    }
}
