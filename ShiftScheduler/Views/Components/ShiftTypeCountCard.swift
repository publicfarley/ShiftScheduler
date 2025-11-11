import SwiftUI

struct ShiftTypeCountCard: View {
    let shiftType: ShiftType
    let count: Int

    @State private var isPressed = false

    private var cardColor: Color {
        ShiftColorPalette.colorForShift(shiftType)
    }

    var body: some View {
        VStack(spacing: 12) {
            // Symbol in colored circle
            Text(shiftType.symbol)
                .font(.system(size: 32))
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    cardColor.opacity(0.15),
                                    cardColor.opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Circle()
                                .stroke(cardColor.opacity(0.3), lineWidth: 1.5)
                        )
                )

            // Shift Title
            Text(shiftType.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            // Count Display
            VStack(spacing: 4) {
                Text("\(count)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(cardColor)

                Text(count == 1 ? "shift" : "shifts")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }

            // Progress Indicator
            if count > 0 {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                cardColor.opacity(0.6),
                                cardColor.opacity(0.3)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 3)
                    .cornerRadius(1.5)
            }

            Spacer()
        }
        .frame(width: 115, height: 145)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    cardColor.opacity(0.3),
                                    cardColor.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(
                    color: cardColor.opacity(0.15),
                    radius: 8,
                    x: 0,
                    y: 4
                )
        )
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(
            .spring(response: 0.3, dampingFraction: 0.7),
            value: isPressed
        )
        .onLongPressGesture(minimumDuration: 0.01, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(shiftType.title), \(count) \(count == 1 ? "shift" : "shifts") scheduled")
        .accessibilityHint("Double tap to view these shifts in the schedule")
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    ShiftTypeCountCard(
        shiftType: ShiftType(
            id: UUID(),
            symbol: "🌅",
            duration: .scheduled(
                from: HourMinuteTime(hour: 9, minute: 0),
                to: HourMinuteTime(hour: 17, minute: 0)
            ),
            title: "Morning Shift",
            description: "Standard morning shift",
            location: Location(
                id: UUID(),
                name: "Main Office",
                address: "123 Main St"
            )
        ),
        count: 5
    )
}
