import Foundation

struct HourMinuteTime: Codable, Equatable, Hashable, Sendable {
    let hour: Int
    let minute: Int

    init(hour: Int, minute: Int) {
        self.hour = hour
        self.minute = minute
    }

    init(from date: Date) {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        self.hour = components.hour ?? 0
        self.minute = components.minute ?? 0
    }

    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let date = toDate()
        return formatter.string(from: date)
    }

    func toDate(on date: Date = Date()) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? date
    }
}

enum ShiftDuration: Equatable, Hashable, Sendable {
    case allDay
    case scheduled(from: HourMinuteTime, to: HourMinuteTime)

    var isAllDay: Bool {
        if case .allDay = self { return true }
        return false
    }

    var startTimeString: String {
        switch self {
        case .allDay:
            return "All Day"
        case .scheduled(let from, _):
            return from.timeString
        }
    }

    var endTimeString: String {
        switch self {
        case .allDay:
            return ""
        case .scheduled(_, let to):
            return to.timeString
        }
    }

    var timeRangeString: String {
        switch self {
        case .allDay:
            return "All Day"
        case .scheduled(let from, let to):
            if spansNextDay {
                return "\(from.timeString) - \(to.timeString) +1"
            } else {
                return "\(from.timeString) - \(to.timeString)"
            }
        }
    }

    var startTime: HourMinuteTime? {
        switch self {
        case .allDay:
            return nil
        case .scheduled(let from, _):
            return from
        }
    }

    var endTime: HourMinuteTime? {
        switch self {
        case .allDay:
            return nil
        case .scheduled(_, let to):
            return to
        }
    }

    /// Returns true if the shift spans to the next day (overnight shift)
    /// Detected when end time is earlier than start time (e.g., 11 PM - 7 AM)
    var spansNextDay: Bool {
        switch self {
        case .allDay:
            return false
        case .scheduled(let from, let to):
            // If end hour < start hour, it spans to next day
            if to.hour < from.hour {
                return true
            }
            // If hours equal, check minutes
            if to.hour == from.hour && to.minute < from.minute {
                return true
            }
            return false
        }
    }

    /// Calculates the actual duration of the shift in hours
    /// Returns nil for all-day shifts
    var durationInHours: Double? {
        switch self {
        case .allDay:
            return nil
        case .scheduled(let from, let to):
            let startMinutes = from.hour * 60 + from.minute
            var endMinutes = to.hour * 60 + to.minute

            // If shift spans next day, add 24 hours to end time
            if spansNextDay {
                endMinutes += 24 * 60
            }

            let durationMinutes = endMinutes - startMinutes
            return Double(durationMinutes) / 60.0
        }
    }

    /// Validates that the shift duration is less than 24 hours
    /// Returns true if valid (< 24 hours), false if invalid (≥ 24 hours)
    var isValidDuration: Bool {
        guard let duration = durationInHours else {
            return true // All-day shifts are always valid
        }
        return duration < 24.0
    }
}

// MARK: - Codable (nonisolated encoding/decoding)
extension ShiftDuration: Codable {
    enum CodingKeys: String, CodingKey {
        case allDay
        case scheduled
    }

    enum ScheduledCodingKeys: String, CodingKey {
        case from, to
    }

    nonisolated func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .allDay:
            var unkeyedContainer = container.nestedUnkeyedContainer(forKey: .allDay)
            try unkeyedContainer.encodeNil()
        case .scheduled(let from, let to):
            var nestedContainer = container.nestedContainer(keyedBy: ScheduledCodingKeys.self, forKey: .scheduled)
            try nestedContainer.encode(from, forKey: .from)
            try nestedContainer.encode(to, forKey: .to)
        }
    }

    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if container.contains(.allDay) {
            self = .allDay
        } else if container.contains(.scheduled) {
            let nestedContainer = try container.nestedContainer(keyedBy: ScheduledCodingKeys.self, forKey: .scheduled)
            let from = try nestedContainer.decode(HourMinuteTime.self, forKey: .from)
            let to = try nestedContainer.decode(HourMinuteTime.self, forKey: .to)
            self = .scheduled(from: from, to: to)
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Unknown ShiftDuration variant"
                )
            )
        }
    }
}
