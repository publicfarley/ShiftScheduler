import Foundation
import Testing

@testable import ShiftScheduler

@MainActor
@Suite("CalendarService Batch Operations")
struct CalendarServiceBatchOperationsTests {
    // MARK: - DeleteMultipleShiftEvents Tests

    @Test("deleteMultipleShiftEvents deletes all provided events")
    func deleteMultipleShiftEventsDeletesAllEvents() async throws {
        let mockService = MockCalendarService()

        let shiftType = ShiftTypeBuilder.nightShift()
        let shift1 = ScheduledShift(id: UUID(), eventIdentifier: "event1", shiftType: shiftType, date: try Date.fixedTestDate_Nov11_2025(), notes: nil)
        let shift2 = ScheduledShift(id: UUID(), eventIdentifier: "event2", shiftType: shiftType, date: try Date.fixedTestDate_Nov11_2025(), notes: nil)
        let shift3 = ScheduledShift(id: UUID(), eventIdentifier: "event3", shiftType: shiftType, date: try Date.fixedTestDate_Nov11_2025(), notes: nil)

        mockService.mockShifts = [shift1, shift2, shift3]

        // Delete multiple events
        let deletedCount = try await mockService.deleteMultipleShiftEvents(["event1", "event3"])

        #expect(deletedCount == 2)
        #expect(mockService.mockShifts.count == 1)
        #expect(mockService.mockShifts[0].eventIdentifier == "event2")
    }

    @Test("deleteMultipleShiftEvents returns count of deleted events")
    func deleteMultipleShiftEventsReturnsCorrectCount() async throws {
        let mockService = MockCalendarService()

        let shiftType = ShiftTypeBuilder.nightShift()

        let shifts = (0..<5).map { i in
            ScheduledShift(
                id: UUID(),
                eventIdentifier: "event\(i)",
                shiftType: shiftType,
                date: try Date.fixedTestDate_Nov11_2025(),
                notes: nil
            )
        }

        mockService.mockShifts = shifts

        // Delete 3 of 5 events
        let deletedCount = try await mockService.deleteMultipleShiftEvents(["event1", "event2", "event4"])

        #expect(deletedCount == 3)
        #expect(mockService.mockShifts.count == 2)
    }

    @Test("deleteMultipleShiftEvents handles non-existent events gracefully")
    func deleteMultipleShiftEventsHandlesNonExistentEvents() async throws {
        let mockService = MockCalendarService()

        let shiftType = ShiftTypeBuilder.nightShift()

        let shift1 = ScheduledShift(id: UUID(), eventIdentifier: "event1", shiftType: shiftType, date: try Date.fixedTestDate_Nov11_2025(), notes: nil)
        let shift2 = ScheduledShift(id: UUID(), eventIdentifier: "event2", shiftType: shiftType, date: try Date.fixedTestDate_Nov11_2025(), notes: nil)

        mockService.mockShifts = [shift1, shift2]

        // Try to delete including non-existent event
        let deletedCount = try await mockService.deleteMultipleShiftEvents(["event1", "nonexistent", "event2"])

        #expect(deletedCount == 2)
        #expect(mockService.mockShifts.isEmpty)
    }

    @Test("deleteMultipleShiftEvents requires authorization")
    func deleteMultipleShiftEventsRequiresAuthorization() async throws {
        let mockService = MockCalendarService()
        mockService.mockIsAuthorized = false

        let shiftType = ShiftTypeBuilder.nightShift()

        let shift = ScheduledShift(id: UUID(), eventIdentifier: "event1", shiftType: shiftType, date: try Date.fixedTestDate_Nov11_2025(), notes: nil)
        mockService.mockShifts = [shift]

        // Should throw authorization error
        do {
            _ = try await mockService.deleteMultipleShiftEvents(["event1"])
            Issue.record("Should have thrown a CalendarServiceError")
        } catch {
            #expect(error is CalendarServiceError)
        }
    }

    @Test("deleteMultipleShiftEvents handles empty array")
    func deleteMultipleShiftEventsHandlesEmptyArray() async throws {
        let mockService = MockCalendarService()

        let shiftType = ShiftTypeBuilder.nightShift()

        let shift = ScheduledShift(id: UUID(), eventIdentifier: "event1", shiftType: shiftType, date: try Date.fixedTestDate_Nov11_2025(), notes: nil)
        mockService.mockShifts = [shift]

        let deletedCount = try await mockService.deleteMultipleShiftEvents([])

        #expect(deletedCount == 0)
        #expect(mockService.mockShifts.count == 1)
    }

    @Test("deleteMultipleShiftEvents increments call count")
    func deleteMultipleShiftEventsIncrementsCallCount() async throws {
        let mockService = MockCalendarService()

        #expect(mockService.deleteMultipleShiftEventsCallCount == 0)

        _ = try await mockService.deleteMultipleShiftEvents([])

        #expect(mockService.deleteMultipleShiftEventsCallCount == 1)

        _ = try await mockService.deleteMultipleShiftEvents([])

        #expect(mockService.deleteMultipleShiftEventsCallCount == 2)
    }

    @Test("deleteMultipleShiftEvents respects shouldThrowError flag")
    func deleteMultipleShiftEventsRespectsErrorFlag() async throws {
        let mockService = MockCalendarService()
        mockService.shouldThrowError = true
        mockService.throwError = PersistenceError.saveFailed("Test error")

        let shiftType = ShiftTypeBuilder.nightShift()

        let shift = ScheduledShift(id: UUID(), eventIdentifier: "event1", shiftType: shiftType, date: try Date.fixedTestDate_Nov11_2025(), notes: nil)
        mockService.mockShifts = [shift]

        do {
            _ = try await mockService.deleteMultipleShiftEvents(["event1"])
            Issue.record("Should have thrown an error")
        } catch {
            #expect(error is PersistenceError)
        }
    }
}
