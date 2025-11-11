import Foundation

/// Data structure representing a shift event from the calendar
/// Used as an intermediate representation when fetching shifts from EventKit
struct ScheduledShiftData: Hashable, Equatable, Sendable {
    let eventIdentifier: String
    let shiftTypeId: UUID
    let date: Date
    let endDate: Date
    let title: String
    let location: String?
    let notes: String?

    func hash(into hasher: inout Hasher) {
        hasher.combine(eventIdentifier)
    }

    static func == (lhs: ScheduledShiftData, rhs: ScheduledShiftData) -> Bool {
        return lhs.eventIdentifier == rhs.eventIdentifier
    }
}
