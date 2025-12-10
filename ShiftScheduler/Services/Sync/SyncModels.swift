import Foundation

// MARK: - Sync Status

/// Represents the current synchronization status of the application
enum SyncStatus: Equatable, Sendable {
    /// Sync is not configured (e.g., user not signed into iCloud)
    case notConfigured

    /// All data is synchronized
    case synced

    /// Currently synchronizing data
    case syncing

    /// An error occurred during sync
    case error(String)

    /// Device is offline, sync will resume when online
    case offline
}

// MARK: - Conflict Entity Types

/// Types of entities that can have sync conflicts
enum ConflictEntityType: String, Equatable, Sendable, Codable {
    case location
    case shiftType
    case changeLogEntry
}

// MARK: - Conflict Version

/// Represents a version of an entity in a conflict scenario
struct ConflictVersion: Equatable, Sendable, Identifiable {
    let id: UUID
    let entityId: String
    let entityType: ConflictEntityType
    let data: [String: String] // Simplified representation of entity data
    let modificationDate: Date
    let deviceName: String? // Name of device that made the change

    nonisolated init(
        id: UUID = UUID(),
        entityId: String,
        entityType: ConflictEntityType,
        data: [String: String],
        modificationDate: Date,
        deviceName: String? = nil
    ) {
        self.id = id
        self.entityId = entityId
        self.entityType = entityType
        self.data = data
        self.modificationDate = modificationDate
        self.deviceName = deviceName
    }
}

// MARK: - Sync Conflict

/// Represents a synchronization conflict that requires resolution
struct SyncConflict: Equatable, Sendable, Identifiable {
    let id: UUID
    let entityType: ConflictEntityType

    /// The version currently on this device
    let localVersion: ConflictVersion

    /// The version from the remote server (CloudKit)
    let remoteVersion: ConflictVersion

    /// The common ancestor version (if available) for three-way merge
    let commonAncestor: ConflictVersion?

    /// When the conflict was detected
    let detectedAt: Date

    nonisolated init(
        id: UUID = UUID(),
        entityType: ConflictEntityType,
        localVersion: ConflictVersion,
        remoteVersion: ConflictVersion,
        commonAncestor: ConflictVersion? = nil,
        detectedAt: Date = Date()
    ) {
        self.id = id
        self.entityType = entityType
        self.localVersion = localVersion
        self.remoteVersion = remoteVersion
        self.commonAncestor = commonAncestor
        self.detectedAt = detectedAt
    }
}

// MARK: - Conflict Resolution

/// User's choice for resolving a sync conflict
enum ConflictResolution: Equatable, Sendable {
    /// Keep the local version and discard remote changes
    case keepLocal

    /// Keep the remote version and discard local changes
    case keepRemote

    /// Attempt automatic three-way merge
    case merge

    /// User will manually resolve (deferred)
    case deferred
}

// MARK: - Sync Metadata

/// Metadata for tracking synchronization state
struct SyncMetadata: Equatable, Sendable, Codable {
    /// Last successful sync timestamp
    let lastSyncDate: Date?

    /// CloudKit change token for incremental sync
    let changeToken: Data?

    /// Number of pending uploads
    let pendingUploadCount: Int

    /// Number of pending downloads
    let pendingDownloadCount: Int

    /// Current sync status
    var status: SyncStatusValue

    nonisolated init(
        lastSyncDate: Date? = nil,
        changeToken: Data? = nil,
        pendingUploadCount: Int = 0,
        pendingDownloadCount: Int = 0,
        status: SyncStatusValue = .notConfigured
    ) {
        self.lastSyncDate = lastSyncDate
        self.changeToken = changeToken
        self.pendingUploadCount = pendingUploadCount
        self.pendingDownloadCount = pendingDownloadCount
        self.status = status
    }
}

// MARK: - Sync Status Value (Codable)

/// Codable representation of SyncStatus for persistence
enum SyncStatusValue: String, Equatable, Sendable, Codable {
    case notConfigured
    case synced
    case syncing
    case error
    case offline
}

// MARK: - Extensions

extension SyncStatus {
    /// Convert to codable value
    var codableValue: SyncStatusValue {
        switch self {
        case .notConfigured: return .notConfigured
        case .synced: return .synced
        case .syncing: return .syncing
        case .error: return .error
        case .offline: return .offline
        }
    }

    /// Initialize from codable value
    static func from(_ value: SyncStatusValue, errorMessage: String? = nil) -> SyncStatus {
        switch value {
        case .notConfigured: return .notConfigured
        case .synced: return .synced
        case .syncing: return .syncing
        case .error: return .error(errorMessage ?? "Unknown error")
        case .offline: return .offline
        }
    }
}
