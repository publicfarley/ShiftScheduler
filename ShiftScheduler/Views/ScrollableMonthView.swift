import SwiftUI

/// A horizontally scrollable calendar with full month views
/// Users can swipe left/right to navigate between months
/// Each month displays in full with all dates visible
struct ScrollableMonthView: View {
    @Binding var selectedDate: Date
    @Binding var displayedMonth: Date
    let scheduledDates: Set<Date>
    let shiftSymbols: [Date: String]
    let selectionMode: SelectionMode?
    let selectedDates: Set<Date>

    @State private var scrollPosition: Date?
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    // Peek width for adjacent months (in points)
    private let peekWidth: CGFloat = 40

    // Calculate natural height for calendar:
    // Month header (~48pt) + Day names (~30pt) + 6 rows (324pt) + padding (24pt) = ~426pt
    private let calendarHeight: CGFloat = 426

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    // Generate months: -12 to +12 months from today
                    ForEach(monthRange(), id: \.self) { month in
                        SingleMonthView(
                            month: month,
                            selectedDate: $selectedDate,
                            scheduledDates: scheduledDates,
                            shiftSymbols: shiftSymbols,
                            selectionMode: selectionMode,
                            selectedDates: selectedDates
                        )
                        // Each month takes FULL container width
                        .containerRelativeFrame(.horizontal)
                        .id(month)
                    }
                }
                .scrollTargetLayout()
            }
            .safeAreaPadding(.horizontal, peekWidth)
            .scrollTargetBehavior(.viewAligned)
            .frame(height: calendarHeight)
            .onAppear {
                // Start with current month displayed
                let currentMonth = getCurrentMonth()
                scrollPosition = currentMonth
                proxy.scrollTo(currentMonth, anchor: .leading)
            }
            .onChange(of: displayedMonth) { _, newMonth in
                withAnimation(.easeInOut(duration: 0.3)) {
                    scrollPosition = newMonth
                    proxy.scrollTo(newMonth, anchor: .leading)
                }
            }
        }
    }

    /// Get the current month (today's month) normalized to start-of-day
    private func getCurrentMonth() -> Date {
        let today = calendar.startOfDay(for: Date())
        let components = calendar.dateComponents([.year, .month], from: today)
        return calendar.date(from: components) ?? today
    }

    // MARK: - Helper Methods

    /// Generate a range of months for scrolling (-12 to +12 months from today)
    /// All dates are normalized to start-of-day for consistent month comparison
    private func monthRange() -> [Date] {
        var months: [Date] = []
        let today = calendar.startOfDay(for: Date())

        for offset in -12...12 {
            if let month = calendar.date(byAdding: .month, value: offset, to: today) {
                // Extract just the year and month, set to 1st of month at start-of-day
                let components = calendar.dateComponents([.year, .month], from: month)
                if let normalized = calendar.date(from: components) {
                    months.append(normalized)
                }
            }
        }

        return months
    }
}

// MARK: - Single Month View

/// Displays a single month's calendar grid with date selection
private struct SingleMonthView: View {
    let month: Date
    @Binding var selectedDate: Date
    let scheduledDates: Set<Date>
    let shiftSymbols: [Date: String]
    let selectionMode: SelectionMode?
    let selectedDates: Set<Date>

    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    var body: some View {
        VStack(spacing: 8) {
            // Month/year header
            Text(dateFormatter.string(from: month))
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.top, 12)

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
                ForEach(daysInMonth(month)) { cell in
                    if let date = cell.date {
                        let isCurrentMonth = calendar.isDate(date, equalTo: month, toGranularity: .month)
                        let hasShift = scheduledDates.contains { scheduledDate in
                            calendar.isDate(date, inSameDayAs: scheduledDate)
                        }

                        if selectionMode == .add && !hasShift {
                            let isSelected = selectedDates.contains { selectedDate in
                                calendar.isDate(date, inSameDayAs: selectedDate)
                            }
                            EmptyDateCard(
                                date: date,
                                isSelected: isSelected,
                                isCurrentMonth: isCurrentMonth
                            ) {
                                // Selection dispatch handled by parent view
                            }
                        } else {
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
                        Color.clear
                            .frame(maxWidth: .infinity)
                            .frame(height: CustomCalendarView.cellHeight)
                            .opacity(0)
                    }
                }
            }
            .padding(12)
        }
    }

    /// Generate calendar cells for a month
    private func daysInMonth(_ month: Date) -> [CalendarCell] {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: month) ?? 1..<1
        let numDays = range.count
        let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth) - 1

        var days: [CalendarCell] = []
        var cellId = 0

        // Add empty cells for days before month starts
        for _ in 0..<firstWeekday {
            days.append(CalendarCell(index: cellId, date: nil))
            cellId += 1
        }

        // Add days of the month
        for day in 1...numDays {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(CalendarCell(index: cellId, date: date))
                cellId += 1
            }
        }

        // Add empty cells to fill the last week (always 6 rows × 7 columns = 42 cells)
        while days.count < 42 {
            days.append(CalendarCell(index: cellId, date: nil))
            cellId += 1
        }

        return days
    }
}

// MARK: - Calendar Cell Helper

/// Wrapper struct to provide unique identities for calendar cells
private struct CalendarCell: Identifiable {
    let id: Int
    let date: Date?

    init(index: Int, date: Date?) {
        self.id = index
        self.date = date
    }
}

// MARK: - Preview

#Preview("Scrollable Month View") {
    let calendar = Calendar.current
    let today = Date()
    let shiftDates = Set([
        today,
        calendar.date(byAdding: .day, value: 1, to: today)!,
        calendar.date(byAdding: .day, value: 5, to: today)!,
        calendar.date(byAdding: .day, value: 15, to: today)!,
        calendar.date(byAdding: .month, value: 1, to: today)!,
    ])

    var symbols: [Date: String] = [:]
    for date in shiftDates {
        symbols[date] = ["☀️", "🌙", "⭐", "🎯"].randomElement()!
    }

    return VStack(spacing: 0) {
        Text("Schedule")
            .fontWeight(.bold)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()

        ScrollableMonthView(
            selectedDate: .constant(today),
            displayedMonth: .constant(today),
            scheduledDates: shiftDates,
            shiftSymbols: symbols,
            selectionMode: nil,
            selectedDates: []
        )
        .background(Color(.systemGray6))

        Spacer()
    }
    .background(Color(.systemBackground))
}
