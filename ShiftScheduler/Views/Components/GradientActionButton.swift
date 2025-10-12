import SwiftUI

/// Premium gradient button for primary actions
/// Features gradient fill, glow effects, and interactive press animations
struct GradientActionButton: View {
    let title: String
    let icon: String?
    let shiftType: ShiftType?
    let isEnabled: Bool
    let isLoading: Bool
    let action: () -> Void

    @State private var isPressed = false
    @State private var shimmerOffset: CGFloat = -200

    init(
        title: String,
        icon: String? = nil,
        shiftType: ShiftType? = nil,
        isEnabled: Bool = true,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.shiftType = shiftType
        self.isEnabled = isEnabled
        self.isLoading = isLoading
        self.action = action
    }

    private var gradientColors: (Color, Color) {
        if isEnabled, let shiftType = shiftType {
            return ShiftColorPalette.gradientColorsForShift(shiftType)
        } else {
            return (Color.gray, Color.gray.opacity(0.7))
        }
    }

    private var glowColor: Color {
        if isEnabled, let shiftType = shiftType {
            return ShiftColorPalette.glowColorForShift(shiftType)
        } else {
            return .clear
        }
    }

    var body: some View {
        Button(action: {
            if isEnabled && !isLoading {
                // Haptic feedback
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                action()
            }
        }) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.headline)
                    }

                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [gradientColors.0, gradientColors.1],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: isEnabled ? glowColor : .clear, radius: 12, x: 0, y: 6)
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                    }
            }
            .overlay {
                if isEnabled && !isLoading {
                    // Shimmer effect
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, .white.opacity(0.3), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 60)
                        .offset(x: shimmerOffset)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(AnimationPresets.scalePress(isPressed: isPressed), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isEnabled || isLoading)
        .onAppear {
            if isEnabled && !isLoading {
                withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: false)) {
                    shimmerOffset = 400
                }
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if isEnabled && !isLoading {
                        withAnimation(AnimationPresets.quickSpring) {
                            isPressed = true
                        }
                    }
                }
                .onEnded { _ in
                    withAnimation(AnimationPresets.quickSpring) {
                        isPressed = false
                    }
                }
        )
        .accessibilityLabel(title)
        .accessibilityHint(isEnabled ? "Double tap to \(title.lowercased())" : "Button disabled")
        .accessibilityAddTraits(.isButton)
    }
}

/// Secondary glass-style button for cancel/dismiss actions
struct GlassActionButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    @State private var isPressed = false

    init(
        title: String,
        icon: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.headline)
                }

                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
            }
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
                    }
            }
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(AnimationPresets.scalePress(isPressed: isPressed), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(AnimationPresets.quickSpring) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(AnimationPresets.quickSpring) {
                        isPressed = false
                    }
                }
        )
        .accessibilityLabel(title)
        .accessibilityHint("Double tap to \(title.lowercased())")
    }
}
