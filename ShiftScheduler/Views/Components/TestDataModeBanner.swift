import SwiftUI

/// Slim, always-visible, non-interactive banner shown pinned to the top edge on every tab
/// while Test Data Mode is active. Overlaid in `ContentView`'s outer `ZStack`.
struct TestDataModeBanner: View {
    var body: some View {
        VStack {
            HStack(spacing: 6) {
                Text("🧪")
                Text("Test Data Mode")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.orange.opacity(0.9))
            )
            .foregroundColor(.white)
            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
            .padding(.top, 8)

            Spacer()
        }
        .allowsHitTesting(false)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Test Data Mode is active")
    }
}

#Preview {
    ZStack {
        Color(.systemBackground)
            .ignoresSafeArea()
        TestDataModeBanner()
    }
}
