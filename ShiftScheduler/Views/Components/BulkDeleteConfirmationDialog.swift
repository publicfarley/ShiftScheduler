import SwiftUI

/// Confirmation dialog for bulk shift deletion
/// Shows the number of shifts to be deleted and provides Confirm/Cancel options
struct BulkDeleteConfirmationDialog: View {
    let count: Int
    let isPresented: Binding<Bool>
    let onConfirm: () async -> Void
    let onCancel: () -> Void

    @State private var isConfirming = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.orange)

                VStack(spacing: 8) {
                    Text("Delete Shifts?")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text("You're about to delete \(count) \(count == 1 ? "shift" : "shifts"). This action can be undone.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))

            // Action buttons
            VStack(spacing: 12) {
                // Confirm button - destructive
                Button(action: {
                    Task {
                        isConfirming = true
                        await onConfirm()
                        isConfirming = false
                        isPresented.wrappedValue = false
                    }
                }) {
                    HStack(spacing: 10) {
                        if isConfirming {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.9)
                        } else {
                            Image(systemName: "trash.fill")
                                .font(.headline)
                        }

                        Text(isConfirming ? "Deleting..." : "Delete \(count) \(count == 1 ? "Shift" : "Shifts")")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(isConfirming ? Color.red.opacity(0.7) : Color.red)
                    )
                }
                .disabled(isConfirming)

                // Cancel button
                Button(action: {
                    onCancel()
                    isPresented.wrappedValue = false
                }) {
                    Text("Cancel")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(.systemGray5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .strokeBorder(Color(.systemGray4), lineWidth: 1)
                                )
                        )
                }
                .disabled(isConfirming)
            }
            .padding(16)
        }
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .padding(16)
        .shadow(color: .black.opacity(0.2), radius: 16, x: 0, y: 8)
    }
}

// MARK: - Alert Modifier
extension View {
    /// Presents a bulk delete confirmation dialog
    func bulkDeleteConfirmationAlert(
        isPresented: Binding<Bool>,
        count: Int,
        onConfirm: @escaping () async -> Void,
        onCancel: @escaping () -> Void
    ) -> some View {
        ZStack {
            self

            if isPresented.wrappedValue {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        onCancel()
                        isPresented.wrappedValue = false
                    }

                VStack {
                    Spacer()

                    BulkDeleteConfirmationDialog(
                        count: count,
                        isPresented: isPresented,
                        onConfirm: onConfirm,
                        onCancel: onCancel
                    )

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isPresented.wrappedValue)
    }
}

#Preview {
    ZStack {
        Color(.systemBackground)
            .ignoresSafeArea()

        VStack(spacing: 20) {
            Text("Multiple Shifts")
                .font(.headline)

            BulkDeleteConfirmationDialog(
                count: 5,
                isPresented: Binding(
                    get: { true },
                    set: { _ in }
                ),
                onConfirm: {},
                onCancel: {}
            )

            Spacer()

            Text("Single Shift")
                .font(.headline)

            BulkDeleteConfirmationDialog(
                count: 1,
                isPresented: Binding(
                    get: { true },
                    set: { _ in }
                ),
                onConfirm: {},
                onCancel: {}
            )
        }
        .padding()
    }
}
