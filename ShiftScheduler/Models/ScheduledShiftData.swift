import Foundation

/// Data structure representing a shift event from the calendar
/// Used as an intermediate representation when fetching shifts from EventKit
struct ScheduledShiftData: Hashable, Equatable, Sendable {
    let eventIdentifier: String
    let shiftTypeId: UUID
    let startDate: Date
    let endDate: Date
    let title: String
    let location: String?
    let notes: String?
    let isSickDay: Bool

    init(eventIdentifier: String, shiftTypeId: UUID, startDate: Date, endDate: Date, title: String, location: String? = nil, notes: String? = nil, isSickDay: Bool = false) {
        self.eventIdentifier = eventIdentifier
        self.shiftTypeId = shiftTypeId
        self.startDate = startDate
        self.endDate = endDate
        self.title = title
        self.location = location
        self.notes = notes
        self.isSickDay = isSickDay
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(eventIdentifier)
    }

    static func == (lhs: ScheduledShiftData, rhs: ScheduledShiftData) -> Bool {
        return lhs.eventIdentifier == rhs.eventIdentifier
    }
}
