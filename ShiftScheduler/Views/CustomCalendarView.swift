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

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    var body: some View {
        VStack(spacing: 8) {
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
            .padding(.horizontal, 12)

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
            .padding(.horizontal, 12)
            .padding(.bottom, 4)

            // Calendar grid - 6 rows × 7 columns (42 cells total)
            LazyVGrid(columns: columns, spacing: 0) {
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
                        // Invisible cell for dates outside current month
                        // Takes up space but is not visible - no border, no content
                        Color.clear
                            .frame(maxWidth: .infinity)
                            .frame(height: 64)
                            .opacity(0)
                    }
                }
            }
            .padding(12)
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
            VStack(alignment: .leading, spacing: 0) {
                // Day number in top-left
                Text(dayNumber)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(isCurrentMonth ? .primary : .tertiary)
                    .lineLimit(1)
                    .padding(8)

                Spacer()

                // Shift symbol centered at bottom
                if let symbol = displaySymbol, hasShift {
                    Text(symbol)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(4)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(backgroundColor)
            .border(Color(.systemGray3), width: 1)
            .overlay(
                isSelected ?
                    RoundedRectangle(cornerRadius: 0)
                        .strokeBorder(Color.accentColor, lineWidth: 2)
                    : nil
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(duration: 0.3, bounce: 0.15), value: isSelected)
        }
        .opacity(isCurrentMonth ? 1.0 : 0.5)
    }

    private var backgroundColor: some View {
        Group {
            if isToday && hasShift {
                // Today with shift: gradient
                LinearGradient(
                    colors: [
                        Color.orange.opacity(0.2),
                        Color.green.opacity(0.15)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else if hasShift {
                // Has shift: subtle green
                Color.green.opacity(0.12)
            } else if isToday {
                // Today: subtle orange
                Color.orange.opacity(0.15)
            } else {
                // Empty day
                Color.clear
            }
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
