import SwiftUI

struct CustomCalendarView: View {
    @Binding var selectedDate: Date
    let scheduledDates: Set<Date>

    @State private var currentMonth = Date()

    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    var body: some View {
        VStack {
            // Header with month/year and navigation
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.blue)
                }

                Spacer()

                Text(dateFormatter.string(from: currentMonth))
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)

            // Days of week header
            HStack {
                ForEach(calendar.shortWeekdaySymbols, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)

            // Calendar grid
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(daysInMonth(), id: \.self) { date in
                    if let date = date {
                        DayView(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            hasShift: scheduledDates.contains { scheduledDate in
                                calendar.isDate(date, inSameDayAs: scheduledDate)
                            },
                            isCurrentMonth: calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
                        ) {
                            selectedDate = date
                        }
                    } else {
                        // Empty space for dates outside current month
                        Color.clear
                            .frame(height: 40)
                    }
                }
            }
            .padding(.horizontal)
        }
        .onChange(of: selectedDate) { _, newDate in
            // Update current month if selected date is in a different month
            if !calendar.isDate(newDate, equalTo: currentMonth, toGranularity: .month) {
                currentMonth = newDate
            }
        }
    }

    private func previousMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
        }
    }

    private func nextMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        }
    }

    private func daysInMonth() -> [Date?] {
        guard let monthRange = calendar.range(of: .day, in: .month, for: currentMonth),
              let firstOfMonth = calendar.dateInterval(of: .month, for: currentMonth)?.start else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let offsetDays = firstWeekday - calendar.firstWeekday

        var days: [Date?] = Array(repeating: nil, count: offsetDays)

        for day in monthRange {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(date)
            }
        }

        // Fill remaining slots to complete the grid (6 weeks = 42 slots)
        while days.count < 42 {
            days.append(nil)
        }

        return days
    }
}

struct DayView: View {
    let date: Date
    let isSelected: Bool
    let hasShift: Bool
    let isCurrentMonth: Bool
    let onTap: () -> Void

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background circle
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 36, height: 36)

                // Day number
                Text(dayNumber)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(textColor)
            }
        }
        .frame(height: 40)
        .opacity(isCurrentMonth ? 1.0 : 0.3)
    }

    private var backgroundColor: Color {
        if isSelected {
            return .blue
        } else if hasShift {
            return .green.opacity(0.3)
        } else if isToday {
            return .orange.opacity(0.3)
        } else {
            return .clear
        }
    }

    private var textColor: Color {
        if isSelected {
            return .white
        } else if isToday {
            return .orange
        } else if hasShift {
            return .green
        } else {
            return .primary
        }
    }
}

#Preview {
    CustomCalendarView(
        selectedDate: .constant(Date()),
        scheduledDates: Set([
            Date(),
            Calendar.current.date(byAdding: .day, value: 2, to: Date())!,
            Calendar.current.date(byAdding: .day, value: 5, to: Date())!
        ])
    )
    .padding()
}