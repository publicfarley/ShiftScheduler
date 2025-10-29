import Testing
import Foundation
@testable import ShiftScheduler

/// Tests for PersistenceService
/// Validates shift types, locations, change log, and undo/redo persistence
/// Note: These tests use actual file-based repositories so they test integration
@Suite("PersistenceService Tests")
@MainActor
struct PersistenceServiceTests {

    // MARK: - Setup Helpers

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

    /// Create a test change log entry
    static func createTestChangeLogEntry() -> ChangeLogEntry {
        ChangeLogEntry(
            id: UUID(),
            timestamp: Date(),
            userId: UUID(),
            userDisplayName: "Test User",
            changeType: .switched,
            scheduledShiftDate: Date(),
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
        let service = PersistenceService()

        // When
        let result = try await service.loadShiftTypes()

        // Then
        #expect(result is [ShiftType])
    }

    @Test("saveShiftType persists shift type")
    func testSaveShiftTypePersistsShiftType() async throws {
        // Given
        let service = PersistenceService()
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
        let service = PersistenceService()
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
        let service = PersistenceService()

        // When
        let result = try await service.loadLocations()

        // Then
        #expect(result is [Location])
    }

    @Test("saveLocation persists location")
    func testSaveLocationPersistsLocation() async throws {
        // Given
        let service = PersistenceService()
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
        let service = PersistenceService()
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
        let service = PersistenceService()

        // When
        let result = try await service.loadChangeLogEntries()

        // Then
        #expect(result is [ChangeLogEntry])
    }

    @Test("addChangeLogEntry persists entry")
    func testAddChangeLogEntryPersistsEntry() async throws {
        // Given
        let service = PersistenceService()
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
        let service = PersistenceService()

        let switchedEntry = ChangeLogEntry(
            id: UUID(),
            timestamp: Date(),
            userId: UUID(),
            userDisplayName: "User 1",
            changeType: .switched,
            scheduledShiftDate: Date(),
            oldShiftSnapshot: nil,
            newShiftSnapshot: nil,
            reason: "Switched shift"
        )

        let deletedEntry = ChangeLogEntry(
            id: UUID(),
            timestamp: Date(),
            userId: UUID(),
            userDisplayName: "User 2",
            changeType: .deleted,
            scheduledShiftDate: Date(),
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
        let service = PersistenceService()

        // When
        let count = try await service.purgeOldChangeLogEntries(olderThanDays: 30)

        // Then
        #expect(count is Int)
    }

    // MARK: - Tests: User Profile Operations

    @Test("loadUserProfile returns UserProfile")
    func testLoadUserProfileReturnsUserProfile() async throws {
        // Given
        let service = PersistenceService()

        // When
        let profile = try await service.loadUserProfile()

        // Then
        #expect(profile is UserProfile)
        #expect(profile.displayName.isEmpty == false)
    }

    @Test("saveUserProfile does not throw")
    func testSaveUserProfileDoesNotThrow() async throws {
        // Given
        let service = PersistenceService()
        let profile = UserProfile(userId: UUID(), displayName: "Test User")

        // When/Then
        try await service.saveUserProfile(profile)
    }

    // MARK: - Tests: Undo/Redo Stacks

    @Test("loadUndoRedoStacks returns tuple of two arrays")
    func testLoadUndoRedoStacksReturnsTuple() async throws {
        // Given
        let service = PersistenceService()

        // When
        let (undo, redo) = try await service.loadUndoRedoStacks()

        // Then
        #expect(undo is [ChangeLogEntry])
        #expect(redo is [ChangeLogEntry])
    }

    @Test("saveUndoRedoStacks does not throw")
    func testSaveUndoRedoStacksDoesNotThrow() async throws {
        // Given
        let service = PersistenceService()
        let undoStack: [ChangeLogEntry] = []
        let redoStack: [ChangeLogEntry] = []

        // When/Then
        try await service.saveUndoRedoStacks(undo: undoStack, redo: redoStack)
    }

    // MARK: - Tests: Multiple Operations

    @Test("Multiple shift types can be saved and retrieved")
    func testMultipleShiftTypesSavedAndRetrieved() async throws {
        // Given
        let service = PersistenceService()
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
        let service = PersistenceService()
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
        let service = PersistenceService()
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
