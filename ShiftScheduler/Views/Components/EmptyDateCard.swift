import SwiftUI

/// Card component for displaying and selecting empty (unscheduled) calendar dates
/// Used in bulk add mode to allow users to select multiple dates for shift addition
struct EmptyDateCard: View {
    let date: Date
    let isSelected: Bool
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
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onTap()
        }) {
            VStack(alignment: .leading, spacing: 4) {
                // Day number in top-left
                Text(dayNumber)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(isCurrentMonth ? .primary : .tertiary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .topLeading)

                Spacer()

                // Checkmark indicator centered at bottom when selected
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.accentColor)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(8)
            .frame(height: 64)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 2.5)
            )
            .shadow(
                color: isSelected ? Color.accentColor.opacity(0.2) : .clear,
                radius: 4,
                y: 2
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
                Color.accentColor.opacity(0.12)
            } else if isToday {
                Color.orange.opacity(0.15)
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
        onTap: {}
    )
    .padding()
}

#Preview("Selected") {
    EmptyDateCard(
        date: Date(),
        isSelected: true,
        isCurrentMonth: true,
        onTap: {}
    )
    .padding()
}

#Preview("Today (Not Selected)") {
    EmptyDateCard(
        date: Date(),
        isSelected: false,
        isCurrentMonth: true,
        onTap: {}
    )
    .padding()
}

#Preview("Today (Selected)") {
    EmptyDateCard(
        date: Date(),
        isSelected: true,
        isCurrentMonth: true,
        onTap: {}
    )
    .padding()
}

#Preview("Out of Month") {
    EmptyDateCard(
        date: Date(),
        isSelected: false,
        isCurrentMonth: false,
        onTap: {}
    )
    .padding()
}
