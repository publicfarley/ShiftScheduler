import SwiftUI

/// A row of days showing each day's shift symbols, so days with more than one
/// shift (e.g. a Day and an Evening shift) are visible at a glance.
struct WeekDayStrip: View {
    let days: [Date]
    let scheduledShifts: [ScheduledShift]

    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            ForEach(days, id: \.self) { day in
                WeekDayStripCell(
                    date: day,
                    shifts: scheduledShifts
                        .filter { $0.startsOn(date: day) }
                        .sorted { $0.actualStartDateTime() < $1.actualStartDateTime() }
                )
            }
        }
    }
}

private struct WeekDayStripCell: View {
    let date: Date
    let shifts: [ScheduledShift]

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    private var weekdayText: String {
        String(date.formatted(.dateTime.weekday(.abbreviated)).prefix(2))
    }

    private var dayNumberText: String {
        date.formatted(.dateTime.day())
    }

    private var accessibilityText: String {
        let dayText = date.formatted(.dateTime.weekday(.wide).month(.wide).day())
        if shifts.isEmpty {
            return "\(dayText), no shifts"
        }
        let titles = shifts.compactMap { $0.shiftType?.title }.joined(separator: ", ")
        return "\(dayText), \(shifts.count) \(shifts.count == 1 ? "shift" : "shifts"): \(titles)"
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(weekdayText)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(isToday ? .blue : .secondary)

            Text(dayNumberText)
                .font(.caption)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundColor(isToday ? .blue : .primary)

            VStack(spacing: 3) {
                if shifts.isEmpty {
                    Text("–")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.6))
                        .frame(height: 22)
                } else {
                    ForEach(shifts) { shift in
                        let color = ShiftColorPalette.colorForShift(shift.shiftType)
                        Text(shift.shiftType?.symbol ?? "?")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 22)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(color.opacity(0.18))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .strokeBorder(color.opacity(0.5), lineWidth: 1)
                            )
                    }
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 3)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isToday ? Color.blue.opacity(0.08) : Color.clear)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }
}
