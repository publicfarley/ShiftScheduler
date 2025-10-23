import Foundation

struct ScheduledShift: Identifiable, Equatable, Sendable {
    let id: UUID
    let eventIdentifier: String
    let shiftType: ShiftType?
    let date: Date

    init(id: UUID = UUID(), eventIdentifier: String, shiftType: ShiftType?, date: Date) {
        self.id = id
        self.eventIdentifier = eventIdentifier
        self.shiftType = shiftType
        self.date = date
    }

    init(from shiftData: ScheduledShiftData, shiftType: ShiftType?) {
        self.id = UUID()
        self.eventIdentifier = shiftData.eventIdentifier
        self.shiftType = shiftType
        self.date = shiftData.date
    }

    static func == (lhs: ScheduledShift, rhs: ScheduledShift) -> Bool {
        return lhs.id == rhs.id &&
               lhs.eventIdentifier == rhs.eventIdentifier &&
               lhs.shiftType?.id == rhs.shiftType?.id &&
               lhs.date == rhs.date
    }
}
