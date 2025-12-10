import Foundation
import OSLog

private nonisolated let logger = Logger(subsystem: "com.shiftscheduler.redux", category: "SyncMiddleware")

/// Middleware that intercepts data changes and triggers CloudKit synchronization
/// Handles bidirectional sync for Locations and ShiftTypes
func syncMiddleware(
    state: AppState,
    action: AppAction,
    services: ServiceContainer,
    dispatch: @escaping Dispatcher<AppAction>
) async {
    // Check if sync is available before proceeding
    let isAvailable = await services.syncService.isAvailable()

    switch action {
    // MARK: - Sync Actions

    case .sync(.checkAvailability):
        await dispatch(.sync(.availabilityChecked(isAvailable)))

    case .sync(.performFullSync):
        await performFullSync(services: services, dispatch: dispatch)

    case .sync(.uploadChanges):
        await uploadPendingChanges(services: services, dispatch: dispatch)

    case .sync(.downloadChanges):
        await downloadRemoteChanges(services: services, dispatch: dispatch)

    case .sync(.resolveConflict(let conflictId, let resolution)):
        await resolveConflict(conflictId: conflictId, resolution: resolution, services: services, dispatch: dispatch)

    case .sync(.resetSyncState):
        await resetSync(services: services, dispatch: dispatch)

    // MARK: - Location Changes

    case .locations(.saveLocation):
        // After save, upload to CloudKit
        if isAvailable {
            await uploadPendingChanges(services: services, dispatch: dispatch)
        }

    case .locations(.deleteLocation):
        // After delete, sync deletion to CloudKit
        if isAvailable {
            await uploadPendingChanges(services: services, dispatch: dispatch)
        }

    // MARK: - ShiftType Changes

    case .shiftTypes(.saveShiftType):
        // After save, upload to CloudKit
        if isAvailable {
            await uploadPendingChanges(services: services, dispatch: dispatch)
        }

    case .shiftTypes(.deleteShiftType):
        // After delete, sync deletion to CloudKit
        if isAvailable {
            await uploadPendingChanges(services: services, dispatch: dispatch)
        }

    default:
        break
    }
}

// MARK: - Helper Functions

/// Perform a full bidirectional sync (upload + download)
private func performFullSync(
    services: ServiceContainer,
    dispatch: @escaping Dispatcher<AppAction>
) async {
    logger.debug("[SyncMiddleware] Starting full sync")
    await dispatch(.sync(.statusUpdated(.syncing)))

    do {
        // First upload local changes
        try await services.syncService.uploadPendingChanges()
        logger.debug("[SyncMiddleware] Upload completed")

        // Then download remote changes
        try await services.syncService.downloadRemoteChanges()
        logger.debug("[SyncMiddleware] Download completed")

        // Check for conflicts
        let conflicts = await services.syncService.getPendingConflicts()
        for conflict in conflicts {
            await dispatch(.sync(.conflictDetected(conflict)))
        }

        // If no conflicts, mark as completed
        if conflicts.isEmpty {
            await dispatch(.sync(.syncCompleted))
        }
    } catch {
        logger.error("[SyncMiddleware] Full sync failed: \(error.localizedDescription)")
        await dispatch(.sync(.syncFailed(error.localizedDescription)))
    }
}

/// Upload local changes to CloudKit
private func uploadPendingChanges(
    services: ServiceContainer,
    dispatch: @escaping Dispatcher<AppAction>
) async {
    logger.debug("[SyncMiddleware] Uploading pending changes")
    await dispatch(.sync(.statusUpdated(.syncing)))

    do {
        try await services.syncService.uploadPendingChanges()
        logger.debug("[SyncMiddleware] Upload completed")

        // Check for conflicts after upload
        let conflicts = await services.syncService.getPendingConflicts()
        for conflict in conflicts {
            await dispatch(.sync(.conflictDetected(conflict)))
        }

        if conflicts.isEmpty {
            await dispatch(.sync(.syncCompleted))
        }
    } catch {
        logger.error("[SyncMiddleware] Upload failed: \(error.localizedDescription)")
        await dispatch(.sync(.syncFailed(error.localizedDescription)))
    }
}

/// Download remote changes from CloudKit
private func downloadRemoteChanges(
    services: ServiceContainer,
    dispatch: @escaping Dispatcher<AppAction>
) async {
    logger.debug("[SyncMiddleware] Downloading remote changes")
    await dispatch(.sync(.statusUpdated(.syncing)))

    do {
        try await services.syncService.downloadRemoteChanges()
        logger.debug("[SyncMiddleware] Download completed")

        // Reload local data after download
        await dispatch(.locations(.loadLocations))
        await dispatch(.shiftTypes(.loadShiftTypes))

        // Check for conflicts
        let conflicts = await services.syncService.getPendingConflicts()
        for conflict in conflicts {
            await dispatch(.sync(.conflictDetected(conflict)))
        }

        if conflicts.isEmpty {
            await dispatch(.sync(.syncCompleted))
        }
    } catch {
        logger.error("[SyncMiddleware] Download failed: \(error.localizedDescription)")
        await dispatch(.sync(.syncFailed(error.localizedDescription)))
    }
}

/// Resolve a sync conflict
private func resolveConflict(
    conflictId: UUID,
    resolution: ConflictResolution,
    services: ServiceContainer,
    dispatch: @escaping Dispatcher<AppAction>
) async {
    logger.debug("[SyncMiddleware] Resolving conflict: \(conflictId)")

    do {
        try await services.syncService.resolveConflict(id: conflictId, resolution: resolution)
        logger.debug("[SyncMiddleware] Conflict resolved")
        await dispatch(.sync(.conflictResolved(conflictId)))

        // Reload data after conflict resolution
        await dispatch(.locations(.loadLocations))
        await dispatch(.shiftTypes(.loadShiftTypes))
    } catch {
        logger.error("[SyncMiddleware] Conflict resolution failed: \(error.localizedDescription)")
        await dispatch(.sync(.syncFailed(error.localizedDescription)))
    }
}

/// Reset sync state
private func resetSync(
    services: ServiceContainer,
    dispatch: @escaping Dispatcher<AppAction>
) async {
    logger.debug("[SyncMiddleware] Resetting sync state")

    do {
        try await services.syncService.resetSyncState()
        logger.debug("[SyncMiddleware] Sync state reset")
        await dispatch(.sync(.statusUpdated(.notConfigured)))
    } catch {
        logger.error("[SyncMiddleware] Reset failed: \(error.localizedDescription)")
        await dispatch(.sync(.syncFailed(error.localizedDescription)))
    }
}
