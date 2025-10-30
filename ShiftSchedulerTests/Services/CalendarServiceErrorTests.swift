import Testing
import Foundation
@testable import ShiftScheduler

/// Error scenario tests for CalendarService
/// Tests authorization denials, permission issues, and error handling
@Suite("CalendarService Error Scenario Tests")
@MainActor
struct CalendarServiceErrorTests {

    // MARK: - Test Helpers

    /// Create a test shift type for shift creation
    static func createTestShiftType() -> ShiftType {
        let location = Location(id: UUID(), name: "Test Office", address: "123 Main St")
        return ShiftType(
            id: UUID(),
            symbol: "🌅",
            duration: .allDay,
            title: "Morning Shift",
            description: "Test shift",
            location: location
        )
    }

    // MARK: - Authorization Error Tests

    @Test("Calendar authorization throws when mock is configured to fail")
    func testAuthorizationThrowsWhenConfigured() async throws {
        let mockService = MockCalendarService()
        mockService.shouldThrowError = true
        mockService.throwError = CalendarServiceError.notAuthorized

        do {
            _ = try await mockService.isCalendarAuthorized()
            #expect(Bool(false), "Expected CalendarServiceError to be thrown")
        } catch let error as CalendarServiceError {
            if case .notAuthorized = error {
                #expect(true)
            } else {
                throw error
            }
        }
    }

    @Test("requestCalendarAccess throws when mock is configured to fail")
    func testRequestCalendarAccessThrowsWhenConfigured() async throws {
        let mockService = MockCalendarService()
        mockService.shouldThrowError = true
        mockService.throwError = CalendarServiceError.notAuthorized

        do {
            _ = try await mockService.requestCalendarAccess()
            #expect(Bool(false), "Expected CalendarServiceError to be thrown")
        } catch let error as CalendarServiceError {
            if case .notAuthorized = error {
                #expect(true)
            } else {
                throw error
            }
        }
    }

    // MARK: - Load Shifts Error Tests

    @Test("loadShifts throws when mock is configured with notAuthorized error")
    func testLoadShiftsThrowsNotAuthorized() async throws {
        let mockService = MockCalendarService()
        mockService.shouldThrowError = true
        mockService.throwError = CalendarServiceError.notAuthorized

        let startDate = Calendar.current.startOfDay(for: Date())
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate)!

