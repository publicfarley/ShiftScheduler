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

        // Check for overlapping shifts (business rule: no overlaps allowed)
        let startDate = Calendar.current.startOfDay(for: date)
        let endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate) ?? startDate

        let existingShifts = mockShifts.filter { $0.date == startDate }
        if !existingShifts.isEmpty {
            let shiftTitles = existingShifts.compactMap { $0.shiftType?.title }
            throw ScheduleError.overlappingShifts(date: startDate, existingShifts: shiftTitles)
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

    func updateShiftEvent(eventIdentifier: String, newShiftType: ShiftType, date: Date) async throws {
        if shouldThrowError, let error = throwError {
            throw error
        }

        // Find the shift to update
        guard let index = mockShifts.firstIndex(where: { $0.eventIdentifier == eventIdentifier }) else {
            throw CalendarServiceError.eventConversionFailed("Event with identifier \(eventIdentifier) not found")
        }

        // Check for overlapping shifts on the same date (excluding the current shift being updated)
        let startDate = Calendar.current.startOfDay(for: date)
        let otherShifts = mockShifts.filter { $0.eventIdentifier != eventIdentifier && $0.date == startDate }

        if !otherShifts.isEmpty {
            let shiftTitles = otherShifts.compactMap { $0.shiftType?.title }
            throw ScheduleError.overlappingShifts(date: startDate, existingShifts: shiftTitles)
        }

        // Update the shift with the new shift type
        mockShifts[index] = ScheduledShift(
            id: mockShifts[index].id,
            eventIdentifier: mockShifts[index].eventIdentifier,
            shiftType: newShiftType,
            date: mockShifts[index].date
        )
    }

    func deleteShiftEvent(eventIdentifier: String) async throws {
        if shouldThrowError, let error = throwError {
            throw error
        }

        // Find the shift to delete
        guard let index = mockShifts.firstIndex(where: { $0.eventIdentifier == eventIdentifier }) else {
            throw ScheduleError.calendarEventDeletionFailed("Event with identifier \(eventIdentifier) not found")
        }

        // Remove the shift
        mockShifts.remove(at: index)
    }
}
