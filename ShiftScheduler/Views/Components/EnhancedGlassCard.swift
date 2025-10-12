import SwiftUI

/// Enhanced glassmorphic card with gradient borders and dynamic colors
/// Builds upon GlassCard with shift-aware color theming and premium visual effects
struct EnhancedGlassCard<Content: View>: View {
    let content: Content
    let cornerRadius: CGFloat
    let blurMaterial: Material
    let shiftType: ShiftType?
    let showBorder: Bool
    let showShadow: Bool

    init(
        cornerRadius: CGFloat = 20,
        blurMaterial: Material = .ultraThinMaterial,
        shiftType: ShiftType? = nil,
        showBorder: Bool = true,
        showShadow: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.blurMaterial = blurMaterial
        self.shiftType = shiftType
        self.showBorder = showBorder
        self.showShadow = showShadow
        self.content = content()
    }

    private var primaryColor: Color {
        ShiftColorPalette.colorForShift(shiftType)
    }

    private var glowColor: Color {
        ShiftColorPalette.glowColorForShift(shiftType)
    }

    var body: some View {
        content
            .padding()
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(blurMaterial)
                    .shadow(
                        color: showShadow ? .black.opacity(0.1) : .clear,
                        radius: 12,
                        x: 0,
                        y: 6
                    )
                    .shadow(
                        color: showShadow ? glowColor.opacity(0.2) : .clear,
                        radius: 8,
                        x: 0,
                        y: 4
                    )
                    .overlay {
                        if showBorder {
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
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
                        }
                    }
            }
    }
}

/// Enhanced glass card with full gradient background
/// Used for more prominent shift displays
struct EnhancedGlassCardGradient<Content: View>: View {
    let content: Content
    let cornerRadius: CGFloat
    let shiftType: ShiftType?

    init(
        cornerRadius: CGFloat = 20,
        shiftType: ShiftType? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.shiftType = shiftType
        self.content = content()
    }

    private var gradientColors: (Color, Color) {
        ShiftColorPalette.gradientColorsForShift(shiftType)
    }

    var body: some View {
        content
            .padding()
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [gradientColors.0, gradientColors.1],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(
                        color: gradientColors.0.opacity(0.3),
                        radius: 12,
                        x: 0,
                        y: 6
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(
                                .white.opacity(0.2),
                                lineWidth: 1
                            )
                    }
            }
    }
}
