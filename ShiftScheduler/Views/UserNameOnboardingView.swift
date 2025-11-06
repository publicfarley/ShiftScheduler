import SwiftUI

/// Modal view that requires user to set their display name before using the app
/// This view blocks all interaction with the app until a valid name is entered
struct UserNameOnboardingView: View {
    @Environment(\.reduxStore) var store
    @State private var displayName: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        ZStack {
            // Dimmed background to indicate modal blocking
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            // Modal content
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)

                    Text("Welcome to Shift Scheduler")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Let's get started by setting your name")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)

                // Input section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your Name")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    TextField("Enter your full name", text: $displayName)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.go)
                        .onSubmit {
                            handleSave()
                        }

                    if showError {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }

                    Text("This is how your name will appear in shift history and change logs.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Action button
                Button(action: handleSave) {
                    HStack {
                        Image(systemName: "checkmark")
                        Text("Continue")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(displayName.trimmingCharacters(in: .whitespaces).isEmpty)

                Spacer()
            }
            .padding(32)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .padding(20)
            .dismissKeyboardOnTap()
        }
    }

    private func handleSave() {
        let trimmedName = displayName.trimmingCharacters(in: .whitespaces)

        // Validation
        guard !trimmedName.isEmpty else {
            errorMessage = "Please enter your name"
            showError = true
            return
        }

        guard trimmedName.count >= 2 else {
            errorMessage = "Name must be at least 2 characters"
            showError = true
            return
        }

        guard trimmedName.count <= 100 else {
            errorMessage = "Name must be less than 100 characters"
            showError = true
            return
        }

        // Clear error and dispatch action
        showError = false
        Task {
            await store.dispatch(action: .appLifecycle(.displayNameChanged(trimmedName)))
        }
    }
}

#Preview {
    UserNameOnboardingView()
}
