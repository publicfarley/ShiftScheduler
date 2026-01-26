import SwiftUI

/// Card component for displaying and selecting empty (unscheduled) calendar dates
/// Used in bulk add mode to allow users to select multiple dates for shift addition
struct EmptyDateCard: View {
    let date: Date
    let isSelected: Bool
    let isCurrentMonth: Bool
    let borderEdges: Edge.Set
    let onTap: () -> Void
    let assignedShiftSymbol: String? = nil  // Shift symbol to display as overlay in bulk add mode

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onTap()
        }) {
            ZStack {
                VStack(alignment: .leading, spacing: 0) {
                    // Day number in top-left
                    Text(dayNumber)
                        .font(.system(size: 20, weight: .thin, design: .rounded))
                        .foregroundStyle(isCurrentMonth
                            ? ScheduleViewColorPalette.cellTextPrimary
                            : ScheduleViewColorPalette.cellTextSecondary)
                        .lineLimit(1)
                        .padding(.top, 8)
                        .padding(.leading, 8)

                    Spacer(minLength: 0)

                    // Checkmark indicator centered at bottom when selected
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(ScheduleViewColorPalette.selectedDateBorder)
                            .frame(maxWidth: .infinity)
                            .padding(.bottom, 4)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .frame(height: CustomCalendarView.cellHeight)

                // Shift symbol overlay (when assigned in bulk add mode)
                if let symbol = assignedShiftSymbol {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text(symbol)
                                .font(.system(size: 32, weight: .semibold))
                                .opacity(0.7)
                            Spacer()
                        }
                        Spacer()
                    }
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .clipped()
            .background(backgroundColor)
            .overlay(
                BorderEdges(edges: borderEdges, width: 1)
                    .fill(ScheduleViewColorPalette.cellBorder)
            )
            .overlay(
                isToday ?
                    RoundedRectangle(cornerRadius: 0)
                        .strokeBorder(ScheduleViewColorPalette.todayBorder, lineWidth: 2)
                    : nil
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
        .disabled(!isCurrentMonth)
    }

    private var backgroundColor: some View {
        Group {
            if isSelected {
                ScheduleViewColorPalette.selectedEmptyDateBackground
            } else if isToday {
                ScheduleViewColorPalette.todayBackground
            } else {
                Color(.systemGray6)
            }
        }
    }
}

// MARK: - Preview

#Preview("Not Selected") {
    EmptyDateCard(
        date: Date(),
        isSelected: false,
        isCurrentMonth: true,
        borderEdges: [.top, .leading, .trailing, .bottom],
        onTap: {}
    )
    .padding()
}

#Preview("Selected") {
    EmptyDateCard(
        date: Date(),
        isSelected: true,
        isCurrentMonth: true,
        borderEdges: [.top, .leading, .trailing, .bottom],
        onTap: {}
    )
    .padding()
}

#Preview("Today (Not Selected)") {
    EmptyDateCard(
        date: Date(),
        isSelected: false,
        isCurrentMonth: true,
        borderEdges: [.top, .leading, .trailing, .bottom],
        onTap: {}
    )
    .padding()
}

#Preview("Today (Selected)") {
    EmptyDateCard(
        date: Date(),
        isSelected: true,
        isCurrentMonth: true,
        borderEdges: [.top, .leading, .trailing, .bottom],
        onTap: {}
    )
    .padding()
}

#Preview("Out of Month") {
    EmptyDateCard(
        date: Date(),
        isSelected: false,
        isCurrentMonth: false,
        borderEdges: [.top, .leading, .trailing, .bottom],
        onTap: {}
    )
    .padding()
}
