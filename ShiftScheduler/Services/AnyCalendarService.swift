import Foundation

/// Type-erased wrapper for CalendarServiceProtocol to work around Swift @Observable protocol conformance issues
struct AnyCalendarService: CalendarServiceProtocol {
    private let _isAuthorized: () -> Bool
    private let _createShiftEvent: (ShiftType, Date) async throws -> String
    private let _fetchShiftsForDate: (Date) async throws -> [ScheduledShiftData]
    private let _fetchShiftsFromTo: (Date, Date) async throws -> [ScheduledShiftData]
    private let _deleteShift: (String) async throws -> Void
    private let _checkForDuplicate: (UUID, Date) async throws -> Bool
    private let _updateShiftEvent: (String, ShiftType) async throws -> Void

    init(_ service: CalendarService) {
        self._isAuthorized = { service.isAuthorized }
        self._createShiftEvent = { shiftType, date in
            try await service.createShiftEvent(from: shiftType, on: date)
        }
        self._fetchShiftsForDate = { date in
            try await service.fetchShifts(for: date)
        }
        self._fetchShiftsFromTo = { startDate, endDate in
            try await service.fetchShifts(from: startDate, to: endDate)
        }
        self._deleteShift = { identifier in
            try await service.deleteShift(withIdentifier: identifier)
        }
        self._checkForDuplicate = { shiftTypeId, date in
            try await service.checkForDuplicateShift(shiftTypeId: shiftTypeId, on: date)
        }
        self._updateShiftEvent = { identifier, newShiftType in
            try await service.updateShiftEvent(identifier: identifier, to: newShiftType)
        }
    }

    nonisolated var isAuthorized: Bool {
        _isAuthorized()
    }

    nonisolated func createShiftEvent(from shiftType: ShiftType, on date: Date) async throws -> String {
        try await _createShiftEvent(shiftType, date)
    }

    nonisolated func fetchShifts(for date: Date) async throws -> [ScheduledShiftData] {
        try await _fetchShiftsForDate(date)
    }

    nonisolated func fetchShifts(from startDate: Date, to endDate: Date) async throws -> [ScheduledShiftData] {
        try await _fetchShiftsFromTo(startDate, endDate)
    }

    nonisolated func deleteShift(withIdentifier identifier: String) async throws {
        try await _deleteShift(identifier)
    }

    nonisolated func checkForDuplicateShift(shiftTypeId: UUID, on date: Date) async throws -> Bool {
        try await _checkForDuplicate(shiftTypeId, date)
    }

    nonisolated func updateShiftEvent(identifier: String, to newShiftType: ShiftType) async throws {
        try await _updateShiftEvent(identifier, newShiftType)
    }
}
