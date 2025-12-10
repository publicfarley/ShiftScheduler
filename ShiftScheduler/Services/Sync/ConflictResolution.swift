import Foundation

// MARK: - Conflict Resolution Types

/// Strategy for resolving conflicts between local and remote versions
enum ConflictResolutionStrategy: Sendable {
    /// Automatically merge non-conflicting changes
    case automaticMerge
    /// Always prefer local version
    case localWins
    /// Always prefer remote version
    case remoteWins
    /// Require manual user resolution
    case manual
}

/// Type of conflict detected during merge
enum ConflictType: Sendable, Equatable {
    /// No conflict - only one side changed
    case noConflict
    /// Both sides changed different fields - can auto-merge
    case autoMergeable
    /// Both sides changed same field - requires manual resolution
    case requiresManualResolution(conflictingFields: [String])
}

/// Result of a three-way merge operation
enum MergeResult<T: Sendable>: Sendable {
    /// Merge succeeded with resolved value
    case success(T)
    /// Conflict detected, requires manual resolution
    case conflict(ConflictInfo<T>)
    /// Merge failed with error
    case failure(Error)
}

/// Information about a detected conflict
struct ConflictInfo<T: Sendable>: Sendable {
    let local: T
    let remote: T
    let conflictType: ConflictType
    let conflictingFields: [String]
}

// MARK: - Three-Way Merger Protocol

/// Protocol for implementing three-way merge logic
protocol ThreeWayMerger: Sendable {
    associatedtype T: Sendable

    /// Performs three-way merge between local and remote versions
    /// - Parameters:
    ///   - local: Current local version
    ///   - remote: Current remote version
    ///   - strategy: Strategy to use for conflict resolution
    /// - Returns: Result of the merge operation
    func merge(local: T, remote: T, strategy: ConflictResolutionStrategy) async -> MergeResult<T>

    /// Detects conflicts between local and remote versions
    /// - Parameters:
    ///   - local: Current local version
    ///   - remote: Current remote version
    /// - Returns: Type of conflict detected
    func detectConflict(local: T, remote: T) -> ConflictType
}

// MARK: - Location Merger

/// Three-way merger implementation for Location
struct LocationMerger: ThreeWayMerger {
    typealias T = Location

    func merge(local: Location, remote: Location, strategy: ConflictResolutionStrategy) async -> MergeResult<Location> {
        // Same ID check
        guard local.id == remote.id else {
            return .failure(SyncError.invalidMerge("Cannot merge locations with different IDs"))
        }

        let conflictType = detectConflict(local: local, remote: remote)

        switch (conflictType, strategy) {
        case (.noConflict, _):
            // No conflict - use whichever version was modified more recently
            if let localSync = local.lastSyncedAt, let remoteSync = remote.lastSyncedAt {
                return .success(localSync > remoteSync ? local : remote)
            }
            return .success(remote) // Default to remote if no sync timestamps

        case (.autoMergeable, .automaticMerge):
            // Auto-merge non-conflicting changes
            let merged = performAutoMerge(local: local, remote: remote)
            return .success(merged)

        case (_, .localWins):
            return .success(local)

        case (_, .remoteWins):
            return .success(remote)

        case (.requiresManualResolution(let fields), _):
            let conflictInfo = ConflictInfo(
                local: local,
                remote: remote,
                conflictType: conflictType,
                conflictingFields: fields
            )
            return .conflict(conflictInfo)

        case (.autoMergeable, .manual):
            // Even auto-mergeable conflicts require manual resolution with manual strategy
            let conflictInfo = ConflictInfo(
                local: local,
                remote: remote,
                conflictType: conflictType,
                conflictingFields: getConflictingFields(local: local, remote: remote)
            )
            return .conflict(conflictInfo)
        }
    }

