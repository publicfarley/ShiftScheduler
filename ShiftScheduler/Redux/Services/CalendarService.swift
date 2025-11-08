import Foundation
import EventKit
import OSLog

private let logger = Logger(subsystem: "com.shiftscheduler.redux.services", category: "CalendarService")

/// Production implementation of CalendarServiceProtocol
/// Uses EventKit to access calendar data and load shifts
final class CalendarService: CalendarServiceProtocol, @unchecked Sendable {
    private let eventStore = EKEventStore()
    private let shiftTypeRepository: ShiftTypeRepository

    /// The app-specific calendar name (matches the bundle identifier)
    private let appCalendarName = "functioncraft.ShiftScheduler"

    init(shiftTypeRepository: ShiftTypeRepository? = nil) {
        self.shiftTypeRepository = shiftTypeRepository ?? ShiftTypeRepository()
    }

    // MARK: - Calendar Management

    /// Gets or creates the app-specific calendar for storing shift events
    /// The calendar name matches the app's bundle identifier
    private func getOrCreateAppCalendar() throws -> EKCalendar {
        // First, check if the calendar already exists
        let calendars = eventStore.calendars(for: .event)
        if let existingCalendar = calendars.first(where: { $0.title == appCalendarName }) {
            logger.debug("Found existing app calendar: \(self.appCalendarName)")
            return existingCalendar
        }

        // Calendar doesn't exist, create it
        logger.debug("Creating new app calendar: \(self.appCalendarName)")
        let newCalendar = EKCalendar(for: .event, eventStore: eventStore)
        newCalendar.title = appCalendarName

        // Set the calendar source (iCloud or local)
        // Prefer iCloud if available, fallback to local
        if let iCloudSource = eventStore.sources.first(where: { $0.sourceType == .calDAV }) {
            newCalendar.source = iCloudSource
            logger.debug("Using iCloud source for app calendar")
        } else if let localSource = eventStore.sources.first(where: { $0.sourceType == .local }) {
            newCalendar.source = localSource
            logger.debug("Using local source for app calendar")
        } else {
            throw CalendarServiceError.eventConversionFailed("No calendar source available")
        }

        // Save the new calendar
        do {
            try eventStore.saveCalendar(newCalendar, commit: true)
            logger.debug("Successfully created app calendar: \(self.appCalendarName)")
            return newCalendar
        } catch {
            logger.error("Failed to create app calendar: \(error.localizedDescription)")
            throw CalendarServiceError.eventConversionFailed("Failed to create app calendar: \(error.localizedDescription)")
        }
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
        logger.debug("Loading shifts from \(startDate.formatted()) to \(endDate.formatted())")

        // Check authorization
        guard try await isCalendarAuthorized() else {
            logger.error("Calendar not authorized")
            throw CalendarServiceError.notAuthorized
        }

        // Get or create the app-specific calendar
        let appCalendar = try getOrCreateAppCalendar()

        // Fetch events only from the app-specific calendar
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: [appCalendar])
        let events = eventStore.events(matching: predicate)

        logger.debug("Loaded \(events.count) events from calendar")

        // Convert events to scheduled shifts
        var shifts: [ScheduledShift] = []

        for event in events {
            guard let shift = try await convertEventToShift(event) else {
                logger.debug("Failed to convert event: \(event.title)")
                continue
            }
            shifts.append(shift)
        }

        logger.debug("Converted to \(shifts.count) scheduled shifts")
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
              let endDate = Calendar.current.date(byAdding: DateComponents(month: 1), to: startDate) else {
            throw CalendarServiceError.dateCalculationFailed
        }

