import Foundation
import CloudKit
import os

/// Actor-based CloudKit synchronization service
/// Provides thread-safe synchronization of Location and ShiftType data with iCloud
actor CloudKitSyncService: SyncServiceProtocol {
    // MARK: - Properties

    private let container: CKContainer
    private let database: CKDatabase
    private let logger = Logger(subsystem: "functioncraft.ShiftScheduler", category: "CloudKitSync")
    private let persistenceService: PersistenceServiceProtocol
    private let conflictResolutionService: ConflictResolutionServiceProtocol

    // Sync state
    private var syncMetadata: SyncMetadata
    private var currentStatus: SyncStatus = .notConfigured

    // Record type names
    private let locationRecordType = "Location"
    private let shiftTypeRecordType = "ShiftType"

    // Zone configuration for change tracking
    private let customZoneName = "ShiftSchedulerZone"
    private lazy var customZone: CKRecordZone = {
        let zoneID = CKRecordZone.ID(zoneName: customZoneName, ownerName: CKCurrentUserDefaultName)
        return CKRecordZone(zoneID: zoneID)
    }()

    // MARK: - Initialization

    init(
        containerIdentifier: String = "iCloud.functioncraft.ShiftScheduler",
        persistenceService: PersistenceServiceProtocol,
        conflictResolutionService: ConflictResolutionServiceProtocol
    ) {
        self.container = CKContainer(identifier: containerIdentifier)
        self.database = container.privateCloudDatabase
        self.persistenceService = persistenceService
        self.conflictResolutionService = conflictResolutionService
        self.syncMetadata = SyncMetadata()
    }

    // MARK: - SyncServiceProtocol Implementation

    func isAvailable() async -> Bool {
        do {
            let status = try await container.accountStatus()
            switch status {
            case .available:
                currentStatus = .synced
                return true
            case .noAccount:
                logger.debug("iCloud account not available")
                currentStatus = .notConfigured
                return false
            case .restricted:
                logger.debug("iCloud account restricted")
                currentStatus = .error("iCloud account is restricted")
                return false
            case .couldNotDetermine:
                logger.debug("Could not determine iCloud account status")
                currentStatus = .error("Could not determine iCloud status")
                return false
            case .temporarilyUnavailable:
                logger.debug("iCloud temporarily unavailable")
                currentStatus = .offline
                return false
            @unknown default:
                logger.debug("Unknown iCloud account status")
                currentStatus = .error("Unknown iCloud status")
                return false
            }
        } catch {
            logger.debug("Error checking CloudKit availability: \(error.localizedDescription)")
            currentStatus = .error(error.localizedDescription)
            return false
        }
    }

    func uploadPendingChanges() async throws {
        guard await isAvailable() else {
            throw SyncError.iCloudUnavailable
        }

        currentStatus = .syncing
        logger.debug("Starting upload of pending changes")

        do {
            // Ensure custom zone exists for change tracking
            try await ensureCustomZoneExists()

            // Load local data
            let locations = try await persistenceService.loadLocations()
            let shiftTypes = try await persistenceService.loadShiftTypes()

            logger.debug("Loaded \(locations.count) locations and \(shiftTypes.count) shift types for upload")

            // Convert to CloudKit records (must be done on main actor)
            let locationRecords = await MainActor.run {
                locations.map { $0.toCloudKitRecord() }
            }
            let shiftTypeRecords = await MainActor.run {
                shiftTypes.map { $0.toCloudKitRecord() }
            }

            // Upload in batches (CloudKit has a 400 operation limit per request)
            let allRecords = locationRecords + shiftTypeRecords
            try await uploadRecordsInBatches(allRecords)

            currentStatus = .synced
            logger.debug("Upload completed successfully - uploaded \(allRecords.count) records")
        } catch {
            currentStatus = .error(error.localizedDescription)
            logger.error("Upload failed: \(error.localizedDescription)")
            throw error
        }
    }

    func downloadRemoteChanges() async throws {
        guard await isAvailable() else {
            throw SyncError.iCloudUnavailable
        }

        currentStatus = .syncing
        logger.debug("Starting download of remote changes")

        do {
            // Ensure custom zone exists
            try await ensureCustomZoneExists()

            // Fetch changes using change token (or all records if no token)
            let (locationRecords, shiftTypeRecords) = try await fetchRemoteRecords()

            logger.debug("Downloaded \(locationRecords.count) locations and \(shiftTypeRecords.count) shift types")

            // Load local data for conflict detection
            let localLocations = try await persistenceService.loadLocations()
            let localShiftTypes = try await persistenceService.loadShiftTypes()

            // Process locations (parsing must be done on main actor)
            for record in locationRecords {
                let remoteLocation = await MainActor.run {
                    Location(from: record)
                }
                guard let remoteLocation else {
                    logger.warning("Failed to parse location record: \(record.recordID.recordName)")
                    continue
                }

                // Check for conflicts using ConflictResolutionService
                if let localLocation = localLocations.first(where: { $0.id == remoteLocation.id }) {
                    let mergeResult = await conflictResolutionService.resolveLocation(
                        local: localLocation,
                        remote: remoteLocation
                    )

                    switch mergeResult {
                    case .success(let mergedLocation):
                        // Automatic merge succeeded - save the merged version
                        try await persistenceService.saveLocation(mergedLocation)
                        logger.debug("Location automatically merged: \(mergedLocation.id)")

                    case .conflict:
                        // Manual resolution required - conflict added to pendingConflicts by service
                        logger.debug("Location conflict requires manual resolution: \(remoteLocation.id)")

                    case .failure(let error):
                        // Merge error - log and skip
                        logger.error("Location merge error: \(error.localizedDescription)")
                    }
                } else {
                    // No local version exists - save remote version directly
                    try await persistenceService.saveLocation(remoteLocation)
                }
            }

            // Process shift types (parsing must be done on main actor)
            for record in shiftTypeRecords {
                let remoteShiftType = await MainActor.run {
                    ShiftType(from: record)
                }
                guard let remoteShiftType else {
                    logger.warning("Failed to parse shift type record: \(record.recordID.recordName)")
                    continue
                }

                // Check for conflicts using ConflictResolutionService
                if let localShiftType = localShiftTypes.first(where: { $0.id == remoteShiftType.id }) {
                    let mergeResult = await conflictResolutionService.resolveShiftType(
                        local: localShiftType,
                        remote: remoteShiftType
                    )

                    switch mergeResult {
                    case .success(let mergedShiftType):
                        // Automatic merge succeeded - save the merged version
                        try await persistenceService.saveShiftType(mergedShiftType)
                        logger.debug("ShiftType automatically merged: \(mergedShiftType.id)")

                    case .conflict:
                        // Manual resolution required - conflict added to pendingConflicts by service
                        logger.debug("ShiftType conflict requires manual resolution: \(remoteShiftType.id)")

                    case .failure(let error):
                        // Merge error - log and skip
                        logger.error("ShiftType merge error: \(error.localizedDescription)")
                    }
                } else {
                    // No local version exists - save remote version directly
                    try await persistenceService.saveShiftType(remoteShiftType)
                }
            }

            // Get pending conflicts from the conflict resolution service
            let conflicts = await conflictResolutionService.getPendingConflicts()
            currentStatus = .synced
            logger.debug("Download completed successfully - \(conflicts.count) conflicts detected")
        } catch {
            currentStatus = .error(error.localizedDescription)
            logger.error("Download failed: \(error.localizedDescription)")
            throw error
        }
    }

    func resolveConflict(id: UUID, resolution: ConflictResolution) async throws {
        logger.debug("Resolving conflict \(id) with resolution: \(String(describing: resolution))")

        // Get all pending conflicts
        let conflicts = await conflictResolutionService.getPendingConflicts()
        guard let conflict = conflicts.first(where: { $0.id == id }) else {
            throw SyncError.conflictResolutionFailed("Conflict with ID \(id) not found")
        }

        // Handle resolution based on conflict type
        switch conflict {
        case .location(_, let info):
            try await resolveLocationConflict(info: info, resolution: resolution)
        case .shiftType(_, let info):
            try await resolveShiftTypeConflict(info: info, resolution: resolution)
        }

        // Remove from pending conflicts in the service
        try await conflictResolutionService.manuallyResolve(conflictId: id, with: resolution)
        logger.debug("Conflict resolved successfully")
    }

    func getSyncStatus() async -> SyncStatus {
        return currentStatus
    }

    func performFullSync() async throws {
        guard await isAvailable() else {
            throw SyncError.iCloudUnavailable
        }

        logger.debug("Starting full sync operation")
        currentStatus = .syncing

        do {
            try await uploadPendingChanges()
            try await downloadRemoteChanges()
            currentStatus = .synced
            logger.debug("Full sync completed successfully")
        } catch {
            currentStatus = .error(error.localizedDescription)
            logger.debug("Full sync failed: \(error.localizedDescription)")
            throw error
        }
    }

    func getPendingConflicts() async -> [PendingConflict] {
        return await conflictResolutionService.getPendingConflicts()
    }

    func resetSyncState() async throws {
        logger.debug("Resetting sync state")
        syncMetadata = SyncMetadata()
        await conflictResolutionService.clearPendingConflicts()
        currentStatus = .notConfigured
    }

    // MARK: - Private Helper Methods

    /// Ensure the custom zone exists for change tracking
    private func ensureCustomZoneExists() async throws {
        do {
            _ = try await database.save(customZone)
            logger.debug("Custom zone created or verified: \(self.customZoneName)")
        } catch let error as CKError where error.code == .serverRecordChanged {
            // Zone already exists, this is fine
            logger.debug("Custom zone already exists: \(self.customZoneName)")
        } catch {
            logger.error("Failed to create custom zone: \(error.localizedDescription)")
            throw SyncError.unknown(error.localizedDescription)
        }
    }

    /// Upload records in batches to respect CloudKit limits
    private func uploadRecordsInBatches(_ records: [CKRecord]) async throws {
        let batchSize = 400
        let batches = stride(from: 0, to: records.count, by: batchSize).map {
            Array(records[$0..<min($0 + batchSize, records.count)])
        }

        for (index, batch) in batches.enumerated() {
            logger.debug("Uploading batch \(index + 1)/\(batches.count) with \(batch.count) records")

            do {
                let operation = CKModifyRecordsOperation(recordsToSave: batch)
                operation.savePolicy = .changedKeys
                operation.qualityOfService = .userInitiated

                try await database.add(operation)
                logger.debug("Batch \(index + 1) uploaded successfully")
            } catch let error as CKError {
                throw handleCloudKitError(error)
            }
        }
    }

    /// Fetch remote records using change tokens for incremental sync
    private func fetchRemoteRecords() async throws -> (locations: [CKRecord], shiftTypes: [CKRecord]) {
        var locationRecords: [CKRecord] = []
        var shiftTypeRecords: [CKRecord] = []

        // Query for locations
        let locationQuery = CKQuery(recordType: locationRecordType, predicate: NSPredicate(value: true))
        do {
            let (results, _) = try await database.records(matching: locationQuery)
            locationRecords = results.compactMap { try? $0.1.get() }
        } catch let error as CKError {
            throw handleCloudKitError(error)
        }

        // Query for shift types
        let shiftTypeQuery = CKQuery(recordType: shiftTypeRecordType, predicate: NSPredicate(value: true))
        do {
            let (results, _) = try await database.records(matching: shiftTypeQuery)
            shiftTypeRecords = results.compactMap { try? $0.1.get() }
        } catch let error as CKError {
            throw handleCloudKitError(error)
        }

        return (locationRecords, shiftTypeRecords)
    }

    /// Resolve a location conflict by applying the chosen resolution
    private func resolveLocationConflict(info: ConflictInfo<Location>, resolution: ConflictResolution) async throws {
        let resolvedLocation: Location

        switch resolution {
        case .keepLocal:
            resolvedLocation = info.local
            logger.debug("Keeping local version for location: \(info.local.id)")

        case .keepRemote:
            resolvedLocation = info.remote
            logger.debug("Keeping remote version for location: \(info.remote.id)")

        case .merge:
            // Use the automatic merge result from the conflict resolution service
            let mergeResult = await conflictResolutionService.resolveLocation(
                local: info.local,
                remote: info.remote
            )
            guard case .success(let merged) = mergeResult else {
                throw SyncError.conflictResolutionFailed("Merge failed for location: \(info.local.id)")
            }
            resolvedLocation = merged
            logger.debug("Merged location: \(merged.id)")

        case .deferred:
            // Should not reach here - deferred conflicts stay pending
            return
        }

        // Save the resolved location
        try await persistenceService.saveLocation(resolvedLocation)

        // Upload to CloudKit
        let record = await MainActor.run {
            resolvedLocation.toCloudKitRecord()
        }
        try await saveRecord(record)
    }

    /// Resolve a shift type conflict by applying the chosen resolution
    private func resolveShiftTypeConflict(info: ConflictInfo<ShiftType>, resolution: ConflictResolution) async throws {
        let resolvedShiftType: ShiftType

        switch resolution {
        case .keepLocal:
            resolvedShiftType = info.local
            logger.debug("Keeping local version for shift type: \(info.local.id)")

        case .keepRemote:
            resolvedShiftType = info.remote
            logger.debug("Keeping remote version for shift type: \(info.remote.id)")

        case .merge:
            // Use the automatic merge result from the conflict resolution service
            let mergeResult = await conflictResolutionService.resolveShiftType(
                local: info.local,
                remote: info.remote
            )
            guard case .success(let merged) = mergeResult else {
                throw SyncError.conflictResolutionFailed("Merge failed for shift type: \(info.local.id)")
            }
            resolvedShiftType = merged
            logger.debug("Merged shift type: \(merged.id)")

        case .deferred:
            // Should not reach here - deferred conflicts stay pending
            return
        }

        // Save the resolved shift type
        try await persistenceService.saveShiftType(resolvedShiftType)

        // Upload to CloudKit
        let record = await MainActor.run {
            resolvedShiftType.toCloudKitRecord()
        }
        try await saveRecord(record)
    }

    private func saveRecord(_ record: CKRecord) async throws {
        do {
            _ = try await database.save(record)
            logger.debug("Record saved successfully: \(record.recordID.recordName)")
        } catch let error as CKError {
            throw handleCloudKitError(error)
        } catch {
            throw SyncError.uploadFailed(error.localizedDescription)
        }
    }

    private func handleCloudKitError(_ error: CKError) -> SyncError {
        switch error.code {
        case .networkUnavailable, .networkFailure:
            return .networkUnavailable
        case .notAuthenticated:
            return .iCloudUnavailable
        case .quotaExceeded:
            return .quotaExceeded
        case .unknownItem:
            return .recordNotFound(error.localizedDescription)
        default:
            return .unknown(error.localizedDescription)
        }
    }
}

