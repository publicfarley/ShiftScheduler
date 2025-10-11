import SwiftUI

/// Wraps the Today section with a dramatic entrance animation featuring fade and slide effects.
/// Animation slides in from the left with dramatic motion and triggers once on first appearance, respecting accessibility settings.
struct AnimatedTodaySection<Content: View>: View {
    let content: Content

    @State private var opacity: Double = 0.0
    @State private var xOffset: CGFloat = -400
    @State private var scale: CGFloat = 0.85
    @State private var hasAppeared = false

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .opacity(opacity)
            .offset(x: xOffset)
            .scaleEffect(scale)
            .onAppear {
                // Respect accessibility reduce motion setting first
                guard !UIAccessibility.isReduceMotionEnabled else {
                    opacity = 1.0
                    xOffset = 0
                    scale = 1.0
                    hasAppeared = true
                    return
                }

                // Only animate on first appearance
                guard !hasAppeared else {
                    opacity = 1.0
                    xOffset = 0
                    scale = 1.0
                    return
                }
                hasAppeared = true

                // Trigger dramatic entrance animation with enhanced spring
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
                    opacity = 1.0
                    xOffset = 0
                    scale = 1.0
                }
            }
    }
}

/// Wraps the Tomorrow section with a dramatic staggered entrance animation featuring fade and slide effects.
/// Animation slides in from the right with dramatic motion and triggers after the Today section with a delay to create a cascading effect.
struct AnimatedTomorrowSection<Content: View>: View {
    let content: Content

    @State private var opacity: Double = 0.0
    @State private var xOffset: CGFloat = 400
    @State private var scale: CGFloat = 0.85
    @State private var hasAppeared = false

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .opacity(opacity)
            .offset(x: xOffset)
            .scaleEffect(scale)
            .onAppear {
                // Respect accessibility reduce motion setting first
                guard !UIAccessibility.isReduceMotionEnabled else {
                    opacity = 1.0
                    xOffset = 0
                    scale = 1.0
                    hasAppeared = true
                    return
                }

                // Only animate on first appearance
                guard !hasAppeared else {
                    opacity = 1.0
                    xOffset = 0
                    scale = 1.0
                    return
                }
                hasAppeared = true

                // Trigger dramatic staggered entrance animation with enhanced spring
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.35)) {
                    opacity = 1.0
                    xOffset = 0
                    scale = 1.0
                }
            }
    }
}
