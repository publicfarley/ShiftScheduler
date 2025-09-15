import Foundation
import SwiftData

@Model
final class ShiftType {
    var id: UUID
    var symbol: String
    var duration: ShiftDuration
    var title: String
    var shiftDescription: String
    var location: Location?

    init(
        id: UUID = UUID(),
        symbol: String,
        duration: ShiftDuration,
        title: String,
        description: String,
        location: Location
    ) {
        self.id = id
        self.symbol = symbol
        self.duration = duration
        self.title = title
        self.shiftDescription = description
        self.location = location
    }

    func update(symbol: String, duration: ShiftDuration, title: String, description: String, location: Location) {
        self.symbol = symbol
        self.duration = duration
        self.title = title
        self.shiftDescription = description
        self.location = location
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