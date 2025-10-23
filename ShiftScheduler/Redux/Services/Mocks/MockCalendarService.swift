import Foundation

/// Mock implementation of CalendarServiceProtocol for testing
final class MockCalendarService: CalendarServiceProtocol {
    var mockShifts: [ScheduledShift] = []
    var mockIsAuthorized: Bool = true
    var mockRequestAccessResult: Bool = true
    var shouldThrowError: Bool = false
    var throwError: Error?

    func isCalendarAuthorized() async throws -> Bool {
        if shouldThrowError, let error = throwError {
            throw error
        }
        return mockIsAuthorized
    }

    func requestCalendarAccess() async throws -> Bool {
        if shouldThrowError, let error = throwError {
            throw error
        }
        return mockRequestAccessResult
    }

    func loadShifts(from startDate: Date, to endDate: Date) async throws -> [ScheduledShift] {
        if shouldThrowError, let error = throwError {
            throw error
        }
        return mockShifts.filter { shift in
            shift.date >= startDate && shift.date <= endDate
        }
    }

    func loadShiftsForNext30Days() async throws -> [ScheduledShift] {
        if shouldThrowError, let error = throwError {
            throw error
        }
        return mockShifts
    }

    func loadShiftsForCurrentMonth() async throws -> [ScheduledShift] {
        if shouldThrowError, let error = throwError {
            throw error
        }
        return mockShifts
    }
}
