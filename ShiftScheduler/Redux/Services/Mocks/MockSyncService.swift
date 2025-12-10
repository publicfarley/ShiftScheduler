import Foundation

/// Mock implementation of SyncServiceProtocol for testing
actor MockSyncService: SyncServiceProtocol {
    // MARK: - Configuration

    var isCloudKitAvailable: Bool = true
    var shouldThrowError: Bool = false
    var simulatedSyncStatus: SyncStatus = .synced

    // MARK: - Test State

    private(set) var uploadCallCount = 0
    private(set) var downloadCallCount = 0
    private(set) var fullSyncCallCount = 0
    private(set) var resolvedConflictIds: [UUID] = []

    private var pendingConflicts: [PendingConflict] = []

    // MARK: - SyncServiceProtocol Implementation

    func isAvailable() async -> Bool {
        return isCloudKitAvailable
    }

    func uploadPendingChanges() async throws {
        if shouldThrowError {
            throw SyncError.uploadFailed("Mock upload error")
        }
        uploadCallCount += 1
    }

    func downloadRemoteChanges() async throws {
        if shouldThrowError {
            throw SyncError.downloadFailed("Mock download error")
        }
        downloadCallCount += 1
    }

    func resolveConflict(id: UUID, resolution: ConflictResolution) async throws {
        if shouldThrowError {
            throw SyncError.conflictResolutionFailed("Mock conflict resolution error")
        }
        resolvedConflictIds.append(id)
        pendingConflicts.removeAll { $0.id == id }
    }

    func getSyncStatus() async -> SyncStatus {
        return simulatedSyncStatus
    }

    func performFullSync() async throws {
        if shouldThrowError {
            throw SyncError.networkUnavailable
        }
        fullSyncCallCount += 1
        try await uploadPendingChanges()
        try await downloadRemoteChanges()
    }

    func getPendingConflicts() async -> [PendingConflict] {
        return pendingConflicts
    }

    func resetSyncState() async throws {
        if shouldThrowError {
            throw SyncError.unknown("Mock reset error")
        }
        uploadCallCount = 0
        downloadCallCount = 0
        fullSyncCallCount = 0
        resolvedConflictIds.removeAll()
        pendingConflicts.removeAll()
        simulatedSyncStatus = .notConfigured
    }

    // MARK: - Test Helpers

    func addPendingConflict(_ conflict: PendingConflict) {
        pendingConflicts.append(conflict)
    }

    func reset() {
        uploadCallCount = 0
        downloadCallCount = 0
        fullSyncCallCount = 0
        resolvedConflictIds.removeAll()
        pendingConflicts.removeAll()
        isCloudKitAvailable = true
        shouldThrowError = false
        simulatedSyncStatus = .synced
    }
}
