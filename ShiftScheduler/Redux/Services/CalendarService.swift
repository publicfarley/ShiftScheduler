import Foundation
import EventKit
import OSLog

private let logger = Logger(subsystem: "com.shiftscheduler.redux.services", category: "CalendarService")

/// Production implementation of CalendarServiceProtocol
/// Uses EventKit to access calendar data and load shifts
final class CalendarService: CalendarServiceProtocol, @unchecked Sendable {
    private let eventStore = EKEventStore()
    private let shiftTypeRepository: ShiftTypeRepository

    init(shiftTypeRepository: ShiftTypeRepository? = nil) {
        self.shiftTypeRepository = shiftTypeRepository ?? ShiftTypeRepository()
    }

    // MARK: - CalendarServiceProtocol Implementation

    func isCalendarAuthorized() async throws -> Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .authorized, .fullAccess:
            return true
        default:
            return false
        }
    }

    func requestCalendarAccess() async throws -> Bool {
        let status = EKEventStore.authorizationStatus(for: .event)

        if status == .fullAccess {
            return true
        }

        let hasAccess = try await eventStore.requestFullAccessToEvents()
        // logger.debug("Calendar access requested: \(hasAccess)")
        return hasAccess
    }

    func loadShifts(from startDate: Date, to endDate: Date) async throws -> [ScheduledShift] {
        // logger.debug("Loading shifts from \(startDate.formatted()) to \(endDate.formatted())")

        // Check authorization
        guard try await isCalendarAuthorized() else {
        // logger.error("Calendar not authorized")
            throw CalendarServiceError.notAuthorized
        }

        // Fetch events from calendar
        let calendars = eventStore.calendars(for: .event)
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
        let events = eventStore.events(matching: predicate)

        // logger.debug("Loaded \(events.count) events from calendar")

        // Convert events to scheduled shifts
        var shifts: [ScheduledShift] = []

        for event in events {
            guard let shift = try await convertEventToShift(event) else {
                continue
            }
            shifts.append(shift)
        }

        // logger.debug("Converted to \(shifts.count) scheduled shifts")
        return shifts.sorted { $0.date < $1.date }
    }

    func loadShiftsForNext30Days() async throws -> [ScheduledShift] {
        let startDate = Calendar.current.startOfDay(for: Date())
        let endDate = Calendar.current.date(byAdding: .day, value: 30, to: startDate) ?? startDate

        return try await loadShifts(from: startDate, to: endDate)
    }

    func loadShiftsForCurrentMonth() async throws -> [ScheduledShift] {
        let today = Date()
        guard let startDate = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: today)),
              let endDate = Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: startDate) else {
            throw CalendarServiceError.dateCalculationFailed
        }

        return try await loadShifts(from: startDate, to: endDate)
    }

    /// Load shift data (before conversion to domain objects) for a date range
    /// Returns ScheduledShiftData which contains raw EventKit information
    func loadShiftData(from startDate: Date, to endDate: Date) async throws -> [ScheduledShiftData] {
        // Check authorization
        guard try await isCalendarAuthorized() else {
            throw CalendarServiceError.notAuthorized
        }

        // Fetch events from calendar
        let calendars = eventStore.calendars(for: .event)
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
        let events = eventStore.events(matching: predicate)

        // Convert events to ScheduledShiftData (reification step)
        var shiftDataArray: [ScheduledShiftData] = []

        for event in events {
            guard let shiftData = convertEventToShiftData(event) else {
                continue
            }
            shiftDataArray.append(shiftData)
        }

        return shiftDataArray.sorted { $0.date < $1.date }
    }

    /// Load shift data for today only
    func loadShiftDataForToday() async throws -> [ScheduledShiftData] {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today

        return try await loadShiftData(from: today, to: tomorrow)
    }

    /// Load shift data for tomorrow only
    func loadShiftDataForTomorrow() async throws -> [ScheduledShiftData] {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today
        let dayAfterTomorrow = Calendar.current.date(byAdding: .day, value: 1, to: tomorrow) ?? tomorrow

        return try await loadShiftData(from: tomorrow, to: dayAfterTomorrow)
    }

    // MARK: - Private Helpers

    /// Reify raw EventKit event to ScheduledShiftData (intermediate representation)
    /// This is the first step of the data transformation pipeline
    private func convertEventToShiftData(_ event: EKEvent) -> ScheduledShiftData? {
        // Extract shift type ID from event notes
        guard let notes = event.notes,
              let shiftTypeId = UUID(uuidString: notes) else {
            // logger.debug("Event '\(event.title)' has no valid shift type ID in notes")
            return nil
        }

        return ScheduledShiftData(
            eventIdentifier: event.eventIdentifier,
            shiftTypeId: shiftTypeId,
            date: Calendar.current.startOfDay(for: event.startDate),
            title: event.title,
            location: event.location
        )
    }

    private func convertEventToShift(_ event: EKEvent) async throws -> ScheduledShift? {
        // Extract shift type ID from event notes
        guard let notes = event.notes,
              let shiftTypeId = UUID(uuidString: notes) else {
        // logger.debug("Event '\(event.title)' has no valid shift type ID in notes")
            return nil
        }

        // Load shift type from repository
        let shiftTypes = try await shiftTypeRepository.fetchAll()
        guard let shiftType = shiftTypes.first(where: { $0.id == shiftTypeId }) else {
        // logger.warning("Shift type \(shiftTypeId) not found for event '\(event.title)'")
            return nil
        }

        let shift = ScheduledShift(
            id: UUID(uuidString: event.eventIdentifier) ?? UUID(),
            eventIdentifier: event.eventIdentifier,
            shiftType: shiftType,
            date: Calendar.current.startOfDay(for: event.startDate)
        )

        return shift
    }
}

// MARK: - Error Types

enum CalendarServiceError: LocalizedError {
    case notAuthorized
    case dateCalculationFailed
    case eventConversionFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Calendar access not authorized"
        case .dateCalculationFailed:
            return "Failed to calculate dates"
        case .eventConversionFailed(let reason):
            return "Failed to convert event: \(reason)"
        }
    }
}
