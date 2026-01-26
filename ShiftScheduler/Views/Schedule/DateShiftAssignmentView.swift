import SwiftUI

/// Main view for assigning shifts to multiple selected dates
/// Manages the flow: mode selection → date range / shift type selection → confirmation
struct DateShiftAssignmentView: View {
    @Environment(\.reduxStore) var store
    @Environment(\.dismiss) var dismiss

    // Track which stage of the flow we're in
    @State private var currentStage: AssignmentStage = .modeSelection
    @State private var showModeWarning = false
    @State private var pendingNewMode: BulkAddMode? = nil

    public enum AssignmentStage {
        case modeSelection
        case assignmentDetails
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Show current stage
                switch currentStage {
                case .modeSelection:
                    BulkAddModeSelector(currentStage: $currentStage)

                case .assignmentDetails:
                    AssignmentDetailsView(currentStage: $currentStage)
                }
            }

            // Mode switch warning dialog
            if showModeWarning {
                ModeWarningDialog(
                    newMode: pendingNewMode ?? .sameShiftForAll,
                    isPresented: $showModeWarning,
                    onConfirm: {
                        if let newMode = pendingNewMode {
                            Task {
                                await store.dispatch(action: .schedule(.bulkAddModeChanged(newMode)))
                                showModeWarning = false
                                pendingNewMode = nil
                            }
                        }
                    },
                    onCancel: {
                        showModeWarning = false
                        pendingNewMode = nil
                    }
                )
            }
        }
    }
}

// MARK: - Assignment Details View

/// Handles the actual assignment logic based on mode
private struct AssignmentDetailsView: View {
    @Environment(\.reduxStore) var store
    @Environment(\.dismiss) var dismiss
    @Binding var currentStage: DateShiftAssignmentView.AssignmentStage

