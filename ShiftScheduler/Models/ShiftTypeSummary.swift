import Foundation

struct ShiftTypeSummary: Identifiable, Equatable {
    let id: UUID
    let shiftType: ShiftType
    let count: Int

    init(shiftType: ShiftType, count: Int) {
        self.id = shiftType.id
        self.shiftType = shiftType
        self.count = count
    }
}
