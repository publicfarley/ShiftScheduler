import SwiftUI

/// Selection toolbar for multi-select operations
/// Displays selection count and provides actions: Delete/Add, Select All, Clear, Exit
struct SelectionToolbarView: View {
    let selectionCount: Int
    let canDelete: Bool
    let isDeleting: Bool
    let selectionMode: SelectionMode?
    let onDelete: () async -> Void
    let onAdd: () -> Void
    let onSelectAll: () -> Void
    let onClear: () -> Void
    let onExit: () -> Void

    @State private var isDeletePressed = false

    var body: some View {
        VStack(spacing: 0) {
            // Top bar with selection info and exit button
            HStack(spacing: 12) {
                // Selection count
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.headline)
                        .foregroundColor(.blue)

                    Text("\(selectionCount) selected")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }

                Spacer()

                // Exit button
                Button(action: onExit) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .border(Color(.systemGray5), width: 1)

            // Action buttons
            VStack(spacing: 12) {
                // Action button - Delete or Add based on selection mode
                if selectionMode == .add {
                    // Add button for bulk add mode
                    Button(action: onAdd) {
                        HStack(spacing: 10) {
                            Image(systemName: "plus.circle.fill")
                                .font(.headline)

                            Text("Add to \(selectionCount) Dates")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(selectionCount > 0 ? Color.blue : Color.blue.opacity(0.5))
                                .shadow(color: selectionCount > 0 ? Color.blue.opacity(0.4) : .clear, radius: 8, x: 0, y: 4)
                        }
                    }
                    .disabled(selectionCount == 0)
                } else {
                    // Delete button for delete mode
                    Button(action: {
                        Task {
                            await performDelete()
                        }
                    }) {
                        HStack(spacing: 10) {
                            if isDeleting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.9)
                            } else {
                                Image(systemName: "trash.fill")
                                    .font(.headline)
                            }

                            Text(isDeleting ? "Deleting..." : "Delete \(selectionCount)")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(isDeleting ? Color.red.opacity(0.7) : Color.red)
                                .shadow(color: canDelete && !isDeleting ? Color.red.opacity(0.4) : .clear, radius: 8, x: 0, y: 4)
                        }
                        .scaleEffect(isDeletePressed ? 0.96 : 1.0)
                        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isDeletePressed)
                    }
                    .disabled(!canDelete || isDeleting)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                if canDelete && !isDeleting {
                                    isDeletePressed = true
                                }
                            }
                            .onEnded { _ in
                                isDeletePressed = false
                            }
                    )
                }

                // Secondary action buttons
                HStack(spacing: 12) {
                    // Select All button
                    Button(action: onSelectAll) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.square.fill")
                                .font(.system(size: 16, weight: .semibold))

                            Text("Select All")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color(.systemGray5))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .strokeBorder(Color(.systemGray4), lineWidth: 1)
                                }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())

                    // Clear selection button
                    Button(action: onClear) {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.square.fill")
                                .font(.system(size: 16, weight: .semibold))

                            Text("Clear")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color(.systemGray5))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .strokeBorder(Color(.systemGray4), lineWidth: 1)
                                }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(12)
        }
        .background(Color(.systemBackground))
    }

    private func performDelete() async {
        guard canDelete && !isDeleting else { return }

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        await onDelete()
    }
}

#Preview {
    VStack(spacing: 20) {
        // Delete mode - 5 items selected
        SelectionToolbarView(
            selectionCount: 5,
            canDelete: true,
            isDeleting: false,
            selectionMode: .delete,
            onDelete: {},
            onAdd: {},
            onSelectAll: {},
            onClear: {},
            onExit: {}
        )

        // Deleting state
        SelectionToolbarView(
            selectionCount: 3,
            canDelete: true,
            isDeleting: true,
            selectionMode: .delete,
            onDelete: {},
            onAdd: {},
            onSelectAll: {},
            onClear: {},
            onExit: {}
        )

        // Bulk add mode - 2 dates selected
        SelectionToolbarView(
            selectionCount: 2,
            canDelete: false,
            isDeleting: false,
            selectionMode: .add,
            onDelete: {},
            onAdd: {},
            onSelectAll: {},
            onClear: {},
            onExit: {}
        )
    }
    .padding()
    .background(Color(.systemBackground))
}
