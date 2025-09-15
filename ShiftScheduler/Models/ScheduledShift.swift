import Foundation
import SwiftData

struct ScheduledShift: Identifiable {
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
}