        return try await loadShifts(from: startDate, to: endDate)
    }

    func loadShiftsForExtendedRange() async throws -> [ScheduledShift] {
        let today = Date()
        guard let startDate = Calendar.current.date(byAdding: DateComponents(month: -6), to: today),
              let endDate = Calendar.current.date(byAdding: DateComponents(month: 6), to: today) else {
            throw CalendarServiceError.dateCalculationFailed
        }

        logger.debug("Loading shifts for extended range: \(startDate.formatted()) to \(endDate.formatted())")
        return try await loadShifts(from: startDate, to: endDate)
    }

    func loadShiftsAroundMonth(_ pivotMonth: Date, monthOffset: Int = 6) async throws -> (shifts: [ScheduledShift], rangeStart: Date, rangeEnd: Date) {
        // Get the start of the pivot month
        let pivotStart = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: pivotMonth)) ?? pivotMonth

        guard let startDate = Calendar.current.date(byAdding: .month, value: -monthOffset, to: pivotStart),
              let endDate = Calendar.current.date(byAdding: .month, value: monthOffset + 1, to: pivotStart) else {
            throw CalendarServiceError.dateCalculationFailed
        }

        logger.debug("Loading shifts around month \(pivotMonth.formatted(.dateTime.year().month())) (±\(monthOffset) months): \(startDate.formatted()) to \(endDate.formatted())")

        let shifts = try await loadShifts(from: startDate, to: endDate)

        return (shifts: shifts, rangeStart: startDate, rangeEnd: endDate)
    }

    /// Load shift data (before conversion to domain objects) for a date range
    /// Returns ScheduledShiftData which contains raw EventKit information
    func loadShiftData(from startDate: Date, to endDate: Date) async throws -> [ScheduledShiftData] {
        // Check authorization
        guard try await isCalendarAuthorized() else {
            throw CalendarServiceError.notAuthorized
        }

        // Get or create the app-specific calendar
        let appCalendar = try getOrCreateAppCalendar()

        // Fetch events only from the app-specific calendar
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: [appCalendar])
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

    func createShiftEvent(date: Date, shiftType: ShiftType, notes: String?) async throws -> ScheduledShift {
        logger.debug("Creating shift event for \(shiftType.title) on \(date.formatted())")

        // Check authorization
        guard try await isCalendarAuthorized() else {
            throw CalendarServiceError.notAuthorized
        }

        // Check for overlapping shifts on the same date (business rule: no overlaps allowed)
        let startDate = Calendar.current.startOfDay(for: date)
        let endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate) ?? startDate

        let existingShifts = try await loadShifts(from: startDate, to: endDate)
        if !existingShifts.isEmpty {
            let shiftTitles = existingShifts.compactMap { $0.shiftType?.title }
            throw ScheduleError.overlappingShifts(date: startDate, existingShifts: shiftTitles)
        }

        // Create event with correct timing based on shift duration
        let event = EKEvent(eventStore: eventStore)
        event.title = shiftType.title
        event.location = shiftType.location.name
        event.notes = shiftType.id.uuidString  // Store shift type ID in notes for later retrieval

        // Configure event dates using shared helper
        configureEventDates(event, shiftType: shiftType, baseDate: startDate)

        if let additionalNotes = notes, !additionalNotes.isEmpty {
            event.notes = (event.notes ?? "") + "\n---\n" + additionalNotes
            logger.debug("Shift has notes: \(additionalNotes)")
        }

        logger.debug("Event notes before save: \(event.notes ?? "nil")")

        // Get or create the app-specific calendar
        let appCalendar = try getOrCreateAppCalendar()

        // Save event to the app-specific calendar
        event.calendar = appCalendar
        do {
            try eventStore.save(event, span: .thisEvent)
            logger.debug("Event saved successfully with identifier: \(event.eventIdentifier)")
        } catch {
            logger.error("Failed to save event: \(error.localizedDescription)")
            throw ScheduleError.calendarEventCreationFailed(error.localizedDescription)
        }

        // Return the created shift
        let shift = ScheduledShift(
            id: UUID(),
            eventIdentifier: event.eventIdentifier,
            shiftType: shiftType,
            date: startDate
        )

        return shift
    }

    func updateShiftEvent(eventIdentifier: String, newShiftType: ShiftType, date: Date) async throws {
        // Check authorization
        guard try await isCalendarAuthorized() else {
            throw CalendarServiceError.notAuthorized
        }

        // Fetch the event by identifier
        guard let event = eventStore.event(withIdentifier: eventIdentifier) else {
            throw CalendarServiceError.eventConversionFailed("Event with identifier \(eventIdentifier) not found")
        }

        // Check for overlapping shifts on the same date (excluding the current shift being updated)
        let startDate = Calendar.current.startOfDay(for: date)
        let endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate) ?? startDate

        let existingShifts = try await loadShifts(from: startDate, to: endDate)
        let otherShifts = existingShifts.filter { $0.eventIdentifier != eventIdentifier }

        if !otherShifts.isEmpty {
            let shiftTitles = otherShifts.compactMap { $0.shiftType?.title }
            throw ScheduleError.overlappingShifts(date: startDate, existingShifts: shiftTitles)
        }

        // Update event with new shift type information
        event.title = newShiftType.title
        event.location = newShiftType.location.name

        // Configure event dates using shared helper
        configureEventDates(event, shiftType: newShiftType, baseDate: startDate)

        // Update the shift type ID in the notes
        // Clear any additional notes since they were associated with the old shift type
        event.notes = newShiftType.id.uuidString

        // Save the updated event
        do {
            try eventStore.save(event, span: .thisEvent)
            logger.debug("Updated shift event \(eventIdentifier) with shift type \(newShiftType.title)")
        } catch {
            throw CalendarServiceError.eventConversionFailed("Failed to save updated event: \(error.localizedDescription)")
        }
    }

    func deleteShiftEvent(eventIdentifier: String) async throws {
        logger.debug("Deleting shift event with identifier: \(eventIdentifier)")

        // Check authorization
        guard try await isCalendarAuthorized() else {
            throw CalendarServiceError.notAuthorized
        }

        // Fetch the event by identifier
        guard let event = eventStore.event(withIdentifier: eventIdentifier) else {
            throw ScheduleError.calendarEventDeletionFailed("Event with identifier \(eventIdentifier) not found")
        }

        // Delete the event
        do {
            try eventStore.remove(event, span: .thisEvent)
            logger.debug("Successfully deleted shift event \(eventIdentifier)")
        } catch {
            logger.error("Failed to delete shift event: \(error.localizedDescription)")
            throw ScheduleError.calendarEventDeletionFailed(error.localizedDescription)
        }
    }

    /// Updates all calendar events created from the given ShiftType with updated ShiftType data
    /// - Parameter shiftType: The updated ShiftType to cascade to existing calendar events
    /// - Returns: The number of events that were updated
    func updateEventsWithShiftType(_ shiftType: ShiftType) async throws -> Int {
        logger.debug("Updating calendar events with ShiftType: \(shiftType.title) (ID: \(shiftType.id))")

        // Check authorization
        guard try await isCalendarAuthorized() else {
            throw CalendarServiceError.notAuthorized
        }

        // Load all shifts in extended range (±6 months from today)
        // This ensures we catch most active/future shifts while being performant
        let shifts = try await loadShiftsForExtendedRange()

        // Find shifts that were created from this shift type
        let affectedShifts = shifts.filter { $0.shiftType?.id == shiftType.id }

        guard !affectedShifts.isEmpty else {
            logger.debug("No calendar events reference ShiftType \(shiftType.id), skipping cascade")
            return 0
        }

        logger.debug("Found \(affectedShifts.count) calendar events to update")

        // Update each affected calendar event
        var updatedCount = 0
        for shift in affectedShifts {
            guard let event = eventStore.event(withIdentifier: shift.eventIdentifier) else {
                logger.warning("Could not find calendar event for shift \(shift.id)")
                continue
            }

            // Update event properties with new ShiftType data
            event.title = shiftType.title
            event.location = shiftType.location.name

            // Reconfigure event dates based on new shift type duration
            let baseDate = Calendar.current.startOfDay(for: shift.date)
            configureEventDates(event, shiftType: shiftType, baseDate: baseDate)

            // Preserve shift type ID in notes (don't override user notes)
            let currentNotes = event.notes ?? ""
            let (_, userNotes) = extractNotesAndShiftTypeId(from: currentNotes, eventTitle: event.title)

            if let notes = userNotes, !notes.isEmpty {
                event.notes = shiftType.id.uuidString + "\n---\n" + notes
            } else {
                event.notes = shiftType.id.uuidString
            }

            // Save the updated event
            do {
                try eventStore.save(event, span: .thisEvent)
                updatedCount += 1
                logger.debug("Updated calendar event '\(event.title)' for date \(shift.date.formatted())")
            } catch {
                logger.error("Failed to update event \(shift.eventIdentifier): \(error.localizedDescription)")
                // Continue updating other events even if one fails
            }
        }

        logger.debug("Successfully updated \(updatedCount) calendar events")
        return updatedCount
    }

    func updateShiftNotes(eventIdentifier: String, notes: String) async throws {
        logger.debug("Updating notes for shift event with identifier: \(eventIdentifier)")

        // Check authorization
        guard try await isCalendarAuthorized() else {
            throw CalendarServiceError.notAuthorized
        }

        // Fetch the event by identifier
        guard let event = eventStore.event(withIdentifier: eventIdentifier) else {
            throw CalendarServiceError.eventConversionFailed("Event with identifier \(eventIdentifier) not found")
        }

        // Extract the shift type ID from current notes
        let currentNotes = event.notes ?? ""
        let (shiftTypeIdString, _) = extractNotesAndShiftTypeId(from: currentNotes, eventTitle: event.title)

        // Update notes while preserving shift type ID
        if notes.isEmpty {
            // If notes are empty, just store the shift type ID
            event.notes = shiftTypeIdString
        } else {
            // Store both shift type ID and user notes
            event.notes = shiftTypeIdString + "\n---\n" + notes
        }

        logger.debug("Updated notes to: \(event.notes ?? "nil")")

        // Save the updated event
        do {
            try eventStore.save(event, span: .thisEvent)
            logger.debug("Successfully updated notes for shift event \(eventIdentifier)")
        } catch {
            logger.error("Failed to update shift notes: \(error.localizedDescription)")
            throw CalendarServiceError.eventConversionFailed("Failed to save updated notes: \(error.localizedDescription)")
        }
    }

    // MARK: - Private Helpers

    /// Configure event dates based on shift type duration
    /// - Parameters:
    ///   - event: The EKEvent to configure
    ///   - shiftType: The shift type defining the duration
    ///   - baseDate: The base date for the shift (should be start of day)
    private func configureEventDates(_ event: EKEvent, shiftType: ShiftType, baseDate: Date) {
        if shiftType.duration.isAllDay {
            // All-day event
            event.startDate = baseDate
            event.endDate = baseDate  // All-day events: end date is same as start date
            event.isAllDay = true
            logger.debug("Configured as all-day event")
        } else {
            // Scheduled event with specific start and end times
            event.isAllDay = false

            // Extract start and end times from the shift duration
            if let startTime = shiftType.duration.startTime,
               let endTime = shiftType.duration.endTime {
                // Convert HourMinuteTime to actual Date objects on the specified date
                let startDate = startTime.toDate(on: baseDate)
                var endDate = endTime.toDate(on: baseDate)

                // Handle overnight shifts: if end time is before or equal to start time, shift crosses midnight
                // Add one day to the end date in this case (e.g., 10:00 PM - 2:00 AM)
                if endDate <= startDate {
                    endDate = Calendar.current.date(byAdding: .day, value: 1, to: endDate) ?? endDate
                    logger.debug("Configured overnight scheduled event from \(startTime.timeString) to \(endTime.timeString) (next day)")
                } else {
                    logger.debug("Configured scheduled event from \(startTime.timeString) to \(endTime.timeString)")
                }

                event.startDate = startDate
                event.endDate = endDate
            } else {
                // Fallback: if we can't extract times, treat as all-day
                logger.warning("Could not extract times from scheduled shift, falling back to all-day")
                event.startDate = baseDate
                event.endDate = baseDate
                event.isAllDay = true
            }
        }
    }

    /// Extract shift type ID and user notes from EventKit event notes field
    ///
    /// **Notes Format in EventKit Events:**
    /// The shift type UUID is stored in the first part of the notes field,
    /// followed by an optional separator and user notes:
    /// ```
    /// "SHIFT_TYPE_UUID\n---\nuser notes"
    /// ```
    /// or just:
    /// ```
    /// "SHIFT_TYPE_UUID"
    /// ```
    ///
    /// **Supported Separators (in priority order):**
    /// 1. `\n---\n` (preferred - newline, three dashes, newline)
    /// 2. `---` (backward compatibility - three dashes only)
    /// 3. `\n--\n` (alternative - newline, two dashes, newline)
    /// 4. ` --- ` (with surrounding spaces)
    ///
    /// **Why the separator format exists:**
    /// - The EventKit notes field is our only way to store the shift type ID reference
    /// - We need to distinguish between the system-managed ID and user-entered notes
    /// - The separator ensures we can extract both pieces of information reliably
    ///
    /// **Edge Cases:**
    /// - If no separator is found, the entire notes field is treated as the UUID
    /// - If user enters "---" in their notes, it won't cause issues because we only
    ///   split on the first occurrence of any separator pattern
    /// - Empty notes after the separator are treated as `nil` (no user notes)
    ///
    /// **Changing the separator format:**
    /// To change or add separator formats, update the `possibleSeparators` array below.
    /// Keep existing formats for backward compatibility with old calendar events.
    ///
    /// - Parameters:
    ///   - notes: The raw notes string from the EventKit event
    ///   - eventTitle: The event title (for logging purposes)
    /// - Returns: A tuple containing the shift type ID string and optional user notes
    private func extractNotesAndShiftTypeId(from notes: String, eventTitle: String) -> (shiftTypeId: String, userNotes: String?) {
        var shiftTypeIdString = ""
        var userNotes: String? = nil

        // Try different possible separators
        let possibleSeparators = ["\n---\n", "---", "\n--\n", " --- "]

        for separator in possibleSeparators {
            if let separatorRange = notes.range(of: separator) {
                shiftTypeIdString = String(notes[..<separatorRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)

                // Extract user notes after separator
                let notesAfterSeparator = String(notes[separatorRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                userNotes = notesAfterSeparator.isEmpty ? nil : notesAfterSeparator

                logger.debug("Event '\(eventTitle)' found separator '\(separator)'. Extracted ID: '\(shiftTypeIdString)', User notes: '\(userNotes ?? "nil")'")
                break
            }
        }

        if shiftTypeIdString.isEmpty {
            // No separator found - entire note string should be the shift type ID
            shiftTypeIdString = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            logger.debug("Event '\(eventTitle)' has no separator. Using full notes as ID: '\(shiftTypeIdString)'")
        }

        return (shiftTypeIdString, userNotes)
    }

    /// Reify raw EventKit event to ScheduledShiftData (intermediate representation)
    /// This is the first step of the data transformation pipeline
    private func convertEventToShiftData(_ event: EKEvent) -> ScheduledShiftData? {
        // Extract shift type ID from event notes
        // Notes format: "SHIFT_TYPE_UUID\n---\nuser notes" or just "SHIFT_TYPE_UUID"
        guard let notes = event.notes else {
            logger.debug("Event '\(event.title)' has no notes")
            return nil
        }

        logger.debug("Event '\(event.title)' full notes: '\(notes)'")

        let (shiftTypeIdString, userNotes) = extractNotesAndShiftTypeId(from: notes, eventTitle: event.title)

        guard let shiftTypeId = UUID(uuidString: shiftTypeIdString) else {
            logger.error("Event '\(event.title)' has invalid shift type ID: '\(shiftTypeIdString)' (raw notes: '\(notes)')")
            return nil
        }

        return ScheduledShiftData(
            eventIdentifier: event.eventIdentifier,
            shiftTypeId: shiftTypeId,
            date: Calendar.current.startOfDay(for: event.startDate),
            title: event.title,
            location: event.location,
            notes: userNotes
        )
    }

    private func convertEventToShift(_ event: EKEvent) async throws -> ScheduledShift? {
        // Extract shift type ID from event notes
        // Notes format: "SHIFT_TYPE_UUID\n---\nuser notes" or just "SHIFT_TYPE_UUID"
        guard let notes = event.notes else {
            logger.debug("Event '\(event.title)' has no notes")
            return nil
        }

        logger.debug("Event '\(event.title)' full notes: '\(notes)'")

        let (shiftTypeIdString, userNotes) = extractNotesAndShiftTypeId(from: notes, eventTitle: event.title)

        guard let shiftTypeId = UUID(uuidString: shiftTypeIdString) else {
            logger.error("Event '\(event.title)' has invalid shift type ID: '\(shiftTypeIdString)' (raw notes: '\(notes)')")
            return nil
        }

        // Load shift type from repository
        let shiftTypes = try await shiftTypeRepository.fetchAll()
        guard let shiftType = shiftTypes.first(where: { $0.id == shiftTypeId }) else {
            logger.warning("Shift type \(shiftTypeId) not found for event '\(event.title)'")
            return nil
        }

        let shift = ScheduledShift(
            id: UUID(uuidString: event.eventIdentifier) ?? UUID(),
            eventIdentifier: event.eventIdentifier,
            shiftType: shiftType,
            date: Calendar.current.startOfDay(for: event.startDate),
            notes: userNotes
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

    var recoverySuggestion: String? {
        switch self {
        case .notAuthorized:
            return "Please grant calendar access in Settings > Privacy > Calendars"
        case .dateCalculationFailed:
            return "Please check your device date and time settings"
        case .eventConversionFailed:
            return "Please try again or contact support if the problem persists"
        }
    }
}
