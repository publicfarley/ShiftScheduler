import Foundation

/// Production implementation of conflict resolution service
actor ConflictResolutionService: ConflictResolutionServiceProtocol {
    // MARK: - Properties

    private var defaultStrategy: ConflictResolutionStrategy
    private var pendingConflicts: [PendingConflict]

    // Mergers for each entity type
    private let locationMerger: LocationMerger
    private let shiftTypeMerger: ShiftTypeMerger

    // MARK: - Initialization

    init(defaultStrategy: ConflictResolutionStrategy = .automaticMerge) {
        self.defaultStrategy = defaultStrategy
        self.pendingConflicts = []
        self.locationMerger = LocationMerger()
        self.shiftTypeMerger = ShiftTypeMerger()
    }

    // MARK: - Conflict Resolution

    func resolveLocation(local: Location, remote: Location) async -> MergeResult<Location> {
        let result = await locationMerger.merge(
            local: local,
            remote: remote,
            strategy: defaultStrategy
        )

        // Store conflict if manual resolution required
        if case .conflict(let info) = result {
            let pendingConflict = PendingConflict.location(
                id: UUID(),
                info: info
            )
            pendingConflicts.append(pendingConflict)
        }

        return result
    }

    func resolveShiftType(local: ShiftType, remote: ShiftType) async -> MergeResult<ShiftType> {
        let result = await shiftTypeMerger.merge(
            local: local,
            remote: remote,
            strategy: defaultStrategy
        )

        // Store conflict if manual resolution required
        if case .conflict(let info) = result {
            let pendingConflict = PendingConflict.shiftType(
                id: UUID(),
                info: info
            )
            pendingConflicts.append(pendingConflict)
        }

        return result
    }

    // MARK: - Strategy Management

    func getDefaultStrategy() async -> ConflictResolutionStrategy {
        defaultStrategy
    }

    func setDefaultStrategy(_ strategy: ConflictResolutionStrategy) async {
        defaultStrategy = strategy
    }

    // MARK: - Pending Conflicts Management

    func getPendingConflicts() async -> [PendingConflict] {
        pendingConflicts
    }

    func manuallyResolve(conflictId: UUID, with resolution: ConflictResolution) async throws {
        guard let index = pendingConflicts.firstIndex(where: { $0.id == conflictId }) else {
            throw SyncError.conflictResolutionFailed("Conflict with ID \(conflictId) not found")
        }

        // Handle resolution based on user choice
        switch resolution {
        case .keepLocal, .keepRemote, .merge:
            // Valid resolutions - remove from pending
            pendingConflicts.remove(at: index)

        case .deferred:
            // Keep in pending for later resolution
            break
        }
    }

    func clearPendingConflicts() async {
        pendingConflicts.removeAll()
    }
}
