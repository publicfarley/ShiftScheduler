import Testing
import Foundation
@testable import ShiftScheduler

/// Integration tests for PersistenceService
/// Validates shift types, locations, change log, and undo/redo persistence
/// Note: These tests use actual file-based repositories with temporary directories
@Suite("PersistenceService Integration Tests")
@MainActor
struct PersistenceServiceIntegrationTests {

    // MARK: - Setup Helpers

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

    /// Create a PersistenceService with temporary directory
    static func createTestService() -> (service: PersistenceService, tempDir: URL) {
        let tempDir = createTemporaryDirectory()
        let shiftTypeRepo = ShiftTypeRepository(directoryURL: tempDir)
        let locationRepo = LocationRepository(directoryURL: tempDir)
        let changeLogRepo = ChangeLogRepository(directoryURL: tempDir)
        let userProfileRepo = UserProfileRepository(directoryURL: tempDir)
        let service = PersistenceService(
            shiftTypeRepository: shiftTypeRepo,
            locationRepository: locationRepo,
            changeLogRepository: changeLogRepo,
            userProfileRepository: userProfileRepo
        )
        return (service, tempDir)
    }

    /// Create a test location
    static func createTestLocation() -> Location {
        Location(id: UUID(), name: "Test Office", address: "123 Test St")
    }

    /// Create a test shift type
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

    /// Create a test change log entry with fixed date
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

    // MARK: - Tests: Shift Type Operations

