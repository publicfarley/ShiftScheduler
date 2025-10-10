import SwiftUI
import SwiftData

struct ShiftChangeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var shiftTypes: [ShiftType]

    let currentShift: ScheduledShift
    let onSwitch: (ShiftType, String?) async throws -> Void

    @State private var selectedShiftType: ShiftType?
    @State private var reason: String = ""
    @State private var showConfirmation = false
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showSuccess = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Liquid glass background
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .dismissKeyboardOnTap()

                VStack(spacing: 24) {
                    // Current shift preview
                    currentShiftSection

                    Divider()

                    // New shift picker
                    newShiftSection

                    // Optional reason field
                    reasonSection

                    Spacer()

                    // Action buttons
                    actionButtons
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding()
            }
            .dismissKeyboardOnTap()
            .navigationTitle("Switch Shift")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Switch Shift?", isPresented: $showConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Switch") {
                    Task {
                        await performSwitch()
                    }
                }
            } message: {
                if let newType = selectedShiftType {
                    Text("Are you sure you want to switch this shift to \(newType.symbol) \(newType.title)?")
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
            .overlay {
                if showSuccess {
                    successToast
                }
            }
        }
        .onAppear {
            selectedShiftType = shiftTypes.first { $0.id != currentShift.shiftType?.id }
        }
    }

    // MARK: - View Components

    private var currentShiftSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Current Shift")
                .font(.headline)
                .foregroundStyle(.secondary)

            if let shiftType = currentShift.shiftType {
                HStack(spacing: 12) {
                    Text(shiftType.symbol)
                        .font(.system(size: 40))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(shiftType.title)
                            .font(.title3)
                            .fontWeight(.semibold)

                        Text(shiftType.timeRangeString)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        if let location = shiftType.location {
                            Text(location.name)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var newShiftSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("New Shift Type")
                .font(.headline)
                .foregroundStyle(.secondary)

            Picker("Select Shift Type", selection: $selectedShiftType) {
                Text("Select a shift type")
                    .tag(nil as ShiftType?)

                ForEach(shiftTypes.filter { $0.id != currentShift.shiftType?.id }) { type in
                    HStack {
                        Text(type.symbol)
                        Text(type.title)
                    }
                    .tag(Optional(type))
                }
            }
            .pickerStyle(.menu)
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            if let selected = selectedShiftType {
                HStack(spacing: 12) {
                    Text(selected.symbol)
                        .font(.system(size: 40))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(selected.title)
                            .font(.title3)
                            .fontWeight(.semibold)

                        Text(selected.timeRangeString)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        if let location = selected.location {
                            Text(location.name)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.4), value: selectedShiftType)
    }

    private var reasonSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Reason (Optional)")
                .font(.headline)
                .foregroundStyle(.secondary)

            TextField("Why are you switching this shift?", text: $reason, axis: .vertical)
                .lineLimit(3...5)
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 16) {
            Button {
                dismiss()
            } label: {
                Text("Cancel")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button {
                showConfirmation = true
            } label: {
                if isProcessing {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    Text("Switch Shift")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .background(selectedShiftType != nil ? Color.blue : Color.gray)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .disabled(selectedShiftType == nil || isProcessing)
        }
    }

    private var successToast: some View {
        VStack {
            Spacer()
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Shift switched successfully")
                    .font(.headline)
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding()
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(duration: 0.4), value: showSuccess)
    }

    // MARK: - Actions

    private func performSwitch() async {
        guard let newShiftType = selectedShiftType else { return }

        isProcessing = true
        errorMessage = nil

        do {
            let reasonText = reason.isEmpty ? nil : reason
            try await onSwitch(newShiftType, reasonText)

            // Show success feedback
            await MainActor.run {
                showSuccess = true
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }

            // Dismiss after a delay
            try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            await MainActor.run {
                dismiss()
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isProcessing = false
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
        }
    }
}
