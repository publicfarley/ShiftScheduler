import Foundation

/// Mock implementation of CalendarServiceProtocol for testing
final class MockCalendarService: CalendarServiceProtocol {
    var mockShifts: [ScheduledShift] = []
    var mockIsAuthorized: Bool = true
    var mockRequestAccessResult: Bool = true
    var shouldThrowError: Bool = false
    var throwError: Error?

    // MARK: - Call Tracking for Testing

    private(set) var isCalendarAuthorizedCallCount = 0
    private(set) var requestCalendarAccessCallCount = 0
    private(set) var loadShiftsCallCount = 0
    private(set) var loadShiftsForNext30DaysCallCount = 0
    private(set) var loadShiftsForCurrentMonthCallCount = 0
    private(set) var loadShiftsForExtendedRangeCallCount = 0
    private(set) var loadShiftsAroundMonthCallCount = 0
    private(set) var loadShiftDataCallCount = 0
    private(set) var createShiftEventCallCount = 0
    private(set) var updateShiftEventCallCount = 0
    private(set) var deleteShiftEventCallCount = 0
    private(set) var deleteMultipleShiftEventsCallCount = 0
    private(set) var updateEventsWithShiftTypeCallCount = 0
    private(set) var updateShiftNotesCallCount = 0

    var lastLoadShiftsRange: (from: Date, to: Date)?
    var lastCreateShiftEventData: (date: Date, shiftType: ShiftType)?
    var lastUpdateShiftEventData: (eventId: String, shiftType: ShiftType)?
    var lastUpdateShiftNotesData: (eventId: String, notes: String)?

    // MARK: - Event Timing Tracking (for testing scheduled vs all-day events)

    /// Tracks whether the last created event was all-day or scheduled
    private(set) var lastCreatedEventIsAllDay: Bool?
    /// Tracks the start time of the last created event
    private(set) var lastCreatedEventStartTime: Date?
    /// Tracks the end time of the last created event
    private(set) var lastCreatedEventEndTime: Date?

    /// Tracks whether the last updated event was all-day or scheduled
    private(set) var lastUpdatedEventIsAllDay: Bool?
    /// Tracks the start time of the last updated event
    private(set) var lastUpdatedEventStartTime: Date?
    /// Tracks the end time of the last updated event
    private(set) var lastUpdatedEventEndTime: Date?

    func isCalendarAuthorized() async throws -> Bool {
        isCalendarAuthorizedCallCount += 1
        if shouldThrowError, let error = throwError {
            throw error
        }
        return mockIsAuthorized
    }

    func requestCalendarAccess() async throws -> Bool {
        requestCalendarAccessCallCount += 1
        if shouldThrowError, let error = throwError {
            throw error
        }
        return mockRequestAccessResult
    }

    func loadShifts(from startDate: Date, to endDate: Date) async throws -> [ScheduledShift] {
        loadShiftsCallCount += 1
        lastLoadShiftsRange = (startDate, endDate)
        if shouldThrowError, let error = throwError {
            throw error
        }
        // Check authorization
        guard mockIsAuthorized else {
            throw CalendarServiceError.notAuthorized
        }
        return mockShifts.filter { shift in
            shift.date >= startDate && shift.date <= endDate
        }
    }

    func loadShiftsForNext30Days() async throws -> [ScheduledShift] {
        loadShiftsForNext30DaysCallCount += 1
        if shouldThrowError, let error = throwError {
            throw error
        }
        return mockShifts
    }

    func loadShiftsForCurrentMonth() async throws -> [ScheduledShift] {
        loadShiftsForCurrentMonthCallCount += 1
        if shouldThrowError, let error = throwError {
            throw error
        }
        return mockShifts
    }

    func loadShiftsForExtendedRange() async throws -> [ScheduledShift] {
        loadShiftsForExtendedRangeCallCount += 1
        if shouldThrowError, let error = throwError {
            throw error
        }
        return mockShifts
    }

