import Testing
import Foundation
@testable import ShiftScheduler

/// Tests for reconstructing ShiftType / Location templates from orphaned calendar
/// events after a local cache loss (Part B recovery).
@Suite("CalendarShiftTypeRecovery Tests")
@MainActor
struct CalendarShiftTypeRecoveryTests {

    // Fixed reference dates so time-of-day parsing is deterministic.
    nonisolated static func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    private func event(
        title: String,
        location: String? = "Work: 1 Main St",
        notes: String?,
        start: Date = CalendarShiftTypeRecoveryTests.date(2026, 1, 5, 8, 0),
        end: Date = CalendarShiftTypeRecoveryTests.date(2026, 1, 5, 16, 0),
        isAllDay: Bool = false
    ) -> RecoverableCalendarEvent {
        RecoverableCalendarEvent(title: title, location: location, notes: notes, startDate: start, endDate: end, isAllDay: isAllDay)
    }

    // MARK: - Notes / UUID parsing

    @Test("Bare UUID in notes is parsed")
    func bareUUID() {
        let id = UUID()
        #expect(CalendarShiftTypeRecovery.shiftTypeId(fromNotes: id.uuidString) == id)
    }

    @Test("UUID before separator + user notes is parsed")
    func uuidWithUserNotes() {
        let id = UUID()
        #expect(CalendarShiftTypeRecovery.shiftTypeId(fromNotes: "\(id.uuidString)\n---\nRemember to bring keys") == id)
    }

    @Test("UUID with inline sick-day flag is parsed")
    func uuidWithSickFlag() {
        let id = UUID()
        #expect(CalendarShiftTypeRecovery.shiftTypeId(fromNotes: "\(id.uuidString)|SICK_DAY:true|REASON:flu") == id)
    }

    @Test("Nil / non-UUID notes yield nil")
    func invalidNotes() {
        #expect(CalendarShiftTypeRecovery.shiftTypeId(fromNotes: nil) == nil)
        #expect(CalendarShiftTypeRecovery.shiftTypeId(fromNotes: "just some free text") == nil)
    }

    // MARK: - Title / location parsing

    @Test("Title splits into symbol and name")
    func titleSplit() {
        let (symbol, title) = CalendarShiftTypeRecovery.splitTitle("☀️: Day Shift")
        #expect(symbol == "☀️")
        #expect(title == "Day Shift")
    }

    @Test("Title without a symbol prefix falls back")
    func titleNoPrefix() {
        let (symbol, title) = CalendarShiftTypeRecovery.splitTitle("Day Shift")
        #expect(symbol == "📅")
        #expect(title == "Day Shift")
    }

    @Test("Location splits into name and address")
    func locationSplit() {
        let (name, address) = CalendarShiftTypeRecovery.splitLocation("Work: 546 GetErDone Ave. Work Town")
        #expect(name == "Work")
        #expect(address == "546 GetErDone Ave. Work Town")
    }

    @Test("Empty location becomes Unknown")
    func locationEmpty() {
        let (name, address) = CalendarShiftTypeRecovery.splitLocation(nil)
        #expect(name == "Unknown")
        #expect(address == "")
    }

    @Test("Deterministic location id is stable for the same name")
    func deterministicLocationID() {
        #expect(CalendarShiftTypeRecovery.deterministicLocationID(for: "Work") == CalendarShiftTypeRecovery.deterministicLocationID(for: "Work"))
        #expect(CalendarShiftTypeRecovery.deterministicLocationID(for: "Work") != CalendarShiftTypeRecovery.deterministicLocationID(for: "Home"))
    }

    // MARK: - Full reconstruction

    @Test("Reconstructs a scheduled shift type and its location from one event")
    func reconstructScheduled() {
        let id = UUID()
        let result = CalendarShiftTypeRecovery.reconstruct(from: [
            event(
                title: "☀️: Day Shift",
                location: "Work: 546 GetErDone Ave.",
                notes: id.uuidString,
                start: Self.date(2026, 1, 5, 8, 0),
                end: Self.date(2026, 1, 5, 16, 30)
            )
        ])

        #expect(result.shiftTypes.count == 1)
        let shiftType = try! #require(result.shiftTypes.first)
        #expect(shiftType.id == id)
        #expect(shiftType.symbol == "☀️")
        #expect(shiftType.title == "Day Shift")
        #expect(shiftType.duration == .scheduled(from: HourMinuteTime(hour: 8, minute: 0), to: HourMinuteTime(hour: 16, minute: 30)))

        #expect(result.locations.count == 1)
        #expect(result.locations.first?.name == "Work")
        #expect(shiftType.location.id == result.locations.first?.id)
    }

    @Test("All-day events reconstruct an allDay duration")
    func reconstructAllDay() {
        let id = UUID()
        let result = CalendarShiftTypeRecovery.reconstruct(from: [
            event(title: "❌: Off", notes: id.uuidString, isAllDay: true)
        ])
        #expect(result.shiftTypes.first?.duration == .allDay)
    }

    @Test("Duplicate shift-type ids collapse to one; first event wins")
    func deduplicates() {
        let id = UUID()
        let result = CalendarShiftTypeRecovery.reconstruct(from: [
            event(title: "☀️: Day Shift", notes: id.uuidString),
            event(title: "🌙: Night Shift", notes: id.uuidString)
        ])
        #expect(result.shiftTypes.count == 1)
        #expect(result.shiftTypes.first?.title == "Day Shift")
    }

    @Test("Events with unparseable notes are ignored")
    func skipsUnparseable() {
        let result = CalendarShiftTypeRecovery.reconstruct(from: [
            event(title: "☀️: Day Shift", notes: "not a uuid"),
            event(title: "🌙: Night", notes: nil)
        ])
        #expect(result.shiftTypes.isEmpty)
        #expect(result.locations.isEmpty)
    }

    @Test("Shared location across shift types is created once")
    func sharedLocation() {
        let result = CalendarShiftTypeRecovery.reconstruct(from: [
            event(title: "☀️: Day", location: "Work: 1 Main St", notes: UUID().uuidString),
            event(title: "🌙: Night", location: "Work: 1 Main St", notes: UUID().uuidString)
        ])
        #expect(result.shiftTypes.count == 2)
        #expect(result.locations.count == 1)
    }
}