    func detectConflict(local: Location, remote: Location) -> ConflictType {
        var conflictingFields: [String] = []

        // Check each field for conflicts
        if local.name != remote.name {
            conflictingFields.append("name")
        }

        if local.address != remote.address {
            conflictingFields.append("address")
        }

        if conflictingFields.isEmpty {
            return .noConflict
        }

        // For simplicity, treat any field change as requiring manual resolution
        // In a more sophisticated implementation, we could auto-merge some field combinations
        return .requiresManualResolution(conflictingFields: conflictingFields)
    }

    // MARK: - Private Helpers

    private func performAutoMerge(local: Location, remote: Location) -> Location {
        // For now, prefer remote changes
        // In future, could implement field-level merging
        return remote
    }

    private func getConflictingFields(local: Location, remote: Location) -> [String] {
        var fields: [String] = []
        if local.name != remote.name { fields.append("name") }
        if local.address != remote.address { fields.append("address") }
        return fields
    }
}

// MARK: - ShiftType Merger

/// Three-way merger implementation for ShiftType
struct ShiftTypeMerger: ThreeWayMerger {
    typealias T = ShiftType

    func merge(local: ShiftType, remote: ShiftType, strategy: ConflictResolutionStrategy) async -> MergeResult<ShiftType> {
        // Same ID check
        guard local.id == remote.id else {
            return .failure(SyncError.invalidMerge("Cannot merge shift types with different IDs"))
        }

        let conflictType = detectConflict(local: local, remote: remote)

        switch (conflictType, strategy) {
        case (.noConflict, _):
            // No conflict - use whichever version was modified more recently
            if let localSync = local.lastSyncedAt, let remoteSync = remote.lastSyncedAt {
                return .success(localSync > remoteSync ? local : remote)
            }
            return .success(remote) // Default to remote if no sync timestamps

        case (.autoMergeable, .automaticMerge):
            // Auto-merge non-conflicting changes
            let merged = performAutoMerge(local: local, remote: remote)
            return .success(merged)

        case (_, .localWins):
            return .success(local)

        case (_, .remoteWins):
            return .success(remote)

        case (.requiresManualResolution(let fields), _):
            let conflictInfo = ConflictInfo(
                local: local,
                remote: remote,
                conflictType: conflictType,
                conflictingFields: fields
            )
            return .conflict(conflictInfo)

        case (.autoMergeable, .manual):
            // Even auto-mergeable conflicts require manual resolution with manual strategy
            let conflictInfo = ConflictInfo(
                local: local,
                remote: remote,
                conflictType: conflictType,
                conflictingFields: getConflictingFields(local: local, remote: remote)
            )
            return .conflict(conflictInfo)
        }
    }

    func detectConflict(local: ShiftType, remote: ShiftType) -> ConflictType {
        var conflictingFields: [String] = []

        // Check each field for conflicts
        if local.symbol != remote.symbol {
            conflictingFields.append("symbol")
        }

        if local.title != remote.title {
            conflictingFields.append("title")
        }

        if local.shiftDescription != remote.shiftDescription {
            conflictingFields.append("description")
        }

        if local.duration != remote.duration {
            conflictingFields.append("duration")
        }

        if local.location != remote.location {
            conflictingFields.append("location")
        }

        if conflictingFields.isEmpty {
            return .noConflict
        }

        // For simplicity, treat any field change as requiring manual resolution
        return .requiresManualResolution(conflictingFields: conflictingFields)
    }

    // MARK: - Private Helpers

    private func performAutoMerge(local: ShiftType, remote: ShiftType) -> ShiftType {
        // For now, prefer remote changes
        // In future, could implement field-level merging
        return remote
    }

    private func getConflictingFields(local: ShiftType, remote: ShiftType) -> [String] {
        var fields: [String] = []
        if local.symbol != remote.symbol { fields.append("symbol") }
        if local.title != remote.title { fields.append("title") }
        if local.shiftDescription != remote.shiftDescription { fields.append("description") }
        if local.duration != remote.duration { fields.append("duration") }
        if local.location != remote.location { fields.append("location") }
        return fields
    }
}

// MARK: - Sync Error Extension

extension SyncError {
    static func invalidMerge(_ message: String) -> SyncError {
        .conflictResolutionFailed(message)
    }
}
