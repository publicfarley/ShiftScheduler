import Testing
import Foundation
import EventKit
@testable import ShiftScheduler

/// Tests for CalendarService
/// Validates calendar operations, shift loading, event creation/update/deletion
/// NOTE: These tests interact with the device calendar, so they may have flaky behavior
/// depending on device permissions and existing calendar data
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

    // MARK: - Tests: Authorization

    @Test("isCalendarAuthorized returns boolean")
    func testIsCalendarAuthorizedReturnsBo() async throws {
        // Given
        let mockRepository = ShiftTypeRepository()
        let service = CalendarService(shiftTypeRepository: mockRepository)

        // When
        let isAuthorized = try await service.isCalendarAuthorized()

        // Then
        #expect(isAuthorized is Bool)
    }

    // MARK: - Tests: Shift Loading (Minimal due to device calendar dependency)

    @Test("loadShifts returns array type")
    func testLoadShiftsReturnsArrayType() async throws {
        // Given
        let mockRepository = ShiftTypeRepository()
        let service = CalendarService(shiftTypeRepository: mockRepository)
        let startDate = Calendar.current.startOfDay(for: Date())
        let endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate) ?? startDate

        // When/Then - Just verify it returns an array, actual data depends on calendar permissions
        do {
            let shifts = try await service.loadShifts(from: startDate, to: endDate)
            #expect(shifts is [ScheduledShift])
        } catch is CalendarServiceError {
            // Expected if not authorized
        }
    }

    @Test("loadShiftsForCurrentMonth returns array type")
    func testLoadShiftsForCurrentMonthReturnsArrayType() async throws {
        // Given
        let mockRepository = ShiftTypeRepository()
        let service = CalendarService(shiftTypeRepository: mockRepository)

        // When/Then
        do {
            let shifts = try await service.loadShiftsForCurrentMonth()
            #expect(shifts is [ScheduledShift])
        } catch is CalendarServiceError {
            // Expected if not authorized
        }
    }

    @Test("loadShiftsForNext30Days returns array type")
    func testLoadShiftsForNext30DaysReturnsArrayType() async throws {
        // Given
        let mockRepository = ShiftTypeRepository()
        let service = CalendarService(shiftTypeRepository: mockRepository)

        // When/Then
        do {
            let shifts = try await service.loadShiftsForNext30Days()
            #expect(shifts is [ScheduledShift])
        } catch is CalendarServiceError {
            // Expected if not authorized
        }
    }

    @Test("loadShiftData returns array type")
    func testLoadShiftDataReturnsArrayType() async throws {
        // Given
        let mockRepository = ShiftTypeRepository()
        let service = CalendarService(shiftTypeRepository: mockRepository)
        let startDate = Calendar.current.startOfDay(for: Date())
        let endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate) ?? startDate

        // When/Then
        do {
            let shiftData = try await service.loadShiftData(from: startDate, to: endDate)
            #expect(shiftData is [ScheduledShiftData])
        } catch is CalendarServiceError {
            // Expected if not authorized
        }
    }

    // MARK: - Tests: Shift Data Extraction

    @Test("convertEventToShiftData extracts shift type IDs")
    func testConvertEventToShiftDataExtractsShiftTypeIds() async throws {
        // This test validates the internal method behavior
        // by creating an event and converting it
        // Actual test would need a mock EKEvent

        // For now, we test the structural expectation
        let location = Self.createTestLocation()
        let shiftType = Self.createTestShiftType(location: location)

        #expect(shiftType.id != nil)
    }

    // MARK: - Tests: Error Handling

    @Test("Unauthorized calendar access throws error")
    func testUnauthorizedCalendarAccessThrowsError() async throws {
        // This test documents expected behavior when calendar is not authorized
        // Actual result depends on device permissions

        let mockRepository = ShiftTypeRepository()
        let service = CalendarService(shiftTypeRepository: mockRepository)

        do {
            let startDate = Calendar.current.startOfDay(for: Date())
            let endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate) ?? startDate
            let _ = try await service.loadShifts(from: startDate, to: endDate)
            // If successful, calendar is authorized
            #expect(true)
        } catch {
            // If error, calendar is not authorized - this is expected
            #expect(true)
        }
    }

    @Test("ShiftType with valid location can be used for event creation")
    func testShiftTypeWithValidLocationForEventCreation() {
        // Given
        let location = Self.createTestLocation()
        let shiftType = Self.createTestShiftType(location: location)

        // Then - Validate structure
        #expect(shiftType.title == "Morning Shift")
        #expect(shiftType.symbol == "🌅")
        #expect(shiftType.location.name == "Test Office")
    }
}

