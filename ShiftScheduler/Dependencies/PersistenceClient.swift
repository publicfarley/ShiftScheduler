import Foundation
import ComposableArchitecture

/// Error thrown when attempting to delete a Location that is referenced by ShiftTypes
enum LocationDeletionError: LocalizedError {
    case locationInUse(count: Int)

    var errorDescription: String? {
        switch self {
        case .locationInUse(let count):
            return "Cannot delete location. It is used by \(count) shift type\(count == 1 ? "" : "s")."
        }
    }

    var recoverySuggestion: String? {
        return "Delete or reassign all shift types that use this location first."
    }
}

/// TCA Dependency Client for data persistence operations
/// Provides controlled access to JSON file-based persistence for TCA reducers
@DependencyClient
struct PersistenceClient: Sendable {
    // MARK: - ShiftType Operations

    /// Fetch all shift types
    var fetchShiftTypes: @Sendable () async throws -> [ShiftType] = { [] }

    /// Fetch shift type by ID
    var fetchShiftType: @Sendable (UUID) async throws -> ShiftType?

    /// Save a new shift type
    var saveShiftType: @Sendable (ShiftType) async throws -> Void

    /// Update an existing shift type
    var updateShiftType: @Sendable (ShiftType) async throws -> Void

    /// Delete a shift type
    var deleteShiftType: @Sendable (ShiftType) async throws -> Void

    // MARK: - Location Operations

    /// Fetch all locations
    var fetchLocations: @Sendable () async throws -> [Location] = { [] }

    /// Fetch location by ID
    var fetchLocation: @Sendable (UUID) async throws -> Location?

    /// Save a new location
    var saveLocation: @Sendable (Location) async throws -> Void

    /// Update an existing location
    var updateLocation: @Sendable (Location) async throws -> Void

    /// Delete a location
    var deleteLocation: @Sendable (Location) async throws -> Void

    /// Check if a location can be safely deleted (not referenced by any ShiftType)
    var canDeleteLocation: @Sendable (Location) async throws -> Bool = { _ in true }

    /// Delete location only if not referenced by any ShiftType
    /// Throws LocationDeletionError if location is in use
    var safeDeleteLocation: @Sendable (Location) async throws -> Void

    // MARK: - ChangeLogEntry Operations

    /// Fetch all change log entries
    var fetchChangeLogEntries: @Sendable () async throws -> [ChangeLogEntry] = { [] }

    /// Save a new change log entry
    var saveChangeLogEntry: @Sendable (ChangeLogEntry) async throws -> Void

    /// Delete change log entries older than date
    var deleteOldChangeLogEntries: @Sendable (Date) async throws -> Void
}

extension PersistenceClient: DependencyKey {
    /// Live implementation using JSON file-based repositories
    static let liveValue: PersistenceClient = {
        let shiftTypeRepo = ShiftTypeRepository()
        let locationRepo = LocationRepository()
        let changeLogRepo = ChangeLogRepository()

        return PersistenceClient(
            fetchShiftTypes: {
                try await shiftTypeRepo.fetchAll()
            },
            fetchShiftType: { id in
                try await shiftTypeRepo.fetch(id: id)
            },
            saveShiftType: { shiftType in
                try await shiftTypeRepo.save(shiftType)
            },
            updateShiftType: { shiftType in
                try await shiftTypeRepo.save(shiftType)
            },
            deleteShiftType: { shiftType in
                try await shiftTypeRepo.delete(id: shiftType.id)
            },
            fetchLocations: {
                try await locationRepo.fetchAll()
            },
            fetchLocation: { id in
                try await locationRepo.fetch(id: id)
            },
            saveLocation: { location in
                try await locationRepo.save(location)
            },
            updateLocation: { location in
                try await locationRepo.save(location)
            },
            deleteLocation: { location in
                try await locationRepo.delete(id: location.id)
            },
            canDeleteLocation: { location in
                let shiftTypes = try await shiftTypeRepo.fetchAll()
                return !shiftTypes.contains { $0.location.id == location.id }
            },
            safeDeleteLocation: { location in
                let shiftTypes = try await shiftTypeRepo.fetchAll()
                let referencingCount = shiftTypes.filter { $0.location.id == location.id }.count

                guard referencingCount == 0 else {
                    throw LocationDeletionError.locationInUse(count: referencingCount)
                }

                try await locationRepo.delete(id: location.id)
            },
            fetchChangeLogEntries: {
                try await changeLogRepo.fetchAll()
            },
            saveChangeLogEntry: { entry in
                try await changeLogRepo.save(entry)
            },
            deleteOldChangeLogEntries: { date in
                let entries = try await changeLogRepo.fetchAll()
                let filtered = entries.filter { $0.timestamp > date }
                for entry in filtered {
                    try await changeLogRepo.save(entry)
                }
            }
        )
    }()

    /// Test value with unimplemented methods
    static let testValue = PersistenceClient()

    /// Preview value with mock data
    static let previewValue = PersistenceClient(
        fetchShiftTypes: { [] },
        fetchShiftType: { _ in nil },
        saveShiftType: { _ in },
        updateShiftType: { _ in },
        deleteShiftType: { _ in },
        fetchLocations: { [] },
        fetchLocation: { _ in nil },
        saveLocation: { _ in },
        updateLocation: { _ in },
        deleteLocation: { _ in },
        canDeleteLocation: { _ in true },
        safeDeleteLocation: { _ in },
        fetchChangeLogEntries: { [] },
        saveChangeLogEntry: { _ in },
        deleteOldChangeLogEntries: { _ in }
    )
}

extension DependencyValues {
    var persistenceClient: PersistenceClient {
        get { self[PersistenceClient.self] }
        set { self[PersistenceClient.self] = newValue }
    }
}
