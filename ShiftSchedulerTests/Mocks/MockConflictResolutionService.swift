import Foundation
@testable import ShiftScheduler

/// Mock conflict resolution service for testing
actor MockConflictResolutionService: ConflictResolutionServiceProtocol {
    // MARK: - Mock Configuration

    var mockDefaultStrategy: ConflictResolutionStrategy = .automaticMerge
    var mockPendingConflicts: [PendingConflict] = []
    var mockLocationMergeResult: MergeResult<Location>?
    var mockShiftTypeMergeResult: MergeResult<ShiftType>?

    // MARK: - Call Tracking

    var resolveLocationCallCount = 0
    var resolveShiftTypeCallCount = 0
    var getDefaultStrategyCallCount = 0
    var setDefaultStrategyCallCount = 0
    var getPendingConflictsCallCount = 0
    var manuallyResolveCallCount = 0
    var clearPendingConflictsCallCount = 0

    var lastResolvedConflictId: UUID?
    var lastConflictResolution: ConflictResolution?
    var lastSetStrategy: ConflictResolutionStrategy?

    // MARK: - Error Configuration

    var shouldThrowError = false
    var throwError: Error = SyncError.conflictResolutionFailed("Mock error")

    // MARK: - Protocol Implementation

    func resolveLocation(local: Location, remote: Location) async -> MergeResult<Location> {
        resolveLocationCallCount += 1

        if let mockResult = mockLocationMergeResult {
            return mockResult
        }

        // Default: return remote version as success
        return .success(remote)
    }

    func resolveShiftType(local: ShiftType, remote: ShiftType) async -> MergeResult<ShiftType> {
        resolveShiftTypeCallCount += 1

        if let mockResult = mockShiftTypeMergeResult {
            return mockResult
        }

        // Default: return remote version as success
        return .success(remote)
    }

    func getDefaultStrategy() async -> ConflictResolutionStrategy {
        getDefaultStrategyCallCount += 1
        return mockDefaultStrategy
    }

    func setDefaultStrategy(_ strategy: ConflictResolutionStrategy) async {
        setDefaultStrategyCallCount += 1
        lastSetStrategy = strategy
        mockDefaultStrategy = strategy
    }

    func getPendingConflicts() async -> [PendingConflict] {
        getPendingConflictsCallCount += 1
        return mockPendingConflicts
    }

    func manuallyResolve(conflictId: UUID, with resolution: ConflictResolution) async throws {
        manuallyResolveCallCount += 1
        lastResolvedConflictId = conflictId
        lastConflictResolution = resolution

        if shouldThrowError {
            throw throwError
        }

        // Remove from pending conflicts
        mockPendingConflicts.removeAll { $0.id == conflictId }
    }

    func clearPendingConflicts() async {
        clearPendingConflictsCallCount += 1
        mockPendingConflicts.removeAll()
    }

    // MARK: - Test Helpers

    func reset() {
        resolveLocationCallCount = 0
        resolveShiftTypeCallCount = 0
        getDefaultStrategyCallCount = 0
        setDefaultStrategyCallCount = 0
        getPendingConflictsCallCount = 0
        manuallyResolveCallCount = 0
        clearPendingConflictsCallCount = 0
        lastResolvedConflictId = nil
        lastConflictResolution = nil
        lastSetStrategy = nil
        mockDefaultStrategy = .automaticMerge
        mockPendingConflicts = []
        mockLocationMergeResult = nil
        mockShiftTypeMergeResult = nil
        shouldThrowError = false
    }
}
