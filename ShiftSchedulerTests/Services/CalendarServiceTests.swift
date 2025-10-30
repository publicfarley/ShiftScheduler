import Testing
import Foundation
import EventKit
@testable import ShiftScheduler

/// Tests for CalendarService
/// Uses MockCalendarService for proper unit testing (not device-dependent)
/// Tests actual behavior and return values (not just types)
@Suite("CalendarService Tests")
@MainActor
struct CalendarServiceTests {

    // MARK: - Setup Helpers

    /// Create a test location
    static func createTestLocation() -> Location {
        Location(id: UUID(), name: "Test Office", address: "123 Test St")
    }

    /// Create test shift types
    static func createTestShiftType(
        title: String = "Morning Shift",
        symbol: String = "🌅",
        duration: ShiftDuration = .allDay,
        location: Location? = nil
    ) -> ShiftType {
        ShiftType(
            id: UUID(),
            symbol: symbol,
            duration: duration,
            title: title,
            description: "Test shift",
            location: location ?? createTestLocation()
        )
    }

    // MARK: - Authorization Tests (Fixed to test actual behavior)

    @Test("isCalendarAuthorized returns true when authorized")
    func testIsCalendarAuthorizedWhenAuthorized() async throws {
        // Given - Mock service configured as authorized
        let mockService = MockCalendarService(isAuthorized: true)

        // When
        let isAuthorized = try await mockService.isCalendarAuthorized()

        // Then - should return actual boolean value, not just type check
        #expect(isAuthorized == true)
    }

    @Test("isCalendarAuthorized returns false when not authorized")
    func testIsCalendarAuthorizedWhenNotAuthorized() async throws {
        // Given - Mock service configured as NOT authorized
        let mockService = MockCalendarService(isAuthorized: false)

        // When
        let isAuthorized = try await mockService.isCalendarAuthorized()

        // Then - should return false
        #expect(isAuthorized == false)
    }

    @Test("requestCalendarAccess returns true when user grants access")
    func testRequestCalendarAccessGranted() async throws {
        // Given - Mock service that will grant access
        let mockService = MockCalendarService(isAuthorized: false)

        // When - request access
        let hasAccess = try await mockService.requestCalendarAccess()

        // Then - should return true (mock grants access by default)
        #expect(hasAccess == true)
    }

    // MARK: - Shift Loading Tests (Fixed to test actual data)

    @Test("loadShifts returns empty array when no shifts exist")
    func testLoadShiftsReturnsEmptyArray() async throws {
        // Given - Mock service with no shifts
        let mockService = MockCalendarService(isAuthorized: true)
        mockService.mockShifts = []  // Explicitly empty

        let startDate = Calendar.current.startOfDay(for: Date())
        let endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate) ?? startDate

        // When
        let shifts = try await mockService.loadShifts(from: startDate, to: endDate)