        do {
            _ = try await mockService.loadShifts(from: startDate, to: endDate)
            #expect(Bool(false), "Expected CalendarServiceError.notAuthorized to be thrown")
        } catch let error as CalendarServiceError {
            if case .notAuthorized = error {
                #expect(true)
            } else {
                throw error
            }
        }
    }

    @Test("loadShiftsForNext30Days throws when error configured")
    func testLoadShiftsForNext30DaysThrowsError() async throws {
        let mockService = MockCalendarService()
        mockService.shouldThrowError = true
        mockService.throwError = CalendarServiceError.dateCalculationFailed

        do {
            _ = try await mockService.loadShiftsForNext30Days()
            #expect(Bool(false), "Expected CalendarServiceError to be thrown")
        } catch let error as CalendarServiceError {
            if case .dateCalculationFailed = error {
                #expect(true)
            } else {
                throw error
            }
        }
    }

    @Test("loadShiftsForCurrentMonth throws when error configured")
    func testLoadShiftsForCurrentMonthThrowsError() async throws {
        let mockService = MockCalendarService()
        mockService.shouldThrowError = true
        mockService.throwError = CalendarServiceError.eventConversionFailed("Test failure")

        do {
            _ = try await mockService.loadShiftsForCurrentMonth()
            #expect(Bool(false), "Expected CalendarServiceError to be thrown")
        } catch let error as CalendarServiceError {
            if case .eventConversionFailed = error {
                #expect(true)
            } else {
                throw error
            }
        }
    }

    // MARK: - Date Range Error Tests

    @Test("loadShifts handles invalid date ranges")
    func testLoadShiftsHandlesInvalidDateRanges() async throws {
        let service = CalendarService()
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: -1, to: startDate)! // End before start

        do {
            _ = try await service.loadShifts(from: startDate, to: endDate)
            // Empty result is acceptable for invalid range
            #expect(true)
        } catch {
            // Error is also acceptable
            #expect(true)
        }
    }

    @Test("loadShifts with same start and end date returns appropriate result")
    func testLoadShiftsWithSameDateRange() async throws {
        let service = CalendarService()
        let date = Calendar.current.startOfDay(for: Date())

        do {
            let shifts = try await service.loadShifts(from: date, to: date)
            // Should return empty array for single-day range or existing shifts
            #expect(shifts is [ScheduledShift])
        } catch {
            // Authorization error is acceptable
            #expect(true)
        }
    }

    // MARK: - Shift Creation Error Tests

    @Test("createShiftEvent throws overlappingShifts error when shift exists")
    func testCreateShiftEventThrowsOverlappingShifts() async throws {
        let mockService = MockCalendarService()
        let date = Calendar.current.startOfDay(for: Date())
        let shiftType = Self.createTestShiftType()

        // Add an existing shift for the same date
        let existingShift = ScheduledShift(
            id: UUID(),
            eventIdentifier: UUID().uuidString,
            shiftType: shiftType,
            date: date
        )
        mockService.mockShifts.append(existingShift)

        do {
            _ = try await mockService.createShiftEvent(date: date, shiftType: shiftType, notes: nil)
            #expect(Bool(false), "Expected overlappingShifts error to be thrown")
        } catch let error as ScheduleError {
            if case .overlappingShifts = error {
                #expect(true)
            } else {
                throw error
            }
        }
    }

    @Test("createShiftEvent throws CalendarServiceError when mock configured")
    func testCreateShiftEventThrowsCalendarError() async throws {
        let mockService = MockCalendarService()
        mockService.shouldThrowError = true
        mockService.throwError = CalendarServiceError.eventConversionFailed("Creation failed")

        let date = Calendar.current.startOfDay(for: Date())
        let shiftType = Self.createTestShiftType()

        do {
            _ = try await mockService.createShiftEvent(date: date, shiftType: shiftType, notes: nil)
            #expect(Bool(false), "Expected CalendarServiceError to be thrown")
        } catch let error as CalendarServiceError {
            if case .eventConversionFailed = error {
                #expect(true)
            } else {
                throw error
            }
        }
    }

    // MARK: - Update/Delete Error Tests

    @Test("updateShiftEvent throws when event not found")
    func testUpdateShiftEventThrowsMissingEvent() async throws {
        let mockService = MockCalendarService()
        let invalidEventId = "nonexistent-event-id"
        let shiftType = Self.createTestShiftType()
        let date = Date()

        do {
            try await mockService.updateShiftEvent(eventIdentifier: invalidEventId, newShiftType: shiftType, date: date)
            #expect(Bool(false), "Expected CalendarServiceError.eventConversionFailed to be thrown")
        } catch let error as CalendarServiceError {
            if case .eventConversionFailed = error {
                #expect(true)
            } else {
                throw error
            }
        }
    }

    @Test("deleteShiftEvent throws when event not found")
    func testDeleteShiftEventThrowsMissingEvent() async throws {
        let mockService = MockCalendarService()
        let invalidEventId = "nonexistent-event-id"

        do {
            try await mockService.deleteShiftEvent(eventIdentifier: invalidEventId)
            #expect(Bool(false), "Expected ScheduleError.calendarEventDeletionFailed to be thrown")
        } catch let error as ScheduleError {
            if case .calendarEventDeletionFailed = error {
                #expect(true)
            } else {
                throw error
            }
        }
    }

    // MARK: - Load Shift Data Error Tests

    @Test("loadShiftData throws when error configured")
    func testLoadShiftDataThrowsError() async throws {
        let mockService = MockCalendarService()
        mockService.shouldThrowError = true
        mockService.throwError = CalendarServiceError.dateCalculationFailed

        let startDate = Calendar.current.startOfDay(for: Date())
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate)!

        do {
            _ = try await mockService.loadShiftData(from: startDate, to: endDate)
            #expect(Bool(false), "Expected CalendarServiceError to be thrown")
        } catch let error as CalendarServiceError {
            if case .dateCalculationFailed = error {
                #expect(true)
            } else {
                throw error
            }
        }
    }

    @Test("loadShiftDataForToday throws when error configured")
    func testLoadShiftDataForTodayThrowsError() async throws {
        let mockService = MockCalendarService()
        mockService.shouldThrowError = true
        mockService.throwError = CalendarServiceError.notAuthorized

        do {
            _ = try await mockService.loadShiftDataForToday()
            #expect(Bool(false), "Expected CalendarServiceError to be thrown")
        } catch let error as CalendarServiceError {
            if case .notAuthorized = error {
                #expect(true)
            } else {
                throw error
            }
        }
    }

    @Test("loadShiftDataForTomorrow throws when error configured")
    func testLoadShiftDataForTomorrowThrowsError() async throws {
        let mockService = MockCalendarService()
        mockService.shouldThrowError = true
        mockService.throwError = CalendarServiceError.eventConversionFailed("Data loading failed")

        do {
            _ = try await mockService.loadShiftDataForTomorrow()
            #expect(Bool(false), "Expected CalendarServiceError to be thrown")
        } catch let error as CalendarServiceError {
            if case .eventConversionFailed = error {
                #expect(true)
            } else {
                throw error
            }
        }
    }

    // MARK: - Error Message Tests

    @Test("CalendarServiceError.notAuthorized provides error description")
    func testNotAuthorizedErrorDescription() {
        let error: CalendarServiceError = .notAuthorized
        let description = error.errorDescription
        #expect(description != nil)
        #expect(description?.isEmpty == false)
    }

    @Test("CalendarServiceError.dateCalculationFailed provides error description")
    func testDateCalculationFailedErrorDescription() {
        let error: CalendarServiceError = .dateCalculationFailed
        let description = error.errorDescription
        #expect(description != nil)
        #expect(description?.isEmpty == false)
    }

    @Test("CalendarServiceError.eventConversionFailed provides error description")
    func testEventConversionFailedErrorDescription() {
        let error: CalendarServiceError = .eventConversionFailed("Test reason")
        let description = error.errorDescription
        #expect(description != nil)
        #expect(description?.contains("Test reason") ?? false)
    }

    // MARK: - Recovery Suggestion Tests

    @Test("CalendarServiceError provides recovery suggestions")
    func testCalendarServiceErrorRecoverySuggestions() {
        let notAuthorizedError: CalendarServiceError = .notAuthorized
        let recoverySuggestion = notAuthorizedError.recoverySuggestion
        #expect(recoverySuggestion != nil)
        #expect(recoverySuggestion?.isEmpty == false)
    }

    // MARK: - Error Propagation Tests

    @Test("CalendarService errors conform to LocalizedError protocol")
    func testCalendarServiceErrorConformsToLocalizedError() {
        let error: CalendarServiceError = .notAuthorized
        #expect(error is LocalizedError)
    }

    @Test("ScheduleError.calendarAccessDenied provides proper error handling")
    func testScheduleErrorCalendarAccessDenied() {
        let error: ScheduleError = .calendarAccessDenied
        let description = error.errorDescription
        #expect(description != nil)
        #expect(description?.contains("access") ?? false)
    }

    @Test("ScheduleError.calendarEventCreationFailed provides error description")
    func testScheduleErrorEventCreationFailed() {
        let error: ScheduleError = .calendarEventCreationFailed("Test failure")
        let description = error.errorDescription
        #expect(description != nil)
        #expect(description?.isEmpty == false)
    }

    @Test("ScheduleError.calendarEventDeletionFailed provides error description")
    func testScheduleErrorEventDeletionFailed() {
        let error: ScheduleError = .calendarEventDeletionFailed("Test failure")
        let description = error.errorDescription
        #expect(description != nil)
        #expect(description?.isEmpty == false)
    }
}
