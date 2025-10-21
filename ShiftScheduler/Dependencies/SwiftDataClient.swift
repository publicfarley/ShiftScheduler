import Foundation
import SwiftData
import ComposableArchitecture

/// TCA Dependency Client for SwiftData operations
/// Provides controlled access to SwiftData model operations for TCA reducers
@DependencyClient
struct SwiftDataClient: Sendable {
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

    // MARK: - ChangeLogEntry Operations

    /// Fetch all change log entries
    var fetchChangeLogEntries: @Sendable () async throws -> [ChangeLogEntry] = { [] }

    /// Save a new change log entry
    var saveChangeLogEntry: @Sendable (ChangeLogEntry) async throws -> Void

    /// Delete change log entries older than date
    var deleteOldChangeLogEntries: @Sendable (Date) async throws -> Void
}

extension SwiftDataClient: DependencyKey {
    /// Live implementation using ModelContext
    /// Note: This requires access to the app's ModelContext
    static let liveValue = SwiftDataClient(
        fetchShiftTypes: {
            // TODO: Implement with ModelContext
            // This will need to be wired up with the app's ModelContainer
            fatalError("Live SwiftDataClient not yet implemented")
        },
        fetchShiftType: { _ in
            fatalError("Live SwiftDataClient not yet implemented")
        },
        saveShiftType: { _ in
            fatalError("Live SwiftDataClient not yet implemented")
        },
        updateShiftType: { _ in
            fatalError("Live SwiftDataClient not yet implemented")
        },
        deleteShiftType: { _ in
            fatalError("Live SwiftDataClient not yet implemented")
        },
        fetchLocations: {
            fatalError("Live SwiftDataClient not yet implemented")
        },
        fetchLocation: { _ in
            fatalError("Live SwiftDataClient not yet implemented")
        },
        saveLocation: { _ in
            fatalError("Live SwiftDataClient not yet implemented")
        },
        updateLocation: { _ in
            fatalError("Live SwiftDataClient not yet implemented")
        },
        deleteLocation: { _ in
            fatalError("Live SwiftDataClient not yet implemented")
        },
        fetchChangeLogEntries: {
            fatalError("Live SwiftDataClient not yet implemented")
        },
        saveChangeLogEntry: { _ in
            fatalError("Live SwiftDataClient not yet implemented")
        },
        deleteOldChangeLogEntries: { _ in
            fatalError("Live SwiftDataClient not yet implemented")
        }
    )

    /// Test value with unimplemented methods
    static let testValue = SwiftDataClient()

    /// Preview value with mock data
    static let previewValue = SwiftDataClient(
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
        fetchChangeLogEntries: { [] },
        saveChangeLogEntry: { _ in },
        deleteOldChangeLogEntries: { _ in }
    )
}

extension DependencyValues {
    var swiftDataClient: SwiftDataClient {
        get { self[SwiftDataClient.self] }
        set { self[SwiftDataClient.self] = newValue }
    }
}
