import Foundation

/// Mock implementation of PersistenceServiceProtocol for testing
final class MockPersistenceService: PersistenceServiceProtocol {
    var mockShiftTypes: [ShiftType] = []
    var mockLocations: [Location] = []
    var mockChangeLogEntries: [ChangeLogEntry] = []
    var mockUserProfile: UserProfile = UserProfile(userId: UUID(), displayName: "Test User", retentionPolicy: .forever, autoPurgeEnabled: true)
    var mockUndoStack: [ChangeLogEntry] = []
    var mockRedoStack: [ChangeLogEntry] = []

    var shouldThrowError: Bool = false
    var throwError: Error?

    // MARK: - Call Tracking for Testing

    private(set) var loadShiftTypesCallCount = 0
    private(set) var saveShiftTypeCallCount = 0
    private(set) var deleteShiftTypeCallCount = 0
    private(set) var loadLocationsCallCount = 0
    private(set) var saveLocationCallCount = 0
    private(set) var deleteLocationCallCount = 0
    private(set) var loadChangeLogEntriesCallCount = 0
    private(set) var addChangeLogEntryCallCount = 0
    private(set) var deleteChangeLogEntryCallCount = 0
    private(set) var purgeOldChangeLogEntriesCallCount = 0
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
        mockShiftTypes.removeAll { $0.id == id }
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

    func deleteChangeLogEntry(id: UUID) async throws {
        deleteChangeLogEntryCallCount += 1
        lastDeletedChangeLogEntryId = id
        if shouldThrowError, let error = throwError {
            throw error
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
