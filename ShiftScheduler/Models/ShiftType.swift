import Foundation

/// Aggregate Root for shift type templates
/// Contains embedded Location as a part of the aggregate
struct ShiftType: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: UUID
    var symbol: String
    var duration: ShiftDuration
    var title: String
    var shiftDescription: String
    var location: Location  // ✅ Non-optional, embedded as aggregate part

    init(
        id: UUID = UUID(),
        symbol: String,
        duration: ShiftDuration,
        title: String,
        description: String,
        location: Location  // ✅ Required parameter
    ) {
        self.id = id
        self.symbol = symbol
        self.duration = duration
        self.title = title
        self.shiftDescription = description
        self.location = location
    }

    /// Convenience method for updating the location
    mutating func updateLocation(_ location: Location) {
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