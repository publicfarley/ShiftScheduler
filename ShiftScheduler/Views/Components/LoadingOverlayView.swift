import SwiftUI

/// Full-screen loading overlay with Liquid Glass effect
/// Displays a centered spinner with optional message
struct LoadingOverlayView: View {
    /// Optional loading message
    let message: String?

    var body: some View {
        ZStack {
            // Liquid Glass background
            Color.black.opacity(0.1)
                .blur(radius: 8)
                .ignoresSafeArea()

            // Content
            VStack(spacing: 24) {
                // Spinner
                ProgressView()
                    .scaleEffect(1.5, anchor: .center)
                    .tint(.blue)

                // Optional message
                if let message = message {
                    Text(message)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(32)
            .frame(maxWidth: 200)
        }
        .transition(.opacity)
        .accessibility(label: Text("Loading"))
        .accessibility(hint: Text(message ?? "Please wait"))
    }
}

#Preview {
    LoadingOverlayView(message: "Adding shift...")
}
