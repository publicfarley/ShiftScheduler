import Foundation
import ComposableArchitecture

/// TCA Dependency Client for Calendar operations
/// Wraps the existing CalendarService for use within TCA reducers
@DependencyClient
struct CalendarClient: Sendable {
    /// Check if calendar access is authorized
    var isAuthorized: @Sendable () -> Bool = { false }

    /// Create a new shift event in the calendar
    var createShift: @Sendable (ShiftType, Date) async throws -> String = { _, _ in "" }

    /// Fetch all shifts for a specific date
    var fetchShifts: @Sendable (Date) async throws -> [ScheduledShiftData] = { _ in [] }

    /// Fetch shifts within a date range
    var fetchShiftsInRange: @Sendable (Date, Date) async throws -> [ScheduledShiftData] = { _, _ in [] }

    /// Delete a shift by its event identifier
    var deleteShift: @Sendable (String) async throws -> Void

    /// Check if a duplicate shift exists for a given date
    var checkForDuplicate: @Sendable (UUID, Date) async throws -> Bool = { _, _ in false }

    /// Update an existing shift event
    var updateShift: @Sendable (String, ShiftType) async throws -> Void

    /// Request calendar authorization
    var requestAuthorization: @Sendable () async -> Bool = { false }
}

extension CalendarClient: DependencyKey {
    /// Live implementation using the real CalendarService
    static let liveValue: CalendarClient = {
        let service = CalendarService.shared

        return CalendarClient(
            isAuthorized: {
                service.isAuthorized
            },
            createShift: { shiftType, date in
                try await service.createShiftEvent(from: shiftType, on: date)
            },
            fetchShifts: { date in
                try await service.fetchShifts(for: date)
            },
            fetchShiftsInRange: { startDate, endDate in
                try await service.fetchShifts(from: startDate, to: endDate)
            },
            deleteShift: { identifier in
                try await service.deleteShift(withIdentifier: identifier)
            },
            checkForDuplicate: { shiftTypeId, date in
                try await service.checkForDuplicateShift(shiftTypeId: shiftTypeId, on: date)
            },
            updateShift: { identifier, newShiftType in
                try await service.updateShiftEvent(identifier: identifier, to: newShiftType)
            },
            requestAuthorization: {
                // This would need to be implemented to handle async authorization
                service.isAuthorized
            }
        )
    }()

    /// Test value with unimplemented methods
    static let testValue = CalendarClient()

    /// Preview value with mock data
    static let previewValue = CalendarClient(
        isAuthorized: { true },
        createShift: { _, _ in "preview-event-id" },
        fetchShifts: { _ in [] },
        fetchShiftsInRange: { _, _ in [] },
        deleteShift: { _ in },
        checkForDuplicate: { _, _ in false },
        updateShift: { _, _ in },
        requestAuthorization: { true }
    )
}

extension DependencyValues {
    var calendarClient: CalendarClient {
        get { self[CalendarClient.self] }
        set { self[CalendarClient.self] = newValue }
    }
}
