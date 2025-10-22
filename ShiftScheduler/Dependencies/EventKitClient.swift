import Foundation
import ComposableArchitecture
import EventKit
import SwiftUI

/// TCA Dependency Client for direct EventKit operations
/// Provides a stateless abstraction over iOS EventKit for calendar event management
@DependencyClient
struct EventKitClient {
    /// Check the current authorization status for calendar access
    var checkAuthorizationStatus: @Sendable () -> EKAuthorizationStatus = { .notDetermined }

    /// Request full access to calendar events (iOS 17+) or basic access (earlier versions)
    var requestFullAccess: @Sendable () async -> Bool = { false }

    /// Get or create the ShiftScheduler app calendar, creating if necessary
    var getOrCreateAppCalendar: @Sendable () async throws -> String = { throw EventKitError.calendarNotFound }

    /// Create a new calendar event with the specified details
    var createEvent: @Sendable (String, Date, Date, Bool, String?) async throws -> String = { _, _, _, _, _ in throw EventKitError.saveFailed(NSError()) }

    /// Event data structure for Sendable compliance
    struct EventData: Sendable {
        let eventIdentifier: String
        let title: String?
        let startDate: Date
        let endDate: Date
        let isAllDay: Bool
        let notes: String?
        let location: String?
    }

    /// Fetch all events within a date range that belong to the app calendar
    var fetchEvents: @Sendable (Date, Date) async throws -> [EventData] = { _, _ in [] }

    /// Delete an event by its identifier
    var deleteEvent: @Sendable (String) async throws -> Void = { _ in throw EventKitError.eventNotFound }

    /// Update an existing event with new details
    var updateEvent: @Sendable (String, String, Date, Date, Bool, String?) async throws -> Void = { _, _, _, _, _, _ in throw EventKitError.eventNotFound }
}

extension EventKitClient: DependencyKey {
    /// Live implementation using the real EventKit framework
    static let liveValue: EventKitClient = {
        let eventStore = EKEventStore()
        let calendarName = "functioncraft.shiftscheduler"
        let appIdentifier = "com.functioncraft.shiftscheduler"

        var appCalendarIdentifier: String?
        var isInitialized = false

        return EventKitClient(
            checkAuthorizationStatus: {
                EKEventStore.authorizationStatus(for: .event)
            },
            requestFullAccess: {
                do {
                    if #available(iOS 17.0, *) {
                        return try await eventStore.requestFullAccessToEvents()
                    } else {
                        return try await eventStore.requestAccess(to: .event)
                    }
                } catch {
                    return false
                }
            },
            getOrCreateAppCalendar: {
                // Check if we already have the calendar identifier cached
                if let identifier = appCalendarIdentifier {
                    if let calendar = eventStore.calendar(withIdentifier: identifier) {
                        return identifier
                    }
                }

                // Try to find existing calendar
                let calendars = eventStore.calendars(for: .event)
                if let existing = calendars.first(where: { $0.title == calendarName }) {
                    appCalendarIdentifier = existing.calendarIdentifier
                    return existing.calendarIdentifier
                }

                // Create new calendar if not found
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
                    throw EventKitError.calendarNotFound
                }

                do {
                    try eventStore.saveCalendar(calendar, commit: true)
                    appCalendarIdentifier = calendar.calendarIdentifier
                    return calendar.calendarIdentifier
                } catch {
                    throw EventKitError.saveFailed(error)
                }
            },
            createEvent: { @Sendable title, startDate, endDate, isAllDay, notes in
                let calendarId = try await EventKitClient.liveValue.getOrCreateAppCalendar()
                guard let calendar = eventStore.calendar(withIdentifier: calendarId) else {
                    throw EventKitError.calendarNotFound
                }

                let event = EKEvent(eventStore: eventStore)
                event.calendar = calendar
                event.title = title
                event.startDate = startDate
                event.endDate = endDate
                event.isAllDay = isAllDay
                event.notes = notes

                do {
                    try eventStore.save(event, span: .thisEvent)
                    return event.eventIdentifier
                } catch {
                    throw EventKitError.saveFailed(error)
                }
            },
            fetchEvents: { @Sendable startDate, endDate in
                let calendarId = try await EventKitClient.liveValue.getOrCreateAppCalendar()
                guard let calendar = eventStore.calendar(withIdentifier: calendarId) else {
                    return []
                }

                let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: [calendar])
                let events = eventStore.events(matching: predicate)
                return events.map { event in
                    EventData(
                        eventIdentifier: event.eventIdentifier,
                        title: event.title,
                        startDate: event.startDate,
                        endDate: event.endDate,
                        isAllDay: event.isAllDay,
                        notes: event.notes,
                        location: event.location
                    )
                }
            },
            deleteEvent: { @Sendable identifier in
                guard let event = eventStore.event(withIdentifier: identifier) else {
                    throw EventKitError.eventNotFound
                }

                do {
                    try eventStore.remove(event, span: .thisEvent)
                } catch {
                    throw EventKitError.deleteFailed(error)
                }
            },
            updateEvent: { @Sendable identifier, title, startDate, endDate, isAllDay, notes in
                guard let event = eventStore.event(withIdentifier: identifier) else {
                    throw EventKitError.eventNotFound
                }

                event.title = title
                event.startDate = startDate
                event.endDate = endDate
                event.isAllDay = isAllDay
                event.notes = notes

                do {
                    try eventStore.save(event, span: .thisEvent)
                } catch {
                    throw EventKitError.saveFailed(error)
                }
            }
        )
    }()

    /// Test value with unimplemented methods (will fail if called)
    static let testValue = EventKitClient()

    /// Preview value with mock implementation
    static let previewValue = EventKitClient(
        checkAuthorizationStatus: { .fullAccess },
        requestFullAccess: { true },
        getOrCreateAppCalendar: { "preview-calendar-id" },
        createEvent: { @Sendable _, _, _, _, _ in "preview-event-id" },
        fetchEvents: { @Sendable _, _ in [] },
        deleteEvent: { @Sendable _ in },
        updateEvent: { @Sendable _, _, _, _, _, _ in }
    )
}

extension DependencyValues {
    var eventKitClient: EventKitClient {
        get { self[EventKitClient.self] }
        set { self[EventKitClient.self] = newValue }
    }
}
