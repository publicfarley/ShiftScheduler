import Foundation
import OSLog

private let logger = Logger(subsystem: "com.shiftscheduler.redux.services", category: "PersistenceService")

/// Production implementation of PersistenceServiceProtocol
/// Manages all data persistence operations using repositories
final class PersistenceService: PersistenceServiceProtocol {
    private let shiftTypeRepository: ShiftTypeRepository
    private let locationRepository: LocationRepository
    private let changeLogRepository: ChangeLogRepository
    private let userProfileRepository: UserProfileRepository

    init(
        shiftTypeRepository: ShiftTypeRepository? = nil,
        locationRepository: LocationRepository? = nil,
        changeLogRepository: ChangeLogRepository? = nil,
        userProfileRepository: UserProfileRepository? = nil
    ) {
        self.shiftTypeRepository = shiftTypeRepository ?? ShiftTypeRepository()
        self.locationRepository = locationRepository ?? LocationRepository()
        self.changeLogRepository = changeLogRepository ?? ChangeLogRepository()
        self.userProfileRepository = userProfileRepository ?? UserProfileRepository()
    }

    // MARK: - Shift Types

    func loadShiftTypes() async throws -> [ShiftType] {
        // logger.debug("Loading shift types")
        let types = try await shiftTypeRepository.fetchAll()
        // logger.debug("Loaded \(types.count) shift types")
        return types
    }

    func saveShiftType(_ shiftType: ShiftType) async throws {
        // logger.debug("Saving shift type: \(shiftType.title)")
        try await shiftTypeRepository.save(shiftType)
    }

    func deleteShiftType(id: UUID) async throws {
        // logger.debug("Deleting shift type: \(id)")
        try await shiftTypeRepository.delete(id: id)
    }

    // MARK: - Locations

    func loadLocations() async throws -> [Location] {
        // logger.debug("Loading locations")
        let locations = try await locationRepository.fetchAll()
        // logger.debug("Loaded \(locations.count) locations")
        return locations
    }

    func saveLocation(_ location: Location) async throws {
        // logger.debug("Saving location: \(location.name)")
        try await locationRepository.save(location)
    }

    func deleteLocation(id: UUID) async throws {
        // logger.debug("Deleting location: \(id)")
        try await locationRepository.delete(id: id)
    }

    // MARK: - Change Log

    func loadChangeLogEntries() async throws -> [ChangeLogEntry] {
        // logger.debug("Loading change log entries")
        let entries = try await changeLogRepository.fetchAll()
        // logger.debug("Loaded \(entries.count) change log entries")
        return entries
    }

    func addChangeLogEntry(_ entry: ChangeLogEntry) async throws {
        // logger.debug("Adding change log entry: \(entry.id)")
        try await changeLogRepository.save(entry)
    }

    func deleteChangeLogEntry(id: UUID) async throws {
        // logger.debug("Deleting change log entry: \(id)")

        // Fetch all entries
        var entries = try await changeLogRepository.fetchAll()

        // Remove the entry with matching ID
        entries.removeAll { $0.id == id }

        // Clear all entries and re-save the filtered list
        try await changeLogRepository.deleteAll()
        for entry in entries {
            try await changeLogRepository.save(entry)
        }
    }

    func purgeOldChangeLogEntries(olderThan cutoffDate: Date) async throws -> Int {
        // logger.debug("Purging change log entries older than \(cutoffDate.formatted())")

        // Get count before deletion
        let beforeCount = try await changeLogRepository.fetchAll().count

        try await changeLogRepository.deleteEntriesOlderThan(cutoffDate)

        // Get count after deletion and calculate deleted count
        let afterCount = try await changeLogRepository.fetchAll().count
        let deletedCount = beforeCount - afterCount

        // logger.debug("Purged \(deletedCount) entries older than \(cutoffDate.formatted())")
        return deletedCount
    }

    // MARK: - Undo/Redo Stacks

    func loadUndoRedoStacks() async throws -> (undo: [ChangeLogEntry], redo: [ChangeLogEntry]) {
        // logger.debug("Loading undo/redo stacks")

        // For now, return empty stacks
        // TODO: Implement persistent undo/redo stack storage
        return ([], [])
    }

    func saveUndoRedoStacks(undo: [ChangeLogEntry], redo: [ChangeLogEntry]) async throws {
        // logger.debug("Saving undo/redo stacks: \(undo.count) undo, \(redo.count) redo")

        // TODO: Implement persistent undo/redo stack storage
    }

    // MARK: - User Profile

    func loadUserProfile() async throws -> UserProfile {
        logger.debug("Loading user profile")

        // Try to load from repository
        if let profile = try await userProfileRepository.fetch() {
            logger.debug("Loaded user profile from persistence: \(profile.displayName)")
            return profile
        }

        // Check for UserDefaults migration
        if let migratedProfile = try await migrateUserDefaultsToProfile() {
            logger.debug("Migrated user profile from UserDefaults")
            // Save migrated profile to JSON
            try await userProfileRepository.save(migratedProfile)
            // Clean up old UserDefaults
            UserDefaults.standard.removeObject(forKey: "displayName")
            UserDefaults.standard.removeObject(forKey: "autoPurgeEnabled")
            UserDefaults.standard.removeObject(forKey: "lastPurgeDate")
            return migratedProfile
        }

        // Return default profile for new users
        logger.debug("Creating default user profile")
        return UserProfile(userId: UUID(), displayName: "", retentionPolicy: .forever, autoPurgeEnabled: true)
    }

    func saveUserProfile(_ profile: UserProfile) async throws {
        logger.debug("Saving user profile: \(profile.displayName)")
        try await userProfileRepository.save(profile)
    }

    /// Migrate old UserDefaults data to UserProfile model
    private func migrateUserDefaultsToProfile() async throws -> UserProfile? {
        let displayName = UserDefaults.standard.string(forKey: "displayName") ?? ""
        let autoPurgeEnabled = UserDefaults.standard.object(forKey: "autoPurgeEnabled") as? Bool ?? true
        var lastPurgeDate: Date? = nil
        if let timestamp = UserDefaults.standard.object(forKey: "lastPurgeDate") as? TimeInterval {
            lastPurgeDate = Date(timeIntervalSince1970: timestamp)
        }

        // Only migrate if we have non-default data
        guard !displayName.isEmpty || !autoPurgeEnabled || lastPurgeDate != nil else {
            return nil
        }

        let userId = UUID()
        let retentionPolicy: ChangeLogRetentionPolicy = .forever

        return UserProfile(
            userId: userId,
            displayName: displayName,
            retentionPolicy: retentionPolicy,
            autoPurgeEnabled: autoPurgeEnabled,
            lastPurgeDate: lastPurgeDate
        )
    }
}
