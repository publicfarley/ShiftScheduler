import SwiftUI

/// A horizontally scrollable month carousel for intuitive month navigation
/// Users can swipe left/right between months with smooth snapping behavior
struct HorizontalMonthScrollView: View {
    @Binding var selectedMonth: Date
    let scheduledDates: Set<Date>
    let shiftSymbols: [Date: String]
    let selectionMode: SelectionMode?
    let selectedDates: Set<Date>
    @Binding var selectedDate: Date

    @State private var scrollPosition: Date?
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    var body: some View {
        VStack(spacing: 0) {
            // Horizontal month carousel
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        // Generate months: -12 to +12 months from today
                        ForEach(monthRange(), id: \.self) { month in
                            MonthCardView(
                                month: month,
                                isSelected: calendar.isDate(month, equalTo: selectedMonth, toGranularity: .month),
                                shiftCount: shiftCountForMonth(month),
                                dateFormatter: dateFormatter
                            )
                            .frame(width: 140)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    selectedMonth = month
                                    scrollPosition = month
                                    proxy.scrollTo(month, anchor: .center)
                                }
                            }
                            .id(month)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .scrollTargetLayout()
                }
                .contentMargins(.horizontal, 0, for: .scrollContent)
                .scrollTargetBehavior(.viewAligned)
                .onAppear {
                    scrollPosition = selectedMonth
                    proxy.scrollTo(selectedMonth, anchor: .center)
                }
                .onChange(of: selectedMonth) { _, newMonth in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        scrollPosition = newMonth
                        proxy.scrollTo(newMonth, anchor: .center)
                    }
                }
            }

            Divider()

            // Calendar grid for selected month
            VStack(spacing: 8) {
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

                // Calendar grid - 6 rows × 7 columns
                let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
                LazyVGrid(columns: columns, spacing: 0) {
                    ForEach(daysInMonth(selectedMonth)) { cell in
                        if let date = cell.date {
                            let isCurrentMonth = calendar.isDate(date, equalTo: selectedMonth, toGranularity: .month)
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

    /// Count shifts in a given month
    private func shiftCountForMonth(_ month: Date) -> Int {
        let calendar = Calendar.current
        return scheduledDates.filter { date in
            calendar.isDate(date, equalTo: month, toGranularity: .month)
        }.count
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

// MARK: - Month Card View

/// Individual month card in the horizontal carousel
private struct MonthCardView: View {
    let month: Date
    let isSelected: Bool
    let shiftCount: Int
    let dateFormatter: DateFormatter

    var body: some View {
        VStack(spacing: 8) {
            // Month/Year header
            Text(dateFormatter.string(from: month))
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(isSelected ? .white : .primary)
                .lineLimit(1)

            // Shift count
            VStack(spacing: 2) {
                Text("\(shiftCount)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(isSelected ? .white : .blue)

                Text(shiftCount == 1 ? "shift" : "shifts")
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }

            Spacer()

            // Mini calendar indicator (3 dots showing shift distribution)
            HStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(isSelected ? Color.white : Color.blue.opacity(0.6))
                        .frame(width: 4, height: 4)
                        .opacity(index < min(shiftCount, 3) ? 1 : 0.3)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(12)
        .background(
            Group {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.blue)
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                        .border(Color(.systemGray5), width: 1)
                }
            }
        )
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

#Preview("Horizontal Month Scroll") {
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

        HorizontalMonthScrollView(
            selectedMonth: .constant(today),
            scheduledDates: shiftDates,
            shiftSymbols: symbols,
            selectionMode: nil,
            selectedDates: [],
            selectedDate: .constant(today)
        )
        .background(Color(.systemBackground))

        Spacer()
    }
    .background(Color(.systemBackground))
}
