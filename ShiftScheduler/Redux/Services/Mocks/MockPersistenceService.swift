import Foundation

// MARK: - Error Types

/// Errors that can be thrown by persistence operations
enum PersistenceError: LocalizedError {
    case notFound(String)
    case saveFailed(String)
    case loadFailed(String)

    var errorDescription: String? {
        switch self {
        case .notFound(let message):
            return "Item not found: \(message)"
        case .saveFailed(let message):
            return "Failed to save: \(message)"
        case .loadFailed(let message):
            return "Failed to load: \(message)"
        }
    }
}

/// Mock implementation of PersistenceServiceProtocol for testing
final class MockPersistenceService: PersistenceServiceProtocol {
    var mockShiftTypes: [ShiftType] = []
    var mockLocations: [Location] = []
    var mockChangeLogEntries: [ChangeLogEntry] = []
    var mockUserProfile: UserProfile = UserProfile()
    var mockUndoStack: [ChangeLogEntry] = []
    var mockRedoStack: [ChangeLogEntry] = []

    var shouldThrowError: Bool = false
    var throwError: Error?

    // MARK: - Call Tracking for Testing

    private(set) var loadShiftTypesCallCount = 0
    private(set) var saveShiftTypeCallCount = 0
    private(set) var deleteShiftTypeCallCount = 0
    private(set) var updateShiftTypesWithLocationCallCount = 0
    private(set) var loadLocationsCallCount = 0
    private(set) var saveLocationCallCount = 0
    private(set) var deleteLocationCallCount = 0
    private(set) var loadChangeLogEntriesCallCount = 0
    private(set) var addChangeLogEntryCallCount = 0
    private(set) var addMultipleChangeLogEntriesCallCount = 0
    private(set) var deleteChangeLogEntryCallCount = 0
    private(set) var purgeOldChangeLogEntriesCallCount = 0
    private(set) var getChangeLogMetadataCallCount = 0
    private(set) var loadUndoRedoStacksCallCount = 0
    private(set) var saveUndoRedoStacksCallCount = 0
    private(set) var loadUserProfileCallCount = 0
    private(set) var saveUserProfileCallCount = 0

    var lastDeletedShiftTypeId: UUID?
    var lastDeletedLocationId: UUID?
    var lastDeletedChangeLogEntryId: UUID?
    var lastPurgeOldEntriesCutoffDate: Date?

    // MARK: - Shift Types

    func loadShiftTypes() async throws -> [ShiftType] {
        loadShiftTypesCallCount += 1
        if shouldThrowError, let error = throwError {
            throw error
        }
        return mockShiftTypes
    }

    func saveShiftType(_ shiftType: ShiftType) async throws {
        saveShiftTypeCallCount += 1
        if shouldThrowError, let error = throwError {
            throw error
        }
        mockShiftTypes.removeAll { $0.id == shiftType.id }
        mockShiftTypes.append(shiftType)
    }

    func deleteShiftType(id: UUID) async throws {
        deleteShiftTypeCallCount += 1
        lastDeletedShiftTypeId = id
        if shouldThrowError, let error = throwError {
            throw error
        }
        // Validate that the shift type exists before deletion
        guard mockShiftTypes.contains(where: { $0.id == id }) else {
            throw PersistenceError.notFound("ShiftType with id \(id) not found")
        }
        mockShiftTypes.removeAll { $0.id == id }
    }

    func updateShiftTypesWithLocation(_ location: Location) async throws -> [ShiftType] {
        updateShiftTypesWithLocationCallCount += 1
        if shouldThrowError, let error = throwError {
            throw error
        }

        // Find shift types that reference this location
        let affectedShiftTypes = mockShiftTypes.filter { $0.location.id == location.id }

        // Update each affected shift type with the new location data
        var updatedShiftTypes: [ShiftType] = []
        for shiftType in affectedShiftTypes {
            var updatedShiftType = shiftType
            updatedShiftType.location = location
            mockShiftTypes.removeAll { $0.id == shiftType.id }
            mockShiftTypes.append(updatedShiftType)
            updatedShiftTypes.append(updatedShiftType)
        }

        return updatedShiftTypes
    }

