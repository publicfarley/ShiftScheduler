import Testing
import Foundation
@testable import ShiftScheduler

/// Integration tests for CalendarService update cascade functionality
/// Tests that ShiftType updates correctly cascade to calendar events
/// Note: Uses MockCalendarService since EventKit requires authorization
@Suite("CalendarService Update Tests")
@MainActor
struct CalendarServiceUpdateTests {

    // MARK: - Test Helpers

    /// Create a mock calendar service for testing
    static func createMockCalendarService() -> MockCalendarService {
        let service = MockCalendarService()
        service.mockIsAuthorized = true
        return service
    }

    // MARK: - updateEventsWithShiftType Tests

    @Test("updateEventsWithShiftType updates all events created from the ShiftType")
    func testUpdateEventsWithShiftTypeUpdatesMatchingEvents() async throws {
        // Given
        let service = Self.createMockCalendarService()

        let location = Location(id: UUID(), name: "Office", address: "123 Main St")
        let shiftType = ShiftType(
            id: UUID(),
            symbol: "D",
            duration: .allDay,
            title: "Day Shift",
            description: "Original description",
            location: location
        )

        // Create calendar events that reference the shift type
        let shift1 = ScheduledShift(
            id: UUID(),
            eventIdentifier: "event1",
            shiftType: shiftType,
            date: try Date.fixedTestDate_Nov11_2025()
        )
        let shift2 = ScheduledShift(
            id: UUID(),
            eventIdentifier: "event2",
            shiftType: shiftType,
            date: try Date.fixedTestDate_Nov11_2025().addingTimeInterval(86400)
        )
        let shift3 = ScheduledShift(
            id: UUID(),
            eventIdentifier: "event3",
            shiftType: shiftType,
            date: try Date.fixedTestDate_Nov11_2025().addingTimeInterval(172800)
        )

        service.mockShifts = [shift1, shift2, shift3]

        // Update the shift type
        let updatedShiftType = ShiftType(
            id: shiftType.id, // Same ID
            symbol: shiftType.symbol,
            duration: shiftType.duration,
            title: "Updated Day Shift",
            description: "New description",
            location: location
        )

        // When
        let updatedCount = try await service.updateEventsWithShiftType(updatedShiftType)

        // Then
        #expect(updatedCount == 3, "Should update all 3 events")
        #expect(service.updateEventsWithShiftTypeCallCount == 1)

        // Verify all events were updated with new ShiftType data
        #expect(service.mockShifts.count == 3)
        for shift in service.mockShifts {
            #expect(shift.shiftType?.id == shiftType.id)
            #expect(shift.shiftType?.title == "Updated Day Shift")
            #expect(shift.shiftType?.shiftDescription == "New description")
        }
    }

    @Test("updateEventsWithShiftType returns zero when no events reference the ShiftType")
    func testUpdateEventsWithShiftTypeNoMatches() async throws {
        // Given
        let service = Self.createMockCalendarService()

        let location = Location(id: UUID(), name: "Office", address: "123 Main St")
        let shiftType1 = ShiftType(
            id: UUID(),
            symbol: "D",
            duration: .allDay,
            title: "Day Shift",
            description: "",
            location: location
        )
        let shiftType2 = ShiftType(
            id: UUID(),
            symbol: "N",
            duration: .allDay,
            title: "Night Shift",
            description: "",
            location: location
        )

        // Create event that references shiftType2
        let shift = ScheduledShift(
            id: UUID(),
            eventIdentifier: "event1",
            shiftType: shiftType2,
            date: try Date.fixedTestDate_Nov11_2025()
        )
        service.mockShifts = [shift]

        // Update shiftType1 (not referenced by any events)
        let updatedShiftType1 = ShiftType(
            id: shiftType1.id,
            symbol: shiftType1.symbol,
            duration: shiftType1.duration,
            title: "Updated Day Shift",
            description: "New",
            location: location
        )

        // When
        let updatedCount = try await service.updateEventsWithShiftType(updatedShiftType1)

        // Then
        #expect(updatedCount == 0, "Should return 0 when no events match")

        // Verify existing event was not modified
        #expect(service.mockShifts.count == 1)
        #expect(service.mockShifts[0].shiftType?.id == shiftType2.id)
        #expect(service.mockShifts[0].shiftType?.title == "Night Shift")
    }

