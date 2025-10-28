import SwiftUI

/// A single particle with position and animation properties
struct Particle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var scale: CGFloat
    var opacity: Double
    var rotation: Angle
}

/// A particle system that creates floating sparkle effects
struct ParticleEffect: View {
    @State private var particles: [Particle] = []
    @State private var isAnimating = false

    let particleCount: Int
    let particleSize: CGFloat
    let animationDuration: TimeInterval
    let color: Color

    init(
        particleCount: Int = 12,
        particleSize: CGFloat = 8,
        animationDuration: TimeInterval = 2.0,
        color: Color = .yellow
    ) {
        self.particleCount = particleCount
        self.particleSize = particleSize
        self.animationDuration = animationDuration
        self.color = color
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Image(systemName: "sparkle")
                        .font(.system(size: particleSize))
                        .foregroundStyle(color)
                        .opacity(particle.opacity)
                        .scaleEffect(particle.scale)
                        .rotationEffect(particle.rotation)
                        .position(x: particle.x, y: particle.y)
                }
            }
            .onAppear {
                setupParticles(in: geometry.size)
                startAnimation()
            }
        }
    }

    private func setupParticles(in size: CGSize) {
        particles = (0..<particleCount).map { index in
            let angle = (Double(index) / Double(particleCount)) * 2 * .pi
            let radius = min(size.width, size.height) / 2 - 20

            return Particle(
                x: size.width / 2 + cos(angle) * radius,
                y: size.height / 2 + sin(angle) * radius,
                scale: Double.random(in: 0.3...0.7),
                opacity: Double.random(in: 0.3...0.7),
                rotation: .degrees(Double.random(in: 0...360))
            )
        }
    }

    private func startAnimation() {
        withAnimation(
            .easeInOut(duration: animationDuration)
            .repeatForever(autoreverses: true)
        ) {
            isAnimating = true
        }

        // Animate each particle with slight variations
        for index in particles.indices {
            animateParticle(at: index)
        }
    }

    private func animateParticle(at index: Int) {
        let delay = Double(index) * 0.1

        Task {
            try await Task.sleep(seconds: delay)
            withAnimation(
                .easeInOut(duration: animationDuration)
                .repeatForever(autoreverses: true)
            ) {
                particles[index].scale = Double.random(in: 0.5...1.2)
                particles[index].opacity = Double.random(in: 0.4...1.0)
                particles[index].rotation = .degrees(Double.random(in: 0...360))
            }
        }
    }
}
