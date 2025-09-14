import Foundation
import SwiftData

@Model
final class ShiftType {
    var id: UUID
    var symbol: String
    var startHour: Int
    var startMinute: Int
    var endHour: Int
    var endMinute: Int
    var title: String
    var shiftDescription: String
    var location: Location?

    init(
        id: UUID = UUID(),
        symbol: String,
        startHour: Int,
        startMinute: Int,
        endHour: Int,
        endMinute: Int,
        title: String,
        description: String,
        location: Location
    ) {
        self.id = id
        self.symbol = symbol
        self.startHour = startHour
        self.startMinute = startMinute
        self.endHour = endHour
        self.endMinute = endMinute
        self.title = title
        self.shiftDescription = description
        self.location = location
    }

    func update(symbol: String, startHour: Int, startMinute: Int, endHour: Int, endMinute: Int, title: String, description: String, location: Location) {
        self.symbol = symbol
        self.startHour = startHour
        self.startMinute = startMinute
        self.endHour = endHour
        self.endMinute = endMinute
        self.title = title
        self.shiftDescription = description
        self.location = location
    }

    var startTimeString: String {
        String(format: "%02d:%02d", startHour, startMinute)
    }

    var endTimeString: String {
        String(format: "%02d:%02d", endHour, endMinute)
    }
}