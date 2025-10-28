
import SwiftUI

struct AboutView: View {
    // Animation states
    @State private var titleAppeared = false
    @State private var creatorAppeared = false
    @State private var roleAppeared = false
    @State private var descriptionAppeared = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Animated app icon with particles
                    ZStack {
                        // Background particles
                        ParticleEffect(
                            particleCount: 12,
                            particleSize: 10,
                            animationDuration: 3.0,
                            color: .cyan.opacity(0.6)
                        )
                        .frame(width: 200, height: 200)

                        AnimatedAppIcon(size: 120) {
                            // App icon tapped
                        }
                    }
                    .padding(.bottom, 30)

                    // App name with staggered animation
                    Text("Shift Scheduler")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.cyan, .blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .offset(y: titleAppeared ? 0 : 30)
                        .opacity(titleAppeared ? 1 : 0)
                        .padding(.bottom, 20)

                    // Creator card with glass effect
                    GlassCard(cornerRadius: 20, blurMaterial: .ultraThinMaterial) {
                        VStack(spacing: 12) {
                            HStack(spacing: 8) {
                                SparkleIcon()

                                Text("Created by Farley Caesar")
                                    .font(.headline)
                                    .fontWeight(.semibold)

                                SparkleIcon()
                            }
                            .frame(maxWidth: .infinity)

                            Text("Developer")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .offset(y: roleAppeared ? 0 : 20)
                                .opacity(roleAppeared ? 1 : 0)
                        }
                    }
                    .padding(.horizontal, 24)
                    .offset(y: creatorAppeared ? 0 : 30)
                    .opacity(creatorAppeared ? 1 : 0)
                    .padding(.bottom, 24)

                    // Description card with glass effect
                    GlassCard(cornerRadius: 20, blurMaterial: .regularMaterial) {
                        VStack(spacing: 16) {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar.badge.checkmark")
                                    .foregroundStyle(.cyan)
                                Text("Schedule Management")
                                    .font(.headline)
                            }

                            Text("Streamline your work schedule management with intuitive shift tracking and calendar integration")
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.primary)

                            HStack(spacing: 20) {
                                FeatureBadge(icon: "clock.fill", text: "Time Tracking")
                                FeatureBadge(icon: "calendar", text: "Calendar Sync")
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal, 24)
                    .offset(y: descriptionAppeared ? 0 : 30)
                    .opacity(descriptionAppeared ? 1 : 0)
                    .padding(.bottom, 40)

                    Spacer()
                        .frame(height: 40)
                }
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                triggerStaggeredAnimations()
            }
        }
    }

    private func triggerStaggeredAnimations() {
        guard !UIAccessibility.isReduceMotionEnabled else {
            // Immediately show all elements if reduced motion is enabled
            titleAppeared = true
            creatorAppeared = true
            roleAppeared = true
            descriptionAppeared = true
            return
        }

        // Stagger animations with spring effects
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
            titleAppeared = true
        }

        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4)) {
            creatorAppeared = true
        }

        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5)) {
            roleAppeared = true
        }

        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6)) {
            descriptionAppeared = true
        }
    }
}

// MARK: - Feature Badge Component

struct FeatureBadge: View {
    let icon: String
    let text: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.cyan, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 40, height: 40)
                .background {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .shadow(color: .cyan.opacity(0.2), radius: 4, x: 0, y: 2)
                }

            Text(text)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Sparkle Icon Component

struct SparkleIcon: View {
    @State private var isAnimating = false
    @State private var scale: CGFloat = 1.0
    @State private var rotation: Double = 0

    var body: some View {
        Image(systemName: "sparkle")
            .foregroundStyle(.yellow)
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                guard !UIAccessibility.isReduceMotionEnabled else { return }

                withAnimation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
                ) {
                    scale = 1.2
                }

                withAnimation(
                    .linear(duration: 3.0)
                    .repeatForever(autoreverses: false)
                ) {
                    rotation = 360
                }
            }
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
