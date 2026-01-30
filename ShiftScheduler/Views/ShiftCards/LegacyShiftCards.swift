import SwiftUI

// MARK: - Tomorrow Shift Card (Legacy)

struct TomorrowShiftCard: View {
    let shift: ScheduledShift?
    @State private var isPressed = false

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
                // Has shift scheduled - Compact but elegant design for tomorrow
                VStack(spacing: 12) {
                    // Tomorrow label
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "sun.max.fill")
                                .font(.caption2)
                                .foregroundColor(.orange)

                            Text("Tomorrow")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(.orange.opacity(0.15))
                                .overlay(
                                    Capsule()
                                        .stroke(.orange.opacity(0.3), lineWidth: 1)
                                )
                        )

                        Spacer()
                    }

                    // Main content - compact professional layout
                    HStack(spacing: 12) {
                        // Symbol - simple design
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

                        // Shift details - compact layout
                        VStack(alignment: .leading, spacing: 4) {
                            Text(shiftType.title)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .lineLimit(1)

                            // Add missing description for tomorrow
                            if !shiftType.shiftDescription.isEmpty {
                                Text(shiftType.shiftDescription)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }

                            // Time - simple text
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.caption2)
                                    .foregroundColor(cardColor)

                                Text(shiftType.timeRangeString)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(cardColor)
                            }

                            // Location if available
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
                }
                .padding(16)
            } else {
                // No shift scheduled - Clean minimal state
                VStack(spacing: 12) {
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "sun.max.fill")
                                .font(.caption2)
                                .foregroundColor(.orange)

                            Text("Tomorrow")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(.orange.opacity(0.15))
                                .overlay(
                                    Capsule()
                                        .stroke(.orange.opacity(0.3), lineWidth: 1)
                                )
                        )

                        Spacer()
                    }

                    HStack(spacing: 12) {
                        // Empty state icon - professional
                        Image(systemName: "moon.stars")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(Color(.systemGray6))
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text("No shift scheduled")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)

                            Text("Another day off to look forward to")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                }
                .padding(16)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray5), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onTapGesture {
            // Add haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()

            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                isPressed = true
            }

            Task {
                try await Task.sleep(nanoseconds: 100_000_000)
                withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                    isPressed = false
                }
            }
        }
    }
}
