import SwiftUI

/// Beautiful animated splash screen with whimsical symbol animations
struct SplashScreenView: View {
    @Environment(\.reduxStore) var store

    @State private var isAnimating = false
    @State private var showTitle = false
    @State private var symbolScale: CGFloat = 0.5
    @State private var symbolOpacity: Double = 0
    @State private var rotationDegrees: Double = 0
    @State private var pulseScale: CGFloat = 1.0

    // Individual symbol states for staggered animations
    @State private var calendarOffset: CGFloat = -200
    @State private var clockOffset: CGFloat = 200
    @State private var briefcaseOffset: CGFloat = -200
    @State private var locationOffset: CGFloat = 200

    var body: some View {
        ZStack {
            // Animated gradient background
            AnimatedGradientBackground()

            // Floating symbols arranged in a circle
            ZStack {
                // Center calendar icon - main feature
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 80, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Color.white.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(symbolScale * pulseScale)
                    .opacity(symbolOpacity)
                    .rotationEffect(.degrees(rotationDegrees))
                    .shadow(color: Color.white.opacity(0.5), radius: 20, x: 0, y: 0)

                // Orbiting symbols
                GeometryReader { geometry in
                    let center = CGPoint(
                        x: geometry.size.width / 2,
                        y: geometry.size.height / 2
                    )

                    // Clock symbol - top right
                    FloatingSymbol(
                        systemName: "clock.fill",
                        color: Color(red: 0.2, green: 0.7, blue: 0.9),
                        offset: clockOffset,
                        angle: 45,
                        center: center,
                        scale: symbolScale,
                        opacity: symbolOpacity
                    )

                    // Briefcase symbol - bottom right
                    FloatingSymbol(
                        systemName: "briefcase.fill",
                        color: Color(red: 0.9, green: 0.5, blue: 0.3),
                        offset: briefcaseOffset,
                        angle: 135,
                        center: center,
                        scale: symbolScale,
                        opacity: symbolOpacity
                    )

                    // Location symbol - bottom left
                    FloatingSymbol(
                        systemName: "mappin.circle.fill",
                        color: Color(red: 0.3, green: 0.8, blue: 0.6),
                        offset: locationOffset,
                        angle: 225,
                        center: center,
                        scale: symbolScale,
                        opacity: symbolOpacity
                    )

                    // Star/sparkle symbol - top left
                    FloatingSymbol(
                        systemName: "star.fill",
                        color: Color(red: 0.9, green: 0.7, blue: 0.3),
                        offset: calendarOffset,
                        angle: 315,
                        center: center,
                        scale: symbolScale,
                        opacity: symbolOpacity
                    )
                }
            }

            // App title
            VStack {
                Spacer()

                Text("ShiftScheduler")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Color.white.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                    .opacity(showTitle ? 1 : 0)
                    .offset(y: showTitle ? 0 : 20)

                Text("Manage your shifts with ease")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.8))
                    .opacity(showTitle ? 1 : 0)
                    .offset(y: showTitle ? 0 : 20)

                Spacer()
                    .frame(height: 100)
            }
        }
        .onAppear {
            startAnimations()
            // Load locations and shift types during splash screen
            Task {
                await store.dispatch(action: .appLifecycle(.loadInitialData))
            }
        }
    }

    private func startAnimations() {
        // Initial symbol appearance with spring animation
        withAnimation(.spring(response: 1.2, dampingFraction: 0.6, blendDuration: 0)) {
            symbolScale = 1.0
            symbolOpacity = 1.0
        }

        // Staggered floating symbols coming in
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7, blendDuration: 0).delay(0.1)) {
            clockOffset = 0
        }

        withAnimation(.spring(response: 0.8, dampingFraction: 0.7, blendDuration: 0).delay(0.2)) {
            briefcaseOffset = 0
        }

        withAnimation(.spring(response: 0.8, dampingFraction: 0.7, blendDuration: 0).delay(0.3)) {
            locationOffset = 0
        }

        withAnimation(.spring(response: 0.8, dampingFraction: 0.7, blendDuration: 0).delay(0.4)) {
            calendarOffset = 0
        }

        // Gentle rotation
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            rotationDegrees = 360
        }

        // Pulsing effect
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseScale = 1.1
        }

        // Title fade in
        withAnimation(.easeIn(duration: 0.8).delay(0.6)) {
            showTitle = true
        }
    }
}

/// Individual floating symbol with position animation
struct FloatingSymbol: View {
    let systemName: String
    let color: Color
    let offset: CGFloat
    let angle: Double
    let center: CGPoint
    let scale: CGFloat
    let opacity: Double

    @State private var isHovering = false

    var body: some View {
        let radians = angle * .pi / 180
        let radius: CGFloat = 100 + offset
        let x = center.x + cos(radians) * radius
        let y = center.y + sin(radians) * radius

        Image(systemName: systemName)
            .font(.system(size: 40, weight: .medium))
            .foregroundStyle(
                LinearGradient(
                    colors: [color, color.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .scaleEffect(scale * (isHovering ? 1.2 : 1.0))
            .opacity(opacity)
            .shadow(color: color.opacity(0.6), radius: 15, x: 0, y: 0)
            .position(x: x, y: y)
            .onAppear {
                // Gentle floating animation
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(Double(angle) / 180.0)) {
                    isHovering = true
                }
            }
    }
}

/// Animated gradient background with slow color shifting
struct AnimatedGradientBackground: View {
    @State private var animateGradient = false

    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.1, green: 0.2, blue: 0.4),
                Color(red: 0.2, green: 0.35, blue: 0.6),
                Color(red: 0.15, green: 0.4, blue: 0.7)
            ],
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                animateGradient = true
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
