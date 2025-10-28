import SwiftUI
import OSLog

private let logger = Logger(subsystem: "com.workevents.ShiftScheduler", category: "AnimatedAppIcon")

/// An animated app icon with floating, bouncing, and rotation effects
struct AnimatedAppIcon: View {
    @State private var isFloating = false
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0
    @State private var particles: [BurstParticle] = []
    @State private var showParticles = false
    @AccessibilityFocusState private var isAccessibilityFocused: Bool

    let size: CGFloat
    let onTap: () -> Void

    init(size: CGFloat = 120, onTap: @escaping () -> Void = {}) {
        self.size = size
        self.onTap = onTap
    }

    var body: some View {
        ZStack {
            // Burst particles
            if showParticles {
                ForEach(particles) { particle in
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [particle.color, particle.color.opacity(0)],
                                startPoint: .center,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: particle.size, height: particle.size)
                        .offset(x: particle.x, y: particle.y)
                        .opacity(particle.opacity)
                        .scaleEffect(particle.scale)
                }
            }

            // Main icon with mesh gradient background
            ZStack {
                // Mesh gradient glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                .cyan.opacity(0.3),
                                .blue.opacity(0.2),
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: size * 0.8
                        )
                    )
                    .frame(width: size * 1.6, height: size * 1.6)
                    .blur(radius: 20)

                // Glass icon container
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: size, height: size)
                    .shadow(color: .cyan.opacity(0.3), radius: 15, x: 0, y: 5)
                    .shadow(color: .blue.opacity(0.2), radius: 25, x: 0, y: 10)
                    .overlay {
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(0.6),
                                        .clear,
                                        .white.opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    }

                // Icon symbol
                Image(systemName: "calendar.badge.clock")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size * 0.5, height: size * 0.5)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.cyan, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation))
            .offset(y: isFloating ? -10 : 10)
            .onTapGesture {
                triggerBurstAnimation()
                onTap()
            }
            .accessibilityLabel("App icon")
            .accessibilityHint("Tap for a fun animation")
            .accessibilityFocused($isAccessibilityFocused)
        }
        .frame(width: size * 2, height: size * 2)
        .onAppear {
            startFloatingAnimation()
        }
    }

    private func startFloatingAnimation() {
        // Check for reduced motion preference
        if UIAccessibility.isReduceMotionEnabled {
        // logger.debug("Reduced motion enabled, skipping icon animations")
            return
        }

        withAnimation(
            .easeInOut(duration: 2.5)
            .repeatForever(autoreverses: true)
        ) {
            isFloating = true
        }

        withAnimation(
            .linear(duration: 20)
            .repeatForever(autoreverses: false)
        ) {
            rotation = 360
        }
    }

    private func triggerBurstAnimation() {
        guard !UIAccessibility.isReduceMotionEnabled else {
        // logger.debug("Reduced motion enabled, skipping burst animation")
            return
        }

        // logger.debug("Triggering burst animation")

        // Scale bounce
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            scale = 1.3
        }

        Task {
            try await Task.sleep(nanoseconds: 0.15.seconds)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                scale = 1.0
            }
        }

        // Generate burst particles
        particles = (0..<24).map { index in
            let angle = (Double(index) / 24.0) * 2 * .pi
            let distance = size * 0.8

            return BurstParticle(
                x: cos(angle) * distance,
                y: sin(angle) * distance,
                size: CGFloat.random(in: 8...16),
                color: [.cyan, .blue, .purple, .pink].randomElement() ?? .cyan,
                opacity: 1.0,
                scale: 0.0
            )
        }

        showParticles = true

        // Animate particles outward
        withAnimation(.easeOut(duration: 0.6)) {
            for index in particles.indices {
                let angle = (Double(index) / 24.0) * 2 * .pi
                let distance = size * 1.5
                particles[index].x = cos(angle) * distance
                particles[index].y = sin(angle) * distance
                particles[index].opacity = 0
                particles[index].scale = 1.0
            }
        }

        // Clean up particles
        Task {
            try await Task.sleep(nanoseconds: 0.6.seconds)
            showParticles = false
            particles = []
        }
    }
}

struct BurstParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var color: Color
    var opacity: Double
    var scale: CGFloat
}
