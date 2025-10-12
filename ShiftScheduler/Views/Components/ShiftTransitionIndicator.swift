import SwiftUI

/// Visual indicator showing transition between two shifts
/// Displays an animated arrow that morphs from old shift color to new shift color
struct ShiftTransitionIndicator: View {
    let fromShift: ShiftType?
    let toShift: ShiftType?

    @State private var animateGlow = false
    @State private var animateRotation = false

    private var fromColor: Color {
        ShiftColorPalette.colorForShift(fromShift)
    }

    private var toColor: Color {
        ShiftColorPalette.colorForShift(toShift)
    }

    var body: some View {
        VStack(spacing: 8) {
            // Arrow icon with gradient
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
                .rotationEffect(.degrees(animateRotation ? 360 : 0))
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

            // Very slow rotation for subtle movement
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                animateRotation = true
            }
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