    @State private var selectedShiftType: ShiftType? = nil
    @State private var assignmentNotes: String = ""
    @State private var showDateRangeWarning = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Button(action: { currentStage = .modeSelection }) {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left")
                                    .font(.system(.body, design: .default))

                                Text("Back")
                                    .font(.system(.body, design: .default))
                            }
                            .foregroundColor(.blue)
                        }

                        Spacer()

                        Text(store.state.schedule.selectionCount > 0 ? "\(store.state.schedule.selectionCount) selected" : "Select dates")
                            .font(.system(.caption, design: .default))
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                    }

                    Text("Assign Shifts")
                        .font(.system(.title2, design: .default))
                        .fontWeight(.semibold)

                    Text(modeDescription)
                        .font(.system(.subheadline, design: .default))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)

                Divider()

                // Content based on mode
                ScrollView {
                    VStack(spacing: 16) {
                        if store.state.schedule.bulkAddMode == .sameShiftForAll {
                            sameShiftForAllSection
                        } else {
                            differentShiftPerDateSection
                        }
                    }
                    .padding(16)
                }

                Spacer()

                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: confirmAssignment) {
                        Text("Confirm Assignment")
                            .frame(maxWidth: .infinity)
                            .font(.system(.body, design: .default))
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(12)
                    }
                    .buttonStyle(.plain)
                    .background(Color.blue)
                    .cornerRadius(8)
                    .disabled(!canConfirm)

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
            .navigationTitle("Assign Shifts")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var modeDescription: String {
        switch store.state.schedule.bulkAddMode {
        case .sameShiftForAll:
            return "Apply the same shift type to all \(store.state.schedule.selectionCount) selected dates"
        case .differentShiftPerDate:
            return "Assign different shift types to individual dates"
        }
    }

    // MARK: - Same Shift For All Section

    private var sameShiftForAllSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Shift Type Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Select Shift Type")
                    .font(.system(.subheadline, design: .default))
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(store.state.shiftTypes.shiftTypes, id: \.id) { shiftType in
                            ShiftTypeButton(
                                shiftType: shiftType,
                                isSelected: selectedShiftType?.id == shiftType.id,
                                action: {
                                    selectedShiftType = shiftType
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }

            // Notes Section (optional)
            VStack(alignment: .leading, spacing: 8) {
                Text("Add Notes (Optional)")
                    .font(.system(.subheadline, design: .default))
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                TextField("Reason for shift, special instructions, etc.", text: $assignmentNotes)
                    .font(.system(.body, design: .default))
                    .padding(12)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(8)
            }

            // Summary
            if let selectedShiftType = selectedShiftType {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Summary")
                        .font(.system(.subheadline, design: .default))
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Shift Type:")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(selectedShiftType.title)
                                .fontWeight(.semibold)
                        }

                        HStack {
                            Text("Dates:")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(store.state.schedule.selectionCount) dates")
                                .fontWeight(.semibold)
                        }

                        if !assignmentNotes.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Notes:")
                                    .foregroundColor(.secondary)
                                Text(assignmentNotes)
                                    .font(.system(.caption, design: .default))
                                    .lineLimit(2)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(8)
                }
            }
        }
    }

    // MARK: - Different Shift Per Date Section

    private var differentShiftPerDateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("You have \(store.state.schedule.selectedDates.count) dates selected")
                .font(.system(.subheadline, design: .default))
                .fontWeight(.semibold)

            Text("Select a shift type for each date using the date picker below")
                .font(.system(.caption, design: .default))
                .foregroundColor(.secondary)

            Divider()

            // Per-date shift picker will be shown in a separate component
            PerDateShiftPickerView()
        }
    }

    // MARK: - Helpers

    private var canConfirm: Bool {
        let hasSelection = store.state.schedule.selectionCount > 0

        if store.state.schedule.bulkAddMode == .sameShiftForAll {
            return hasSelection && selectedShiftType != nil
        } else {
            // In different shift per date mode, need all dates assigned
            return hasSelection && store.state.schedule.dateShiftAssignments.count == store.state.schedule.selectedDates.count
        }
    }

    private func confirmAssignment() {
        if store.state.schedule.bulkAddMode == .sameShiftForAll {
            if let selectedShiftType = selectedShiftType {
                Task {
                    await store.dispatch(action: .schedule(.bulkAddConfirmed(shiftType: selectedShiftType, notes: assignmentNotes)))
                    dismiss()
                }
            }
        } else {
            Task {
                await store.dispatch(action: .schedule(.bulkAddDifferentShiftsConfirmed(assignments: store.state.schedule.dateShiftAssignments, notes: assignmentNotes)))
                dismiss()
            }
        }
    }
}

// MARK: - Shift Type Button

private struct ShiftTypeButton: View {
    let shiftType: ShiftType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(shiftType.symbol)
                    .font(.system(size: 24))

                Text(shiftType.title)
                    .font(.system(.caption, design: .default))
                    .lineLimit(1)
            }
            .frame(minWidth: 70)
            .padding(12)
            .background(isSelected ? Color.blue : Color(UIColor.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(8)
        }
    }
}

// MARK: - Mode Warning Dialog

private struct ModeWarningDialog: View {
    let newMode: BulkAddMode
    @Binding var isPresented: Bool
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Switch Mode?")
                        .font(.system(.headline, design: .default))
                        .fontWeight(.semibold)

                    Text("Switching modes will clear all existing per-date shift assignments. Are you sure?")
                        .font(.system(.subheadline, design: .default))
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 12) {
                    Button(action: onCancel) {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                            .font(.system(.body, design: .default))
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .padding(12)
                    }
                    .buttonStyle(.bordered)

                    Button(action: onConfirm) {
                        Text("Switch")
                            .frame(maxWidth: .infinity)
                            .font(.system(.body, design: .default))
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(12)
                    }
                    .buttonStyle(.plain)
                    .background(Color.orange)
                    .cornerRadius(8)
                }
            }
            .padding(16)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
            .padding(16)
        }
    }
}

#Preview {
    DateShiftAssignmentView()
}
