import SwiftUI

/// Wraps the Today section with a smooth entrance animation featuring fade and slide effects.
/// Animation triggers once on first appearance and respects accessibility settings.
struct AnimatedTodaySection<Content: View>: View {
    let content: Content

    @State private var opacity: Double = 0.0
    @State private var yOffset: CGFloat = 30
    @State private var hasAppeared = false

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .opacity(opacity)
            .offset(y: yOffset)
            .onAppear {
                // Respect accessibility reduce motion setting first
                guard !UIAccessibility.isReduceMotionEnabled else {
                    opacity = 1.0
                    yOffset = 0
                    hasAppeared = true
                    return
                }

                // Only animate on first appearance
                guard !hasAppeared else {
                    opacity = 1.0
                    yOffset = 0
                    return
                }
                hasAppeared = true

                // Trigger smooth entrance animation with project-standard timing
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                    opacity = 1.0
                    yOffset = 0
                }
            }
    }
}

/// Wraps the Tomorrow section with a staggered entrance animation featuring fade and slide effects.
/// Animation triggers after the Today section with a delay to create a cascading effect.
struct AnimatedTomorrowSection<Content: View>: View {
    let content: Content

    @State private var opacity: Double = 0.0
    @State private var yOffset: CGFloat = 30
    @State private var hasAppeared = false

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .opacity(opacity)
            .offset(y: yOffset)
            .onAppear {
                // Respect accessibility reduce motion setting first
                guard !UIAccessibility.isReduceMotionEnabled else {
                    opacity = 1.0
                    yOffset = 0
                    hasAppeared = true
                    return
                }

                // Only animate on first appearance
                guard !hasAppeared else {
                    opacity = 1.0
                    yOffset = 0
                    return
                }
                hasAppeared = true

                // Trigger staggered entrance animation with project-standard timing
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4)) {
                    opacity = 1.0
                    yOffset = 0
                }
            }
    }
}
