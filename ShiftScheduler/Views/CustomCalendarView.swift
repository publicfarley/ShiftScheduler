import SwiftUI

// Wrapper struct to provide unique identities for calendar cells
private struct CalendarCell: Identifiable {
    let id: Int
    let date: Date?

    init(index: Int, date: Date?) {
        self.id = index
        self.date = date
    }
}

struct CustomCalendarView: View {
    @Binding var selectedDate: Date
    let scheduledDates: Set<Date>
    let shiftSymbols: [Date: String]  // Map of dates to shift symbols
    let selectionMode: SelectionMode?
    let selectedDates: Set<Date>

    @State private var currentMonth = Date()
    @Environment(\.reduxStore) var store

    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    var body: some View {
        VStack(spacing: 6) {
            // Header with month/year and navigation
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.blue)
                        .font(.system(size: 14, weight: .medium))
                }

                Spacer()

                Text(dateFormatter.string(from: currentMonth))
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.blue)
                        .font(.system(size: 14, weight: .medium))
                }
            }
            .padding(.horizontal, 10)

            // Days of week header
            HStack(spacing: 0) {
                ForEach(calendar.shortWeekdaySymbols, id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 10)

            // Calendar grid
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(daysInMonth()) { cell in
                    if let date = cell.date {
                        let isCurrentMonth = calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
                        let hasShift = scheduledDates.contains { scheduledDate in
                            calendar.isDate(date, inSameDayAs: scheduledDate)
                        }

                        // Show EmptyDateCard in bulk add mode (.add) if no shift on that date
                        if selectionMode == .add && !hasShift {
                            let isSelected = selectedDates.contains { selectedDate in
                                calendar.isDate(date, inSameDayAs: selectedDate)
                            }
                            EmptyDateCard(
                                date: date,
                                isSelected: isSelected,
                                isCurrentMonth: isCurrentMonth
                            ) {
                                Task {
                                    await store.dispatch(action: .schedule(.toggleDateSelection(date)))
                                }
                            }
                        } else {
                            // Show normal DayView for dates with shifts or when not in bulk add mode
                            let shiftSymbol = shiftSymbols.first(where: { symbolDate, _ in
                                calendar.isDate(date, inSameDayAs: symbolDate)
                            })?.value

                            DayView(
                                date: date,
                                isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                                hasShift: hasShift,
                                shiftSymbol: shiftSymbol,
                                isCurrentMonth: isCurrentMonth
                            ) {
                                selectedDate = date
                            }
                        }
                    } else {
                        // Empty space for dates outside current month
                        Color.clear
                            .frame(height: 40)
                    }
                }
            }
            .padding(.horizontal, 10)
        }
        .onChange(of: selectedDate) { _, newDate in
            // Update current month if selected date is in a different month
            if !calendar.isDate(newDate, equalTo: currentMonth, toGranularity: .month) {
                currentMonth = newDate
            }
        }
        .onChange(of: currentMonth) { _, newMonth in
            // Notify Redux that the displayed month changed (for fault detection)
            Task {
                await store.dispatch(action: .schedule(.displayedMonthChanged(newMonth)))
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

    private func daysInMonth() -> [CalendarCell] {
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

        // Convert to CalendarCell array with unique IDs
        return days.enumerated().map { index, date in
            CalendarCell(index: index, date: date)
        }
    }
}

struct DayView: View {
    let date: Date
    let isSelected: Bool
    let hasShift: Bool
    let shiftSymbol: String?
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

    private var displaySymbol: String? {
        guard let symbol = shiftSymbol else { return nil }

        // Limit to 3 characters, add ellipsis if longer
        if symbol.count > 3 {
            let index = symbol.index(symbol.startIndex, offsetBy: 3)
            return String(symbol[..<index]) + "…"
        }
        return symbol
    }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background circle or stroke for selected
                if isSelected {
                    Circle()
                        .stroke(.blue, lineWidth: 2)
                        .frame(width: 36, height: 36)
                } else {
                    Circle()
                        .fill(backgroundColor)
                        .frame(width: 36, height: 36)
                }

                // Day number and shift symbol layout
                if let symbol = displaySymbol, hasShift {
                    VStack(spacing: -2) {
                        Text(symbol)
                            .font(.system(size: 14))
                        Text(dayNumber)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(textColor)
                    }
                } else {
                    // Just day number
                    Text(dayNumber)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(textColor)
                }
            }
        }
        .frame(height: 40)
        .opacity(isCurrentMonth ? 1.0 : 0.3)
    }

    private var backgroundColor: Color {
        if hasShift {
            return .green.opacity(0.3)
        } else if isToday {
            return .orange.opacity(0.3)
        } else {
            return .clear
        }
    }

    private var textColor: Color {
        if isSelected {
            return .blue
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
    let today = Date()
    let date2 = Calendar.current.date(byAdding: .day, value: 2, to: today)
    let date5 = Calendar.current.date(byAdding: .day, value: 5, to: today)
    let date7 = Calendar.current.date(byAdding: .day, value: 7, to: today)

    Group {
        if let date2, let date5, let date7 {
            CustomCalendarView(
                selectedDate: .constant(today),
                scheduledDates: Set([today, date2, date5, date7].compactMap { $0 }),
                shiftSymbols: [
                    today: "🌅",
                    date2: "🌃",
                    date5: "🏢",
                    date7: "LONG"  // Test truncation with 4+ chars
                ].mapValues { $0 },
                selectionMode: nil,
                selectedDates: []
            )
            .padding()
        } else {
            EmptyView()
        }
        
    }
}
