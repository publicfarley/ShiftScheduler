import SwiftUI

/// Shape that draws borders on specific edges using filled rectangles
struct BorderEdges: Shape {
    let edges: Edge.Set
    let width: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        if edges.contains(.top) {
            path.addRect(CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: width))
        }

        if edges.contains(.bottom) {
            path.addRect(CGRect(x: rect.minX, y: rect.maxY - width, width: rect.width, height: width))
        }

        if edges.contains(.leading) {
            path.addRect(CGRect(x: rect.minX, y: rect.minY, width: width, height: rect.height))
        }

        if edges.contains(.trailing) {
            path.addRect(CGRect(x: rect.maxX - width, y: rect.minY, width: width, height: rect.height))
        }

        return path
    }
}

/// Calculates which border edges a cell should draw based on its position in a 7-column grid
/// - Parameters:
///   - cellIndex: The cell's index in the grid (0-41 for a 6-row, 7-column grid)
///   - dateIndices: Set of indices that have dates (empty cells should not draw borders)
/// - Returns: The set of edges this cell should draw
func gridEdgesForCell(at cellIndex: Int, dateIndices: Set<Int>) -> Edge.Set {
    // Empty cells draw no borders
    guard dateIndices.contains(cellIndex) else {
        return []
    }

    let row = cellIndex / 7
    let col = cellIndex % 7

    var edges: Edge.Set = [.trailing, .bottom]  // All date cells draw right and bottom

    // Draw top if first row OR cell above is empty
    if row == 0 || !dateIndices.contains(cellIndex - 7) {
        edges.insert(.top)
    }

    // Draw left if first column OR cell to the left is empty
    if col == 0 || !dateIndices.contains(cellIndex - 1) {
        edges.insert(.leading)
    }

    return edges
}

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
    let scheduledShiftsByDate: [Date: [ScheduledShift]]
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
    static let cellHeight: CGFloat = 54

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
                let cells = daysInMonth()
                let dateIndices = Set(cells.compactMap { $0.date != nil ? $0.id : nil })
                ForEach(cells) { cell in
                    let cellEdges = gridEdgesForCell(at: cell.id, dateIndices: dateIndices)

                    if let date = cell.date {
                        let isCurrentMonth = calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
                        let shiftsForDate = scheduledShiftsByDate[date] ?? []
                        let hasShift = !shiftsForDate.isEmpty
                        let isAllDayShift = shiftsForDate.contains { $0.shiftType?.isAllDay == true }
                        let shiftSymbol = shiftsForDate.first?.shiftType?.symbol

                        // Show EmptyDateCard in bulk add mode (.add) if no shift on that date
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
                            // Show normal DayView for dates with shifts or when not in bulk add mode
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
    let isAllDayShift: Bool
    let shiftSymbol: String?
    let isCurrentMonth: Bool
    let borderEdges: Edge.Set
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
                    .font(.system(size: 20, weight: .thin, design: .rounded))
                    .foregroundStyle(isCurrentMonth ? .black : .black.opacity(0.3))
                    .lineLimit(1)
                    .padding(.top, 8)
                    .padding(.leading, 8)

                Spacer(minLength: 0)

                // Shift symbol centered at bottom
                if let symbol = displaySymbol, hasShift {
                    Text(symbol)
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundStyle(.black)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .frame(height: CustomCalendarView.cellHeight)
            .fixedSize(horizontal: false, vertical: true)
            .clipped()
            .background(backgroundColor)
            .overlay(
                BorderEdges(edges: borderEdges, width: 1)
                    .fill(Color.black)
            )
            .overlay(
                isSelected ?
                    RoundedRectangle(cornerRadius: 0)
                        .strokeBorder(ScheduleViewColorPalette.selectedDateBorder, lineWidth: 2)
                    : nil
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(duration: 0.3, bounce: 0.15), value: isSelected)
        }
        .opacity(isCurrentMonth ? 1.0 : 0.5)
    }

    private var backgroundColor: some View {
        Group {
            if isToday {
                ScheduleViewColorPalette.todayBackground.opacity(0.80)
            } else if hasShift {
                if isAllDayShift {
                    ScheduleViewColorPalette.scheduledShiftBackground.opacity(0.40)
                } else {
                    ScheduleViewColorPalette.scheduledShiftBackground.opacity(0.80)
                }
            } else {
                Color.white
            }
        }
    }
}

#Preview {
    let today = Date()
    let date2 = Calendar.current.date(byAdding: .day, value: 2, to: today)!
    let date5 = Calendar.current.date(byAdding: .day, value: 5, to: today)!
    let date7 = Calendar.current.date(byAdding: .day, value: 7, to: today)!

    // Mock Location
    let mockLocation = Location(name: "Office", address: "123 Main St")

    // Mock ShiftTypes
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

    // Mock ScheduledShifts
    let shiftTodayRegular = ScheduledShift(
        eventIdentifier: UUID().uuidString,
        shiftType: mockShiftTypeRegular,
        date: today
    )

    let shiftDate2AllDay = ScheduledShift(
        eventIdentifier: UUID().uuidString,
        shiftType: mockShiftTypeAllDay,
        date: date2
    )

    let shiftDate5Regular = ScheduledShift(
        eventIdentifier: UUID().uuidString,
        shiftType: mockShiftTypeRegular,
        date: date5
    )
    
    // Shift with a long symbol to test truncation
    let shiftDate7LongSymbol = ShiftType(
        symbol: "LON",
        duration: .allDay,
        title: "All Day Event",
        description: "Full day meeting",
        location: mockLocation
    )

    let scheduledShiftsByDate: [Date: [ScheduledShift]] = [
        today: [shiftTodayRegular],
        date2: [shiftDate2AllDay],
        date5: [shiftDate5Regular],
        date7: [ScheduledShift(eventIdentifier: UUID().uuidString, shiftType: shiftDate7LongSymbol, date: date7)]
    ]

    CustomCalendarView(
        selectedDate: .constant(today),
        scheduledShiftsByDate: scheduledShiftsByDate,
        selectionMode: nil,
        selectedDates: []
    )
    .padding()
}
