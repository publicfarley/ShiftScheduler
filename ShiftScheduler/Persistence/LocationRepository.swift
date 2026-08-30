import Foundation
import OSLog

/// Actor-based repository for persisting locations to JSON files
/// with CloudKit sync for cross-account data sharing
actor LocationRepository: Sendable {
    private static let defaultDirectory: URL = {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("ShiftSchedulerData", isDirectory: true)
    }()

    private let logger = Logger(subsystem: "com.functioncraft.ShiftScheduler", category: "LocationRepository")
    private let fileManager = FileManager.default
    internal let directoryURL: URL
    private let fileName = "locations.json"
    private let cloudKitManager: CloudKitManager

    init(directoryURL: URL? = nil, cloudKitManager: CloudKitManager = CloudKitManager()) {
        self.directoryURL = directoryURL ?? Self.defaultDirectory
        self.cloudKitManager = cloudKitManager
    }

    /// Ensure the directory exists
    private func ensureDirectory() throws {
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }

    /// Fetch all locations (from local cache, syncing from CloudKit in background)
    func fetchAll() async throws -> [Location] {
        try ensureDirectory()

        // 1. Load from local JSON cache first (fast, doesn't block UI)
        let localLocations = try fetchLocal()

        // 2. Try to sync from CloudKit in background (don't block on failure)
        Task {
            await syncFromCloudKit()
        }

        return localLocations
    }

    /// Fetch from local JSON cache only
    private func fetchLocal() throws -> [Location] {
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
        // Load from local cache (not full sync)
        var locations = try fetchLocal()
        if let index = locations.firstIndex(where: { $0.id == location.id }) {
            locations[index] = location
        } else {
            locations.append(location)
        }

        // 1. Save to local JSON first (fast, reliable)
        try await saveLocal(locations)

        // 2. Sync to CloudKit (async, may fail if offline)
        Task {
            await syncOneToCloudKit(location)
        }
    }

    /// Delete a location
    func delete(id: UUID) async throws {
        var locations = try fetchLocal()
        locations.removeAll { $0.id == id }

        // 1. Delete from local JSON first
        try await saveLocal(locations)

        // 2. Delete from CloudKit
        Task {
            await deleteOneFromCloudKit(id)
        }
    }

    /// Save all locations to local JSON
    private func saveLocal(_ locations: [Location]) async throws {
        try ensureDirectory()
        let fileURL = directoryURL.appendingPathComponent(fileName)
        let data = try JSONEncoder().encode(locations)
        try data.write(to: fileURL, options: .atomic)
    }

    // MARK: - CloudKit Sync

    /// Sync a single location to CloudKit
    private func syncOneToCloudKit(_ location: Location) async {
        do {
            try await cloudKitManager.saveLocation(location)
            logger.debug("Synced Location to CloudKit: \(location.name)")
        } catch {
            logger.warning("Failed to sync Location to CloudKit (offline?): \(error.localizedDescription)")
        }
    }

    /// Delete a location from CloudKit
    private func deleteOneFromCloudKit(_ id: UUID) async {
        do {
            try await cloudKitManager.deleteLocation(id: id)
            logger.debug("Deleted Location from CloudKit: \(id)")
        } catch {
            logger.warning("Failed to delete Location from CloudKit (offline?): \(error.localizedDescription)")
        }
    }

    /// Merge CloudKit results into the local cache **without destroying local-only data.**
    ///
    /// A remote empty result (no records for this iCloud account, decode failure,
    /// throttling) must never clear a populated local cache — that wipes the user's
    /// locations and breaks every calendar event that references them (see
    /// DATA_LOSS_INCIDENT_REPORT.md). Union by id instead.
    private func mergeFromCloud(_ cloudLocations: [Location]) async throws {
        let local = try fetchLocal()

        guard !cloudLocations.isEmpty else {
            if !local.isEmpty {
                logger.warning("CloudKit returned 0 Locations but local cache has \(local.count); keeping local data")
            }
            return
        }

        var merged: [UUID: Location] = Dictionary(local.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        for location in cloudLocations {
            merged[location.id] = location
        }

        let mergedList = Array(merged.values).sorted { $0.name < $1.name }
        let localSorted = local.sorted { $0.name < $1.name }
        let encoder = JSONEncoder()
        if let a = try? encoder.encode(mergedList), let b = try? encoder.encode(localSorted), a == b {
            logger.debug("CloudKit sync produced no changes for Locations")
            return
        }

        try await saveLocal(mergedList)
        logger.debug("Merged \(cloudLocations.count) CloudKit Locations into local cache (now \(mergedList.count))")
    }

    /// Sync all locations from CloudKit to local cache
    private func syncFromCloudKit() async {
        do {
            let cloudLocations = try await cloudKitManager.fetchAllLocations()
            try await mergeFromCloud(cloudLocations)
        } catch let error as CloudKitManager.CloudKitError {
            if case .fetchFailed(let message) = error, message.contains("schema not configured") {
                // First-time setup - try to initialize schema in development
                logger.warning("Attempting automatic schema initialization...")
                do {
                    try await cloudKitManager.initializeSchemaIfNeeded()
                    // Retry fetch after initialization
                    let cloudLocations = try await cloudKitManager.fetchAllLocations()
                    try await mergeFromCloud(cloudLocations)
                    logger.debug("✅ Schema initialized and synced successfully")
                } catch {
                    logger.error("Schema initialization failed: \(error.localizedDescription)")
                    logger.error("📚 Manual setup required - see CLOUDKIT_SETUP.md")
                }
            } else {
                logger.warning("Failed to sync Locations from CloudKit (offline?): \(error.localizedDescription)")
            }
        } catch {
            logger.warning("Failed to sync Locations from CloudKit (offline?): \(error.localizedDescription)")
        }
    }
}
