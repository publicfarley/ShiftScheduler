import Foundation

/// Aggregate Root for shift type templates
/// Contains embedded Location as a part of the aggregate
struct ShiftType: Identifiable, Equatable, Hashable, Sendable {
    let id: UUID
    var symbol: String
    var duration: ShiftDuration
    var title: String
    var shiftDescription: String
    var location: Location  // ✅ Non-optional, embedded as aggregate part

    nonisolated init(
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

// MARK: - Codable (nonisolated encoding/decoding)
extension ShiftType: Codable {
    enum CodingKeys: String, CodingKey {
        case id, symbol, duration, title, shiftDescription, location
    }

    nonisolated func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(symbol, forKey: .symbol)
        try container.encode(duration, forKey: .duration)
        try container.encode(title, forKey: .title)
        try container.encode(shiftDescription, forKey: .shiftDescription)
        try container.encode(location, forKey: .location)
    }

    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        symbol = try container.decode(String.self, forKey: .symbol)
        duration = try container.decode(ShiftDuration.self, forKey: .duration)
        title = try container.decode(String.self, forKey: .title)
        shiftDescription = try container.decode(String.self, forKey: .shiftDescription)
        location = try container.decode(Location.self, forKey: .location)
    }
}
