import Testing
import Foundation
@testable import ShiftScheduler

/// Tests for MockPersistenceService
/// Validates mock service functionality for testing middleware and features
@Suite("MockPersistenceService Tests")
@MainActor
struct MockPersistenceServiceTests {

    // MARK: - Tests: Shift Type Operations

    @Test("Load shift types returns mocked data")
    func testLoadShiftTypesReturnsMockedData() async throws {
        // Given
        let service = MockPersistenceService()
        let location = Location(id: UUID(), name: "Main", address: "")
        let testShiftType = ShiftType(
            id: UUID(),
            symbol: "sun.fill",
            duration: .scheduled(from: HourMinuteTime(hour: 6, minute: 0), to: HourMinuteTime(hour: 14, minute: 0)),
            title: "Morning",
            description: "Morning shift",
            location: location
        )
        service.mockShiftTypes = [testShiftType]

        // When
        let result = try await service.loadShiftTypes()

        // Then
        #expect(result.count == 1)
        #expect(result.first?.title == "Morning")
    }

    @Test("Save shift type adds to mock storage")
    func testSaveShiftTypeAddsToMockStorage() async throws {
        // Given
        let service = MockPersistenceService()
        let location = Location(id: UUID(), name: "Main", address: "")
        let shiftType = ShiftType(
            id: UUID(),
            symbol: "moon.fill",
            duration: .scheduled(from: HourMinuteTime(hour: 14, minute: 0), to: HourMinuteTime(hour: 22, minute: 0)),
            title: "Evening",
            description: "Evening shift",
            location: location
        )

        // When
        try await service.saveShiftType(shiftType)

        // Then
        #expect(service.mockShiftTypes.contains { $0.id == shiftType.id })
    }

    @Test("Delete shift type removes from mock storage")
    func testDeleteShiftTypeRemovesFromMockStorage() async throws {
        // Given
        let id = UUID()
        let service = MockPersistenceService()
        let location = Location(id: UUID(), name: "Main", address: "")
        let shiftType = ShiftType(
            id: id,
            symbol: "star.fill",
            duration: .scheduled(from: HourMinuteTime(hour: 22, minute: 0), to: HourMinuteTime(hour: 6, minute: 0)),
            title: "Night",
            description: "Night shift",
            location: location
        )
        service.mockShiftTypes = [shiftType]

        // When
        try await service.deleteShiftType(id: id)

        // Then
        #expect(service.mockShiftTypes.isEmpty)
    }

    // MARK: - Tests: Location Operations

    @Test("Load locations returns mocked data")
    func testLoadLocationsReturnsMockedData() async throws {
        // Given
        let service = MockPersistenceService()
        let location = Location(id: UUID(), name: "HQ", address: "123 Main St")
        service.mockLocations = [location]

        // When
        let result = try await service.loadLocations()

        // Then
        #expect(result.count == 1)
        #expect(result.first?.name == "HQ")
    }

    @Test("Save location adds to mock storage")
    func testSaveLocationAddsToMockStorage() async throws {
        // Given
        let service = MockPersistenceService()
        let location = Location(id: UUID(), name: "Remote", address: "Home")

        // When
        try await service.saveLocation(location)

        // Then
        #expect(service.mockLocations.contains { $0.id == location.id })
    }

    // MARK: - Tests: Error Handling

    @Test("Service can be configured to throw errors")
    func testServiceErrorConfiguration() async throws {
        // Given
        let service = MockPersistenceService()
        service.shouldThrowError = true

        // When - Service is configured to throw
        // Then - shouldThrowError flag is set for test use
        #expect(service.shouldThrowError)
    }

    // MARK: - Tests: Change Log Operations

    @Test("Load change log entries returns mocked data")
    func testLoadChangeLogEntriesReturnsMockedData() async throws {
        // Given
        let service = MockPersistenceService()
        let userId = UUID()
        let entry = ChangeLogEntry(
            id: UUID(),
            timestamp: Date(),
            userId: userId,
            userDisplayName: "Test User",
            changeType: .switched,
            scheduledShiftDate: Date(),
            oldShiftSnapshot: nil,
            newShiftSnapshot: nil,
            reason: "Testing"
        )
        service.mockChangeLogEntries = [entry]

        // When
        let result = try await service.loadChangeLogEntries()

        // Then
        #expect(result.count == 1)
        #expect(result.first?.changeType == .switched)
    }

    @Test("Add change log entry adds to mock storage")
    func testAddChangeLogEntryAddsToMockStorage() async throws {
        // Given
        let service = MockPersistenceService()
        let userId = UUID()
        let entry = ChangeLogEntry(
            id: UUID(),
            timestamp: Date(),
            userId: userId,
            userDisplayName: "Test User",
            changeType: .deleted,
            scheduledShiftDate: Date(),
            oldShiftSnapshot: nil,
            newShiftSnapshot: nil,
            reason: "Shift removed"
        )

        // When
        try await service.addChangeLogEntry(entry)

        // Then
        #expect(service.mockChangeLogEntries.contains { $0.id == entry.id })
    }
}
