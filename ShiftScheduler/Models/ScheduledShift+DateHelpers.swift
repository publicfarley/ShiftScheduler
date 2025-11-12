import Foundation

extension ScheduledShift {
    /// Checks if the shift STARTS on the given date
    /// For multi-day shifts, only returns true if the shift's start date matches the target date
    /// This is different from occursOn() which returns true for all dates the shift spans
    func startsOn(date targetDate: Date) -> Bool {
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: targetDate)
        let startDay = calendar.startOfDay(for: date)

        return targetDay == startDay
    }

    /// Checks if the shift occurs on the given date
    /// For multi-day shifts, returns true if the date falls within the shift's date range
    func occursOn(date targetDate: Date) -> Bool {
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: targetDate)
        let startDay = calendar.startOfDay(for: date)
        let endDay = calendar.startOfDay(for: endDate)

        // Check if targetDay is between startDay and endDay (inclusive)
        return targetDay >= startDay && targetDay <= endDay
    }

    /// Returns all calendar dates that this shift occupies
    /// For example, a shift from Nov 10 11 PM to Nov 11 7 AM returns [Nov 10, Nov 11]
    func affectedDates() -> [Date] {
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: date)
        let endDay = calendar.startOfDay(for: endDate)

        var dates: [Date] = []
        var currentDay = startDay

        while currentDay <= endDay {
            dates.append(currentDay)
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDay) else {
                break
            }
            currentDay = nextDay
        }

        return dates
    }

    /// Checks if this shift overlaps with another shift based on date-time ranges
    /// Returns true if the actual start/end DateTimes intersect
    func overlaps(with other: ScheduledShift) -> Bool {
        let thisStart = actualStartDateTime()
        let thisEnd = actualEndDateTime()
        let otherStart = other.actualStartDateTime()
        let otherEnd = other.actualEndDateTime()

        // Two date ranges overlap if: thisStart < otherEnd AND thisEnd > otherStart
        return thisStart < otherEnd && thisEnd > otherStart
    }

    /// Returns the actual start date-time by combining date with shift's start time
    /// For all-day shifts, returns the start of the day
    func actualStartDateTime() -> Date {
        guard let shiftType = shiftType else {
            return Calendar.current.startOfDay(for: date)
        }

        switch shiftType.duration {
        case .allDay:
            return Calendar.current.startOfDay(for: date)
        case .scheduled(let from, _):
            return from.toDate(on: date)
        }
    }

    /// Returns the actual end date-time by combining endDate with shift's end time
    /// For all-day shifts, returns the end of the day
    func actualEndDateTime() -> Date {
        guard let shiftType = shiftType else {
            // For shifts without type, return end of the end date
            return Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: endDate)) ?? endDate
        }

        switch shiftType.duration {
        case .allDay:
            // All-day shift ends at the start of the next day
            return Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: endDate)) ?? endDate
        case .scheduled(_, let to):
            return to.toDate(on: endDate)
        }
    }
}
