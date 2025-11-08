import Testing
import Foundation
@testable import ShiftScheduler

/// Integration tests for PersistenceService cascade functionality
/// Tests that Location updates correctly cascade to ShiftTypes
/// Note: These tests use actual file-based repositories with temporary directories
@Suite("PersistenceService Cascade Tests")
@MainActor
struct PersistenceServiceCascadeTests {

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

    // MARK: - Location Cascade Tests

    @Test("updateShiftTypesWithLocation updates all ShiftTypes that reference the Location")
    func testUpdateShiftTypesWithLocationCascade() async throws {
        // Given
        let (service, tempDir) = Self.createTestService()
        defer { Self.cleanupTemporaryDirectory(tempDir) }

        // Create and save a location
        let location = Location(id: UUID(), name: "Office", address: "123 Main St")
        try await service.saveLocation(location)

        // Create and save shift types that reference the location
        let shiftType1 = ShiftType(
            id: UUID(),
            symbol: "D",
            duration: .allDay,
            title: "Day Shift",
            shiftDescription: "Morning work",
            location: location
        )
        let shiftType2 = ShiftType(
            id: UUID(),
            symbol: "N",
            duration: .allDay,
            title: "Night Shift",
            shiftDescription: "Evening work",
            location: location
        )
        try await service.saveShiftType(shiftType1)
        try await service.saveShiftType(shiftType2)

        // Update the location with new address
        let updatedLocation = Location(id: location.id, name: "Office", address: "456 New Ave")

        // When
        let updatedShiftTypes = try await service.updateShiftTypesWithLocation(updatedLocation)

        // Then
        #expect(updatedShiftTypes.count == 2)
        #expect(updatedShiftTypes[0].location.address == "456 New Ave")
        #expect(updatedShiftTypes[1].location.address == "456 New Ave")

        // Verify changes persisted to disk
        let loadedShiftTypes = try await service.loadShiftTypes()
        #expect(loadedShiftTypes.count == 2)
        for loadedShiftType in loadedShiftTypes {
            #expect(loadedShiftType.location.address == "456 New Ave")
        }
    }

    @Test("updateShiftTypesWithLocation returns empty array when no ShiftTypes reference the Location")
    func testUpdateShiftTypesWithLocationNoMatches() async throws {
        // Given
        let (service, tempDir) = Self.createTestService()
        defer { Self.cleanupTemporaryDirectory(tempDir) }

        let location1 = Location(id: UUID(), name: "Office", address: "123 Main St")
        let location2 = Location(id: UUID(), name: "Home", address: "789 Home Ave")
        try await service.saveLocation(location1)
        try await service.saveLocation(location2)

        // Create shift type that references location2
        let shiftType = ShiftType(
            id: UUID(),
            symbol: "D",
            duration: .allDay,
            title: "Day Shift",
            shiftDescription: "Work",
            location: location2
        )
        try await service.saveShiftType(shiftType)

        // Update location1 (not referenced by any shift types)
        let updatedLocation1 = Location(id: location1.id, name: "Office", address: "456 New St")

        // When
        let updatedShiftTypes = try await service.updateShiftTypesWithLocation(updatedLocation1)

        // Then
        #expect(updatedShiftTypes.isEmpty, "Should return empty array when no ShiftTypes reference the Location")

        // Verify existing shift type was not modified
        let loadedShiftTypes = try await service.loadShiftTypes()
        #expect(loadedShiftTypes.count == 1)
        #expect(loadedShiftTypes[0].location.address == "789 Home Ave")
    }

    @Test("updateShiftTypesWithLocation updates multiple ShiftTypes and persists all changes")
    func testUpdateShiftTypesWithLocationMultiplePersist() async throws {
        // Given
        let (service, tempDir) = Self.createTestService()
        defer { Self.cleanupTemporaryDirectory(tempDir) }

        let location = Location(id: UUID(), name: "Hospital", address: "100 Health Blvd")
        try await service.saveLocation(location)

        // Create 5 shift types that all reference the same location
        for index in 1...5 {
            let shiftType = ShiftType(
                id: UUID(),
                symbol: "S\(index)",
                duration: .allDay,
                title: "Shift \(index)",
                shiftDescription: "Description \(index)",
                location: location
            )
            try await service.saveShiftType(shiftType)
        }

        // Update the location
        let updatedLocation = Location(id: location.id, name: "Hospital", address: "200 New Health Ave")

        // When
        let updatedShiftTypes = try await service.updateShiftTypesWithLocation(updatedLocation)

        // Then
        #expect(updatedShiftTypes.count == 5)

        // Verify all persisted with updated location
        let loadedShiftTypes = try await service.loadShiftTypes()
        #expect(loadedShiftTypes.count == 5)
        for loadedShiftType in loadedShiftTypes {
            #expect(loadedShiftType.location.id == location.id)
            #expect(loadedShiftType.location.address == "200 New Health Ave")
        }
    }

