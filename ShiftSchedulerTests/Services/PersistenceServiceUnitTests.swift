import Testing
import Foundation
@testable import ShiftScheduler

/// Unit tests for PersistenceService using MockPersistenceService
/// Validates service logic without file I/O
@Suite("PersistenceService Unit Tests")
@MainActor
struct PersistenceServiceUnitTests {

    // MARK: - Test Helpers

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

    /// Create a mock service
    static func createMockService() -> MockPersistenceService {
        MockPersistenceService()
    }

    // MARK: - Tests: Shift Type Operations

    @Test("loadShiftTypes returns empty array when no types saved")
    func testLoadShiftTypesReturnsEmptyArray() async throws {
        // Given
        let mockService = Self.createMockService()

        // When
        let result = try await mockService.loadShiftTypes()

        // Then
        #expect(result.isEmpty)
    }

    @Test("saveShiftType adds shift type to mock storage")
    func testSaveShiftTypeAddsToMockStorage() async throws {
        // Given
        let mockService = Self.createMockService()
        let shiftType = Self.createTestShiftType()
        #expect(mockService.mockShiftTypes.isEmpty)

        // When
        try await mockService.saveShiftType(shiftType)

        // Then
        #expect(mockService.mockShiftTypes.count == 1)
        #expect(mockService.mockShiftTypes.first?.id == shiftType.id)
    }

    @Test("saveShiftType updates existing shift type with same ID")
    func testSaveShiftTypeUpdatesExisting() async throws {
        // Given
        let mockService = Self.createMockService()
        let originalType = Self.createTestShiftType()
        try await mockService.saveShiftType(originalType)

        // Create updated version with same ID
        let updatedType = ShiftType(
            id: originalType.id,
            symbol: "🌙",
            duration: .allDay,
            title: "Evening Shift",
            description: "Updated",
            location: originalType.location
        )

        // When
        try await mockService.saveShiftType(updatedType)

        // Then
        #expect(mockService.mockShiftTypes.count == 1)
        #expect(mockService.mockShiftTypes.first?.title == "Evening Shift")
        #expect(mockService.mockShiftTypes.first?.symbol == "🌙")
    }

    @Test("deleteShiftType removes shift type from mock storage")
    func testDeleteShiftTypeRemovesFromMockStorage() async throws {
        // Given
        let mockService = Self.createMockService()
        let shiftType = Self.createTestShiftType()
        try await mockService.saveShiftType(shiftType)
        #expect(mockService.mockShiftTypes.count == 1)

        // When
        try await mockService.deleteShiftType(id: shiftType.id)

        // Then
        #expect(mockService.mockShiftTypes.isEmpty)
    }

    @Test("saveShiftType throws error when configured")
    func testSaveShiftTypeThrowsWhenConfigured() async throws {
        // Given
        let mockService = Self.createMockService()
        mockService.shouldThrowError = true
        mockService.throwError = NSError(domain: "TestError", code: 1)
        let shiftType = Self.createTestShiftType()

        // When/Then
        var didThrow = false
        do {
            try await mockService.saveShiftType(shiftType)
        } catch {
            didThrow = true
        }
        #expect(didThrow)
    }

    // MARK: - Tests: Location Operations

    @Test("loadLocations returns empty array when no locations saved")
    func testLoadLocationsReturnsEmptyArray() async throws {
        // Given
        let mockService = Self.createMockService()

        // When
        let result = try await mockService.loadLocations()

        // Then
        #expect(result.isEmpty)
    }

    @Test("saveLocation adds location to mock storage")
    func testSaveLocationAddsToMockStorage() async throws {
        // Given
        let mockService = Self.createMockService()
        let location = Self.createTestLocation()
        #expect(mockService.mockLocations.isEmpty)

        // When
        try await mockService.saveLocation(location)

        // Then
        #expect(mockService.mockLocations.count == 1)
        #expect(mockService.mockLocations.first?.id == location.id)
    }

    @Test("deleteLocation removes location from mock storage")
    func testDeleteLocationRemovesFromMockStorage() async throws {
        // Given
        let mockService = Self.createMockService()
        let location = Self.createTestLocation()
        try await mockService.saveLocation(location)
        #expect(mockService.mockLocations.count == 1)

        // When
        try await mockService.deleteLocation(id: location.id)

        // Then
        #expect(mockService.mockLocations.isEmpty)
    }

