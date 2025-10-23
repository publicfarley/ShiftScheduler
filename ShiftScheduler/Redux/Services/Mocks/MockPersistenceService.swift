import Foundation

/// Mock implementation of PersistenceServiceProtocol for testing
final class MockPersistenceService: PersistenceServiceProtocol {
    var mockShiftTypes: [ShiftType] = []
    var mockLocations: [Location] = []
    var mockChangeLogEntries: [ChangeLogEntry] = []
    var mockUserProfile: UserProfile = UserProfile(userId: UUID(), displayName: "Test User")
    var mockUndoStack: [ChangeLogEntry] = []
    var mockRedoStack: [ChangeLogEntry] = []

    var shouldThrowError: Bool = false
    var throwError: Error?

    // MARK: - Shift Types

    func loadShiftTypes() async throws -> [ShiftType] {
        if shouldThrowError, let error = throwError {
            throw error
        }
        return mockShiftTypes
    }

    func saveShiftType(_ shiftType: ShiftType) async throws {
        if shouldThrowError, let error = throwError {
            throw error
        }
        mockShiftTypes.removeAll { $0.id == shiftType.id }
        mockShiftTypes.append(shiftType)
    }

    func deleteShiftType(id: UUID) async throws {
        if shouldThrowError, let error = throwError {
            throw error
        }
        mockShiftTypes.removeAll { $0.id == id }
    }

    // MARK: - Locations

    func loadLocations() async throws -> [Location] {
        if shouldThrowError, let error = throwError {
            throw error
        }
        return mockLocations
    }

    func saveLocation(_ location: Location) async throws {
        if shouldThrowError, let error = throwError {
            throw error
        }
        mockLocations.removeAll { $0.id == location.id }
        mockLocations.append(location)
    }

    func deleteLocation(id: UUID) async throws {
        if shouldThrowError, let error = throwError {
            throw error
        }
        mockLocations.removeAll { $0.id == id }
    }

    // MARK: - Change Log

    func loadChangeLogEntries() async throws -> [ChangeLogEntry] {
        if shouldThrowError, let error = throwError {
            throw error
        }
        return mockChangeLogEntries
    }

    func addChangeLogEntry(_ entry: ChangeLogEntry) async throws {
        if shouldThrowError, let error = throwError {
            throw error
        }
        mockChangeLogEntries.append(entry)
    }

    func deleteChangeLogEntry(id: UUID) async throws {
        if shouldThrowError, let error = throwError {
            throw error
        }
        mockChangeLogEntries.removeAll { $0.id == id }
    }

    func purgeOldChangeLogEntries(olderThanDays: Int) async throws -> Int {
        if shouldThrowError, let error = throwError {
            throw error
        }
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -olderThanDays, to: Date()) ?? Date()
        let oldCount = mockChangeLogEntries.count
        mockChangeLogEntries.removeAll { $0.timestamp < cutoffDate }
        return oldCount - mockChangeLogEntries.count
    }

    // MARK: - Undo/Redo Stacks

    func loadUndoRedoStacks() async throws -> (undo: [ChangeLogEntry], redo: [ChangeLogEntry]) {
        if shouldThrowError, let error = throwError {
            throw error
        }
        return (mockUndoStack, mockRedoStack)
    }

    func saveUndoRedoStacks(undo: [ChangeLogEntry], redo: [ChangeLogEntry]) async throws {
        if shouldThrowError, let error = throwError {
            throw error
        }
        mockUndoStack = undo
        mockRedoStack = redo
    }

    // MARK: - User Profile

    func loadUserProfile() async throws -> UserProfile {
        if shouldThrowError, let error = throwError {
            throw error
        }
        return mockUserProfile
    }

    func saveUserProfile(_ profile: UserProfile) async throws {
        if shouldThrowError, let error = throwError {
            throw error
        }
        mockUserProfile = profile
    }
}
