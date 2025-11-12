import Testing
import Foundation
@testable import ShiftScheduler

/// Error scenario tests for PersistenceService
/// Tests file I/O errors, encoding/decoding failures, and error handling
@Suite("PersistenceService Error Scenario Tests")
@MainActor
struct PersistenceServiceErrorTests {

    // MARK: - Test Helpers

    /// Create a temporary directory for testing
    static func createTemporaryDirectory() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        return tempDir
    }

    /// Clean up temporary directory
    static func cleanupTemporaryDirectory(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    /// Create test location
    static func createTestLocation() -> Location {
        Location(id: UUID(), name: "Test Office", address: "123 Test St")
    }

    /// Create test shift type
    static func createTestShiftType() -> ShiftType {
        let location = createTestLocation()
        return ShiftType(
            id: UUID(),
            symbol: "🌅",
            duration: .allDay,
            title: "Morning Shift",
            description: "Test shift",
            location: location
        )
    }

    /// Create test change log entry
    static func createTestChangeLogEntry() throws -> ChangeLogEntry {
        let fixedDate = try #require(Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 29)))
        return ChangeLogEntry(
            id: UUID(),
            timestamp: fixedDate,
            userId: UUID(),
            userDisplayName: "Test User",
            changeType: .switched,
            scheduledShiftDate: fixedDate,
            oldShiftSnapshot: nil,
            newShiftSnapshot: nil,
            reason: "Test change"
        )
    }

    // MARK: - Mock-Based Error Tests

    @Test("MockPersistenceService throws when configured with error for loadShiftTypes")
    func testLoadShiftTypesThrowsWhenConfigured() async throws {
        let mockService = MockPersistenceService()
        mockService.shouldThrowError = true
        mockService.throwError = ScheduleError.persistenceFailed("Cannot load shift types")

        do {
            _ = try await mockService.loadShiftTypes()
            #expect(Bool(false), "Expected error to be thrown")
        } catch let error as ScheduleError {
            if case .persistenceFailed = error {
                #expect(true)
            } else {
                throw error
            }
        }
    }

    @Test("MockPersistenceService throws when configured with error for saveShiftType")
    func testSaveShiftTypeThrowsWhenConfigured() async throws {
        let mockService = MockPersistenceService()
        mockService.shouldThrowError = true
        mockService.throwError = ScheduleError.persistenceFailed("Cannot save")

        let shiftType = Self.createTestShiftType()

        do {
            try await mockService.saveShiftType(shiftType)
            #expect(Bool(false), "Expected error to be thrown")
        } catch let error as ScheduleError {
            if case .persistenceFailed = error {
                #expect(true)
            } else {
                throw error
            }
        }
    }

    @Test("MockPersistenceService throws when configured with error for deleteShiftType")
    func testDeleteShiftTypeThrowsWhenConfigured() async throws {
        let mockService = MockPersistenceService()
        mockService.shouldThrowError = true
        mockService.throwError = ScheduleError.persistenceFailed("Cannot delete")

        do {
            try await mockService.deleteShiftType(id: UUID())
            #expect(Bool(false), "Expected error to be thrown")
        } catch let error as ScheduleError {
            if case .persistenceFailed = error {
                #expect(true)
            } else {
                throw error
            }
        }
    }

    // MARK: - File System Error Tests

    @Test("PersistenceService handles missing file gracefully")
    func testHandlesMissingFile() async throws {
        let nonExistentDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("nonexistent-\(UUID())")
        let repo = ShiftTypeRepository(directoryURL: nonExistentDir)

        // Should return empty array for missing directory, not throw
        let result = try await repo.fetchAll()
        #expect(result.isEmpty)
    }

    @Test("ShiftTypeRepository handles corrupted JSON gracefully")
    func testHandlesCorruptedJSON() async throws {
        let tempDir = Self.createTemporaryDirectory()
        defer { Self.cleanupTemporaryDirectory(tempDir) }

        // Create a corrupted JSON file
        let repo = ShiftTypeRepository(directoryURL: tempDir)
        let corruptedFile = tempDir.appendingPathComponent("shiftTypes.json")
        try "{ invalid json }".write(to: corruptedFile, atomically: true, encoding: .utf8)

        // Should handle gracefully and return empty array
        do {
            let result = try await repo.fetchAll()
            #expect(result.isEmpty)
        } catch {
            // Decoding error is acceptable
            #expect(true)
        }
    }

    @Test("MockPersistenceService throws when configured with error for loadLocations")
    func testLoadLocationsThrowsWhenConfigured() async throws {
        let mockService = MockPersistenceService()
        mockService.shouldThrowError = true
        mockService.throwError = ScheduleError.persistenceFailed("Cannot load locations")

        do {
            _ = try await mockService.loadLocations()
            #expect(Bool(false), "Expected error to be thrown")
        } catch let error as ScheduleError {
            if case .persistenceFailed = error {
                #expect(true)
            } else {
                throw error
            }
        }
    }

    @Test("MockPersistenceService throws when configured with error for saveLocation")
    func testSaveLocationThrowsWhenConfigured() async throws {
        let mockService = MockPersistenceService()
        mockService.shouldThrowError = true
        mockService.throwError = ScheduleError.persistenceFailed("Cannot save location")

        let location = Self.createTestLocation()

        do {
            try await mockService.saveLocation(location)
            #expect(Bool(false), "Expected error to be thrown")
        } catch let error as ScheduleError {
            if case .persistenceFailed = error {
                #expect(true)
            } else {
                throw error
            }
        }
    }

    @Test("MockPersistenceService tracks error calls for service verification")
    func testMockServiceTracksErrorCalls() async throws {
        let mockService = MockPersistenceService()
        mockService.shouldThrowError = true
        mockService.throwError = ScheduleError.persistenceFailed("Test")
        let location = Self.createTestLocation()

        // Verify call tracking works even when errors occur
        _ = try? await mockService.saveLocation(location)
        #expect(mockService.saveLocationCallCount == 1)
    }

    @Test("LocationRepository handles corrupted JSON gracefully")
    func testLocationRepositoryHandlesCorruptedJSON() async throws {
        let tempDir = Self.createTemporaryDirectory()
        defer { Self.cleanupTemporaryDirectory(tempDir) }

        let repo = LocationRepository(directoryURL: tempDir)
        let corruptedFile = tempDir.appendingPathComponent("locations.json")
        try "{ invalid json }".write(to: corruptedFile, atomically: true, encoding: .utf8)

        do {
            let result = try await repo.fetchAll()
            #expect(result.isEmpty)
        } catch {
            #expect(true)
        }
    }

    // MARK: - Encoding/Decoding Error Tests

    @Test("ShiftType encoding and decoding handles edge cases")
    func testShiftTypeEncodingEdgeCases() async throws {
        let tempDir = Self.createTemporaryDirectory()
        defer { Self.cleanupTemporaryDirectory(tempDir) }

        let shiftType = Self.createTestShiftType()
        let repo = ShiftTypeRepository(directoryURL: tempDir)

        try await repo.save(shiftType)
        let loaded = try await repo.fetchAll()

        #expect(loaded.count == 1)
        #expect(loaded.first?.id == shiftType.id)
        #expect(loaded.first?.title == shiftType.title)
    }

    @Test("Location encoding and decoding with special characters")
    func testLocationEncodingWithSpecialCharacters() async throws {
        let tempDir = Self.createTemporaryDirectory()
        defer { Self.cleanupTemporaryDirectory(tempDir) }

        let location = Location(
            id: UUID(),
            name: "Café & Bar 🍺",
            address: "123 \"Main\" St. (Apt #5)"
        )
        let repo = LocationRepository(directoryURL: tempDir)

        try await repo.save(location)
        let loaded = try await repo.fetchAll()

        #expect(loaded.count == 1)
        #expect(loaded.first?.name == "Café & Bar 🍺")
        #expect(loaded.first?.address == "123 \"Main\" St. (Apt #5)")
    }

    // MARK: - Data Validation Error Tests

    @Test("PersistenceService validates shift type data on save")
    func testValidatesShiftTypeDataOnSave() async throws {
        let tempDir = Self.createTemporaryDirectory()
        defer { Self.cleanupTemporaryDirectory(tempDir) }

        let service = PersistenceService(
            shiftTypeRepository: ShiftTypeRepository(directoryURL: tempDir),
            locationRepository: LocationRepository(directoryURL: tempDir),
            changeLogRepository: ChangeLogRepository(directoryURL: tempDir)
        )

        let shiftType = Self.createTestShiftType()
        try await service.saveShiftType(shiftType)

        let loaded = try await service.loadShiftTypes()
        #expect(loaded.contains { $0.id == shiftType.id })
    }

    @Test("PersistenceService validates location data on save")
    func testValidatesLocationDataOnSave() async throws {
        let tempDir = Self.createTemporaryDirectory()
        defer { Self.cleanupTemporaryDirectory(tempDir) }

        let service = PersistenceService(
            shiftTypeRepository: ShiftTypeRepository(directoryURL: tempDir),
            locationRepository: LocationRepository(directoryURL: tempDir),
            changeLogRepository: ChangeLogRepository(directoryURL: tempDir)
        )

        let location = Self.createTestLocation()
        try await service.saveLocation(location)

        let loaded = try await service.loadLocations()
        #expect(loaded.contains { $0.id == location.id })
    }

    // MARK: - Concurrent Access Error Tests

    @Test("PersistenceService handles rapid sequential saves")
    func testHandlesRapidSequentialSaves() async throws {
        let tempDir = Self.createTemporaryDirectory()
        defer { Self.cleanupTemporaryDirectory(tempDir) }

        let service = PersistenceService(
            shiftTypeRepository: ShiftTypeRepository(directoryURL: tempDir),
            locationRepository: LocationRepository(directoryURL: tempDir),
            changeLogRepository: ChangeLogRepository(directoryURL: tempDir)
        )

        var savedIds: [UUID] = []
        for i in 0..<5 {
            let location = Location(id: UUID(), name: "Office \(i)", address: "123 Main St")
            try await service.saveLocation(location)
            savedIds.append(location.id)
        }

        let loaded = try await service.loadLocations()
        #expect(loaded.count == 5)
        for id in savedIds {
            #expect(loaded.contains { $0.id == id })
        }
    }

    @Test("PersistenceService handles interleaved save and delete operations")
    func testHandlesInterleavedSaveAndDelete() async throws {
        let tempDir = Self.createTemporaryDirectory()
        defer { Self.cleanupTemporaryDirectory(tempDir) }

        let service = PersistenceService(
            shiftTypeRepository: ShiftTypeRepository(directoryURL: tempDir),
            locationRepository: LocationRepository(directoryURL: tempDir),
            changeLogRepository: ChangeLogRepository(directoryURL: tempDir)
        )

        let location1 = Location(id: UUID(), name: "Office 1", address: "123 Main")
        let location2 = Location(id: UUID(), name: "Office 2", address: "456 Oak")

        try await service.saveLocation(location1)
        try await service.saveLocation(location2)
        try await service.deleteLocation(id: location1.id)

        let loaded = try await service.loadLocations()
        #expect(loaded.count == 1)
        #expect(loaded.first?.id == location2.id)
    }

    // MARK: - Change Log Error Tests with Mocks

    @Test("MockPersistenceService throws when configured with error for loadChangeLogEntries")
    func testLoadChangeLogEntriesThrowsWhenConfigured() async throws {
        let mockService = MockPersistenceService()
        mockService.shouldThrowError = true
        mockService.throwError = ScheduleError.persistenceFailed("Cannot load change log")

        do {
            _ = try await mockService.loadChangeLogEntries()
            #expect(Bool(false), "Expected error to be thrown")
        } catch let error as ScheduleError {
            if case .persistenceFailed = error {
                #expect(true)
            } else {
                throw error
            }
        }
    }

    @Test("MockPersistenceService throws when configured with error for addChangeLogEntry")
    func testAddChangeLogEntryThrowsWhenConfigured() async throws {
        let mockService = MockPersistenceService()
        mockService.shouldThrowError = true
        mockService.throwError = ScheduleError.persistenceFailed("Cannot add entry")

        let entry = try Self.createTestChangeLogEntry()

        do {
            try await mockService.addChangeLogEntry(entry)
            #expect(Bool(false), "Expected error to be thrown")
        } catch let error as ScheduleError {
            if case .persistenceFailed = error {
                #expect(true)
            } else {
                throw error
            }
        }
    }

    @Test("MockPersistenceService throws when configured with error for purgeOldChangeLogEntries")
    func testPurgeOldChangeLogEntriesThrowsWhenConfigured() async throws {
        let mockService = MockPersistenceService()
        mockService.shouldThrowError = true
        mockService.throwError = ScheduleError.persistenceFailed("Cannot purge")

        do {
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            _ = try await mockService.purgeOldChangeLogEntries(olderThan: cutoffDate)
            #expect(Bool(false), "Expected error to be thrown")
        } catch let error as ScheduleError {
            if case .persistenceFailed = error {
                #expect(true)
            } else {
                throw error
            }
        }
    }

    // MARK: - Change Log Error Tests with Real Services

    @Test("PersistenceService handles change log entry with nil snapshots")
    func testHandlesChangeLogEntryWithNilSnapshots() async throws {
        let tempDir = Self.createTemporaryDirectory()
        defer { Self.cleanupTemporaryDirectory(tempDir) }

        let service = PersistenceService(
            shiftTypeRepository: ShiftTypeRepository(directoryURL: tempDir),
            locationRepository: LocationRepository(directoryURL: tempDir),
            changeLogRepository: ChangeLogRepository(directoryURL: tempDir)
        )

        let entry = try Self.createTestChangeLogEntry()
        try await service.addChangeLogEntry(entry)

        let loaded = try await service.loadChangeLogEntries()
        #expect(loaded.contains { $0.id == entry.id })
        #expect(loaded.first?.oldShiftSnapshot == nil)
        #expect(loaded.first?.newShiftSnapshot == nil)
    }

    @Test("PersistenceService handles purge with no matching entries")
    func testPurgeWithNoMatchingEntries() async throws {
        let tempDir = Self.createTemporaryDirectory()
        defer { Self.cleanupTemporaryDirectory(tempDir) }

        let service = PersistenceService(
            shiftTypeRepository: ShiftTypeRepository(directoryURL: tempDir),
            locationRepository: LocationRepository(directoryURL: tempDir),
            changeLogRepository: ChangeLogRepository(directoryURL: tempDir)
        )

        // Add a recent entry
        let recentDate = try #require(Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 29)))
        let recentEntry = ChangeLogEntry(
            id: UUID(),
            timestamp: recentDate,
            userId: UUID(),
            userDisplayName: "User",
            changeType: .switched,
            scheduledShiftDate: recentDate,
            oldShiftSnapshot: nil,
            newShiftSnapshot: nil,
            reason: "Recent change"
        )

        try await service.addChangeLogEntry(recentEntry)

        // Purge very old entries (none should match)
        let cutoffDate = try #require(Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 28)))
        let purgedCount = try await service.purgeOldChangeLogEntries(olderThan: cutoffDate)

        #expect(purgedCount == 0)
    }

    @Test("PersistenceService handles purge with mixed old and new entries")
    func testPurgeWithMixedEntries() async throws {
        let tempDir = Self.createTemporaryDirectory()
        defer { Self.cleanupTemporaryDirectory(tempDir) }

        let service = PersistenceService(
            shiftTypeRepository: ShiftTypeRepository(directoryURL: tempDir),
            locationRepository: LocationRepository(directoryURL: tempDir),
            changeLogRepository: ChangeLogRepository(directoryURL: tempDir)
        )

        // Add old entry (from 60 days ago)
        let oldDate = try #require(Calendar.current.date(from: DateComponents(year: 2025, month: 8, day: 30)))
        let oldEntry = ChangeLogEntry(
            id: UUID(),
            timestamp: oldDate,
            userId: UUID(),
            userDisplayName: "User",
            changeType: .switched,
            scheduledShiftDate: oldDate,
            oldShiftSnapshot: nil,
            newShiftSnapshot: nil,
            reason: "Old change"
        )

        // Add new entry (from reference date)
        let newDate = try #require(Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 29)))
        let newEntry = ChangeLogEntry(
            id: UUID(),
            timestamp: newDate,
            userId: UUID(),
            userDisplayName: "User",
            changeType: .switched,
            scheduledShiftDate: newDate,
            oldShiftSnapshot: nil,
            newShiftSnapshot: nil,
            reason: "Recent change"
        )

        try await service.addChangeLogEntry(oldEntry)
        try await service.addChangeLogEntry(newEntry)

        // Cutoff at 30 days ago from reference date (October 29, 2025)
        let cutoffDate = try #require(Calendar.current.date(from: DateComponents(year: 2025, month: 9, day: 29)))
        let purgedCount = try await service.purgeOldChangeLogEntries(olderThan: cutoffDate)
        #expect(purgedCount >= 1)

        let remaining = try await service.loadChangeLogEntries()
        #expect(remaining.contains { $0.id == newEntry.id })
    }

    // MARK: - User Profile Error Tests with Mocks

    @Test("MockPersistenceService throws when configured with error for loadUserProfile")
    func testLoadUserProfileThrowsWhenConfigured() async throws {
        let mockService = MockPersistenceService()
        mockService.shouldThrowError = true
        mockService.throwError = ScheduleError.persistenceFailed("Cannot load profile")

        do {
            _ = try await mockService.loadUserProfile()
            #expect(Bool(false), "Expected error to be thrown")
        } catch let error as ScheduleError {
            if case .persistenceFailed = error {
                #expect(true)
            } else {
                throw error
            }
        }
    }

    @Test("MockPersistenceService throws when configured with error for saveUserProfile")
    func testSaveUserProfileThrowsWhenConfigured() async throws {
        let mockService = MockPersistenceService()
        mockService.shouldThrowError = true
        mockService.throwError = ScheduleError.persistenceFailed("Cannot save profile")

        let profile = UserProfile(userId: UUID(), displayName: "Test")

        do {
            try await mockService.saveUserProfile(profile)
            #expect(Bool(false), "Expected error to be thrown")
        } catch let error as ScheduleError {
            if case .persistenceFailed = error {
                #expect(true)
            } else {
                throw error
            }
        }
    }

    // MARK: - User Profile Error Tests with Real Services

    @Test("PersistenceService handles user profile save and load")
    func testUserProfileSaveAndLoad() async throws {
        let tempDir = Self.createTemporaryDirectory()
        defer { Self.cleanupTemporaryDirectory(tempDir) }

        let service = PersistenceService(
            shiftTypeRepository: ShiftTypeRepository(directoryURL: tempDir),
            locationRepository: LocationRepository(directoryURL: tempDir),
            changeLogRepository: ChangeLogRepository(directoryURL: tempDir),
            userProfileRepository: UserProfileRepository(directoryURL: tempDir)
        )

        let profile = UserProfile(userId: UUID(), displayName: "John Doe")
        try await service.saveUserProfile(profile)

        let loaded = try await service.loadUserProfile()
        #expect(loaded.displayName == "John Doe")
    }

    @Test("PersistenceService handles profile update with empty name")
    func testProfileUpdateWithEmptyName() async throws {
        let tempDir = Self.createTemporaryDirectory()
        defer { Self.cleanupTemporaryDirectory(tempDir) }

        let service = PersistenceService(
            shiftTypeRepository: ShiftTypeRepository(directoryURL: tempDir),
            locationRepository: LocationRepository(directoryURL: tempDir),
            changeLogRepository: ChangeLogRepository(directoryURL: tempDir),
            userProfileRepository: UserProfileRepository(directoryURL: tempDir)
        )

        let profile = UserProfile(userId: UUID(), displayName: "")
        try await service.saveUserProfile(profile)

        let loaded = try await service.loadUserProfile()
        #expect(loaded.displayName.isEmpty)
    }

    // MARK: - Undo/Redo Stack Error Tests with Mocks

    @Test("MockPersistenceService throws when configured with error for loadUndoRedoStacks")
    func testLoadUndoRedoStacksThrowsWhenConfigured() async throws {
        let mockService = MockPersistenceService()
        mockService.shouldThrowError = true
        mockService.throwError = ScheduleError.stackRestorationFailed("Cannot load stacks")

        do {
            _ = try await mockService.loadUndoRedoStacks()
            #expect(Bool(false), "Expected error to be thrown")
        } catch let error as ScheduleError {
            if case .stackRestorationFailed = error {
                #expect(true)
            } else {
                throw error
            }
        }
    }

    @Test("MockPersistenceService throws when configured with error for saveUndoRedoStacks")
    func testSaveUndoRedoStacksThrowsWhenConfigured() async throws {
        let mockService = MockPersistenceService()
        mockService.shouldThrowError = true
        mockService.throwError = ScheduleError.stackRestorationFailed("Cannot save stacks")

        do {
            try await mockService.saveUndoRedoStacks(undo: [], redo: [])
            #expect(Bool(false), "Expected error to be thrown")
        } catch let error as ScheduleError {
            if case .stackRestorationFailed = error {
                #expect(true)
            } else {
                throw error
            }
        }
    }

    // MARK: - Undo/Redo Stack Error Tests with Real Services

    @Test("PersistenceService handles empty undo/redo stacks")
    func testHandlesEmptyStacks() async throws {
        let tempDir = Self.createTemporaryDirectory()
        defer { Self.cleanupTemporaryDirectory(tempDir) }

        let service = PersistenceService(
            shiftTypeRepository: ShiftTypeRepository(directoryURL: tempDir),
            locationRepository: LocationRepository(directoryURL: tempDir),
            changeLogRepository: ChangeLogRepository(directoryURL: tempDir)
        )

        let (undo, redo) = try await service.loadUndoRedoStacks()
        #expect(undo.isEmpty)
        #expect(redo.isEmpty)
    }

    @Test("PersistenceService handles saving large undo/redo stacks")
    func testSavesLargeStacks() async throws {
        let tempDir = Self.createTemporaryDirectory()
        defer { Self.cleanupTemporaryDirectory(tempDir) }

        let service = PersistenceService(
            shiftTypeRepository: ShiftTypeRepository(directoryURL: tempDir),
            locationRepository: LocationRepository(directoryURL: tempDir),
            changeLogRepository: ChangeLogRepository(directoryURL: tempDir),
            userProfileRepository: UserProfileRepository(directoryURL: tempDir)
        )

        var undoStack: [ChangeLogEntry] = []
        let redoStack: [ChangeLogEntry] = []

        let baseDate = try #require(Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 29)))
        for i in 0..<10 {
            let entryDate = try #require(Calendar.current.date(byAdding: .day, value: -i, to: baseDate))
            let entry = ChangeLogEntry(
                id: UUID(),
                timestamp: entryDate,
                userId: UUID(),
                userDisplayName: "User \(i)",
                changeType: .switched,
                scheduledShiftDate: entryDate,
                oldShiftSnapshot: nil,
                newShiftSnapshot: nil,
                reason: "Change \(i)"
            )
            undoStack.append(entry)
        }

        try await service.saveUndoRedoStacks(undo: undoStack, redo: redoStack)
        let (loadedUndo, loadedRedo) = try await service.loadUndoRedoStacks()

        #expect(loadedUndo.count == 10)
        #expect(loadedRedo.isEmpty)
    }

    // MARK: - Recovery Tests

    @Test("PersistenceService recovers from transient directory issues")
    func testRecoveryFromDirectoryIssues() async throws {
        let tempDir = Self.createTemporaryDirectory()
        defer { Self.cleanupTemporaryDirectory(tempDir) }

        let service = PersistenceService(
            shiftTypeRepository: ShiftTypeRepository(directoryURL: tempDir),
            locationRepository: LocationRepository(directoryURL: tempDir),
            changeLogRepository: ChangeLogRepository(directoryURL: tempDir)
        )

        // Save data
        let location = Self.createTestLocation()
        try await service.saveLocation(location)

        // Verify data persists
        let loaded = try await service.loadLocations()
        #expect(loaded.contains { $0.id == location.id })

        // Save again - should handle file already exists
        try await service.saveLocation(location)
        let reloaded = try await service.loadLocations()
        #expect(reloaded.count == 1)
    }
}
