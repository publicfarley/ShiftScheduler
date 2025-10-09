import Foundation

/// Protocol abstraction for calendar operations to enable unit testing
protocol CalendarServiceProtocol: Sendable {
    var isAuthorized: Bool { get }

    func createShiftEvent(from shiftType: ShiftType, on date: Date) async throws -> String
    func fetchShifts(for date: Date) async throws -> [ScheduledShiftData]
    func fetchShifts(from startDate: Date, to endDate: Date) async throws -> [ScheduledShiftData]
    func deleteShift(withIdentifier identifier: String) async throws
    func checkForDuplicateShift(shiftTypeId: UUID, on date: Date) async throws -> Bool
    func updateShiftEvent(identifier: String, to newShiftType: ShiftType) async throws
}