    @Test("updateEventsWithShiftType updates Location in calendar events")
    func testUpdateEventsWithShiftTypeUpdatesLocation() async throws {
        // Given
        let service = Self.createMockCalendarService()

        let originalLocation = Location(id: UUID(), name: "Office", address: "123 Main St")
        let shiftType = ShiftType(
            id: UUID(),
            symbol: "D",
            duration: .allDay,
            title: "Day Shift",
            description: "",
            location: originalLocation
        )

        let shift = ScheduledShift(
            id: UUID(),
            eventIdentifier: "event1",
            shiftType: shiftType,
            date: try Date.fixedTestDate_Nov11_2025()
        )
        service.mockShifts = [shift]

        // Update shift type with new location
        let newLocation = Location(id: originalLocation.id, name: "Office", address: "456 New Ave")
        let updatedShiftType = ShiftType(
            id: shiftType.id,
            symbol: shiftType.symbol,
            duration: shiftType.duration,
            title: shiftType.title,
            description: shiftType.shiftDescription,
            location: newLocation
        )

        // When
        let updatedCount = try await service.updateEventsWithShiftType(updatedShiftType)

        // Then
        #expect(updatedCount == 1)
        #expect(service.mockShifts[0].shiftType?.location.address == "456 New Ave")
    }

    @Test("updateEventsWithShiftType preserves user notes in calendar events")
    func testUpdateEventsWithShiftTypePreservesNotes() async throws {
        // Given
        let service = Self.createMockCalendarService()

        let location = Location(id: UUID(), name: "Office", address: "123 Main St")
        let shiftType = ShiftType(
            id: UUID(),
            symbol: "D",
            duration: .allDay,
            title: "Day Shift",
            description: "",
            location: location
        )

        let shiftWithNotes = ScheduledShift(
            id: UUID(),
            eventIdentifier: "event1",
            shiftType: shiftType,
            date: try Date.fixedTestDate_Nov11_2025(),
            notes: "Important meeting at 3pm"
        )
        service.mockShifts = [shiftWithNotes]

        // Update shift type
        let updatedShiftType = ShiftType(
            id: shiftType.id,
            symbol: shiftType.symbol,
            duration: shiftType.duration,
            title: "Updated Day Shift",
            description: "New desc",
            location: location
        )

        // When
        let updatedCount = try await service.updateEventsWithShiftType(updatedShiftType)

        // Then
        #expect(updatedCount == 1)
        #expect(service.mockShifts[0].shiftType?.title == "Updated Day Shift")
        #expect(service.mockShifts[0].notes == "Important meeting at 3pm", "Should preserve user notes")
    }

