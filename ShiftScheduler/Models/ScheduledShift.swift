import Foundation

struct ScheduledShift: Identifiable, Equatable, Sendable {
    let id: UUID
    let eventIdentifier: String
    let shiftType: ShiftType?
    let date: Date
    let endDate: Date
    let notes: String?
    let isSickDay: Bool

    init(id: UUID = UUID(), eventIdentifier: String, shiftType: ShiftType?, date: Date, endDate: Date? = nil, notes: String? = nil, isSickDay: Bool = false) {
        self.id = id
        self.eventIdentifier = eventIdentifier
        self.shiftType = shiftType
        self.date = date
        self.notes = notes
        self.isSickDay = isSickDay

        // Calculate endDate based on shift type if not explicitly provided
        if let providedEndDate = endDate {
            self.endDate = providedEndDate
        } else if let shiftType = shiftType, shiftType.duration.spansNextDay {
            self.endDate = Calendar.current.date(byAdding: .day, value: 1, to: date) ?? date
        } else {
            // Default to same day for backward compatibility
            self.endDate = date
        }
    }

    init(from shiftData: ScheduledShiftData, shiftType: ShiftType?) {
        self.id = UUID()
        self.eventIdentifier = shiftData.eventIdentifier
        self.shiftType = shiftType
        self.date = shiftData.startDate
        self.notes = shiftData.notes
        self.isSickDay = shiftData.isSickDay
        self.endDate = shiftData.endDate
    }

    /// Number of calendar days this shift spans (1 for same-day, 2 for overnight)
    var spansDays: Int {
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: date)
        let endDay = calendar.startOfDay(for: endDate)
        let components = calendar.dateComponents([.day], from: startDay, to: endDay)
        return (components.day ?? 0) + 1
    }

    static func == (lhs: ScheduledShift, rhs: ScheduledShift) -> Bool {
        return lhs.id == rhs.id &&
               lhs.eventIdentifier == rhs.eventIdentifier &&
               lhs.shiftType?.id == rhs.shiftType?.id &&
               lhs.date == rhs.date &&
               lhs.endDate == rhs.endDate &&
               lhs.notes == rhs.notes &&
               lhs.isSickDay == rhs.isSickDay
    }
}
