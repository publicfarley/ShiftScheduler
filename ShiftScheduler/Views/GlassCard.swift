import SwiftUI

/// A glassmorphic card component with blur effects and subtle borders
struct GlassCard<Content: View>: View {
    let content: Content
    let cornerRadius: CGFloat
    let blurMaterial: Material

    init(
        cornerRadius: CGFloat = 24,
        blurMaterial: Material = .ultraThinMaterial,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.blurMaterial = blurMaterial
        self.content = content()
    }

    var body: some View {
        content
            .padding()
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(blurMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    .shadow(color: .white.opacity(0.5), radius: 1, x: 0, y: -1)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(0.6),
                                        .clear,
                                        .white.opacity(0.2)
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
