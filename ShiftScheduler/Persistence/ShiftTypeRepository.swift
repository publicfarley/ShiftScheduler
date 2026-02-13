import Foundation
import OSLog

/// Actor-based repository for persisting shift types to JSON files
/// with CloudKit sync for cross-account data sharing
actor ShiftTypeRepository: Sendable {
    private static let defaultDirectory: URL = {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("ShiftSchedulerData", isDirectory: true)
    }()

    private let logger = Logger(subsystem: "com.functioncraft.ShiftScheduler", category: "ShiftTypeRepository")
    private let fileManager = FileManager.default
    internal let directoryURL: URL
    private let fileName = "shiftTypes.json"
    private let cloudKitManager: CloudKitManager

    init(directoryURL: URL? = nil, cloudKitManager: CloudKitManager = CloudKitManager()) {
        self.directoryURL = directoryURL ?? Self.defaultDirectory
        self.cloudKitManager = cloudKitManager
    }

    /// Ensure the directory exists
    private func ensureDirectory() throws {
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }

    /// Fetch all shift types (from local cache, syncing from CloudKit in background)
    func fetchAll() async throws -> [ShiftType] {
        try ensureDirectory()

        // 1. Load from local JSON cache first (fast, doesn't block UI)
        let localShiftTypes = try fetchLocal()

        // 2. Try to sync from CloudKit in background (don't block on failure)
        Task {
            await syncFromCloudKit()
        }

        return localShiftTypes
    }

    /// Fetch from local JSON cache only
    private func fetchLocal() throws -> [ShiftType] {
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
        // Load from local cache (not full sync)
        var shiftTypes = try fetchLocal()
        if let index = shiftTypes.firstIndex(where: { $0.id == shiftType.id }) {
            shiftTypes[index] = shiftType
        } else {
            shiftTypes.append(shiftType)
        }

        // 1. Save to local JSON first (fast, reliable)
        try await saveLocal(shiftTypes)

        // 2. Sync to CloudKit (async, may fail if offline)
        Task {
            await syncOneToCloudKit(shiftType)
        }
    }

    /// Delete a shift type
    func delete(id: UUID) async throws {
        var shiftTypes = try fetchLocal()
        shiftTypes.removeAll { $0.id == id }

        // 1. Delete from local JSON first
        try await saveLocal(shiftTypes)

        // 2. Delete from CloudKit
        Task {
            await deleteOneFromCloudKit(id)
        }
    }

    /// Save all shift types to local JSON
    private func saveLocal(_ shiftTypes: [ShiftType]) async throws {
        try ensureDirectory()
        let fileURL = directoryURL.appendingPathComponent(fileName)
        let data = try JSONEncoder().encode(shiftTypes)
        try data.write(to: fileURL, options: .atomic)
    }

    // MARK: - CloudKit Sync

    /// Sync a single shift type to CloudKit
    private func syncOneToCloudKit(_ shiftType: ShiftType) async {
        do {
            try await cloudKitManager.saveShiftType(shiftType)
            logger.debug("Synced ShiftType to CloudKit: \(shiftType.title)")
        } catch {
            logger.warning("Failed to sync ShiftType to CloudKit (offline?): \(error.localizedDescription)")
        }
    }

    /// Delete a shift type from CloudKit
    private func deleteOneFromCloudKit(_ id: UUID) async {
        do {
            try await cloudKitManager.deleteShiftType(id: id)
            logger.debug("Deleted ShiftType from CloudKit: \(id)")
        } catch {
            logger.warning("Failed to delete ShiftType from CloudKit (offline?): \(error.localizedDescription)")
        }
    }

    /// Sync all shift types from CloudKit to local cache
    private func syncFromCloudKit() async {
        do {
            let cloudShiftTypes = try await cloudKitManager.fetchAllShiftTypes()

            // Merge strategy: CloudKit wins for conflicts (last-write-wins)
            // In production, compare modifiedAt timestamps for proper conflict resolution
            try await saveLocal(cloudShiftTypes)
            logger.debug("Synced \(cloudShiftTypes.count) ShiftTypes from CloudKit to local cache")
        } catch {
            logger.warning("Failed to sync ShiftTypes from CloudKit (offline?): \(error.localizedDescription)")
        }
    }
}
