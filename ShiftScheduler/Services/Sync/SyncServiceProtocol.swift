import Foundation

/// Protocol defining synchronization service operations for CloudKit sync
protocol SyncServiceProtocol: Sendable {
    /// Check if CloudKit sync is available
    /// - Returns: `true` if iCloud account is available and CloudKit is accessible
    func isAvailable() async -> Bool

    /// Upload pending local changes to CloudKit
    /// - Throws: `SyncError` if upload fails
    func uploadPendingChanges() async throws

    /// Download and apply remote changes from CloudKit
    /// - Throws: `SyncError` if download fails
    func downloadRemoteChanges() async throws

    /// Resolve a synchronization conflict
    /// - Parameters:
    ///   - id: The ID of the conflict to resolve
    ///   - resolution: User's chosen resolution strategy
    /// - Throws: `SyncError` if resolution fails
    func resolveConflict(id: UUID, resolution: ConflictResolution) async throws

    /// Get the current synchronization status
    /// - Returns: Current `SyncStatus`
    func getSyncStatus() async -> SyncStatus

    /// Perform a complete synchronization (upload + download)
    /// - Throws: `SyncError` if sync fails
    func performFullSync() async throws

    /// Get any pending conflicts that need resolution
    /// - Returns: Array of unresolved conflicts
    func getPendingConflicts() async -> [PendingConflict]

    /// Clear the sync change token (force full sync on next operation)
    func resetSyncState() async throws
}

// MARK: - Sync Errors

/// Errors that can occur during synchronization
enum SyncError: Error, Equatable, Sendable {
    /// iCloud account is not available
    case iCloudUnavailable

    /// CloudKit container is not accessible
    case containerUnavailable

    /// Network connection is unavailable
    case networkUnavailable

    /// Conflict resolution failed
    case conflictResolutionFailed(String)

    /// Upload operation failed
    case uploadFailed(String)

    /// Download operation failed
    case downloadFailed(String)

    /// Record not found in CloudKit
    case recordNotFound(String)

    /// Quota exceeded
    case quotaExceeded

    /// Unknown error occurred
    case unknown(String)
}

// MARK: - Sync Error Description

extension SyncError: CustomStringConvertible {
    var description: String {
        switch self {
        case .iCloudUnavailable:
            return "iCloud account is not available. Please sign in to iCloud in Settings."
        case .containerUnavailable:
            return "CloudKit container is not accessible. Please check your iCloud settings."
        case .networkUnavailable:
            return "Network connection is unavailable. Please check your internet connection."
        case .conflictResolutionFailed(let message):
            return "Failed to resolve conflict: \(message)"
        case .uploadFailed(let message):
            return "Upload failed: \(message)"
        case .downloadFailed(let message):
            return "Download failed: \(message)"
        case .recordNotFound(let recordId):
            return "Record not found: \(recordId)"
        case .quotaExceeded:
            return "iCloud storage quota exceeded. Please free up space in iCloud."
        case .unknown(let message):
            return "Unknown sync error: \(message)"
        }
    }
}
