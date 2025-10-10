import Foundation

/// Protocol abstraction for calendar operations to enable unit testing
protocol CalendarServiceProtocol: Sendable {
    nonisolated var isAuthorized: Bool { get }

    nonisolated func createShiftEvent(from shiftType: ShiftType, on date: Date) async throws -> String
    nonisolated func fetchShifts(for date: Date) async throws -> [ScheduledShiftData]
    nonisolated func fetchShifts(from startDate: Date, to endDate: Date) async throws -> [ScheduledShiftData]
    nonisolated func deleteShift(withIdentifier identifier: String) async throws
    nonisolated func checkForDuplicateShift(shiftTypeId: UUID, on date: Date) async throws -> Bool
    nonisolated func updateShiftEvent(identifier: String, to newShiftType: ShiftType) async throws
}
