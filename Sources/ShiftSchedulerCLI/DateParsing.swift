import Foundation

/// Parses CLI date and time arguments.
enum DateParsing {
    /// Accepted formats: YYYY-MM-DD, today, tomorrow, yesterday,
    /// and relative offsets like +3d, -1w (days/weeks from today).
    /// Returns the date normalized to the start of day.
    static func parseDate(_ input: String, calendar: Calendar = .current, now: Date = Date()) throws -> Date {
        let trimmed = input.trimmingCharacters(in: .whitespaces).lowercased()
        let today = calendar.startOfDay(for: now)

        switch trimmed {
        case "today":
            return today
        case "tomorrow":
            return calendar.date(byAdding: .day, value: 1, to: today) ?? today
        case "yesterday":
            return calendar.date(byAdding: .day, value: -1, to: today) ?? today
        default:
            break
        }

        if let relative = parseRelative(trimmed, calendar: calendar, from: today) {
            return relative
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = calendar
        if let date = formatter.date(from: trimmed) {
            return calendar.startOfDay(for: date)
        }

        throw CLIError.invalidDate(input)
    }

    /// Parses a 24-hour HH:MM time argument.
    static func parseTime(_ input: String) throws -> HourMinuteTime {
        let parts = input.trimmingCharacters(in: .whitespaces).split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]), (0...23).contains(hour),
              let minute = Int(parts[1]), (0...59).contains(minute) else {
            throw CLIError.invalidTime(input)
        }
        return HourMinuteTime(hour: hour, minute: minute)
    }

    /// Parses +Nd/-Nd (days) and +Nw/-Nw (weeks) offsets from today.
    private static func parseRelative(_ input: String, calendar: Calendar, from today: Date) -> Date? {
        guard input.count >= 3 else { return nil }
        let sign: Int
        switch input.first {
        case "+": sign = 1
        case "-": sign = -1
        default: return nil
        }
        let unit = input.last
        guard let amount = Int(input.dropFirst().dropLast()), amount >= 0 else { return nil }
        switch unit {
        case "d":
            return calendar.date(byAdding: .day, value: sign * amount, to: today)
        case "w":
            return calendar.date(byAdding: .day, value: sign * amount * 7, to: today)
        default:
            return nil
        }
    }
}
