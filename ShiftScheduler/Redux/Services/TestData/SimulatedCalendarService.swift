import Foundation
import OSLog

private let logger = Logger(subsystem: "com.shiftscheduler.redux.services", category: "SimulatedCalendarService")

/// JSON-backed record standing in for an `EKEvent` inside Test Data Mode.
/// Mirrors the fields `CalendarService` derives from an EventKit event's notes/dates.
struct SimulatedEvent: Codable, Sendable {
    let eventIdentifier: String
    var shiftTypeId: UUID
    var date: Date
    var endDate: Date
    var notes: String?
    var isSickDay: Bool
    var reason: String?
}

/// Fully simulated implementation of `CalendarServiceProtocol` used by Test Data Mode.
/// Holds no reference to EventKit whatsoever — no calendar permission is ever requested,
/// and the real device calendar is never read or written. All shift "events" are persisted
/// as JSON (`simulatedCalendar.json`) inside the sandboxed test data directory.
///
/// Implemented as an actor to serialize file access and satisfy `Sendable`.
actor SimulatedCalendarService: CalendarServiceProtocol {
    private let directoryURL: URL
    private let fileName = "simulatedCalendar.json"
    private let fileManager = FileManager.default
    private let shiftTypeRepository: ShiftTypeRepository

    init(directoryURL: URL, shiftTypeRepository: ShiftTypeRepository) {
        self.directoryURL = directoryURL
        self.shiftTypeRepository = shiftTypeRepository
    }

    // MARK: - Authorization (always granted, nothing to request)

    func isCalendarAuthorized() async throws -> Bool {
        true
    }

    func requestCalendarAccess() async throws -> Bool {
        true
    }

    // MARK: - Loading Shifts

    func loadShifts(from startDate: Date, to endDate: Date) async throws -> [ScheduledShift] {
        let events = try loadEvents().filter { overlaps($0, start: startDate, end: endDate) }
        let shiftTypes = try await shiftTypeRepository.fetchAll()

        var shifts: [ScheduledShift] = []
        for event in events {
            guard let shiftType = shiftTypes.first(where: { $0.id == event.shiftTypeId }) else {
                logger.warning("Simulated shift type \(event.shiftTypeId) not found for event \(event.eventIdentifier)")
                continue
            }

            shifts.append(
                ScheduledShift(
                    id: UUID(uuidString: event.eventIdentifier) ?? UUID(),
                    eventIdentifier: event.eventIdentifier,
                    shiftType: shiftType,
                    date: event.date,
                    endDate: event.endDate,
                    notes: event.notes,
                    isSickDay: event.isSickDay,
                    reason: event.reason
                )
            )
        }

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
        return try await loadShifts(from: startDate, to: endDate)
    }

    func loadShiftsAroundMonth(_ pivotMonth: Date, monthOffset: Int = 6) async throws -> (shifts: [ScheduledShift], rangeStart: Date, rangeEnd: Date) {
        let pivotStart = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: pivotMonth)) ?? pivotMonth

        guard let startDate = Calendar.current.date(byAdding: .month, value: -monthOffset, to: pivotStart),
              let endDate = Calendar.current.date(byAdding: .month, value: monthOffset + 1, to: pivotStart) else {
            throw CalendarServiceError.dateCalculationFailed
        }

        let shifts = try await loadShifts(from: startDate, to: endDate)
        return (shifts: shifts, rangeStart: startDate, rangeEnd: endDate)
    }

    // MARK: - Loading Raw Shift Data

    func loadShiftData(from startDate: Date, to endDate: Date) async throws -> [ScheduledShiftData] {
        let events = try loadEvents().filter { overlaps($0, start: startDate, end: endDate) }
        let shiftTypes = try await shiftTypeRepository.fetchAll()

        let dataArray: [ScheduledShiftData] = events.map { event in
            let shiftType = shiftTypes.first { $0.id == event.shiftTypeId }
            let title = shiftType.map { "\($0.symbol): \($0.title)" } ?? ""
            let location = shiftType.map { "\($0.location.name): \($0.location.address)" }

            return ScheduledShiftData(
                eventIdentifier: event.eventIdentifier,
                shiftTypeId: event.shiftTypeId,
                startDate: event.date,
                endDate: event.endDate,
                title: title,
                location: location,
                notes: event.notes,
                isSickDay: event.isSickDay,
                reason: event.reason
            )
        }

        return dataArray.sorted { $0.startDate < $1.startDate }
    }

    func loadShiftDataForToday() async throws -> [ScheduledShiftData] {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today
        return try await loadShiftData(from: today, to: tomorrow)
    }

    func loadShiftDataForTomorrow() async throws -> [ScheduledShiftData] {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today
        let dayAfterTomorrow = Calendar.current.date(byAdding: .day, value: 1, to: tomorrow) ?? tomorrow
        return try await loadShiftData(from: tomorrow, to: dayAfterTomorrow)
    }

    // MARK: - Mutating Shifts

    func createShiftEvent(date: Date, shiftType: ShiftType, notes: String?) async throws -> ScheduledShift {
        let startDate = Calendar.current.startOfDay(for: date)

        // Check for overlapping shifts using the same date-time range intersection as CalendarService
        let rangeStart = Calendar.current.date(byAdding: .day, value: -1, to: startDate) ?? startDate
        let rangeEnd = Calendar.current.date(byAdding: .day, value: 2, to: startDate) ?? startDate
        let existingShifts = try await loadShifts(from: rangeStart, to: rangeEnd)

        let calculatedEndDate: Date
        if shiftType.duration.spansNextDay {
            calculatedEndDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate) ?? startDate
        } else {
            calculatedEndDate = startDate
        }

        let candidateShift = ScheduledShift(
            id: UUID(),
            eventIdentifier: "",
            shiftType: shiftType,
            date: startDate,
            endDate: calculatedEndDate
        )

        if let overlappingShift = candidateShift.findOverlap(in: existingShifts) {
            let shiftTitles = [overlappingShift.shiftType?.title].compactMap { $0 }
            throw ScheduleError.overlappingShifts(date: startDate, existingShifts: shiftTitles)
        }

        let eventIdentifier = UUID().uuidString
        let finalNotes = (notes?.isEmpty == true) ? nil : notes

        let event = SimulatedEvent(
            eventIdentifier: eventIdentifier,
            shiftTypeId: shiftType.id,
            date: startDate,
            endDate: calculatedEndDate,
            notes: finalNotes,
            isSickDay: false,
            reason: nil
        )

        var events = try loadEvents()
        events.append(event)
        try saveEvents(events)

        return ScheduledShift(
            id: UUID(),
            eventIdentifier: eventIdentifier,
            shiftType: shiftType,
            date: startDate,
            endDate: calculatedEndDate,
            notes: finalNotes,
            isSickDay: false,
            reason: nil
        )
    }

    func updateShiftEvent(eventIdentifier: String, newShiftType: ShiftType, date: Date) async throws {
        var events = try loadEvents()
        guard let index = events.firstIndex(where: { $0.eventIdentifier == eventIdentifier }) else {
            throw CalendarServiceError.eventConversionFailed("Event with identifier \(eventIdentifier) not found")
        }

        let startDate = Calendar.current.startOfDay(for: date)
        let rangeStart = Calendar.current.date(byAdding: .day, value: -1, to: startDate) ?? startDate
        let rangeEnd = Calendar.current.date(byAdding: .day, value: 2, to: startDate) ?? startDate
        let existingShifts = try await loadShifts(from: rangeStart, to: rangeEnd)
        let otherShifts = existingShifts.filter { $0.eventIdentifier != eventIdentifier }

        let calculatedEndDate: Date
        if newShiftType.duration.spansNextDay {
            calculatedEndDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate) ?? startDate
        } else {
            calculatedEndDate = startDate
        }

        let candidateShift = ScheduledShift(
            id: UUID(),
            eventIdentifier: "",
            shiftType: newShiftType,
            date: startDate,
            endDate: calculatedEndDate
        )

        if let overlappingShift = candidateShift.findOverlap(in: otherShifts) {
            let shiftTitles = [overlappingShift.shiftType?.title].compactMap { $0 }
            throw ScheduleError.overlappingShifts(date: startDate, existingShifts: shiftTitles)
        }

        events[index].shiftTypeId = newShiftType.id
        events[index].date = startDate
        events[index].endDate = calculatedEndDate

        try saveEvents(events)
    }

    func deleteShiftEvent(eventIdentifier: String) async throws {
        var events = try loadEvents()
        guard let index = events.firstIndex(where: { $0.eventIdentifier == eventIdentifier }) else {
            throw ScheduleError.calendarEventDeletionFailed("Event with identifier \(eventIdentifier) not found")
        }
        events.remove(at: index)
        try saveEvents(events)
    }

    func deleteMultipleShiftEvents(_ eventIdentifiers: [String]) async throws -> Int {
        var events = try loadEvents()
        var deletedCount = 0

        for identifier in eventIdentifiers {
            if let index = events.firstIndex(where: { $0.eventIdentifier == identifier }) {
                events.remove(at: index)
                deletedCount += 1
            }
        }

        if deletedCount > 0 {
            try saveEvents(events)
        }

        return deletedCount
    }

    func updateEventsWithShiftType(_ shiftType: ShiftType) async throws -> Int {
        var events = try loadEvents()
        var updatedCount = 0

        for index in events.indices where events[index].shiftTypeId == shiftType.id {
            let baseDate = Calendar.current.startOfDay(for: events[index].date)
            let newEndDate: Date
            if shiftType.duration.spansNextDay {
                newEndDate = Calendar.current.date(byAdding: .day, value: 1, to: baseDate) ?? baseDate
            } else {
                newEndDate = baseDate
            }
            events[index].endDate = newEndDate
            updatedCount += 1
        }

        if updatedCount > 0 {
            try saveEvents(events)
        }

        return updatedCount
    }

    func updateShiftNotes(eventIdentifier: String, notes: String) async throws {
        var events = try loadEvents()
        guard let index = events.firstIndex(where: { $0.eventIdentifier == eventIdentifier }) else {
            throw CalendarServiceError.eventConversionFailed("Event with identifier \(eventIdentifier) not found")
        }
        events[index].notes = notes.isEmpty ? nil : notes
        try saveEvents(events)
    }

    func resyncAllCalendarEvents() async throws -> (updated: Int, total: Int) {
        let allShiftTypes = try await shiftTypeRepository.fetchAll()
        guard !allShiftTypes.isEmpty else {
            return (updated: 0, total: 0)
        }

        var totalUpdated = 0
        for shiftType in allShiftTypes {
            totalUpdated += try await updateEventsWithShiftType(shiftType)
        }

        return (updated: totalUpdated, total: totalUpdated)
    }

    func markShiftAsSick(eventIdentifier: String, isSickDay: Bool, reason: String?) async throws {
        var events = try loadEvents()
        guard let index = events.firstIndex(where: { $0.eventIdentifier == eventIdentifier }) else {
            throw CalendarServiceError.eventConversionFailed("Event with identifier \(eventIdentifier) not found")
        }
        events[index].isSickDay = isSickDay
        events[index].reason = isSickDay ? reason : nil
        try saveEvents(events)
    }

    // MARK: - Private Helpers

    /// Returns true if a simulated event's [date, endDate] range overlaps [start, end),
    /// mirroring `EKEventStore.predicateForEvents(withStart:end:calendars:)` semantics.
    private func overlaps(_ event: SimulatedEvent, start: Date, end: Date) -> Bool {
        event.date < end && event.endDate >= start
    }

    private func ensureDirectory() throws {
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }

    private var fileURL: URL {
        directoryURL.appendingPathComponent(fileName)
    }

    private func loadEvents() throws -> [SimulatedEvent] {
        try ensureDirectory()
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return []
        }
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode([SimulatedEvent].self, from: data)
    }

    private func saveEvents(_ events: [SimulatedEvent]) throws {
        try ensureDirectory()
        let data = try JSONEncoder().encode(events)
        try data.write(to: fileURL, options: .atomic)
    }
}
