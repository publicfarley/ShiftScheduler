import SwiftUI

/// Error screen displayed when app initialization fails
/// Prevents app startup and shows the error with a retry button
struct InitializationErrorView: View {
    @Environment(\.reduxStore) var reduxStore

    var errorMessage: String
    @State private var isRetrying = false

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemBackground),
                    Color(.systemGray6)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Error Icon
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                    .padding(.bottom, 8)

                // Error Title
                Text("Initialization Failed")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)

                // Error Message
                VStack(spacing: 12) {
                    Text("The app encountered an error during startup:")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.secondary)

                    Text(errorMessage)
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(.red)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .padding(.horizontal, 20)

                // Help Text
                VStack(spacing: 8) {
                    Text("Please ensure that:")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("You have sufficient storage space")
                                .font(.system(size: 13, weight: .regular))
                        }

                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("File permissions are correct")
                                .font(.system(size: 13, weight: .regular))
                        }

                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Calendar app is available")
                                .font(.system(size: 13, weight: .regular))
                        }
                    }
                    .foregroundColor(.secondary)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                .padding(.horizontal, 20)

                Spacer()

                // Retry Button
                Button {
                    isRetrying = true
                    Task {
                        await reduxStore.dispatch(action: .appLifecycle(.loadInitialData))
                        isRetrying = false
                    }
                } label: {
                    HStack {
                        if isRetrying {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }

                        Text(isRetrying ? "Retrying..." : "Try Again")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .disabled(isRetrying)
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
    }
}

#Preview {
    InitializationErrorView(errorMessage: "Failed to load locations: The file couldn't be opened.")
        .environment(\.reduxStore, Store(
            state: AppState(),
            reducer: appReducer,
            services: ServiceContainer(),
            middlewares: []
        ))
}
