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
            ZStack {
                // Background for selection state
                if isSelected {
                    // Selected state: filled circle with primary color
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .blue.opacity(0.8)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                        .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
                } else if isToday {
                    // Today state: orange background with subtle styling
                    Circle()
                        .fill(.orange.opacity(0.2))
                        .frame(width: 36, height: 36)
                } else {
                    // Default: subtle background for hover state
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 36, height: 36)
                        .opacity(0)
                }

                // Selection indicator when selected
                if isSelected {
                    VStack(spacing: 0) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                } else {
                    // Day number
                    Text(dayNumber)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(dayNumberColor)
                }
            }
        }
        .frame(height: 40)
        .opacity(isCurrentMonth ? 1.0 : 0.3)
        .disabled(!isCurrentMonth)
    }

    private var dayNumberColor: Color {
        if isToday {
            return .orange
        } else {
            return .primary
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
