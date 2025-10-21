import Foundation
import EventKit
import SwiftUI
import Observation

@Observable
class CalendarService {
    static let shared = CalendarService()

    private let eventStore = EKEventStore()
    private let calendarName = "functioncraft.shiftscheduler"
    private let appIdentifier = "com.functioncraft.shiftscheduler"

    var isAuthorized = false
    var authorizationError: String?

    private var appCalendar: EKCalendar?

    private init() {
        checkAuthorizationStatus()
    }

    func checkAuthorizationStatus() {
        let status = EKEventStore.authorizationStatus(for: .event)

        switch status {
        case .authorized, .fullAccess:
            isAuthorized = true
            Task {
                await ensureCalendarExists()
            }
        case .notDetermined:
            requestAccess()
        case .denied, .restricted, .writeOnly:
            isAuthorized = false
            authorizationError = "Calendar access is required for ShiftScheduler to function. Please enable calendar access in Settings."
        @unknown default:
            isAuthorized = false
            authorizationError = "Unknown calendar authorization status."
        }
    }

    private func requestAccess() {
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToEvents { [weak self] granted, error in
                DispatchQueue.main.async {
                    self?.isAuthorized = granted
                    if !granted {
                        self?.authorizationError = "Calendar access is required for ShiftScheduler to function. Please enable calendar access in Settings."
                    } else {
                        Task {
                            await self?.ensureCalendarExists()
                        }
                    }
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { [weak self] granted, error in
                DispatchQueue.main.async {
                    self?.isAuthorized = granted
                    if !granted {
                        self?.authorizationError = "Calendar access is required for ShiftScheduler to function. Please enable calendar access in Settings."
                    } else {
                        Task {
                            await self?.ensureCalendarExists()
                        }
                    }
                }
            }
        }
    }

    private func ensureCalendarExists() async {
        if let calendar = findAppCalendar() {
            appCalendar = calendar
        } else {
            appCalendar = createAppCalendar()
        }
    }

    private func findAppCalendar() -> EKCalendar? {
        let calendars = eventStore.calendars(for: .event)
        return calendars.first { calendar in
            calendar.title == calendarName
        }
    }

    private func createAppCalendar() -> EKCalendar? {
        let calendar = EKCalendar(for: .event, eventStore: eventStore)
        calendar.title = calendarName
        calendar.cgColor = UIColor.black.cgColor

        if let source = eventStore.defaultCalendarForNewEvents?.source {
            calendar.source = source
        } else if let source = eventStore.sources.first(where: { $0.sourceType == .local }) {
            calendar.source = source
        } else if let source = eventStore.sources.first(where: { $0.sourceType == .calDAV }) {
            calendar.source = source
        } else if let source = eventStore.sources.first {
            calendar.source = source
        } else {
            return nil
        }

        do {
            try eventStore.saveCalendar(calendar, commit: true)
            return calendar
        } catch {
            print("Error creating calendar: \(error)")
            return nil
        }
    }

    nonisolated func createShiftEvent(from shiftType: ShiftType, on date: Date) async throws -> String {
        guard isAuthorized else {
            throw CalendarError.notAuthorized
        }

        guard let calendar = appCalendar ?? findAppCalendar() else {
            throw CalendarError.calendarNotFound
        }

        let event = EKEvent(eventStore: eventStore)
        event.calendar = calendar
        event.title = "\(shiftType.symbol) - \(shiftType.title)"

        let shiftDate = Calendar.current.startOfDay(for: date)

        switch shiftType.duration {
        case .allDay:
            event.isAllDay = true
            event.startDate = shiftDate
            event.endDate = shiftDate

        case .scheduled(let from, let to):
            event.isAllDay = false

            var startComponents = Calendar.current.dateComponents([.year, .month, .day], from: shiftDate)
            startComponents.hour = from.hour
            startComponents.minute = from.minute

            var endComponents = Calendar.current.dateComponents([.year, .month, .day], from: shiftDate)
            endComponents.hour = to.hour
            endComponents.minute = to.minute

            guard let startDate = Calendar.current.date(from: startComponents),
                  let endDate = Calendar.current.date(from: endComponents) else {
                throw CalendarError.invalidDate
            }

            event.startDate = startDate
            event.endDate = endDate
        }

        // Location will need to be fetched via repository when needed
        // For now, location is stored as locationId in ShiftType

        event.notes = """
        ShiftType ID: \(shiftType.id.uuidString)
        App: \(appIdentifier)
        Description: \(shiftType.shiftDescription)
        """

        do {
            try eventStore.save(event, span: .thisEvent)
            return event.eventIdentifier
        } catch {
            throw CalendarError.saveFailed(error)
        }
    }

    nonisolated func fetchShifts(for date: Date) async throws -> [ScheduledShiftData] {
        guard isAuthorized else {
            throw CalendarError.notAuthorized
        }

        guard let calendar = appCalendar ?? findAppCalendar() else {
            throw CalendarError.calendarNotFound
        }

        let startOfDay = Calendar.current.startOfDay(for: date)
        guard let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) else {
            throw CalendarError.invalidDate
        }

        let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: [calendar])
        let events = eventStore.events(matching: predicate)

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
    }

    nonisolated func fetchShifts(from startDate: Date, to endDate: Date) async throws -> [ScheduledShiftData] {
        guard isAuthorized else {
            throw CalendarError.notAuthorized
        }

        guard let calendar = appCalendar ?? findAppCalendar() else {
            throw CalendarError.calendarNotFound
        }

        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: [calendar])
        let events = eventStore.events(matching: predicate)

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
    }

    nonisolated func deleteShift(withIdentifier identifier: String) async throws {
        guard isAuthorized else {
            throw CalendarError.notAuthorized
        }

        guard let event = eventStore.event(withIdentifier: identifier) else {
            throw CalendarError.eventNotFound
        }

        do {
            try eventStore.remove(event, span: .thisEvent)
        } catch {
            throw CalendarError.deleteFailed(error)
        }
    }

    nonisolated func checkForDuplicateShift(shiftTypeId: UUID, on date: Date) async throws -> Bool {
        let shifts = try await fetchShifts(for: date)
        return shifts.contains { $0.shiftTypeId == shiftTypeId }
    }

    nonisolated func updateShiftEvent(identifier: String, to newShiftType: ShiftType) async throws {
        guard isAuthorized else {
            throw CalendarError.notAuthorized
        }

        guard let event = eventStore.event(withIdentifier: identifier) else {
            throw CalendarError.eventNotFound
        }

        // Update event properties
        event.title = "\(newShiftType.symbol) - \(newShiftType.title)"

        switch newShiftType.duration {
        case .allDay:
            event.isAllDay = true
            let shiftDate = Calendar.current.startOfDay(for: event.startDate)
            event.startDate = shiftDate
            event.endDate = shiftDate

        case .scheduled(let from, let to):
            event.isAllDay = false

            let shiftDate = Calendar.current.startOfDay(for: event.startDate)
            var startComponents = Calendar.current.dateComponents([.year, .month, .day], from: shiftDate)
            startComponents.hour = from.hour
            startComponents.minute = from.minute

            var endComponents = Calendar.current.dateComponents([.year, .month, .day], from: shiftDate)
            endComponents.hour = to.hour
            endComponents.minute = to.minute

            guard let startDate = Calendar.current.date(from: startComponents),
                  let endDate = Calendar.current.date(from: endComponents) else {
                throw CalendarError.invalidDate
            }

            event.startDate = startDate
            event.endDate = endDate
        }

        // Location will need to be fetched via repository when needed
        // For now, location is stored as locationId in ShiftType
        event.location = nil

        event.notes = """
        ShiftType ID: \(newShiftType.id.uuidString)
        App: \(appIdentifier)
        Description: \(newShiftType.shiftDescription)
        """

        do {
            try eventStore.save(event, span: .thisEvent)
        } catch {
            throw CalendarError.saveFailed(error)
        }
    }

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
}

