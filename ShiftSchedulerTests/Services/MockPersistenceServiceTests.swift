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

    @Test("Shift type operations throw when error configured")
    func testShiftTypeOperationsThrowWhenErrorConfigured() async throws {
        // Given
        let service = MockPersistenceService()
        let testError = NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        service.shouldThrowError = true
        service.throwError = testError

        let location = Location(id: UUID(), name: "Test", address: "")
        let shiftType = ShiftType(
            id: UUID(),
            symbol: "test",
            duration: .allDay,
            title: "Test",
            description: "Test",
            location: location
        )

        // When/Then - loadShiftTypes throws
        var didThrow = false
        do {
            _ = try await service.loadShiftTypes()
        } catch {
            didThrow = true
            #expect((error as NSError).code == 1)
        }
        #expect(didThrow, "loadShiftTypes should throw when error configured")

        // When/Then - saveShiftType throws
        didThrow = false
        do {
            try await service.saveShiftType(shiftType)
        } catch {
            didThrow = true
            #expect((error as NSError).code == 1)
        }
        #expect(didThrow, "saveShiftType should throw when error configured")

        // When/Then - deleteShiftType throws
        didThrow = false
        do {
            try await service.deleteShiftType(id: UUID())
        } catch {
            didThrow = true
            #expect((error as NSError).code == 1)
        }
        #expect(didThrow, "deleteShiftType should throw when error configured")
    }

    @Test("Location operations throw when error configured")
    func testLocationOperationsThrowWhenErrorConfigured() async throws {
        // Given
        let service = MockPersistenceService()
        let testError = NSError(domain: "TestError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        service.shouldThrowError = true
        service.throwError = testError

        let location = Location(id: UUID(), name: "Test", address: "123 Test St")

        // When/Then - loadLocations throws
        var didThrow = false
        do {
            _ = try await service.loadLocations()
        } catch {
            didThrow = true
            #expect((error as NSError).code == 2)
        }
        #expect(didThrow, "loadLocations should throw when error configured")

        // When/Then - saveLocation throws
        didThrow = false
        do {
            try await service.saveLocation(location)
        } catch {
            didThrow = true
            #expect((error as NSError).code == 2)
        }
        #expect(didThrow, "saveLocation should throw when error configured")

        // When/Then - deleteLocation throws
        didThrow = false
        do {
            try await service.deleteLocation(id: UUID())
        } catch {
            didThrow = true
            #expect((error as NSError).code == 2)
        }
        #expect(didThrow, "deleteLocation should throw when error configured")
    }

    @Test("Change log operations throw when error configured")
    func testChangeLogOperationsThrowWhenErrorConfigured() async throws {
        // Given
        let service = MockPersistenceService()
        let testError = NSError(domain: "TestError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        service.shouldThrowError = true
        service.throwError = testError

        let fixedDate = Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 29))!
        let entry = ChangeLogEntry(
            id: UUID(),
            timestamp: fixedDate,
            userId: UUID(),
            userDisplayName: "Test",
            changeType: .switched,
            scheduledShiftDate: fixedDate,
            oldShiftSnapshot: nil,
            newShiftSnapshot: nil,
            reason: "Test"
        )

        // When/Then - loadChangeLogEntries throws
        var didThrow = false
        do {
            _ = try await service.loadChangeLogEntries()
        } catch {
            didThrow = true
            #expect((error as NSError).code == 3)
        }
        #expect(didThrow, "loadChangeLogEntries should throw when error configured")

        // When/Then - addChangeLogEntry throws
        didThrow = false
        do {
            try await service.addChangeLogEntry(entry)
        } catch {
            didThrow = true
            #expect((error as NSError).code == 3)
        }
        #expect(didThrow, "addChangeLogEntry should throw when error configured")

        // When/Then - deleteChangeLogEntry throws
        didThrow = false
        do {
            try await service.deleteChangeLogEntry(id: UUID())
        } catch {
            didThrow = true
            #expect((error as NSError).code == 3)
        }
        #expect(didThrow, "deleteChangeLogEntry should throw when error configured")

        // When/Then - purgeOldChangeLogEntries throws
        didThrow = false
        do {
            _ = try await service.purgeOldChangeLogEntries(olderThanDays: 30)
        } catch {
            didThrow = true
            #expect((error as NSError).code == 3)
        }
        #expect(didThrow, "purgeOldChangeLogEntries should throw when error configured")
    }

    @Test("User profile operations throw when error configured")
    func testUserProfileOperationsThrowWhenErrorConfigured() async throws {
        // Given
        let service = MockPersistenceService()
        let testError = NSError(domain: "TestError", code: 4, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        service.shouldThrowError = true
        service.throwError = testError

        let profile = UserProfile(userId: UUID(), displayName: "Test")

        // When/Then - loadUserProfile throws
        var didThrow = false
        do {
            _ = try await service.loadUserProfile()
        } catch {
            didThrow = true
            #expect((error as NSError).code == 4)
        }
        #expect(didThrow, "loadUserProfile should throw when error configured")

        // When/Then - saveUserProfile throws
        didThrow = false
        do {
            try await service.saveUserProfile(profile)
        } catch {
            didThrow = true
            #expect((error as NSError).code == 4)
        }
        #expect(didThrow, "saveUserProfile should throw when error configured")
    }

    @Test("Undo/Redo stack operations throw when error configured")
    func testUndoRedoStackOperationsThrowWhenErrorConfigured() async throws {
        // Given
        let service = MockPersistenceService()
        let testError = NSError(domain: "TestError", code: 5, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        service.shouldThrowError = true
        service.throwError = testError

        // When/Then - loadUndoRedoStacks throws
        var didThrow = false
        do {
            _ = try await service.loadUndoRedoStacks()
        } catch {
            didThrow = true
            #expect((error as NSError).code == 5)
        }
        #expect(didThrow, "loadUndoRedoStacks should throw when error configured")

        // When/Then - saveUndoRedoStacks throws
        didThrow = false
        do {
            try await service.saveUndoRedoStacks(undo: [], redo: [])
        } catch {
            didThrow = true
            #expect((error as NSError).code == 5)
        }
        #expect(didThrow, "saveUndoRedoStacks should throw when error configured")
    }

    // MARK: - Tests: Change Log Operations

    @Test("Load change log entries returns mocked data")
    func testLoadChangeLogEntriesReturnsMockedData() async throws {
        // Given
        let service = MockPersistenceService()
        let userId = UUID()
        let fixedDate = Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 29))!
        let entry = ChangeLogEntry(
            id: UUID(),
            timestamp: fixedDate,
            userId: userId,
            userDisplayName: "Test User",
            changeType: .switched,
            scheduledShiftDate: fixedDate,
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
        let fixedDate = Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 29))!
        let entry = ChangeLogEntry(
            id: UUID(),
            timestamp: fixedDate,
            userId: userId,
            userDisplayName: "Test User",
            changeType: .deleted,
            scheduledShiftDate: fixedDate,
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
