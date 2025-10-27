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

    var mockShiftData: [ScheduledShiftData] = []

    func loadShiftData(from startDate: Date, to endDate: Date) async throws -> [ScheduledShiftData] {
        if shouldThrowError, let error = throwError {
            throw error
        }
        return mockShiftData.filter { data in
            data.date >= startDate && data.date <= endDate
        }
    }

    func loadShiftDataForToday() async throws -> [ScheduledShiftData] {
        if shouldThrowError, let error = throwError {
            throw error
        }
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today
        return try await loadShiftData(from: today, to: tomorrow)
    }

    func loadShiftDataForTomorrow() async throws -> [ScheduledShiftData] {
        if shouldThrowError, let error = throwError {
            throw error
        }
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today
        let dayAfterTomorrow = Calendar.current.date(byAdding: .day, value: 1, to: tomorrow) ?? tomorrow
        return try await loadShiftData(from: tomorrow, to: dayAfterTomorrow)
    }

    func createShiftEvent(date: Date, shiftType: ShiftType, notes: String?) async throws -> ScheduledShift {
        if shouldThrowError, let error = throwError {
            throw error
        }

        // Check for duplicate shifts
        let startDate = Calendar.current.startOfDay(for: date)
        let endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate) ?? startDate

        if mockShifts.contains(where: { $0.shiftType?.id == shiftType.id && $0.date == startDate }) {
            throw ScheduleError.duplicateShift(date: startDate)
        }

        // Create and add mock shift
        let shift = ScheduledShift(
            id: UUID(),
            eventIdentifier: UUID().uuidString,
            shiftType: shiftType,
            date: startDate
        )

        mockShifts.append(shift)
        return shift
    }
}