    @Test("saveLocation throws error when configured")
    func testSaveLocationThrowsWhenConfigured() async throws {
        // Given
        let mockService = Self.createMockService()
        mockService.shouldThrowError = true
        mockService.throwError = NSError(domain: "TestError", code: 1)
        let location = Self.createTestLocation()

        // When/Then
        var didThrow = false
        do {
            try await mockService.saveLocation(location)
        } catch {
            didThrow = true
        }
        #expect(didThrow)
    }

    // MARK: - Tests: Change Log Operations

    @Test("loadChangeLogEntries returns empty array when no entries saved")
    func testLoadChangeLogEntriesReturnsEmptyArray() async throws {
        // Given
        let mockService = Self.createMockService()

        // When
        let result = try await mockService.loadChangeLogEntries()

        // Then
        #expect(result.isEmpty)
    }

    @Test("addChangeLogEntry adds entry to mock storage")
    func testAddChangeLogEntryAddsToMockStorage() async throws {
        // Given
        let mockService = Self.createMockService()
        let entry = try Self.createTestChangeLogEntry()
        #expect(mockService.mockChangeLogEntries.isEmpty)

        // When
        try await mockService.addChangeLogEntry(entry)

        // Then
        #expect(mockService.mockChangeLogEntries.count == 1)
        #expect(mockService.mockChangeLogEntries.first?.id == entry.id)
    }

    @Test("deleteChangeLogEntry removes entry from mock storage")
    func testDeleteChangeLogEntryRemovesFromMockStorage() async throws {
        // Given
        let mockService = Self.createMockService()
        let entry = try Self.createTestChangeLogEntry()
        try await mockService.addChangeLogEntry(entry)
        #expect(mockService.mockChangeLogEntries.count == 1)

        // When
        try await mockService.deleteChangeLogEntry(id: entry.id)

        // Then
        #expect(mockService.mockChangeLogEntries.isEmpty)
    }

    @Test("purgeOldChangeLogEntries removes entries older than threshold")
    func testPurgeOldChangeLogEntriesRemovesOldEntries() async throws {
        // Given
        let mockService = Self.createMockService()

        // Create entry from 60 days ago
        let oldDate = try #require(Calendar.current.date(byAdding: .day, value: -60, to: try Date.fixedTestDate_Nov11_2025()))
        let oldEntry = ChangeLogEntry(
            id: UUID(),
            timestamp: oldDate,
            userId: UUID(),
            userDisplayName: "Old User",
            changeType: .switched,
            scheduledShiftDate: oldDate,
            oldShiftSnapshot: nil,
            newShiftSnapshot: nil,
            reason: "Old change"
        )

        // Create recent entry
        let recentEntry = try Self.createTestChangeLogEntry()

        try await mockService.addChangeLogEntry(oldEntry)
        try await mockService.addChangeLogEntry(recentEntry)
        #expect(mockService.mockChangeLogEntries.count == 2)

        // When - Purge entries older than 30 days
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -30, to: try Date.fixedTestDate_Nov11_2025()) ?? try Date.fixedTestDate_Nov11_2025()
        let purgedCount = try await mockService.purgeOldChangeLogEntries(olderThan: cutoffDate)