    @Test("updateShiftTypesWithLocation preserves other ShiftType fields")
    func testUpdateShiftTypesWithLocationPreservesFields() async throws {
        // Given
        let (service, tempDir) = Self.createTestService()
        defer { Self.cleanupTemporaryDirectory(tempDir) }

        let location = Location(id: UUID(), name: "Office", address: "123 Main St")
        try await service.saveLocation(location)

        let originalShiftType = ShiftType(
            id: UUID(),
            symbol: "🌅",
            duration: .scheduled(from: HourMinuteTime(hour: 9, minute: 0), to: HourMinuteTime(hour: 17, minute: 0)),
            title: "Day Shift",
            shiftDescription: "Standard workday",
            location: location
        )
        try await service.saveShiftType(originalShiftType)

        // Update the location
        let updatedLocation = Location(id: location.id, name: "Office", address: "456 New Ave")

        // When
        let updatedShiftTypes = try await service.updateShiftTypesWithLocation(updatedLocation)

        // Then
        #expect(updatedShiftTypes.count == 1)
        let updatedShiftType = updatedShiftTypes[0]

        // Verify only location was updated, all other fields preserved
        #expect(updatedShiftType.id == originalShiftType.id)
        #expect(updatedShiftType.symbol == "🌅")
        #expect(updatedShiftType.title == "Day Shift")
        #expect(updatedShiftType.shiftDescription == "Standard workday")

        if case .scheduled(let from, let to) = updatedShiftType.duration {
            #expect(from.hour == 9)
            #expect(from.minute == 0)
            #expect(to.hour == 17)
            #expect(to.minute == 0)
        } else {
            #expect(Bool(false), "Duration should be scheduled")
        }

        // Verify location was updated
        #expect(updatedShiftType.location.id == location.id)
        #expect(updatedShiftType.location.address == "456 New Ave")
    }

    @Test("updateShiftTypesWithLocation handles mixed ShiftTypes (some matching, some not)")
    func testUpdateShiftTypesWithLocationMixedMatches() async throws {
        // Given
        let (service, tempDir) = Self.createTestService()
        defer { Self.cleanupTemporaryDirectory(tempDir) }

        let location1 = Location(id: UUID(), name: "Office", address: "123 Main St")
        let location2 = Location(id: UUID(), name: "Home", address: "789 Home Ave")
        try await service.saveLocation(location1)
        try await service.saveLocation(location2)

        // Create shift types: 3 reference location1, 2 reference location2
        let shiftType1 = ShiftType(id: UUID(), symbol: "A", duration: .allDay, title: "A", shiftDescription: "", location: location1)
        let shiftType2 = ShiftType(id: UUID(), symbol: "B", duration: .allDay, title: "B", shiftDescription: "", location: location2)
        let shiftType3 = ShiftType(id: UUID(), symbol: "C", duration: .allDay, title: "C", shiftDescription: "", location: location1)
        let shiftType4 = ShiftType(id: UUID(), symbol: "D", duration: .allDay, title: "D", shiftDescription: "", location: location2)
        let shiftType5 = ShiftType(id: UUID(), symbol: "E", duration: .allDay, title: "E", shiftDescription: "", location: location1)

        try await service.saveShiftType(shiftType1)
        try await service.saveShiftType(shiftType2)
        try await service.saveShiftType(shiftType3)
        try await service.saveShiftType(shiftType4)
        try await service.saveShiftType(shiftType5)

        // Update location1
        let updatedLocation1 = Location(id: location1.id, name: "Office", address: "999 Updated St")

        // When
        let updatedShiftTypes = try await service.updateShiftTypesWithLocation(updatedLocation1)

        // Then
        #expect(updatedShiftTypes.count == 3, "Should update 3 ShiftTypes that reference location1")

        // Verify the 3 matching shift types were updated
        let loadedShiftTypes = try await service.loadShiftTypes()
        #expect(loadedShiftTypes.count == 5)

        let location1ShiftTypes = loadedShiftTypes.filter { $0.location.id == location1.id }
        #expect(location1ShiftTypes.count == 3)
        for shiftType in location1ShiftTypes {
            #expect(shiftType.location.address == "999 Updated St")
        }

        // Verify the 2 non-matching shift types were NOT updated
        let location2ShiftTypes = loadedShiftTypes.filter { $0.location.id == location2.id }
        #expect(location2ShiftTypes.count == 2)
        for shiftType in location2ShiftTypes {
            #expect(shiftType.location.address == "789 Home Ave")
        }
    }

    @Test("updateShiftTypesWithLocation updates Location name correctly")
    func testUpdateShiftTypesWithLocationUpdatesBothNameAndAddress() async throws {
        // Given
        let (service, tempDir) = Self.createTestService()
        defer { Self.cleanupTemporaryDirectory(tempDir) }

        let location = Location(id: UUID(), name: "Old Office", address: "123 Old St")
        try await service.saveLocation(location)

        let shiftType = ShiftType(
            id: UUID(),
            symbol: "D",
            duration: .allDay,
            title: "Day Shift",
            shiftDescription: "Work",
            location: location
        )
        try await service.saveShiftType(shiftType)

        // Update both name and address of the location
        let updatedLocation = Location(id: location.id, name: "New Office", address: "456 New St")

        // When
        let updatedShiftTypes = try await service.updateShiftTypesWithLocation(updatedLocation)

        // Then
        #expect(updatedShiftTypes.count == 1)
        #expect(updatedShiftTypes[0].location.name == "New Office")
        #expect(updatedShiftTypes[0].location.address == "456 New St")

        // Verify persisted
        let loadedShiftTypes = try await service.loadShiftTypes()
        #expect(loadedShiftTypes[0].location.name == "New Office")
        #expect(loadedShiftTypes[0].location.address == "456 New St")
    }
}