    // MARK: - Locations

    func loadLocations() async throws -> [Location] {
        loadLocationsCallCount += 1
        if shouldThrowError, let error = throwError {
            throw error
        }
        return mockLocations
    }

    func saveLocation(_ location: Location) async throws {
        saveLocationCallCount += 1
        if shouldThrowError, let error = throwError {
            throw error
        }
        mockLocations.removeAll { $0.id == location.id }
        mockLocations.append(location)
    }

    func deleteLocation(id: UUID) async throws {
        deleteLocationCallCount += 1
        lastDeletedLocationId = id
        if shouldThrowError, let error = throwError {
            throw error
        }
        // Validate that the location exists before deletion
        guard mockLocations.contains(where: { $0.id == id }) else {
            throw PersistenceError.notFound("Location with id \(id) not found")
        }
        mockLocations.removeAll { $0.id == id }
    }

    // MARK: - Change Log

    func loadChangeLogEntries() async throws -> [ChangeLogEntry] {
        loadChangeLogEntriesCallCount += 1
        if shouldThrowError, let error = throwError {
            throw error
        }
        return mockChangeLogEntries
    }

    func addChangeLogEntry(_ entry: ChangeLogEntry) async throws {
        addChangeLogEntryCallCount += 1
        if shouldThrowError, let error = throwError {
            throw error
        }
        mockChangeLogEntries.append(entry)
    }

    func addMultipleChangeLogEntries(_ entries: [ChangeLogEntry]) async throws {
        addMultipleChangeLogEntriesCallCount += 1
        if shouldThrowError, let error = throwError {
            throw error
        }
        mockChangeLogEntries.append(contentsOf: entries)
    }

    func deleteChangeLogEntry(id: UUID) async throws {
        deleteChangeLogEntryCallCount += 1
        lastDeletedChangeLogEntryId = id
        if shouldThrowError, let error = throwError {
            throw error
        }
        // Validate that the change log entry exists before deletion
        guard mockChangeLogEntries.contains(where: { $0.id == id }) else {
            throw PersistenceError.notFound("ChangeLogEntry with id \(id) not found")
        }
        mockChangeLogEntries.removeAll { $0.id == id }
    }

    func purgeOldChangeLogEntries(olderThan cutoffDate: Date) async throws -> Int {
        purgeOldChangeLogEntriesCallCount += 1
        lastPurgeOldEntriesCutoffDate = cutoffDate
        if shouldThrowError, let error = throwError {
            throw error
        }
        let oldCount = mockChangeLogEntries.count
        mockChangeLogEntries.removeAll { $0.timestamp < cutoffDate }
        return oldCount - mockChangeLogEntries.count
    }

    func getChangeLogMetadata() async throws -> (count: Int, oldestDate: Date?) {
        getChangeLogMetadataCallCount += 1
        if shouldThrowError, let error = throwError {
            throw error
        }
        let count = mockChangeLogEntries.count
        let oldestDate = mockChangeLogEntries.map { $0.timestamp }.min()
        return (count, oldestDate)
    }

    // MARK: - Undo/Redo Stacks

    func loadUndoRedoStacks() async throws -> (undo: [ChangeLogEntry], redo: [ChangeLogEntry]) {
        loadUndoRedoStacksCallCount += 1
        if shouldThrowError, let error = throwError {
            throw error
        }
        return (mockUndoStack, mockRedoStack)
    }

    func saveUndoRedoStacks(undo: [ChangeLogEntry], redo: [ChangeLogEntry]) async throws {
        saveUndoRedoStacksCallCount += 1
        if shouldThrowError, let error = throwError {
            throw error
        }
        mockUndoStack = undo
        mockRedoStack = redo
    }

    // MARK: - User Profile

    func loadUserProfile() async throws -> UserProfile {
        loadUserProfileCallCount += 1
        if shouldThrowError, let error = throwError {
            throw error
        }
        return mockUserProfile
    }

    func saveUserProfile(_ profile: UserProfile) async throws {
        saveUserProfileCallCount += 1
        if shouldThrowError, let error = throwError {
            throw error
        }
        mockUserProfile = profile
    }
}
