import Foundation

// MARK: - Conflict Resolution Service Protocol

/// Service for resolving sync conflicts between local and remote data
protocol ConflictResolutionServiceProtocol: Sendable {
    /// Resolve a Location conflict using the configured strategy
    /// - Parameters:
    ///   - local: Local version of the location
    ///   - remote: Remote version from CloudKit
    /// - Returns: MergeResult with resolved location, conflict info, or error
    func resolveLocation(local: Location, remote: Location) async -> MergeResult<Location>

    /// Resolve a ShiftType conflict using the configured strategy
    /// - Parameters:
    ///   - local: Local version of the shift type
    ///   - remote: Remote version from CloudKit
    /// - Returns: MergeResult with resolved shift type, conflict info, or error
    func resolveShiftType(local: ShiftType, remote: ShiftType) async -> MergeResult<ShiftType>

    /// Get the current default conflict resolution strategy
    func getDefaultStrategy() async -> ConflictResolutionStrategy

    /// Set the default conflict resolution strategy
    /// - Parameter strategy: The strategy to use for future conflicts
    func setDefaultStrategy(_ strategy: ConflictResolutionStrategy) async

    /// Get all pending conflicts that require manual resolution
    /// - Returns: Array of unresolved conflicts
    func getPendingConflicts() async -> [PendingConflict]

    /// Manually resolve a specific pending conflict
    /// - Parameters:
    ///   - conflictId: ID of the conflict to resolve
    ///   - resolution: The chosen resolution (keepLocal, keepRemote, merge, or deferred)
    /// - Throws: SyncError if conflict not found or resolution fails
    func manuallyResolve(conflictId: UUID, with resolution: ConflictResolution) async throws

    /// Clear all pending conflicts (useful after batch resolution)
    func clearPendingConflicts() async
}

// MARK: - Supporting Types

/// Represents a pending conflict awaiting manual resolution
enum PendingConflict: Identifiable, Sendable, Equatable {
    case location(id: UUID, info: ConflictInfo<Location>)
    case shiftType(id: UUID, info: ConflictInfo<ShiftType>)

    nonisolated var id: UUID {
        switch self {
        case .location(let id, _):
            return id
        case .shiftType(let id, _):
            return id
        }
    }

    nonisolated var timestamp: Date {
        Date()
    }

    static func == (lhs: PendingConflict, rhs: PendingConflict) -> Bool {
        switch (lhs, rhs) {
        case (.location(let lid, let linfo), .location(let rid, let rinfo)):
            return lid == rid && linfo.local.id == rinfo.local.id && linfo.remote.id == rinfo.remote.id
        case (.shiftType(let lid, let linfo), .shiftType(let rid, let rinfo)):
            return lid == rid && linfo.local.id == rinfo.local.id && linfo.remote.id == rinfo.remote.id
        default:
            return false
        }
    }
}
