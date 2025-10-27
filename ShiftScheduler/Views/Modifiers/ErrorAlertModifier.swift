import SwiftUI

/// View modifier for displaying error alerts
/// Binds to a ScheduleError and presents an alert with recovery options
struct ErrorAlertModifier: ViewModifier {
    @Binding var error: ScheduleError?
    let onRetry: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: .constant(error != nil), presenting: error) { error in
                // Dismiss button
                Button("Dismiss") {
                    self.error = nil
                }

                // Retry button (if callback provided)
                if onRetry != nil {
                    Button("Retry") {
                        onRetry?()
                        self.error = nil
                    }
                }
            } message: { error in
                VStack(alignment: .leading, spacing: 8) {
                    Text(error.errorDescription ?? "An error occurred")
                    if let suggestion = error.recoverySuggestion {
                        Text(suggestion)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
    }
}

/// Extension to add error alert to any view
extension View {
    /// Present an error alert when error binding is non-nil
    /// - Parameters:
    ///   - error: Binding to optional ScheduleError
    ///   - onRetry: Optional callback for retry button
    func errorAlert(error: Binding<ScheduleError?>, onRetry: (() -> Void)? = nil) -> some View {
        modifier(ErrorAlertModifier(error: error, onRetry: onRetry))
    }
}

#Preview {
    VStack {
        Text("Press button to see error")

        Button("Show Error") {
            // Error would be bound from state in real usage
        }
    }
    .errorAlert(
        error: .constant(ScheduleError.duplicateShift(date: Date())),
        onRetry: { print("Retry tapped") }
    )
}
