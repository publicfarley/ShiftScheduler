import Foundation

struct HourMinuteTime: Codable, Equatable, Hashable {
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

enum ShiftDuration: Codable, Equatable, Hashable {
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
            return "\(from.timeString) - \(to.timeString)"
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
}
