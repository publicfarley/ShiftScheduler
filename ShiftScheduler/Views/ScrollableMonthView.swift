import SwiftUI

/// A horizontally scrollable calendar with full month views
/// Users can swipe left/right to navigate between months
/// Each month displays in full with all dates visible
struct ScrollableMonthView: View {
    @Binding var selectedDate: Date
    @Binding var displayedMonth: Date
    @Binding var scrollToDateTrigger: Date?
    let scheduledShiftsByDate: [Date: [ScheduledShift]]
    let selectionMode: SelectionMode?
    let selectedDates: Set<Date>

    @Environment(\.reduxStore) var store
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
                LazyHStack(spacing: 16) {
                    // Generate months: -12 to +12 months from today
                    ForEach(monthRange(), id: \.self) { month in
                        SingleMonthView(
                            month: month,
                            selectedDate: $selectedDate,
                            scheduledShiftsByDate: scheduledShiftsByDate,
                            selectionMode: selectionMode,
                            selectedDates: selectedDates
                        )
                        .background {
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(Color.blue.opacity(0.2), lineWidth: 1.5)
                        }
                        // Each month takes FULL container width minus padding
                        .containerRelativeFrame(.horizontal)
                        .id(month)
                    }
                }
                .scrollTargetLayout()
            }
            .safeAreaPadding(.horizontal, peekWidth)
            .scrollTargetBehavior(.viewAligned)
            .frame(height: calendarHeight + 40) // Add space for card padding
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
            .onChange(of: scrollToDateTrigger) { _, triggerDate in
                guard let date = triggerDate else { return }

                // Extract the month from the trigger date
                let components = calendar.dateComponents([.year, .month], from: date)
                if let targetMonth = calendar.date(from: components) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        scrollPosition = targetMonth
                        proxy.scrollTo(targetMonth, anchor: .leading)
                    }
                }

                // Dispatch scrollCompleted to clear the trigger
                Task {
                    await store.dispatch(action: .schedule(.scrollCompleted))
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
    let scheduledShiftsByDate: [Date: [ScheduledShift]]
    let selectionMode: SelectionMode?
    let selectedDates: Set<Date>

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
                let cells = daysInMonth(month)
                let dateIndices = Set(cells.compactMap { $0.date != nil ? $0.id : nil })
                ForEach(cells) { cell in
                    let cellEdges = gridEdgesForCell(at: cell.id, dateIndices: dateIndices)

                    if let date = cell.date {
                        let isCurrentMonth = calendar.isDate(date, equalTo: month, toGranularity: .month)
                        let shiftsForDate = scheduledShiftsByDate[date] ?? []
                        let hasShift = !shiftsForDate.isEmpty
                        let isAllDayShift = shiftsForDate.contains { $0.shiftType?.isAllDay == true }
                        let shiftSymbol = shiftsForDate.first?.shiftType?.symbol

                        if selectionMode == .add && !hasShift {
                            let isSelected = selectedDates.contains { selectedDate in
                                calendar.isDate(date, inSameDayAs: selectedDate)
                            }
                            EmptyDateCard(
                                date: date,
                                isSelected: isSelected,
                                isCurrentMonth: isCurrentMonth,
                                borderEdges: cellEdges
                            ) {
                                Task {
                                    await store.dispatch(action: .schedule(.toggleDateSelection(date)))
                                }
                            }
                        } else {
                            DayView(
                                date: date,
                                isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                                hasShift: hasShift,
                                isAllDayShift: isAllDayShift,
                                shiftSymbol: shiftSymbol,
                                isCurrentMonth: isCurrentMonth,
                                borderEdges: cellEdges
                            ) {
                                selectedDate = date
                            }
                        }
                    } else {
                        // Empty cell for dates outside current month
                        // No borders - adjacent date cells will draw their edges
                        Color.clear
                            .frame(maxWidth: .infinity)
                            .frame(height: CustomCalendarView.cellHeight)
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
    let mockLocation = Location(name: "Office", address: "123 Main St")
    let mockShiftTypeRegular = ShiftType(
        symbol: "🏢",
        duration: ShiftDuration.scheduled(
            from: HourMinuteTime(hour: 9, minute: 0),
            to: HourMinuteTime(hour: 17, minute: 0)
        ),
        title: "Office Shift",
        description: "Regular office hours",
        location: mockLocation
    )
    let mockShiftTypeAllDay = ShiftType(
        symbol: "🗓️",
        duration: .allDay,
        title: "All Day Event",
        description: "Full day meeting",
        location: mockLocation
    )

    let shiftTodayRegular = ScheduledShift(
        eventIdentifier: UUID().uuidString,
        shiftType: mockShiftTypeRegular,
        date: today
    )
    let shiftTomorrowAllDay = ScheduledShift(
        eventIdentifier: UUID().uuidString,
        shiftType: mockShiftTypeAllDay,
        date: calendar.date(byAdding: .day, value: 1, to: today)!
    )
    let shiftNextWeekRegular = ScheduledShift(
        eventIdentifier: UUID().uuidString,
        shiftType: mockShiftTypeRegular,
        date: calendar.date(byAdding: .day, value: 5, to: today)!
    )
    let shiftNextMonthRegular = ScheduledShift(
        eventIdentifier: UUID().uuidString,
        shiftType: mockShiftTypeRegular,
        date: calendar.date(byAdding: .month, value: 1, to: today)!
    )

    let scheduledShiftsByDate: [Date: [ScheduledShift]] = [
        today: [shiftTodayRegular],
        calendar.date(byAdding: .day, value: 1, to: today)!: [shiftTomorrowAllDay],
        calendar.date(byAdding: .day, value: 5, to: today)!: [shiftNextWeekRegular],
        calendar.date(byAdding: .month, value: 1, to: today)!: [shiftNextMonthRegular]
    ]

    return VStack(spacing: 0) {
        Text("Schedule")
            .fontWeight(.bold)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()

        ScrollableMonthView(
            selectedDate: .constant(today),
            displayedMonth: .constant(today),
            scrollToDateTrigger: .constant(nil),
            scheduledShiftsByDate: scheduledShiftsByDate,
            selectionMode: nil,
            selectedDates: []
        )
        .background(Color(.white))

        Spacer()
    }
    .background(Color(.systemBackground))
}
