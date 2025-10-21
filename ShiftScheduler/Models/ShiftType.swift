import Foundation

/// Value-type model for a shift type/template
struct ShiftType: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var symbol: String
    var duration: ShiftDuration
    var title: String
    var shiftDescription: String
    var locationId: UUID?

    init(
        id: UUID = UUID(),
        symbol: String,
        duration: ShiftDuration,
        title: String,
        description: String,
        locationId: UUID? = nil
    ) {
        self.id = id
        self.symbol = symbol
        self.duration = duration
        self.title = title
        self.shiftDescription = description
        self.locationId = locationId
    }

    var startTimeString: String {
        duration.startTimeString
    }

    var endTimeString: String {
        duration.endTimeString
    }

    var timeRangeString: String {
        duration.timeRangeString
    }

    var isAllDay: Bool {
        duration.isAllDay
    }
}