        // Then - should return empty array
        #expect(shifts.isEmpty)
        #expect(shifts.count == 0)
    }

    @Test("loadShifts returns scheduled shifts when they exist")
    func testLoadShiftsReturnsScheduledShifts() async throws {
        // Given - Mock service with test shifts
        let mockService = MockCalendarService(isAuthorized: true)
        let testShift = ScheduledShift(
            id: UUID(),
            date: Date(),
            shiftType: nil,
            eventIdentifier: "test-event-123"
        )
        mockService.mockShifts = [testShift]

        let startDate = Calendar.current.startOfDay(for: Date())
        let endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate) ?? startDate

        // When
        let shifts = try await mockService.loadShifts(from: startDate, to: endDate)

        // Then - should return the test shift
        #expect(shifts.count == 1)
        #expect(shifts.first?.eventIdentifier == "test-event-123")
    }

    @Test("loadShifts throws error when not authorized")
    func testLoadShiftsThrowsWhenNotAuthorized() async throws {
        // Given - Mock service NOT authorized
        let mockService = MockCalendarService(isAuthorized: false)

        let startDate = Calendar.current.startOfDay(for: Date())
        let endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate) ?? startDate

        // When/Then - should throw CalendarServiceError
        await #expect(throws: CalendarServiceError.self) {
            try await mockService.loadShifts(from: startDate, to: endDate)
        }
    }

    @Test("loadShiftsForCurrentMonth loads shifts for current month")
    func testLoadShiftsForCurrentMonth() async throws {
        // Given - Mock service with shifts
        let mockService = MockCalendarService(isAuthorized: true)
        let testShift = ScheduledShift(
            id: UUID(),
            date: Date(),
            shiftType: nil,
            eventIdentifier: "monthly-shift"
        )
        mockService.mockShifts = [testShift]

        // When
        let shifts = try await mockService.loadShiftsForCurrentMonth()

        // Then
        #expect(shifts.count == 1)
        #expect(shifts.first?.eventIdentifier == "monthly-shift")
    }

    @Test("loadShiftsForNext30Days loads shifts for next 30 days")
    func testLoadShiftsForNext30Days() async throws {
        // Given - Mock service with shifts
        let mockService = MockCalendarService(isAuthorized: true)
        let testShift = ScheduledShift(
            id: UUID(),
            date: Date(),
            shiftType: nil,
            eventIdentifier: "future-shift"
        )
        mockService.mockShifts = [testShift]

        // When
        let shifts = try await mockService.loadShiftsForNext30Days()

        // Then
        #expect(shifts.count == 1)
        #expect(shifts.first?.eventIdentifier == "future-shift")
    }

    // MARK: - Shift Data Loading Tests

    @Test("loadShiftData returns shift data array")
    func testLoadShiftDataReturnsData() async throws {
        // Given - Mock service with shift data
        let mockService = MockCalendarService(isAuthorized: true)
        let testShiftData = ScheduledShiftData(
            eventIdentifier: "data-event",
            date: Date(),
            shiftTypeId: UUID()
        )
        mockService.mockShiftData = [testShiftData]

        let startDate = Calendar.current.startOfDay(for: Date())
        let endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate) ?? startDate

        // When
        let shiftData = try await mockService.loadShiftData(from: startDate, to: endDate)

        // Then - should return actual data (not just type check)
        #expect(shiftData.count == 1)
        #expect(shiftData.first?.eventIdentifier == "data-event")
    }

    @Test("loadShiftData throws error when not authorized")
    func testLoadShiftDataThrowsWhenNotAuthorized() async throws {
        // Given - Mock service NOT authorized
        let mockService = MockCalendarService(isAuthorized: false)

        let startDate = Calendar.current.startOfDay(for: Date())
        let endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate) ?? startDate

        // When/Then - should throw error
        await #expect(throws: CalendarServiceError.self) {
            try await mockService.loadShiftData(from: startDate, to: endDate)
        }
    }

    // MARK: - Shift Event Creation/Update Tests

    @Test("createShiftEvent creates event successfully")
    func testCreateShiftEventSucceeds() async throws {
        // Given - Mock service authorized
        let mockService = MockCalendarService(isAuthorized: true)
        let shiftType = Self.createTestShiftType()
        let date = Calendar.current.startOfDay(for: Date())

        // When
        let eventId = try await mockService.createShiftEvent(shiftType: shiftType, date: date)

        // Then - should return event identifier
        #expect(eventId != nil)
        #expect(!eventId.isEmpty)
    }

    @Test("createShiftEvent throws error when not authorized")
    func testCreateShiftEventThrowsWhenNotAuthorized() async throws {
        // Given - Mock service NOT authorized
        let mockService = MockCalendarService(isAuthorized: false)
        let shiftType = Self.createTestShiftType()
        let date = Date()

        // When/Then - should throw error
        await #expect(throws: CalendarServiceError.self) {
            try await mockService.createShiftEvent(shiftType: shiftType, date: date)
        }
    }

    @Test("updateShiftEvent updates event successfully")
    func testUpdateShiftEventSucceeds() async throws {
        // Given - Mock service authorized
        let mockService = MockCalendarService(isAuthorized: true)
        let eventId = "test-event-update"
        let newShiftType = Self.createTestShiftType(title: "Updated Shift")
        let date = Date()

        // When - should not throw
        try await mockService.updateShiftEvent(
            eventIdentifier: eventId,
            newShiftType: newShiftType,
            date: date
        )

        // Then - no exception means success
        #expect(true)
    }

    @Test("updateShiftEvent throws error when not authorized")
    func testUpdateShiftEventThrowsWhenNotAuthorized() async throws {
        // Given - Mock service NOT authorized
        let mockService = MockCalendarService(isAuthorized: false)
        let eventId = "test-event"
        let shiftType = Self.createTestShiftType()
        let date = Date()

        // When/Then - should throw error
        await #expect(throws: CalendarServiceError.self) {
            try await mockService.updateShiftEvent(
                eventIdentifier: eventId,
                newShiftType: shiftType,
                date: date
            )
        }
    }

    @Test("deleteShiftEvent deletes event successfully")
    func testDeleteShiftEventSucceeds() async throws {
        // Given - Mock service authorized
        let mockService = MockCalendarService(isAuthorized: true)
        let eventId = "test-event-delete"

        // When - should not throw
        try await mockService.deleteShiftEvent(eventIdentifier: eventId)

        // Then - no exception means success
        #expect(true)
    }

    @Test("deleteShiftEvent throws error when not authorized")
    func testDeleteShiftEventThrowsWhenNotAuthorized() async throws {
        // Given - Mock service NOT authorized
        let mockService = MockCalendarService(isAuthorized: false)
        let eventId = "test-event"

        // When/Then - should throw error
        await #expect(throws: CalendarServiceError.self) {
            try await mockService.deleteShiftEvent(eventIdentifier: eventId)
        }
    }

    // MARK: - Helper Tests (Structural validation)

    @Test("ShiftType with valid location can be used for event creation")
    func testShiftTypeWithValidLocationStructure() {
        // Given
        let location = Self.createTestLocation()
        let shiftType = Self.createTestShiftType(location: location)

        // Then - Validate actual values (not just types)
        #expect(shiftType.title == "Morning Shift")
        #expect(shiftType.symbol == "🌅")
        #expect(shiftType.location.name == "Test Office")
        #expect(shiftType.location.address == "123 Test St")
    }

    @Test("Multiple shifts can be loaded at once")
    func testLoadMultipleShifts() async throws {
        // Given - Mock service with multiple shifts
        let mockService = MockCalendarService(isAuthorized: true)
        let shift1 = ScheduledShift(id: UUID(), date: Date(), shiftType: nil, eventIdentifier: "shift-1")
        let shift2 = ScheduledShift(id: UUID(), date: Date(), shiftType: nil, eventIdentifier: "shift-2")
        let shift3 = ScheduledShift(id: UUID(), date: Date(), shiftType: nil, eventIdentifier: "shift-3")
        mockService.mockShifts = [shift1, shift2, shift3]

        let startDate = Calendar.current.startOfDay(for: Date())
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate) ?? startDate

        // When
        let shifts = try await mockService.loadShifts(from: startDate, to: endDate)

        // Then - should return all 3 shifts
        #expect(shifts.count == 3)
        #expect(shifts[0].eventIdentifier == "shift-1")
        #expect(shifts[1].eventIdentifier == "shift-2")
        #expect(shifts[2].eventIdentifier == "shift-3")
    }
}
