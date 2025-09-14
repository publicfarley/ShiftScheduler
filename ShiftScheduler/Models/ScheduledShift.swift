import Foundation
import SwiftData

@Model
final class ScheduledShift {
    var id: UUID
    var shiftType: ShiftType?
    var date: Date

    init(id: UUID = UUID(), shiftType: ShiftType, date: Date) {
        self.id = id
        self.shiftType = shiftType
        self.date = date
    }
}