import SwiftUI

/// Centralized animation presets for consistent motion design
/// All animations respect accessibility settings (Reduced Motion)
struct AnimationPresets {

    // MARK: - Spring Animations

    /// Standard spring animation for most UI interactions
    /// Duration: ~0.4s, Natural bounce
    static let standardSpring = Animation.spring(response: 0.4, dampingFraction: 0.7)

    /// Quick spring for rapid interactions
    /// Duration: ~0.25s, Snappy feel
    static let quickSpring = Animation.spring(response: 0.25, dampingFraction: 0.8)

    /// Slow spring for deliberate, emphasized motions
    /// Duration: ~0.6s, Smooth and flowing
    static let slowSpring = Animation.spring(response: 0.6, dampingFraction: 0.75)

    /// Bouncy spring for playful interactions
    /// Duration: ~0.5s, High bounce
    static let bouncySpring = Animation.spring(response: 0.5, dampingFraction: 0.6)

    // MARK: - Easing Animations

    /// Smooth ease-in-out for linear property changes
    static let smooth = Animation.easeInOut(duration: 0.3)

    /// Quick fade for subtle transitions
    static let quickFade = Animation.easeOut(duration: 0.2)

    /// Slow fade for emphasis
    static let slowFade = Animation.easeInOut(duration: 0.5)

    // MARK: - Interactive Animations

    /// Animation for press/scale interactions
    /// - Parameter isPressed: Whether the element is currently pressed
    /// - Returns: Animation that respects Reduced Motion settings
    static func scalePress(isPressed: Bool) -> Animation {
        if UIAccessibility.isReduceMotionEnabled {
            return .easeOut(duration: 0.1)
        }
        return isPressed ? quickSpring : standardSpring
    }

    /// Animation for color transitions
    static let colorTransition = Animation.easeInOut(duration: 0.4)

    /// Animation for layout changes
    static let layoutChange = Animation.spring(response: 0.35, dampingFraction: 0.75)

    // MARK: - Sheet Animations

    /// Animation for sheet presentation
    static let sheetPresentation = Animation.spring(response: 0.45, dampingFraction: 0.8)

    /// Animation for sheet dismissal
    static let sheetDismissal = Animation.spring(response: 0.35, dampingFraction: 0.85)

    // MARK: - Shimmer/Glow Animations

    /// Continuous shimmer effect animation
    /// Returns an infinite repeating animation for shimmer effects
    static var shimmer: Animation {
        .easeInOut(duration: 2.0).repeatForever(autoreverses: false)
    }

    /// Pulse glow animation for emphasis
    /// Returns an infinite repeating animation for pulsing glows
    static var pulseGlow: Animation {
        .easeInOut(duration: 1.5).repeatForever(autoreverses: true)
    }

    // MARK: - Staggered Animations

    /// Create a staggered animation delay
    /// - Parameters:
    ///   - index: The index of the element in the sequence
    ///   - baseDelay: Base delay in seconds before first element animates
    ///   - increment: Delay increment between each element
    /// - Returns: Total delay for this element
    static func staggerDelay(index: Int, baseDelay: Double = 0.1, increment: Double = 0.05) -> Double {
        baseDelay + (Double(index) * increment)
    }

    // MARK: - Accessibility-Aware Animations

    /// Returns appropriate animation based on Reduced Motion setting
    /// - Parameter normalAnimation: Animation to use when Reduced Motion is off
    /// - Returns: Simple fade if Reduced Motion is on, otherwise the provided animation
    static func accessible(_ normalAnimation: Animation) -> Animation {
        if UIAccessibility.isReduceMotionEnabled {
            return .easeOut(duration: 0.2)
        }
        return normalAnimation
    }
}

// MARK: - Scale Effect Presets

extension View {

    /// Apply a standard press scale effect
    /// - Parameter isPressed: Whether the view is currently pressed
    /// - Returns: View with scale animation
    func pressScale(isPressed: Bool) -> some View {
        self.scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(AnimationPresets.scalePress(isPressed: isPressed), value: isPressed)
    }

    /// Apply a button press scale effect (more pronounced)
    /// - Parameter isPressed: Whether the button is currently pressed
    /// - Returns: View with scale animation
    func buttonPressScale(isPressed: Bool) -> some View {
        self.scaleEffect(isPressed ? 0.94 : 1.0)
            .animation(AnimationPresets.scalePress(isPressed: isPressed), value: isPressed)
    }
}

// MARK: - Timing Constants

extension AnimationPresets {

    /// Standard timing durations for consistent feel
    enum Duration {
        /// Very quick interaction (0.15s)
        static let veryQuick: Double = 0.15

        /// Quick interaction (0.25s)
        static let quick: Double = 0.25

        /// Standard interaction (0.4s)
        static let standard: Double = 0.4

        /// Slow, deliberate motion (0.6s)
        static let slow: Double = 0.6

        /// Very slow, emphasized motion (0.8s)
        static let verySlow: Double = 0.8
    }

    /// Delay constants for sequential animations
    enum Delay {
        /// Minimal stagger between elements
        static let minimal: Double = 0.05

        /// Standard stagger between elements
        static let standard: Double = 0.1

        /// Large stagger for emphasis
        static let large: Double = 0.15
    }
}