// MARK: - CloudKit Record Extensions

extension Location {
    /// Convert Location to CloudKit record
    func toCloudKitRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: id.uuidString)
        let record = CKRecord(recordType: "Location", recordID: recordID)
        record["name"] = name as CKRecordValue
        record["address"] = address as CKRecordValue
        record["modificationDate"] = Date() as CKRecordValue
        return record
    }

    /// Initialize Location from CloudKit record
    init?(from record: CKRecord) {
        guard let name = record["name"] as? String,
              let address = record["address"] as? String,
              let recordName = UUID(uuidString: record.recordID.recordName) else {
            return nil
        }
        self.init(id: recordName, name: name, address: address)
    }
}

extension ShiftType {
    /// Convert ShiftType to CloudKit record
    func toCloudKitRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: id.uuidString)
        let record = CKRecord(recordType: "ShiftType", recordID: recordID)
        record["symbol"] = symbol as CKRecordValue
        record["title"] = title as CKRecordValue
        record["shiftDescription"] = shiftDescription as CKRecordValue
        record["modificationDate"] = Date() as CKRecordValue

        // Note: Duration and Location will be serialized in Phase 2
        // For now, storing as JSON string
        if let durationData = try? JSONEncoder().encode(duration),
           let durationString = String(data: durationData, encoding: .utf8) {
            record["duration"] = durationString as CKRecordValue
        }

        if let locationData = try? JSONEncoder().encode(location),
           let locationString = String(data: locationData, encoding: .utf8) {
            record["location"] = locationString as CKRecordValue
        }

        return record
    }

    /// Initialize ShiftType from CloudKit record
    init?(from record: CKRecord) {
        guard let symbol = record["symbol"] as? String,
              let title = record["title"] as? String,
              let description = record["shiftDescription"] as? String,
              let durationString = record["duration"] as? String,
              let locationString = record["location"] as? String,
              let recordName = UUID(uuidString: record.recordID.recordName) else {
            return nil
        }

        // Decode duration
        guard let durationData = durationString.data(using: .utf8),
              let duration = try? JSONDecoder().decode(ShiftDuration.self, from: durationData) else {
            return nil
        }

        // Decode location
        guard let locationData = locationString.data(using: .utf8),
              let location = try? JSONDecoder().decode(Location.self, from: locationData) else {
            return nil
        }

        self.init(
            id: recordName,
            symbol: symbol,
            duration: duration,
            title: title,
            description: description,
            location: location
        )
    }
}