    @Test("updateEventsWithShiftType handles mixed events (some matching, some not)")
    func testUpdateEventsWithShiftTypeMixedMatches() async throws {
        // Given
        let service = Self.createMockCalendarService()

        let location = Location(id: UUID(), name: "Office", address: "123 Main St")
        let shiftType1 = ShiftType(
            id: UUID(),
            symbol: "D",
            duration: .allDay,
            title: "Day Shift",
            description: "",
            location: location
        )
        let shiftType2 = ShiftType(
            id: UUID(),
            symbol: "N",
            duration: .allDay,
            title: "Night Shift",
            description: "",
            location: location
        )

        // Create 5 events: 3 from shiftType1, 2 from shiftType2
        let shift1 = ScheduledShift(id: UUID(), eventIdentifier: "e1", shiftType: shiftType1, date: try Date.fixedTestDate_Nov11_2025())
        let shift2 = ScheduledShift(id: UUID(), eventIdentifier: "e2", shiftType: shiftType2, date: try Date.fixedTestDate_Nov11_2025())
        let shift3 = ScheduledShift(id: UUID(), eventIdentifier: "e3", shiftType: shiftType1, date: try Date.fixedTestDate_Nov11_2025())
        let shift4 = ScheduledShift(id: UUID(), eventIdentifier: "e4", shiftType: shiftType2, date: try Date.fixedTestDate_Nov11_2025())
        let shift5 = ScheduledShift(id: UUID(), eventIdentifier: "e5", shiftType: shiftType1, date: try Date.fixedTestDate_Nov11_2025())

        service.mockShifts = [shift1, shift2, shift3, shift4, shift5]

        // Update shiftType1
        let updatedShiftType1 = ShiftType(
            id: shiftType1.id,
            symbol: shiftType1.symbol,
            duration: shiftType1.duration,
            title: "Updated Day Shift",
            description: "New",
            location: location
        )

        // When
        let updatedCount = try await service.updateEventsWithShiftType(updatedShiftType1)

        // Then
        #expect(updatedCount == 3, "Should update 3 events that match shiftType1")

        // Verify the 3 matching events were updated
        let shiftType1Events = service.mockShifts.filter { $0.shiftType?.id == shiftType1.id }
        #expect(shiftType1Events.count == 3)
        for shift in shiftType1Events {
            #expect(shift.shiftType?.title == "Updated Day Shift")
        }

        // Verify the 2 non-matching events were NOT updated
        let shiftType2Events = service.mockShifts.filter { $0.shiftType?.id == shiftType2.id }
        #expect(shiftType2Events.count == 2)
        for shift in shiftType2Events {
            #expect(shift.shiftType?.title == "Night Shift")
        }
    }

    @Test("updateEventsWithShiftType requires calendar authorization")
    func testUpdateEventsWithShiftTypeRequiresAuthorization() async throws {
        // Given
        let service = Self.createMockCalendarService()
        service.mockIsAuthorized = false // Not authorized

        let location = Location(id: UUID(), name: "Office", address: "123 Main St")
        let shiftType = ShiftType(
            id: UUID(),
            symbol: "D",
            duration: .allDay,
            title: "Day Shift",
            description: "",
            location: location
        )

        // When/Then
        await #expect(throws: CalendarServiceError.self) {
            _ = try await service.updateEventsWithShiftType(shiftType)
        }
    }

    @Test("updateEventsWithShiftType updates multiple events across date range")
    func testUpdateEventsWithShiftTypeMultipleDates() async throws {
        // Given
        let service = Self.createMockCalendarService()

        let location = Location(id: UUID(), name: "Hospital", address: "100 Health Blvd")
        let shiftType = ShiftType(
            id: UUID(),
            symbol: "S",
            duration: .allDay,
            title: "Standard Shift",
            description: "",
            location: location
        )

        // Create 10 events spread across 10 days, all from the same shift type
        let shifts = (0..<10).map { dayOffset in
            ScheduledShift(
                id: UUID(),
                eventIdentifier: "event\(dayOffset)",
                shiftType: shiftType,
                date: try Date.fixedTestDate_Nov11_2025().addingTimeInterval(Double(dayOffset) * 86400)
            )
        }
        service.mockShifts = shifts

        // Update shift type with new title and location
        let newLocation = Location(id: location.id, name: "Hospital", address: "200 New Health Ave")
        let updatedShiftType = ShiftType(
            id: shiftType.id,
            symbol: shiftType.symbol,
            duration: shiftType.duration,
            title: "Updated Standard Shift",
            description: "New desc",
            location: newLocation
        )

        // When
        let updatedCount = try await service.updateEventsWithShiftType(updatedShiftType)

        // Then
        #expect(updatedCount == 10, "Should update all 10 events across the date range")

        // Verify all events were updated
        for shift in service.mockShifts {
            #expect(shift.shiftType?.id == shiftType.id)
            #expect(shift.shiftType?.title == "Updated Standard Shift")
            #expect(shift.shiftType?.location.address == "200 New Health Ave")
        }
    }
}
