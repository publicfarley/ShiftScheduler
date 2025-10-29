import SwiftUI

/// Visual indicator showing transition between two shifts
/// Displays an animated arrow that morphs from old shift color to new shift color
struct ShiftTransitionIndicator: View {
    let fromShift: ShiftType?
    let toShift: ShiftType?

    @State private var animateGlow = false
    @State private var swayRotation: Double = 300

    private var fromColor: Color {
        ShiftColorPalette.colorForShift(fromShift)
    }

    private var toColor: Color {
        ShiftColorPalette.colorForShift(toShift)
    }

    var body: some View {
        VStack(spacing: 8) {
            // Arrow icon with gradient - sways downward left to right
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 32))
                .foregroundStyle(
                    LinearGradient(
                        colors: [fromColor, toColor],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: toColor.opacity(animateGlow ? 0.6 : 0.3), radius: 8)
                .rotationEffect(.degrees(swayRotation))
                .scaleEffect(animateGlow ? 1.05 : 1.0)

            // Label
            Text("Switch To")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(
                    LinearGradient(
                        colors: [fromColor, toColor],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
        .padding(.vertical, 12)
        .onAppear {
            // Gentle pulsing glow
            withAnimation(AnimationPresets.pulseGlow) {
                animateGlow = true
            }

            // Gentle swaying motion between 300 and 200 degrees (pointing downward right and downward left)
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                swayRotation = 180
            }
            // Start from 300 degrees
            swayRotation = 300
        }
        .accessibilityLabel("Transition indicator")
        .accessibilityHint("Shows you are switching from one shift to another")
    }
}

/// Compact transition indicator for smaller spaces
struct CompactTransitionIndicator: View {
    let fromShift: ShiftType?
    let toShift: ShiftType?

    private var fromColor: Color {
        ShiftColorPalette.colorForShift(fromShift)
    }

    private var toColor: Color {
        ShiftColorPalette.colorForShift(toShift)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Left line
            Rectangle()
                .fill(fromColor)
                .frame(height: 2)

            // Arrow
            Image(systemName: "arrow.right")
                .font(.caption)
                .foregroundStyle(
                    LinearGradient(
                        colors: [fromColor, toColor],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            // Right line
            Rectangle()
                .fill(toColor)
                .frame(height: 2)
        }
        .accessibilityHidden(true) // Decorative element
    }
}

#if DEBUG
import SwiftUI

#Preview("Shift Transition Indicator") {
    let location = Location(id: UUID(), name: "Preview HQ", address: "123 Main St")
    let morning = ShiftType(
        id: UUID(),
        symbol: "☀️",
        duration: .scheduled(
            from: HourMinuteTime(hour: 7, minute: 0),
            to: HourMinuteTime(hour: 15, minute: 0)
        ),
        title: "Morning",
        description: "Morning shift",
        location: location
    )
    let evening = ShiftType(
        id: UUID(),
        symbol: "🌙",
        duration: .scheduled(
            from: HourMinuteTime(hour: 15, minute: 0),
            to: HourMinuteTime(hour: 23, minute: 0)
        ),
        title: "Evening",
        description: "Evening shift",
        location: location
    )
    ShiftTransitionIndicator(
        fromShift: morning,
        toShift: evening
    )
    .padding()
    .previewLayout(.sizeThatFits)
}
#endif

