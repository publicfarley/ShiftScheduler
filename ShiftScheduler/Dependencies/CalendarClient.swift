import Foundation
import ComposableArchitecture
import EventKit

/// TCA Dependency Client for Calendar operations
/// Provides shift management through EventKit abstraction
@DependencyClient
struct CalendarClient {
    /// Check if calendar access is authorized
    var isAuthorized: @Sendable () -> Bool = { false }

    /// Create a new shift event in the calendar
    var createShift: @Sendable (ShiftType, Date) async throws -> String

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
    /// Live implementation using EventKitClient
    static let liveValue: CalendarClient = {
        return CalendarClient(
            isAuthorized: {
                @Dependency(\.eventKitClient) var eventKitClient
                let status = eventKitClient.checkAuthorizationStatus()
                return status == .fullAccess || status == .authorized
            },
            createShift: { @Sendable shiftType, date in
                @Dependency(\.eventKitClient) var eventKitClient

                let shiftDate = Calendar.current.startOfDay(for: date)

                let (startDate, endDate, isAllDay): (Date, Date, Bool)

                if case .allDay = shiftType.duration {
                    (startDate, endDate, isAllDay) = (shiftDate, shiftDate, true)
                } else if case let .scheduled(from, to) = shiftType.duration {
                    var startComponents = Calendar.current.dateComponents([.year, .month, .day], from: shiftDate)
                    startComponents.hour = from.hour
                    startComponents.minute = from.minute

                    var endComponents = Calendar.current.dateComponents([.year, .month, .day], from: shiftDate)
                    endComponents.hour = to.hour
                    endComponents.minute = to.minute

                    guard let start = Calendar.current.date(from: startComponents),
                          let end = Calendar.current.date(from: endComponents) else {
                        throw EventKitError.invalidDate
                    }

                    (startDate, endDate, isAllDay) = (start, end, false)
                } else {
                    throw EventKitError.invalidDate
                }

                let notes = """
                ShiftType ID: \(shiftType.id.uuidString)
                App: com.functioncraft.shiftscheduler
                Description: \(shiftType.shiftDescription)
                """

                return try await eventKitClient.createEvent(
                    "\(shiftType.symbol) - \(shiftType.title)",
                    startDate,
                    endDate,
                    isAllDay,
                    notes
                )
            },
            fetchShifts: { date in
                @Dependency(\.eventKitClient) var eventKitClient

                let startOfDay = Calendar.current.startOfDay(for: date)
                guard let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) else {
                    throw EventKitError.invalidDate
                }

                let events = try await eventKitClient.fetchEvents(startOfDay, endOfDay)
                return events.compactMap { event in
                    guard let notes = event.notes,
                          let shiftTypeId = extractShiftTypeId(from: notes) else {
                        return nil
                    }

                    return ScheduledShiftData(
                        eventIdentifier: event.eventIdentifier,
                        shiftTypeId: shiftTypeId,
                        date: event.startDate,
                        title: event.title ?? "",
                        location: event.location
                    )
                }
            },
            fetchShiftsInRange: { startDate, endDate in
                @Dependency(\.eventKitClient) var eventKitClient

                let events = try await eventKitClient.fetchEvents(startDate, endDate)
                return events.compactMap { event in
                    guard let notes = event.notes,
                          let shiftTypeId = extractShiftTypeId(from: notes) else {
                        return nil
                    }

                    return ScheduledShiftData(
                        eventIdentifier: event.eventIdentifier,
                        shiftTypeId: shiftTypeId,
                        date: event.startDate,
                        title: event.title ?? "",
                        location: event.location
                    )
                }
            },
            deleteShift: { identifier in
                @Dependency(\.eventKitClient) var eventKitClient
                try await eventKitClient.deleteEvent(identifier)
            },
            checkForDuplicate: { shiftTypeId, date in
                @Dependency(\.eventKitClient) var eventKitClient

                let startOfDay = Calendar.current.startOfDay(for: date)
                guard let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) else {
                    throw EventKitError.invalidDate
                }

                let events = try await eventKitClient.fetchEvents(startOfDay, endOfDay)
                return events.contains { event in
                    guard let notes = event.notes,
                          let eventShiftTypeId = extractShiftTypeId(from: notes) else {
                        return false
                    }
                    return eventShiftTypeId == shiftTypeId
                }
            },
            updateShift: { @Sendable identifier, newShiftType in
                @Dependency(\.eventKitClient) var eventKitClient

                let shiftDate = Calendar.current.startOfDay(for: Date())

                let (startDate, endDate, isAllDay): (Date, Date, Bool)

                if case .allDay = newShiftType.duration {
                    (startDate, endDate, isAllDay) = (shiftDate, shiftDate, true)
                } else if case let .scheduled(from, to) = newShiftType.duration {
                    var startComponents = Calendar.current.dateComponents([.year, .month, .day], from: shiftDate)
                    startComponents.hour = from.hour
                    startComponents.minute = from.minute

                    var endComponents = Calendar.current.dateComponents([.year, .month, .day], from: shiftDate)
                    endComponents.hour = to.hour
                    endComponents.minute = to.minute

                    guard let start = Calendar.current.date(from: startComponents),
                          let end = Calendar.current.date(from: endComponents) else {
                        throw EventKitError.invalidDate
                    }

                    (startDate, endDate, isAllDay) = (start, end, false)
                } else {
                    throw EventKitError.invalidDate
                }

                let notes = """
                ShiftType ID: \(newShiftType.id.uuidString)
                App: com.functioncraft.shiftscheduler
                Description: \(newShiftType.shiftDescription)
                """

                try await eventKitClient.updateEvent(
                    identifier,
                    "\(newShiftType.symbol) - \(newShiftType.title)",
                    startDate,
                    endDate,
                    isAllDay,
                    notes
                )
            },
            requestAuthorization: {
                @Dependency(\.eventKitClient) var eventKitClient
                return await eventKitClient.requestFullAccess()
            }
        )
    }()

    /// Test value with unimplemented methods
    static let testValue = CalendarClient()

    /// Preview value with mock data
    static let previewValue = CalendarClient(
        isAuthorized: { true },
        createShift: { @Sendable _, _ in "preview-event-id" },
        fetchShifts: { _ in [] },
        fetchShiftsInRange: { _, _ in [] },
        deleteShift: { _ in },
        checkForDuplicate: { _, _ in false },
        updateShift: { @Sendable _, _ in },
        requestAuthorization: { true }
    )
}

// MARK: - Helper Functions

private func extractShiftTypeId(from notes: String) -> UUID? {
    let lines = notes.components(separatedBy: .newlines)
    for line in lines {
        if line.hasPrefix("ShiftType ID: ") {
            let idString = line.replacingOccurrences(of: "ShiftType ID: ", with: "")
            return UUID(uuidString: idString)
        }
    }
    return nil
}

extension DependencyValues {
    var calendarClient: CalendarClient {
        get { self[CalendarClient.self] }
        set { self[CalendarClient.self] = newValue }
    }
}
