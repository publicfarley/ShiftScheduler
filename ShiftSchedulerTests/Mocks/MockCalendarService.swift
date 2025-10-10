import Foundation
@testable import ShiftScheduler

/// Mock implementation of CalendarServiceProtocol for unit testing
final class MockCalendarService: @unchecked Sendable {
    var isAuthorized = true
    var mockShifts: [ScheduledShiftData] = []
    var createdEvents: [(shiftType: ShiftType, date: Date)] = []
    var deletedIdentifiers: [String] = []
    var updatedEvents: [(identifier: String, newShiftType: ShiftType)] = []
    var shouldThrowOnCreate = false
    var shouldThrowOnFetch = false
    var shouldThrowOnDelete = false
    var shouldThrowOnUpdate = false
    var nextEventIdentifier = "mock-event-001"

    enum MockError: Error {
        case createFailed
        case fetchFailed
        case deleteFailed
        case updateFailed
    }
}

extension MockCalendarService: CalendarServiceProtocol {
    nonisolated func createShiftEvent(from shiftType: ShiftType, on date: Date) async throws -> String {
        if shouldThrowOnCreate {
            throw MockError.createFailed
        }
        createdEvents.append((shiftType, date))
        let identifier = nextEventIdentifier
        nextEventIdentifier = "mock-event-\(String(format: "%03d", (createdEvents.count + 1)))"
        return identifier
    }

    nonisolated func fetchShifts(for date: Date) async throws -> [ScheduledShiftData] {
        if shouldThrowOnFetch {
            throw MockError.fetchFailed
        }
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? date
        return mockShifts.filter { $0.date >= startOfDay && $0.date < endOfDay }
    }

    nonisolated func fetchShifts(from startDate: Date, to endDate: Date) async throws -> [ScheduledShiftData] {
        if shouldThrowOnFetch {
            throw MockError.fetchFailed
        }
        return mockShifts.filter { $0.date >= startDate && $0.date <= endDate }
    }

    nonisolated func deleteShift(withIdentifier identifier: String) async throws {
        if shouldThrowOnDelete {
            throw MockError.deleteFailed
        }
        deletedIdentifiers.append(identifier)
        mockShifts.removeAll { $0.eventIdentifier == identifier }
    }

    nonisolated func checkForDuplicateShift(shiftTypeId: UUID, on date: Date) async throws -> Bool {
        if shouldThrowOnFetch {
            throw MockError.fetchFailed
        }
        let shifts = try await fetchShifts(for: date)
        return shifts.contains { $0.shiftTypeId == shiftTypeId }
    }

    nonisolated func updateShiftEvent(identifier: String, to newShiftType: ShiftType) async throws {
        if shouldThrowOnUpdate {
            throw MockError.updateFailed
        }
        updatedEvents.append((identifier, newShiftType))
    }
}
