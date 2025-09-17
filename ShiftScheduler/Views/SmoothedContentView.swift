import SwiftUI

/// A view that provides instant, flash-free content changes with content preservation
struct SmoothedContentView<Content: View>: View {
    let content: () -> Content
    let contentKey: String

    @State private var currentContent: AnyView?

    init(contentKey: String, @ViewBuilder content: @escaping () -> Content) {
        self.contentKey = contentKey
        self.content = content
    }

    var body: some View {
        ZStack {
            // Simply show the current content without any transition effects
            if let currentContent = currentContent {
                currentContent
            }
        }
        .onChange(of: contentKey) { _, _ in
            updateContent()
        }
        .onAppear {
            updateContent()
        }
    }

    private func updateContent() {
        // Instant update without any transition - prevents flash
        currentContent = AnyView(content())
    }
}

/// Extension for easy integration with data-driven content
extension View {
    func smoothedTransition(key: String) -> some View {
        SmoothedContentView(contentKey: key) {
            self
        }
    }
}