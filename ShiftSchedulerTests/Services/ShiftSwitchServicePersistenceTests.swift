import Testing
import Foundation
@testable import ShiftScheduler

/// Tests for ShiftSwitchService with persistence
/// NOTE: Persistence is currently disabled since ShiftType is a SwiftData model
/// These tests verify that the service works correctly even with disabled persistence
@Suite("ShiftSwitchService Persistence Tests")
struct ShiftSwitchServicePersistenceTests {
    let suiteName = "com.functioncraft.shiftscheduler.tests.shiftswitchpersistence"

    @Test("Service initializes correctly with persistence disabled")
    func testServiceInitializesWithDisabledPersistence() async throws {
        // Given
        let userDefaults = UserDefaults(suiteName: suiteName)!
        defer { userDefaults.removePersistentDomain(forName: suiteName) }

        let persistence = UndoRedoPersistence(userDefaults: userDefaults)
        let mockCalendar = MockCalendarService()
        let mockRepository = MockChangeLogRepository()

        // When
        let service = ShiftSwitchService(
            calendarService: mockCalendar,
            changeLogRepository: mockRepository,
            persistence: persistence
        )

        // Then - service should initialize without errors
        let canUndo = await service.canUndo()
        let canRedo = await service.canRedo()
        #expect(canUndo == false)
        #expect(canRedo == false)
    }

    @Test("Restore from persistence returns empty stacks when disabled")
    func testRestoreFromPersistenceWithDisabled() async throws {
        // Given
        let userDefaults = UserDefaults(suiteName: suiteName)!
        defer { userDefaults.removePersistentDomain(forName: suiteName) }

        let persistence = UndoRedoPersistence(userDefaults: userDefaults)
        let mockCalendar = MockCalendarService()
        let mockRepository = MockChangeLogRepository()

        let service = ShiftSwitchService(
            calendarService: mockCalendar,
            changeLogRepository: mockRepository,
            persistence: persistence
        )

        // When
        await service.restoreFromPersistence()

        // Then - stacks should remain empty
        let canUndo = await service.canUndo()
        let canRedo = await service.canRedo()
        #expect(canUndo == false)
        #expect(canRedo == false)
    }

    @Test("Service operates correctly without persistence")
    func testServiceOperatesWithoutPersistence() async throws {
        // Given
        let userDefaults = UserDefaults(suiteName: suiteName)!
        defer { userDefaults.removePersistentDomain(forName: suiteName) }

        let persistence = UndoRedoPersistence(userDefaults: userDefaults)
        let mockCalendar = MockCalendarService()
        let mockRepository = MockChangeLogRepository()

        let location = Location(name: "Office", address: "123 Main St")
        let oldShiftType = ShiftType(
            title: "Morning Shift",
            symbol: "☀️",
            duration: .allDay,
            location: location
        )
        let newShiftType = ShiftType(
            title: "Evening Shift",
            symbol: "🌙",
            duration: .allDay,
            location: location
        )

        let service = ShiftSwitchService(
            calendarService: mockCalendar,
            changeLogRepository: mockRepository,
            persistence: persistence
        )

        // When - perform a switch (in-memory stack should still work)
        try await service.switchShift(
            eventIdentifier: "event1",
            scheduledDate: Date(),
            from: oldShiftType,
            to: newShiftType,
            reason: "Test"
        )

        // Then - in-memory undo should work even though persistence is disabled
        let canUndo = await service.canUndo()
        #expect(canUndo == true)
    }

    @Test("Clear history works with disabled persistence")
    func testClearHistoryWithDisabledPersistence() async throws {
        // Given
        let userDefaults = UserDefaults(suiteName: suiteName)!
        defer { userDefaults.removePersistentDomain(forName: suiteName) }

        let persistence = UndoRedoPersistence(userDefaults: userDefaults)
        let mockCalendar = MockCalendarService()
        let mockRepository = MockChangeLogRepository()

        let location = Location(name: "Office", address: "123 Main St")
        let oldShiftType = ShiftType(
            title: "Morning Shift",
            symbol: "☀️",
            duration: .allDay,
            location: location
        )
        let newShiftType = ShiftType(
            title: "Evening Shift",
            symbol: "🌙",
            duration: .allDay,
            location: location
        )

        let service = ShiftSwitchService(
            calendarService: mockCalendar,
            changeLogRepository: mockRepository,
            persistence: persistence
        )

        // Create some history
        try await service.switchShift(
            eventIdentifier: "event1",
            scheduledDate: Date(),
            from: oldShiftType,
            to: newShiftType,
            reason: nil
        )

        // When
        await service.clearUndoRedoHistory()

        // Then - stacks should be cleared
        let canUndo = await service.canUndo()
        let canRedo = await service.canRedo()
        #expect(canUndo == false)
        #expect(canRedo == false)
    }
}
