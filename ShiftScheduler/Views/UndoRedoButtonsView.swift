import SwiftUI

/// Undo/Redo buttons view with visual feedback and animations
struct UndoRedoButtonsView: View {
    let canUndo: Bool
    let canRedo: Bool
    let onUndo: () async -> Void
    let onRedo: () async -> Void

    @State private var isUndoPressed = false
    @State private var isRedoPressed = false
    @State private var isUndoing = false
    @State private var isRedoing = false

    var body: some View {
        HStack(spacing: 12) {
            // Undo button
            UndoRedoButton(
                icon: "arrow.uturn.backward",
                color: .orange,
                isEnabled: canUndo,
                isPressed: $isUndoPressed,
                isLoading: isUndoing
            ) {
                await performUndo()
            }

            // Redo button
            UndoRedoButton(
                icon: "arrow.uturn.forward",
                color: .blue,
                isEnabled: canRedo,
                isPressed: $isRedoPressed,
                isLoading: isRedoing
            ) {
                await performRedo()
            }
        }
    }

    private func performUndo() async {
        guard !isUndoing else { return }
        isUndoing = true
        await onUndo()
        isUndoing = false
    }

    private func performRedo() async {
        guard !isRedoing else { return }
        isRedoing = true
        await onRedo()
        isRedoing = false
    }
}

/// Individual undo/redo button component
struct UndoRedoButton: View {
    let icon: String
    let color: Color
    let isEnabled: Bool
    @Binding var isPressed: Bool
    let isLoading: Bool
    let action: () async -> Void

    var body: some View {
        Button {
            Task {
                await performAction()
            }
        } label: {
            ZStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: isEnabled ? color : .gray))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isEnabled ? color : Color(.systemGray3))
                }
            }
            .frame(width: 40, height: 40)
            .background(
                Circle()
                    .fill(isEnabled ? color.opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        Circle()
                            .stroke(
                                isEnabled ? color.opacity(0.3) : Color(.systemGray4),
                                lineWidth: 1.5
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            .opacity(isEnabled ? 1.0 : 0.5)
        }
        .disabled(!isEnabled || isLoading)
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if isEnabled && !isLoading {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }

    private func performAction() async {
        guard isEnabled && !isLoading else { return }

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // Animate button press
        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
            isPressed = true
        }

        // Perform action
        await action()

        // Release button
        await MainActor.run {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                isPressed = false
            }
        }
    }
}

/// Compact undo/redo buttons for toolbar placement
struct CompactUndoRedoButtons: View {
    let canUndo: Bool
    let canRedo: Bool
    let onUndo: () async -> Void
    let onRedo: () async -> Void

    @State private var isUndoing = false
    @State private var isRedoing = false

    var body: some View {
        HStack(spacing: 16) {
            // Undo button
            Button {
                Task {
                    guard !isUndoing else { return }
                    isUndoing = true

                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()

                    await onUndo()
                    isUndoing = false
                }
            } label: {
                ZStack {
                    if isUndoing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                            .scaleEffect(0.7)
                    } else {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(canUndo ? .orange : Color(.systemGray3))
                    }
                }
                .frame(width: 28, height: 28)
            }
            .disabled(!canUndo || isUndoing)

            // Redo button
            Button {
                Task {
                    guard !isRedoing else { return }
                    isRedoing = true

                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()

                    await onRedo()
                    isRedoing = false
                }
            } label: {
                ZStack {
                    if isRedoing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            .scaleEffect(0.7)
                    } else {
                        Image(systemName: "arrow.uturn.forward")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(canRedo ? .blue : Color(.systemGray3))
                    }
                }
                .frame(width: 28, height: 28)
            }
            .disabled(!canRedo || isRedoing)
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        // Full size buttons
        UndoRedoButtonsView(
            canUndo: true,
            canRedo: true,
            onUndo: {},
            onRedo: {}
        )

        // Disabled buttons
        UndoRedoButtonsView(
            canUndo: false,
            canRedo: false,
            onUndo: {},
            onRedo: {}
        )

        // Compact buttons
        CompactUndoRedoButtons(
            canUndo: true,
            canRedo: true,
            onUndo: {},
            onRedo: {}
        )
    }
    .padding()
}
