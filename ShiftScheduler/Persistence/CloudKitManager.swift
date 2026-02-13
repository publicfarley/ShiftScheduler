import Foundation
import CloudKit
import OSLog

/// Actor-based CloudKit manager for syncing shift types and locations
/// to the public CloudKit database for cross-account synchronization
actor CloudKitManager: Sendable {
    private let logger = Logger(subsystem: "com.functioncraft.ShiftScheduler", category: "CloudKit")
    private let container: CKContainer
    private let publicDatabase: CKDatabase

    enum CloudKitError: Error, LocalizedError, Sendable {
        case accountNotAvailable
        case networkUnavailable
        case recordNotFound
        case saveFailed(String)
        case fetchFailed(String)
        case deleteFailed(String)
        case migrationFailed(String)

        var errorDescription: String? {
            switch self {
            case .accountNotAvailable: return "iCloud account not available"
            case .networkUnavailable: return "Network connection unavailable"
            case .recordNotFound: return "Record not found"
            case .saveFailed(let msg): return "Save failed: \(msg)"
            case .fetchFailed(let msg): return "Fetch failed: \(msg)"
            case .deleteFailed(let msg): return "Delete failed: \(msg)"
            case .migrationFailed(let msg): return "Migration failed: \(msg)"
            }
        }
    }

    init(containerIdentifier: String = "iCloud.com.functioncraft.ShiftScheduler") {
        self.container = CKContainer(identifier: containerIdentifier)
        self.publicDatabase = container.publicCloudDatabase
    }

    // MARK: - Account Status

    /// Check if CloudKit account is available
    func checkAccountStatus() async throws -> Bool {
        let status = try await container.accountStatus()
        switch status {
        case .available:
            logger.debug("CloudKit account available")
            return true
        case .noAccount:
            logger.warning("No iCloud account signed in")
            throw CloudKitError.accountNotAvailable
        case .restricted:
            logger.warning("iCloud account restricted")
            throw CloudKitError.accountNotAvailable
        case .couldNotDetermine:
            logger.warning("Could not determine iCloud account status")
            throw CloudKitError.accountNotAvailable
        case .temporarilyUnavailable:
            logger.warning("iCloud temporarily unavailable")
            throw CloudKitError.networkUnavailable
        @unknown default:
            logger.warning("Unknown iCloud account status")
            throw CloudKitError.accountNotAvailable
        }
    }

    // MARK: - ShiftType Operations

    /// Save a shift type to CloudKit
    func saveShiftType(_ shiftType: ShiftType) async throws {
        _ = try await checkAccountStatus()

        let record = CKRecord(recordType: "ShiftType", recordID: CKRecord.ID(recordName: shiftType.id.uuidString))
        record["recordID"] = shiftType.id.uuidString
        record["symbol"] = shiftType.symbol
        record["title"] = shiftType.title
        record["shiftDescription"] = shiftType.shiftDescription
        record["locationID"] = shiftType.location.id.uuidString
        record["locationName"] = shiftType.location.name
        record["locationAddress"] = shiftType.location.address
        record["modifiedAt"] = Date()

        // Store shift duration as encoded data
        let durationData = try encodeDuration(shiftType.duration)
        record["durationData"] = durationData as NSData

        do {
            let savedRecord = try await saveWithRetry(record)
            logger.debug("Saved ShiftType: \(shiftType.title)")
        } catch {
            logger.error("Failed to save ShiftType: \(error.localizedDescription)")
            throw CloudKitError.saveFailed(error.localizedDescription)
        }
    }

    /// Fetch all shift types from CloudKit
    func fetchAllShiftTypes() async throws -> [ShiftType] {
        _ = try await checkAccountStatus()

        let query = CKQuery(recordType: "ShiftType", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]

        do {
            let results = try await publicDatabase.records(matching: query)
            let shiftTypes = results.matchResults.compactMap { _, result -> ShiftType? in
                guard case .success(let record) = result else { return nil }
                return shiftTypeFromRecord(record)
            }
            logger.debug("Fetched \(shiftTypes.count) ShiftTypes from CloudKit")
            return shiftTypes
        } catch {
            logger.error("Failed to fetch ShiftTypes: \(error.localizedDescription)")
            throw CloudKitError.fetchFailed(error.localizedDescription)
        }
    }

    /// Delete a shift type from CloudKit
    func deleteShiftType(id: UUID) async throws {
        _ = try await checkAccountStatus()

        let recordID = CKRecord.ID(recordName: id.uuidString)
        do {
            _ = try await publicDatabase.deleteRecord(withID: recordID)
            logger.debug("Deleted ShiftType: \(id.uuidString)")
        } catch {
            logger.error("Failed to delete ShiftType: \(error.localizedDescription)")
            throw CloudKitError.deleteFailed(error.localizedDescription)
        }
    }

    // MARK: - Location Operations

    /// Save a location to CloudKit
    func saveLocation(_ location: Location) async throws {
        _ = try await checkAccountStatus()

        let record = CKRecord(recordType: "Location", recordID: CKRecord.ID(recordName: location.id.uuidString))
        record["recordID"] = location.id.uuidString
        record["name"] = location.name
        record["address"] = location.address
        record["modifiedAt"] = Date()

        do {
            let savedRecord = try await saveWithRetry(record)
            logger.debug("Saved Location: \(location.name)")
        } catch {
            logger.error("Failed to save Location: \(error.localizedDescription)")
            throw CloudKitError.saveFailed(error.localizedDescription)
        }
    }

    /// Fetch all locations from CloudKit
    func fetchAllLocations() async throws -> [Location] {
        _ = try await checkAccountStatus()

        let query = CKQuery(recordType: "Location", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        do {
            let results = try await publicDatabase.records(matching: query)
            let locations = results.matchResults.compactMap { _, result -> Location? in
                guard case .success(let record) = result else { return nil }
                return locationFromRecord(record)
            }
            logger.debug("Fetched \(locations.count) Locations from CloudKit")
            return locations
        } catch {
            logger.error("Failed to fetch Locations: \(error.localizedDescription)")
            throw CloudKitError.fetchFailed(error.localizedDescription)
        }
    }

    /// Delete a location from CloudKit
    func deleteLocation(id: UUID) async throws {
        _ = try await checkAccountStatus()

        let recordID = CKRecord.ID(recordName: id.uuidString)
        do {
            _ = try await publicDatabase.deleteRecord(withID: recordID)
            logger.debug("Deleted Location: \(id.uuidString)")
        } catch {
            logger.error("Failed to delete Location: \(error.localizedDescription)")
            throw CloudKitError.deleteFailed(error.localizedDescription)
        }
    }

    // MARK: - Subscriptions

    /// Subscribe to ShiftType changes (for real-time updates)
    func subscribeToShiftTypeChanges() async throws {
        let subscription = CKQuerySubscription(
            recordType: "ShiftType",
            predicate: NSPredicate(value: true),
            subscriptionID: "shift-type-changes",
            options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
        )

        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo

        do {
            _ = try await publicDatabase.save(subscription)
            logger.debug("Subscribed to ShiftType changes")
        } catch {
            logger.warning("Failed to create ShiftType subscription: \(error.localizedDescription)")
        }
    }

    /// Subscribe to Location changes (for real-time updates)
    func subscribeToLocationChanges() async throws {
        let subscription = CKQuerySubscription(
            recordType: "Location",
            predicate: NSPredicate(value: true),
            subscriptionID: "location-changes",
            options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
        )

        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo

        do {
            _ = try await publicDatabase.save(subscription)
            logger.debug("Subscribed to Location changes")
        } catch {
            logger.warning("Failed to create Location subscription: \(error.localizedDescription)")
        }
    }

    // MARK: - Migration

    /// Migrate local data to CloudKit (initial setup)
    func migrateLocalDataToCloudKit(
        shiftTypes: [ShiftType],
        locations: [Location]
    ) async throws {
        _ = try await checkAccountStatus()

        logger.debug("Starting CloudKit migration...")

        // Check if CloudKit already has data (avoid duplicate migration)
        let existingShiftTypes = try await fetchAllShiftTypes()
        let existingLocations = try await fetchAllLocations()

        if !existingShiftTypes.isEmpty || !existingLocations.isEmpty {
            logger.warning("CloudKit already has data - skipping migration")
            return
        }

        // Upload locations first (shift types reference locations)
        for location in locations {
            try await saveLocation(location)
        }
        logger.debug("Migrated \(locations.count) locations to CloudKit")

        // Upload shift types
        for shiftType in shiftTypes {
            try await saveShiftType(shiftType)
        }
        logger.debug("Migrated \(shiftTypes.count) shift types to CloudKit")

        logger.debug("CloudKit migration complete")
    }

    // MARK: - Private Helpers

    /// Encode a ShiftDuration to Data
    nonisolated private func encodeDuration(_ duration: ShiftDuration) throws -> Data {
        return try JSONEncoder().encode(duration)
    }

    /// Retry save operation with exponential backoff for network errors
    private func saveWithRetry(_ record: CKRecord, maxRetries: Int = 3) async throws -> CKRecord {
        var lastError: Error?

        for attempt in 1...maxRetries {
            do {
                return try await publicDatabase.save(record)
            } catch let error as CKError {
                lastError = error

                switch error.code {
                case .networkUnavailable, .networkFailure:
                    if attempt < maxRetries {
                        let delay = UInt64(attempt) * 1_000_000_000  // 1 second per attempt
                        try? await Task.sleep(nanoseconds: delay)
                        continue
                    }
                case .zoneBusy, .serviceUnavailable:
                    if attempt < maxRetries {
                        try? await Task.sleep(nanoseconds: 2_000_000_000)  // 2 seconds
                        continue
                    }
                default:
                    throw error  // Don't retry other errors
                }
            } catch {
                throw error
            }
        }

        throw lastError ?? CloudKitError.saveFailed("Max retries exceeded")
    }

    /// Convert CKRecord to ShiftType
    nonisolated private func shiftTypeFromRecord(_ record: CKRecord) -> ShiftType? {
        guard
            let idString = record["recordID"] as? String,
            let id = UUID(uuidString: idString),
            let symbol = record["symbol"] as? String,
            let title = record["title"] as? String,
            let shiftDescription = record["shiftDescription"] as? String,
            let locationIDString = record["locationID"] as? String,
            let locationID = UUID(uuidString: locationIDString),
            let locationName = record["locationName"] as? String,
            let locationAddress = record["locationAddress"] as? String,
            let durationData = record["durationData"] as? NSData
        else {
            return nil
        }

        // Decode duration from data
        guard let shiftDuration = try? JSONDecoder().decode(ShiftDuration.self, from: Data(durationData)) else {
            return nil
        }

        let location = Location(id: locationID, name: locationName, address: locationAddress)

        return ShiftType(
            id: id,
            symbol: symbol,
            duration: shiftDuration,
            title: title,
            description: shiftDescription,
            location: location
        )
    }

    /// Convert CKRecord to Location
    nonisolated private func locationFromRecord(_ record: CKRecord) -> Location? {
        guard
            let idString = record["recordID"] as? String,
            let id = UUID(uuidString: idString),
            let name = record["name"] as? String,
            let address = record["address"] as? String
        else {
            return nil
        }

        return Location(id: id, name: name, address: address)
    }
}