    func loadShiftsAroundMonth(_ pivotMonth: Date, monthOffset: Int = 6) async throws -> (shifts: [ScheduledShift], rangeStart: Date, rangeEnd: Date) {
        loadShiftsAroundMonthCallCount += 1
        if shouldThrowError, let error = throwError {
            throw error
        }

        // Calculate range dates
        let pivotStart = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: pivotMonth)) ?? pivotMonth
        let startDate = Calendar.current.date(byAdding: .month, value: -monthOffset, to: pivotStart) ?? pivotStart
        let endDate = Calendar.current.date(byAdding: .month, value: monthOffset + 1, to: pivotStart) ?? pivotStart

        // Filter shifts within the range
        let filteredShifts = mockShifts.filter { shift in
            shift.date >= startDate && shift.date < endDate
        }

        return (shifts: filteredShifts, rangeStart: startDate, rangeEnd: endDate)
    }

    var mockShiftData: [ScheduledShiftData] = []

    func loadShiftData(from startDate: Date, to endDate: Date) async throws -> [ScheduledShiftData] {
        loadShiftDataCallCount += 1
        lastLoadShiftsRange = (startDate, endDate)
        if shouldThrowError, let error = throwError {
            throw error
        }
        // Check authorization
        guard mockIsAuthorized else {
            throw CalendarServiceError.notAuthorized
        }
        return mockShiftData.filter { data in
            data.startDate >= startDate && data.startDate <= endDate
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
        createShiftEventCallCount += 1
        lastCreateShiftEventData = (date, shiftType)
        if shouldThrowError, let error = throwError {
            throw error
        }

        // Check authorization
        guard mockIsAuthorized else {
            throw CalendarServiceError.notAuthorized
        }

        // Check for overlapping shifts (business rule: no overlaps allowed)
        let startDate = Calendar.current.startOfDay(for: date)

        let existingShifts = mockShifts.filter { $0.date == startDate }
        if !existingShifts.isEmpty {
            let shiftTitles = existingShifts.compactMap { $0.shiftType?.title }
            throw ScheduleError.overlappingShifts(date: startDate, existingShifts: shiftTitles)
        }

        // Track event timing details for testing
        if shiftType.duration.isAllDay {
            lastCreatedEventIsAllDay = true
            lastCreatedEventStartTime = startDate
            lastCreatedEventEndTime = startDate
        } else {
            lastCreatedEventIsAllDay = false
            if let startTime = shiftType.duration.startTime,
               let endTime = shiftType.duration.endTime {
                let eventStartTime = startTime.toDate(on: startDate)
                var eventEndTime = endTime.toDate(on: startDate)

                // Handle overnight shifts: if end time is before or equal to start time, shift crosses midnight
                if eventEndTime <= eventStartTime {
                    eventEndTime = Calendar.current.date(byAdding: .day, value: 1, to: eventEndTime) ?? eventEndTime
                }

                lastCreatedEventStartTime = eventStartTime
                lastCreatedEventEndTime = eventEndTime
            }
        }

        // Create and add mock shift
        // Note: Production stores notes in EventKit but returns them in ScheduledShift for testing
        // Convert empty notes to nil to match production behavior
        let finalNotes = notes?.isEmpty == true ? nil : notes

        // Calculate endDate based on whether the shift spans next day
        let calculatedEndDate: Date
        if shiftType.duration.spansNextDay {
            calculatedEndDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate) ?? startDate
        } else {
            calculatedEndDate = startDate
        }

        let shift = ScheduledShift(
            id: UUID(),
            eventIdentifier: UUID().uuidString,
            shiftType: shiftType,
            date: startDate,
            endDate: calculatedEndDate,
            notes: finalNotes
        )

        mockShifts.append(shift)
        return shift
    }

    func updateShiftEvent(eventIdentifier: String, newShiftType: ShiftType, date: Date) async throws {
        updateShiftEventCallCount += 1
        lastUpdateShiftEventData = (eventIdentifier, newShiftType)
        if shouldThrowError, let error = throwError {
            throw error
        }

        // Check authorization
        guard mockIsAuthorized else {
            throw CalendarServiceError.notAuthorized
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

        // Track event timing details for testing
        if newShiftType.duration.isAllDay {
            lastUpdatedEventIsAllDay = true
            lastUpdatedEventStartTime = startDate
            lastUpdatedEventEndTime = startDate
        } else {
            lastUpdatedEventIsAllDay = false
            if let startTime = newShiftType.duration.startTime,
               let endTime = newShiftType.duration.endTime {
                let eventStartTime = startTime.toDate(on: startDate)
                var eventEndTime = endTime.toDate(on: startDate)

                // Handle overnight shifts: if end time is before or equal to start time, shift crosses midnight
                if eventEndTime <= eventStartTime {
                    eventEndTime = Calendar.current.date(byAdding: .day, value: 1, to: eventEndTime) ?? eventEndTime
                }

                lastUpdatedEventStartTime = eventStartTime
                lastUpdatedEventEndTime = eventEndTime
            }
        }

        // Calculate endDate based on whether the new shift type spans next day
        let calculatedEndDate: Date
        if newShiftType.duration.spansNextDay {
            calculatedEndDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate) ?? startDate
        } else {
            calculatedEndDate = startDate
        }

        // Update the shift with the new shift type (preserve notes)
        mockShifts[index] = ScheduledShift(
            id: mockShifts[index].id,
            eventIdentifier: mockShifts[index].eventIdentifier,
            shiftType: newShiftType,
            date: mockShifts[index].date,
            endDate: calculatedEndDate,
            notes: mockShifts[index].notes
        )
    }

    func deleteShiftEvent(eventIdentifier: String) async throws {
        deleteShiftEventCallCount += 1
        if shouldThrowError, let error = throwError {
            throw error
        }

        // Check authorization
        guard mockIsAuthorized else {
            throw CalendarServiceError.notAuthorized
        }

        // Find the shift to delete
        guard let index = mockShifts.firstIndex(where: { $0.eventIdentifier == eventIdentifier }) else {
            throw ScheduleError.calendarEventDeletionFailed("Event with identifier \(eventIdentifier) not found")
        }

        // Remove the shift
        mockShifts.remove(at: index)
    }

    func deleteMultipleShiftEvents(_ eventIdentifiers: [String]) async throws -> Int {
        deleteMultipleShiftEventsCallCount += 1
        if shouldThrowError, let error = throwError {
            throw error
        }

        // Check authorization
        guard mockIsAuthorized else {
            throw CalendarServiceError.notAuthorized
        }

        var deletedCount = 0

        // Delete each event (in reverse order to avoid index shifting)
        for eventIdentifier in eventIdentifiers {
            if let index = mockShifts.firstIndex(where: { $0.eventIdentifier == eventIdentifier }) {
                mockShifts.remove(at: index)
                deletedCount += 1
            }
        }

        return deletedCount
    }

    func updateEventsWithShiftType(_ shiftType: ShiftType) async throws -> Int {
        updateEventsWithShiftTypeCallCount += 1
        if shouldThrowError, let error = throwError {
            throw error
        }

        // Check authorization
        guard mockIsAuthorized else {
            throw CalendarServiceError.notAuthorized
        }

        // Find all shifts that were created from this shift type
        let affectedShifts = mockShifts.filter { $0.shiftType?.id == shiftType.id }

        // Update each affected shift with the new ShiftType data
        var updatedCount = 0
        for shift in affectedShifts {
            guard let index = mockShifts.firstIndex(where: { $0.eventIdentifier == shift.eventIdentifier }) else {
                continue
            }

            // Calculate endDate based on whether the new shift type spans next day
            let calculatedEndDate: Date
            if shiftType.duration.spansNextDay {
                calculatedEndDate = Calendar.current.date(byAdding: .day, value: 1, to: shift.date) ?? shift.date
            } else {
                calculatedEndDate = shift.date
            }

            // Update the shift with new ShiftType data while preserving notes and date
            mockShifts[index] = ScheduledShift(
                id: shift.id,
                eventIdentifier: shift.eventIdentifier,
                shiftType: shiftType,
                date: shift.date,
                endDate: calculatedEndDate,
                notes: shift.notes
            )
            updatedCount += 1
        }

        return updatedCount
    }

    func updateShiftNotes(eventIdentifier: String, notes: String) async throws {
        updateShiftNotesCallCount += 1
        lastUpdateShiftNotesData = (eventIdentifier, notes)
        if shouldThrowError, let error = throwError {
            throw error
        }

        // Check authorization
        guard mockIsAuthorized else {
            throw CalendarServiceError.notAuthorized
        }

        // Find the shift to update
        guard let index = mockShifts.firstIndex(where: { $0.eventIdentifier == eventIdentifier }) else {
            throw CalendarServiceError.eventConversionFailed("Event with identifier \(eventIdentifier) not found")
        }

        // Update the shift with new notes (preserve endDate)
        mockShifts[index] = ScheduledShift(
            id: mockShifts[index].id,
            eventIdentifier: mockShifts[index].eventIdentifier,
            shiftType: mockShifts[index].shiftType,
            date: mockShifts[index].date,
            endDate: mockShifts[index].endDate,
            notes: notes.isEmpty ? nil : notes
        )
    }

    func resyncAllCalendarEvents() async throws -> (updated: Int, total: Int) {
        if shouldThrowError {
            throw CalendarServiceError.notAuthorized
        }

        // Mock behavior: return count of all scheduled shifts
        let count = mockShifts.count
        return (updated: count, total: count)
    }
}