enum CalendarError: LocalizedError {
    case notAuthorized
    case calendarNotFound
    case invalidDate
    case eventNotFound
    case saveFailed(Error)
    case deleteFailed(Error)

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Calendar access is not authorized. Please enable calendar access in Settings."
        case .calendarNotFound:
            return "Could not find or create the ShiftScheduler calendar."
        case .invalidDate:
            return "Invalid date provided."
        case .eventNotFound:
            return "Shift event not found in calendar."
        case .saveFailed(let error):
            return "Failed to save shift: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete shift: \(error.localizedDescription)"
        }
    }
}

struct ScheduledShiftData: Hashable, Equatable {
    let eventIdentifier: String
    let shiftTypeId: UUID
    let date: Date
    let title: String
    let location: String?

    func hash(into hasher: inout Hasher) {
        hasher.combine(eventIdentifier)
    }

    static func == (lhs: ScheduledShiftData, rhs: ScheduledShiftData) -> Bool {
        return lhs.eventIdentifier == rhs.eventIdentifier
    }
}

// MARK: - Protocol Conformance
extension CalendarService: CalendarServiceProtocol {}

// MARK: - CurrentDayManager Integration Extensions
extension CalendarService {
    func fetchTodaysShifts() async throws -> [ScheduledShiftData] {
        return try await fetchShifts(for: CurrentDayManager.shared.today)
    }

    func fetchTomorrowsShifts() async throws -> [ScheduledShiftData] {
        return try await fetchShifts(for: CurrentDayManager.shared.tomorrow)
    }

    func fetchCurrentWeekShifts() async throws -> [ScheduledShiftData] {
        let today = CurrentDayManager.shared.today
        let startOfWeek = Calendar.current.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let endOfWeek = Calendar.current.date(byAdding: .day, value: 6, to: startOfWeek) ?? today
        return try await fetchShifts(from: startOfWeek, to: endOfWeek)
    }
}