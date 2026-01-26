import SwiftUI

/// Component for selecting bulk add mode
/// Allows user to choose between applying same shift to all dates or different shifts per date
struct BulkAddModeSelector: View {
    @Environment(\.reduxStore) var store
    @Environment(\.dismiss) var dismiss
    @Binding var currentStage: DateShiftAssignmentView.AssignmentStage

    private var isModeSelected: Bool {
        store.state.schedule.bulkAddMode == .sameShiftForAll ||
        store.state.schedule.bulkAddMode == .differentShiftPerDate
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Add Shifts to Multiple Dates")
                        .font(.system(.title2, design: .default))
                        .fontWeight(.semibold)

                    Text("Choose how you want to assign shifts to the selected dates")
                        .font(.system(.subheadline, design: .default))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)

                Divider()

                // Mode Selection
                VStack(spacing: 12) {
                    // Same Shift for All Option
                    ModeOptionCard(
                        isSelected: store.state.schedule.bulkAddMode == .sameShiftForAll,
                        title: "Same Shift for All",
                        description: "Apply the same shift type to all selected dates",
                        icon: "repeat",
                        action: {
                            Task {
                                await handleModeSelection(.sameShiftForAll)
                            }
                        }
                    )

                    // Different Shift Per Date Option
                    ModeOptionCard(
                        isSelected: store.state.schedule.bulkAddMode == .differentShiftPerDate,
                        title: "Different Shift Per Date",
                        description: "Assign different shift types to individual dates",
                        icon: "list.bullet.rectangle",
                        action: {
                            Task {
                                await handleModeSelection(.differentShiftPerDate)
                            }
                        }
                    )
                }
                .padding(16)

                Spacer()

                // Action Buttons
                VStack(spacing: 12) {
                    // Continue button - enabled when mode is selected
                    Button(action: {
                        currentStage = .assignmentDetails
                    }) {
                        Text("Continue")
                            .frame(maxWidth: .infinity)
                            .font(.system(.body, design: .default))
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(12)
                    }
                    .buttonStyle(.plain)
                    .background(isModeSelected ? Color.blue : Color.blue.opacity(0.5))
                    .cornerRadius(8)
                    .disabled(!isModeSelected)

                    // Cancel button
                    Button(action: {
                        Task {
                            await store.dispatch(action: .schedule(.bulkAddCancelled))
                        }
                    }) {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                            .font(.system(.body, design: .default))
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .padding(12)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(16)
            }
            .navigationTitle("Select Mode")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func handleModeSelection(_ newMode: BulkAddMode) async {
        // If mode has changed and there are existing assignments, show warning
        if store.state.schedule.bulkAddMode != newMode && !store.state.schedule.dateShiftAssignments.isEmpty {
            // Dispatch warning confirmation action
            await store.dispatch(action: .schedule(.switchModeWarningConfirmed(newMode: newMode)))
        } else {
            // No existing assignments, just change the mode
            await store.dispatch(action: .schedule(.bulkAddModeChanged(newMode)))
        }
    }
}

// MARK: - Mode Option Card

private struct ModeOptionCard: View {
    let isSelected: Bool
    let title: String
    let description: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(.blue)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(.headline, design: .default))
                            .foregroundColor(.primary)

                        Text(description)
                            .font(.system(.caption, design: .default))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "circle")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                    }
                }
                .padding(12)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(UIColor.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var stage: DateShiftAssignmentView.AssignmentStage = .modeSelection
        var body: some View {
            BulkAddModeSelector(currentStage: $stage)
        }
    }
    return PreviewWrapper()
}