    @Test("loadShiftTypes returns array of ShiftType")
    func testLoadShiftTypesReturnsShiftTypeArray() async throws {
        // Given
        let (service, tempDir) = Self.createTestService()
        defer { Self.cleanupTemporaryDirectory(tempDir) }

        // Then
        await #expect(throws: Never.self) {
            // When
            _ = try await service.loadShiftTypes()
        }
    }

    @Test("saveShiftType persists shift type")
    func testSaveShiftTypePersistsShiftType() async throws {
        // Given
        let (service, tempDir) = Self.createTestService()
        defer { Self.cleanupTemporaryDirectory(tempDir) }
        let shiftType = Self.createTestShiftType()

        // When
        try await service.saveShiftType(shiftType)

        // Then - Verify it was saved by loading all
        let allTypes = try await service.loadShiftTypes()
        #expect(allTypes.contains { $0.id == shiftType.id })
    }

    @Test("deleteShiftType removes shift type")
    func testDeleteShiftTypeRemovesShiftType() async throws {
        // Given
        let (service, tempDir) = Self.createTestService()
        defer { Self.cleanupTemporaryDirectory(tempDir) }
        let shiftType = Self.createTestShiftType()

        // When
        try await service.saveShiftType(shiftType)
        try await service.deleteShiftType(id: shiftType.id)

        // Then
        let remaining = try await service.loadShiftTypes()
        #expect(!remaining.contains { $0.id == shiftType.id })
    }

    // MARK: - Tests: Location Operations

    @Test("saveLocation persists location")
    func testSaveLocationPersistsLocation() async throws {
        // Given
        let (service, tempDir) = Self.createTestService()
        defer { Self.cleanupTemporaryDirectory(tempDir) }
        let location = Self.createTestLocation()

        // When
        try await service.saveLocation(location)

        // Then
        let allLocations = try await service.loadLocations()
        #expect(allLocations.contains { $0.id == location.id })
    }

    @Test("deleteLocation removes location")
    func testDeleteLocationRemovesLocation() async throws {
        // Given
        let (service, tempDir) = Self.createTestService()
        defer { Self.cleanupTemporaryDirectory(tempDir) }
        let location = Self.createTestLocation()

        // When
        try await service.saveLocation(location)
        try await service.deleteLocation(id: location.id)

        // Then
        let remaining = try await service.loadLocations()
        #expect(!remaining.contains { $0.id == location.id })
    }

    // MARK: - Tests: Change Log Operations

    @Test("addChangeLogEntry persists entry")
    func testAddChangeLogEntryPersistsEntry() async throws {
        // Given
        let (service, tempDir) = Self.createTestService()
        defer { Self.cleanupTemporaryDirectory(tempDir) }
        let entry = try Self.createTestChangeLogEntry()

        // When
        try await service.addChangeLogEntry(entry)

        // Then
        let allEntries = try await service.loadChangeLogEntries()
        #expect(allEntries.contains { $0.id == entry.id })
    }

    @Test("addChangeLogEntry with different change types")
    func testAddChangeLogEntryWithDifferentChangeTypes() async throws {
        // Given
        let (service, tempDir) = Self.createTestService()
        defer { Self.cleanupTemporaryDirectory(tempDir) }

        let fixedDate = try #require(Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 29)))

        let switchedEntry = ChangeLogEntry(
            id: UUID(),
            timestamp: fixedDate,
            userId: UUID(),
            userDisplayName: "User 1",
            changeType: .switched,
            scheduledShiftDate: fixedDate,
            oldShiftSnapshot: nil,
            newShiftSnapshot: nil,
            reason: "Switched shift"
        )

        let deletedEntry = ChangeLogEntry(
            id: UUID(),
            timestamp: fixedDate,
            userId: UUID(),
            userDisplayName: "User 2",
            changeType: .deleted,
            scheduledShiftDate: fixedDate,
            oldShiftSnapshot: nil,
            newShiftSnapshot: nil,
            reason: "Deleted shift"
        )

        // When
        try await service.addChangeLogEntry(switchedEntry)
        try await service.addChangeLogEntry(deletedEntry)

        // Then
        let allEntries = try await service.loadChangeLogEntries()
        #expect(allEntries.contains { $0.changeType == .switched })
        #expect(allEntries.contains { $0.changeType == .deleted })
    }

    @Test("purgeOldChangeLogEntries returns integer count")
    func testPurgeOldChangeLogEntriesReturnsCount() async throws {
        // Given
        let (service, tempDir) = Self.createTestService()
        defer { Self.cleanupTemporaryDirectory(tempDir) }

        // When
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -30, to: try Date.fixedTestDate_Nov11_2025()) ?? try Date.fixedTestDate_Nov11_2025()
        let count = try await service.purgeOldChangeLogEntries(olderThan: cutoffDate)

        // Then - purge should return non-negative count of purged entries
        #expect(count >= 0)
    }

    // MARK: - Tests: User Profile Operations

    @Test("loadUserProfile does not throw")
    func testLoadUserProfileReturnsUserProfile() async throws {
        // Given
        let (service, tempDir) = Self.createTestService()
        defer { Self.cleanupTemporaryDirectory(tempDir) }

        // Then
        await #expect(throws: Never.self) {
            // When
            _ = try await service.loadUserProfile()
        }
    }

    @Test("saveUserProfile does not throw")
    func testSaveUserProfileDoesNotThrow() async throws {
        // Given
        let (service, tempDir) = Self.createTestService()
        defer { Self.cleanupTemporaryDirectory(tempDir) }
        let profile = UserProfile(userId: UUID(), displayName: "Test User")

        // Then
        await #expect(throws: Never.self) {
            // When
            try await service.saveUserProfile(profile)
        }
    }

    // MARK: - Tests: Undo/Redo Stacks

    @Test("loadUndoRedoStacks returns empty stacks when no file exists")
    func testLoadUndoRedoStacksReturnsTuple() async throws {
        // Given
        let (service, tempDir) = Self.createTestService()
        defer { Self.cleanupTemporaryDirectory(tempDir) }

        // When
        let (undo, redo) = try await service.loadUndoRedoStacks()

        // Then
        #expect(undo.isEmpty)
        #expect(redo.isEmpty)
    }

    @Test("saveUndoRedoStacks persists stacks to file")
    func testSaveUndoRedoStacksDoesNotThrow() async throws {
        // Given
        let (service, tempDir) = Self.createTestService()
        defer { Self.cleanupTemporaryDirectory(tempDir) }

        let fixedDate = try #require(Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 29)))
        let entry1 = ChangeLogEntry(
            id: UUID(),
            timestamp: fixedDate,
            userId: UUID(),
            userDisplayName: "User 1",
            changeType: .switched,
            scheduledShiftDate: fixedDate
        )
        let entry2 = ChangeLogEntry(
            id: UUID(),
            timestamp: fixedDate,
            userId: UUID(),
            userDisplayName: "User 2",
            changeType: .deleted,
            scheduledShiftDate: fixedDate
        )

        // When
        try await service.saveUndoRedoStacks(undo: [entry1], redo: [entry2])

        // Then - verify stacks persisted correctly
        let (undo, redo) = try await service.loadUndoRedoStacks()
        #expect(undo.count == 1)
        #expect(redo.count == 1)
        #expect(undo[0].id == entry1.id)
        #expect(redo[0].id == entry2.id)
    }

    @Test("saveUndoRedoStacks with empty stacks creates file")
    func testSaveUndoRedoStacksWithEmptyStacks() async throws {
        // Given
        let (service, tempDir) = Self.createTestService()
        defer { Self.cleanupTemporaryDirectory(tempDir) }

        // When
        try await service.saveUndoRedoStacks(undo: [], redo: [])

        // Then
        let (undo, redo) = try await service.loadUndoRedoStacks()
        #expect(undo.isEmpty)
        #expect(redo.isEmpty)
    }

    @Test("loadUndoRedoStacks retrieves multiple entries")
    func testLoadUndoRedoStacksRetrievesMultipleEntries() async throws {
        // Given
        let (service, tempDir) = Self.createTestService()
        defer { Self.cleanupTemporaryDirectory(tempDir) }

        let fixedDate = try #require(Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 29)))
        var entries: [ChangeLogEntry] = []
        for i in 0..<3 {
            let entry = ChangeLogEntry(
                id: UUID(),
                timestamp: fixedDate.addingTimeInterval(TimeInterval(i * 3600)),
                userId: UUID(),
                userDisplayName: "User \(i)",
                changeType: .switched,
                scheduledShiftDate: fixedDate
            )
            entries.append(entry)
        }

        // When
        try await service.saveUndoRedoStacks(undo: entries, redo: [])

        // Then
        let (undo, redo) = try await service.loadUndoRedoStacks()
        #expect(undo.count == 3)
        #expect(redo.isEmpty)
        #expect(undo[0].id == entries[0].id)
        #expect(undo[1].id == entries[1].id)
        #expect(undo[2].id == entries[2].id)
    }

    @Test("saveUndoRedoStacks overwrites previous stacks")
    func testSaveUndoRedoStacksOverwritesPreviousStacks() async throws {
        // Given
        let (service, tempDir) = Self.createTestService()
        defer { Self.cleanupTemporaryDirectory(tempDir) }

        let fixedDate = try #require(Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 29)))
        let entry1 = ChangeLogEntry(
            id: UUID(),
            timestamp: fixedDate,
            userId: UUID(),
            userDisplayName: "User 1",
            changeType: .switched,
            scheduledShiftDate: fixedDate
        )
        let entry2 = ChangeLogEntry(
            id: UUID(),
            timestamp: fixedDate,
            userId: UUID(),
            userDisplayName: "User 2",
            changeType: .deleted,
            scheduledShiftDate: fixedDate
        )

        // When - first save
        try await service.saveUndoRedoStacks(undo: [entry1], redo: [])

        // And - second save overwrites
        try await service.saveUndoRedoStacks(undo: [entry2], redo: [entry1])

        // Then
        let (undo, redo) = try await service.loadUndoRedoStacks()
        #expect(undo.count == 1)
        #expect(redo.count == 1)
        #expect(undo[0].id == entry2.id)
        #expect(redo[0].id == entry1.id)
    }

    // MARK: - Tests: Multiple Operations

    @Test("Multiple shift types can be saved and retrieved")
    func testMultipleShiftTypesSavedAndRetrieved() async throws {
        // Given
        let (service, tempDir) = Self.createTestService()
        defer { Self.cleanupTemporaryDirectory(tempDir) }
        let type1 = Self.createTestShiftType()
        let type2 = Self.createTestShiftType()

        // When
        try await service.saveShiftType(type1)
        try await service.saveShiftType(type2)
        let allTypes = try await service.loadShiftTypes()

        // Then
        #expect(allTypes.contains { $0.id == type1.id })
        #expect(allTypes.contains { $0.id == type2.id })
    }

    @Test("Multiple locations can be saved and retrieved")
    func testMultipleLocationsSavedAndRetrieved() async throws {
        // Given
        let (service, tempDir) = Self.createTestService()
        defer { Self.cleanupTemporaryDirectory(tempDir) }
        let loc1 = Location(id: UUID(), name: "Office 1", address: "123 Main St")
        let loc2 = Location(id: UUID(), name: "Office 2", address: "456 Oak Ave")

        // When
        try await service.saveLocation(loc1)
        try await service.saveLocation(loc2)
        let allLocations = try await service.loadLocations()

        // Then
        #expect(allLocations.contains { $0.id == loc1.id })
        #expect(allLocations.contains { $0.id == loc2.id })
    }

    @Test("Shift types can be updated by saving with same ID")
    func testShiftTypeCanBeUpdated() async throws {
        // Given
        let (service, tempDir) = Self.createTestService()
        defer { Self.cleanupTemporaryDirectory(tempDir) }
        let originalType = Self.createTestShiftType()

        // When - Save original
        try await service.saveShiftType(originalType)

        // Update with same ID but different title
        let location = originalType.location
        let updatedType = ShiftType(
            id: originalType.id,
            symbol: "🌙",
            duration: .allDay,
            title: "Evening Shift",
            description: "Updated",
            location: location
        )
        try await service.saveShiftType(updatedType)

        // Then
        let allTypes = try await service.loadShiftTypes()
        let saved = allTypes.first { $0.id == originalType.id }
        #expect(saved?.title == "Evening Shift")
        #expect(saved?.symbol == "🌙")
    }
}
