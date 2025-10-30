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
        let changeLogRepo = ChangeLogRepository() // Uses default directory
        let service = PersistenceService(
            shiftTypeRepository: shiftTypeRepo,
            locationRepository: locationRepo,
            changeLogRepository: changeLogRepo
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
    static func createTestChangeLogEntry() -> ChangeLogEntry {
        let fixedDate = Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 29))!
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

    @Test("PersistenceService initializes with default repositories")
    func testPersistenceServiceInitializesWithDefaultRepositories() {
        // Given - Create service with defaults
        let service = PersistenceService()

        // Then - Verify it doesn't throw on creation
        #expect(service != nil)
    }

    @Test("PersistenceService can be initialized with custom repositories")
    func testPersistenceServiceCanInitializeWithCustomRepositories() {
        // Given
        let customShiftTypeRepository = ShiftTypeRepository()
        let customLocationRepository = LocationRepository()
        let customChangeLogRepository = ChangeLogRepository()

        // When
        let service = PersistenceService(
            shiftTypeRepository: customShiftTypeRepository,
            locationRepository: customLocationRepository,
            changeLogRepository: customChangeLogRepository
        )

        // Then
        #expect(service != nil)
    }

    @Test("loadShiftTypes returns array of ShiftType")
    func testLoadShiftTypesReturnsShiftTypeArray() async throws {
        // Given
        let (service, tempDir) = Self.createTestService()
        defer { Self.cleanupTemporaryDirectory(tempDir) }

        // When
        let result = try await service.loadShiftTypes()

        // Then
        #expect(result is [ShiftType])
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

    @Test("loadLocations returns array of Location")
    func testLoadLocationsReturnsLocationArray() async throws {
        // Given
        let (service, tempDir) = Self.createTestService()
        defer { Self.cleanupTemporaryDirectory(tempDir) }

        // When
        let result = try await service.loadLocations()

        // Then
        #expect(result is [Location])
    }

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

    @Test("loadChangeLogEntries returns array of ChangeLogEntry")
    func testLoadChangeLogEntriesReturnsEntryArray() async throws {
        // Given
        let (service, tempDir) = Self.createTestService()
        defer { Self.cleanupTemporaryDirectory(tempDir) }

        // When
        let result = try await service.loadChangeLogEntries()

        // Then
        #expect(result is [ChangeLogEntry])
    }

    @Test("addChangeLogEntry persists entry")
    func testAddChangeLogEntryPersistsEntry() async throws {
        // Given
        let (service, tempDir) = Self.createTestService()
        defer { Self.cleanupTemporaryDirectory(tempDir) }
        let entry = Self.createTestChangeLogEntry()

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

        let fixedDate = Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 29))!

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
        let count = try await service.purgeOldChangeLogEntries(olderThanDays: 30)

        // Then - purge should return non-negative count of purged entries
        #expect(count >= 0)
    }

    // MARK: - Tests: User Profile Operations

    @Test("loadUserProfile returns UserProfile")
    func testLoadUserProfileReturnsUserProfile() async throws {
        // Given
        let (service, tempDir) = Self.createTestService()
        defer { Self.cleanupTemporaryDirectory(tempDir) }

        // When
        let profile = try await service.loadUserProfile()

        // Then
        #expect(profile is UserProfile)
        #expect(profile.displayName.isEmpty == false)
    }

    @Test("saveUserProfile does not throw")
    func testSaveUserProfileDoesNotThrow() async throws {
        // Given
        let (service, tempDir) = Self.createTestService()
        defer { Self.cleanupTemporaryDirectory(tempDir) }
        let profile = UserProfile(userId: UUID(), displayName: "Test User")

        // When/Then
        try await service.saveUserProfile(profile)
    }

    // MARK: - Tests: Undo/Redo Stacks

    @Test("loadUndoRedoStacks returns tuple of two arrays")
    func testLoadUndoRedoStacksReturnsTuple() async throws {
        // Given
        let (service, tempDir) = Self.createTestService()
        defer { Self.cleanupTemporaryDirectory(tempDir) }

        // When
        let (undo, redo) = try await service.loadUndoRedoStacks()

        // Then
        #expect(undo is [ChangeLogEntry])
        #expect(redo is [ChangeLogEntry])
    }

    @Test("saveUndoRedoStacks does not throw")
    func testSaveUndoRedoStacksDoesNotThrow() async throws {
        // Given
        let (service, tempDir) = Self.createTestService()
        defer { Self.cleanupTemporaryDirectory(tempDir) }
        let undoStack: [ChangeLogEntry] = []
        let redoStack: [ChangeLogEntry] = []

        // When/Then
        try await service.saveUndoRedoStacks(undo: undoStack, redo: redoStack)
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