        // Then
        #expect(purgedCount == 1)
        #expect(mockService.mockChangeLogEntries.count == 1)
        #expect(mockService.mockChangeLogEntries.first?.id == recentEntry.id)
    }

    @Test("addChangeLogEntry throws error when configured")
    func testAddChangeLogEntryThrowsWhenConfigured() async throws {
        // Given
        let mockService = Self.createMockService()
        mockService.shouldThrowError = true
        mockService.throwError = NSError(domain: "TestError", code: 1)
        let entry = try Self.createTestChangeLogEntry()

        // When/Then
        var didThrow = false
        do {
            try await mockService.addChangeLogEntry(entry)
        } catch {
            didThrow = true
        }
        #expect(didThrow)
    }

    // MARK: - Tests: User Profile Operations

    @Test("loadUserProfile returns default profile")
    func testLoadUserProfileReturnsDefaultProfile() async throws {
        // Given
        let mockService = Self.createMockService()
        
        // When
        let profile = try await mockService.loadUserProfile()

        // Then
        #expect(profile.displayName == "")
    }

    @Test("saveUserProfile updates profile in mock storage")
    func testSaveUserProfileUpdatesProfile() async throws {
        // Given
        let mockService = Self.createMockService()
        let newProfile = UserProfile(userId: UUID(), displayName: "Updated User")

        // When
        try await mockService.saveUserProfile(newProfile)

        // Then
        let saved = try await mockService.loadUserProfile()
        #expect(saved.displayName == "Updated User")
        #expect(saved.userId == newProfile.userId)
    }

    @Test("saveUserProfile throws error when configured")
    func testSaveUserProfileThrowsWhenConfigured() async throws {
        // Given
        let mockService = Self.createMockService()
        mockService.shouldThrowError = true
        mockService.throwError = NSError(domain: "TestError", code: 1)
        let profile = UserProfile(userId: UUID(), displayName: "Test")

        // When/Then
        var didThrow = false
        do {
            try await mockService.saveUserProfile(profile)
        } catch {
            didThrow = true
        }
        #expect(didThrow)
    }

    // MARK: - Tests: Undo/Redo Stack Operations

    @Test("loadUndoRedoStacks returns empty stacks by default")
    func testLoadUndoRedoStacksReturnsEmptyStacks() async throws {
        // Given
        let mockService = Self.createMockService()

        // When
        let (undo, redo) = try await mockService.loadUndoRedoStacks()

        // Then
        #expect(undo.isEmpty)
        #expect(redo.isEmpty)
    }

    @Test("saveUndoRedoStacks updates stacks in mock storage")
    func testSaveUndoRedoStacksUpdatesStacks() async throws {
        // Given
        let mockService = Self.createMockService()
        let entry1 = try Self.createTestChangeLogEntry()
        let entry2 = try Self.createTestChangeLogEntry()

        // When
        try await mockService.saveUndoRedoStacks(undo: [entry1], redo: [entry2])

        // Then
        let (undo, redo) = try await mockService.loadUndoRedoStacks()
        #expect(undo.count == 1)
        #expect(redo.count == 1)
        #expect(undo.first?.id == entry1.id)
        #expect(redo.first?.id == entry2.id)
    }

    @Test("saveUndoRedoStacks throws error when configured")
    func testSaveUndoRedoStacksThrowsWhenConfigured() async throws {
        // Given
        let mockService = Self.createMockService()
        mockService.shouldThrowError = true
        mockService.throwError = NSError(domain: "TestError", code: 1)

        // When/Then
        var didThrow = false
        do {
            try await mockService.saveUndoRedoStacks(undo: [], redo: [])
        } catch {
            didThrow = true
        }
        #expect(didThrow)
    }

    // MARK: - Tests: Multiple Operations

    @Test("Multiple shift types can be saved in sequence")
    func testMultipleShiftTypesSavedSequentially() async throws {
        // Given
        let mockService = Self.createMockService()
        let type1 = Self.createTestShiftType()
        let type2 = Self.createTestShiftType()

        // When
        try await mockService.saveShiftType(type1)
        try await mockService.saveShiftType(type2)

        // Then
        let all = try await mockService.loadShiftTypes()
        #expect(all.count == 2)
        #expect(all.contains { $0.id == type1.id })
        #expect(all.contains { $0.id == type2.id })
    }

    @Test("Multiple locations can be saved in sequence")
    func testMultipleLocationsSavedSequentially() async throws {
        // Given
        let mockService = Self.createMockService()
        let loc1 = Location(id: UUID(), name: "Office 1", address: "123 Main St")
        let loc2 = Location(id: UUID(), name: "Office 2", address: "456 Oak Ave")

        // When
        try await mockService.saveLocation(loc1)
        try await mockService.saveLocation(loc2)

        // Then
        let all = try await mockService.loadLocations()
        #expect(all.count == 2)
        #expect(all.contains { $0.id == loc1.id })
        #expect(all.contains { $0.id == loc2.id })
    }

    @Test("Multiple change log entries can be added in sequence")
    func testMultipleChangeLogEntriesAddedSequentially() async throws {
        // Given
        let mockService = Self.createMockService()
        let entry1 = try Self.createTestChangeLogEntry()
        let entry2 = try Self.createTestChangeLogEntry()

        // When
        try await mockService.addChangeLogEntry(entry1)
        try await mockService.addChangeLogEntry(entry2)

        // Then
        let all = try await mockService.loadChangeLogEntries()
        #expect(all.count == 2)
        #expect(all.contains { $0.id == entry1.id })
        #expect(all.contains { $0.id == entry2.id })
    }
}
