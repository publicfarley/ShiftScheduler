import SwiftUI

/// Toast notification for displaying temporary messages with haptic feedback
struct ToastView: View {
    let message: String
    let icon: String
    let iconColor: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)
                .frame(width: 28, height: 28)

            Text(message)
                .font(.callout)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        )
        .padding(.horizontal, 16)
    }
}

/// Toast modifier for displaying temporary notifications
struct ToastModifier: ViewModifier {
    @Binding var toast: ToastMessage?

    func body(content: Content) -> some View {
        ZStack {
            content

            if let toast = toast {
                VStack {
                    Spacer()

                    ToastView(
                        message: toast.message,
                        icon: toast.icon,
                        iconColor: toast.iconColor
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        // Trigger haptic feedback
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(toast.feedbackType)

                        // Auto-dismiss after duration
                        Task {
                            try await Task.sleep(nanoseconds: toast.duration.seconds)
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                self.toast = nil
                            }
                        }
                    }

                    Spacer()
                        .frame(height: 100) // Space for tab bar
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: toast.id)
            }
        }
    }
}

/// Toast message model
struct ToastMessage: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let icon: String
    let iconColor: Color
    let feedbackType: UINotificationFeedbackGenerator.FeedbackType
    let duration: TimeInterval

    static func success(_ message: String, duration: TimeInterval = 2.0) -> ToastMessage {
        ToastMessage(
            message: message,
            icon: "checkmark.circle.fill",
            iconColor: .green,
            feedbackType: .success,
            duration: duration
        )
    }

    static func error(_ message: String, duration: TimeInterval = 3.0) -> ToastMessage {
        ToastMessage(
            message: message,
            icon: "exclamationmark.circle.fill",
            iconColor: .red,
            feedbackType: .error,
            duration: duration
        )
    }

    static func info(_ message: String, duration: TimeInterval = 2.0) -> ToastMessage {
        ToastMessage(
            message: message,
            icon: "info.circle.fill",
            iconColor: .blue,
            feedbackType: .success,
            duration: duration
        )
    }

    static func undo(_ message: String = "Action undone") -> ToastMessage {
        ToastMessage(
            message: message,
            icon: "arrow.uturn.backward.circle.fill",
            iconColor: .orange,
            feedbackType: .success,
            duration: 1.5
        )
    }

    static func redo(_ message: String = "Action redone") -> ToastMessage {
        ToastMessage(
            message: message,
            icon: "arrow.uturn.forward.circle.fill",
            iconColor: .blue,
            feedbackType: .success,
            duration: 1.5
        )
    }

    static func == (lhs: ToastMessage, rhs: ToastMessage) -> Bool {
        lhs.id == rhs.id
    }
}

/// View extension for easy toast usage
extension View {
    func toast(_ toast: Binding<ToastMessage?>) -> some View {
        modifier(ToastModifier(toast: toast))
    }
}
