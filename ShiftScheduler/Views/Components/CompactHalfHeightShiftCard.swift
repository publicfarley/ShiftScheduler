import SwiftUI

/// A specialized compact shift card for tomorrow's preview on the Today screen
/// Displays shift information at half the height of the standard UnifiedShiftCard
/// Provides essential details with optimized spacing and layout for a condensed preview
struct CompactHalfHeightShiftCard: View {
    let shift: ScheduledShift?
    let onTap: (() -> Void)?

    @State private var isPressed = false

    init(
        shift: ScheduledShift?,
        onTap: (() -> Void)? = nil
    ) {
        self.shift = shift
        self.onTap = onTap
    }

    private var cardColor: Color {
        guard let shiftType = shift?.shiftType else { return Color(red: 0.2, green: 0.35, blue: 0.5) }

        // Use professional, muted color palette
        let hash = shiftType.symbol.hashValue
        let professionalColors: [Color] = [
            Color(red: 0.2, green: 0.35, blue: 0.5),   // Professional Blue
            Color(red: 0.25, green: 0.4, blue: 0.35),  // Forest Green
            Color(red: 0.4, green: 0.35, blue: 0.3),   // Warm Brown
            Color(red: 0.35, green: 0.3, blue: 0.4),   // Slate Purple
            Color(red: 0.4, green: 0.3, blue: 0.35),   // Muted Burgundy
            Color(red: 0.3, green: 0.4, blue: 0.4)     // Teal
        ]
        return professionalColors[abs(hash) % professionalColors.count]
    }

    var body: some View {
        VStack(spacing: 0) {
            if let shift = shift, let shiftType = shift.shiftType {
                // Compact layout optimized for half-height display
                HStack(spacing: 12) {
                    // Symbol - smaller circle
                    Text(shiftType.symbol)
                        .font(.title3)
                        .foregroundColor(cardColor)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(cardColor.opacity(0.08))
                                .overlay(
                                    Circle()
                                        .stroke(cardColor.opacity(0.15), lineWidth: 1)
                                )
                        )

                    // Shift details - vertically stacked, compact
                    VStack(alignment: .leading, spacing: 2) {
                        Text(shiftType.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        // Time - primary information
                        HStack(spacing: 3) {
                            Image(systemName: "clock")
                                .font(.caption2)
                                .foregroundColor(cardColor)

                            Text(shiftType.timeRangeString)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(cardColor)
                        }

                        // Location - secondary information
                        let location = shiftType.location
                        HStack(spacing: 3) {
                            Image(systemName: "location")
                                .font(.caption2)
                                .foregroundColor(.secondary)

                            Text(location.name)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer()
                }
                .padding(12)
            } else {
                // Compact empty state
                HStack(spacing: 12) {
                    // Empty state icon
                    Image(systemName: "moon.stars")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(Color(.systemGray6))
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("No shift scheduled")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        Text("Day off")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()
                }
                .padding(12)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(cardColor, lineWidth: 2)
                )
                .shadow(color: cardColor.opacity(0.12), radius: 4, x: 0, y: 2)
        )
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onTapGesture {
            handleTap()
        }
    }

    private func handleTap() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()

        withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
            isPressed = true
        }

        Task {
            try await Task.sleep(seconds: 0.1)
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                isPressed = false
            }

            // Call the onTap handler if provided
            onTap?()
        }
    }
}

#Preview {
    let sampleLocation = Location(id: UUID(), name: "Main Office", address: "123 Main St")
    let sampleShiftType = ShiftType(
        id: UUID(),
        symbol: "🌆",
        duration: .scheduled(
            from: HourMinuteTime(hour: 14, minute: 0),
            to: HourMinuteTime(hour: 22, minute: 0)
        ),
        title: "Evening Shift",
        description: "Evening shift",
        location: sampleLocation
    )

    let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    let tomorrowShift = ScheduledShift(
        id: UUID(),
        eventIdentifier: UUID().uuidString,
        shiftType: sampleShiftType,
        date: tomorrowDate
    )

    VStack(spacing: 20) {
        Text("With Shift")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.secondary)

        CompactHalfHeightShiftCard(
            shift: tomorrowShift,
            onTap: { print("Tomorrow shift tapped!") }
        )

        Text("No Shift (Empty State)")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.secondary)
            .padding(.top, 8)

        CompactHalfHeightShiftCard(
            shift: nil,
            onTap: nil
        )

        Spacer()
    }
    .padding()
}
