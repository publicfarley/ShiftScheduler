import SwiftUI

/// Enhanced shift preview card for ShiftChangeSheet
/// Displays shift information with gradient symbol, color-coded badges, and premium styling
struct EnhancedShiftPreviewCard: View {
    let shiftType: ShiftType
    let label: String?
    let showBadge: Bool

    @State private var shimmerOffset: CGFloat = -200

    init(
        shiftType: ShiftType,
        label: String? = nil,
        showBadge: Bool = false
    ) {
        self.shiftType = shiftType
        self.label = label
        self.showBadge = showBadge
    }

    private var primaryColor: Color {
        ShiftColorPalette.colorForShift(shiftType)
    }

    private var gradientColors: (Color, Color) {
        ShiftColorPalette.gradientColorsForShift(shiftType)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Label badge if provided
            if let label = label, showBadge {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: labelIcon)
                            .font(.caption2)
                            .foregroundStyle(.white)

                        Text(label)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [gradientColors.0, gradientColors.1],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: primaryColor.opacity(0.3), radius: 4, x: 0, y: 2)
                    )

                    Spacer()
                }
            }

            // Main content
            HStack(spacing: 16) {
                // Large gradient symbol
                Text(shiftType.symbol)
                    .font(.system(size: 56))
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(width: 88, height: 88)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [gradientColors.0, gradientColors.1],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                Circle()
                                    .stroke(.white.opacity(0.2), lineWidth: 2)
                            )
                            .shadow(color: primaryColor.opacity(0.4), radius: 12, x: 0, y: 6)
                    )

                // Shift details
                VStack(alignment: .leading, spacing: 10) {
                    Text(shiftType.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)

                    if !shiftType.shiftDescription.isEmpty {
                        Text(shiftType.shiftDescription)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    // Time badge with gradient
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.caption)
                            .foregroundStyle(.white)

                        Text(shiftType.timeRangeString)
                            .font(.callout)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [gradientColors.0, gradientColors.1],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: primaryColor.opacity(0.3), radius: 4, x: 0, y: 2)
                    )

                    // Location if available
                    if let location = shiftType.location {
                        HStack(spacing: 6) {
                            Image(systemName: "location.fill")
                                .font(.caption)
                                .foregroundStyle(primaryColor)

                            Text(location.name)
                                .font(.callout)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    primaryColor.opacity(0.4),
                                    .clear,
                                    primaryColor.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
                .shadow(color: primaryColor.opacity(0.2), radius: 8, x: 0, y: 4)
        }
        .overlay(
            // Subtle shimmer effect
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.1), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 80)
                .offset(x: shimmerOffset)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .onAppear {
                    withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: false)) {
                        shimmerOffset = 400
                    }
                }
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label ?? "Shift"): \(shiftType.title), \(shiftType.timeRangeString)")
    }

    private var labelIcon: String {
        guard let label = label else { return "circle.fill" }
        switch label.lowercased() {
        case "current": return "circle.fill"
        case "new": return "sparkles"
        default: return "circle.fill"
        }
    }
}
