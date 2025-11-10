import SwiftUI

/// View for selecting a shift type and adding optional notes during bulk add operations
/// Provides a focused interface for users to confirm their shift type choice for multiple selected dates
struct ShiftTypeSelectionView: View {
    @Environment(\.reduxStore) var store
    @Environment(\.dismiss) var dismiss
    @Binding var isPresented: Bool

    let availableShiftTypes: [ShiftType]
    let selectedDateCount: Int
    let onConfirm: (ShiftType, String) async -> Void
    let onDismiss: () -> Void

    @State private var selectedShiftType: ShiftType?
    @State private var notes: String = ""
    @State private var isConfirming = false
    @FocusState private var isNotesFocused: Bool

    var isFormValid: Bool {
        selectedShiftType != nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.98, green: 0.98, blue: 1.0),
                        Color(red: 0.95, green: 0.97, blue: 1.0)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // MARK: - Header Information
                        VStack(spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "calendar.badge.plus")
                                    .font(.title3)
                                    .foregroundColor(.blue)

                                Text("Bulk Add")
                                    .font(.headline)
                                    .fontWeight(.semibold)

                                Spacer()

                                Text("\(selectedDateCount) dates")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.7))
                                    .cornerRadius(6)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .strokeBorder(
                                                LinearGradient(
                                                    colors: [.blue.opacity(0.3), .clear],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                            )
                        }

                        // MARK: - Shift Type Selection
                        if !availableShiftTypes.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Select Shift Type")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)

                                // Scrollable list of shift types
                                VStack(spacing: 8) {
                                    ForEach(availableShiftTypes, id: \.id) { shiftType in
                                        ShiftTypeOptionCard(
                                            shiftType: shiftType,
                                            isSelected: selectedShiftType?.id == shiftType.id,
                                            onTap: {
                                                withAnimation(.easeOut(duration: 0.2)) {
                                                    selectedShiftType = shiftType
                                                }
                                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            }
                                        )
                                    }
                                }
                            }
                        } else {
                            // Empty state
                            VStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.orange)
                                Text("No Shift Types Available")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("Create a shift type first in Shift Types view")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .strokeBorder(.orange.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }

                        // MARK: - Shift Preview
                        if let shiftType = selectedShiftType {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Shift Preview")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)

                                ShiftDisplayCard(
                                    shiftType: shiftType,
                                    date: Date(),
                                    label: "Bulk Add Shift",
                                    showBadge: true
                                )
                                .transition(
                                    .asymmetric(
                                        insertion: .scale(scale: 0.95).combined(with: .opacity),
                                        removal: .scale(scale: 0.98).combined(with: .opacity)
                                    )
                                )
                            }
                        }

                        // MARK: - Notes Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Notes (Optional)")
                                .font(.headline)
                                .foregroundStyle(.secondary)

                            TextEditor(text: $notes)
                                .focused($isNotesFocused)
                                .frame(minHeight: 80, maxHeight: 120)
                                .padding(12)
                                .font(.body)
                                .scrollContentBackground(.hidden)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .strokeBorder(
                                                    isNotesFocused
                                                        ? ShiftColorPalette.colorForShift(selectedShiftType).opacity(0.5)
                                                        : Color.clear,
                                                    lineWidth: 2
                                                )
                                        )
                                        .shadow(
                                            color: isNotesFocused
                                                ? ShiftColorPalette.colorForShift(selectedShiftType).opacity(0.15)
                                                : .clear,
                                            radius: 8,
                                            x: 0,
                                            y: 4
                                        )
                                )
                                .animation(.easeOut(duration: 0.2), value: isNotesFocused)
                        }

                        // MARK: - Action Buttons
                        HStack(spacing: 16) {
                            // Cancel Button
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                onDismiss()
                                isPresented = false
                            }) {
                                HStack {
                                    Image(systemName: "xmark")
                                        .font(.callout)
                                    Text("Cancel")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .strokeBorder(.secondary.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())

                            // Confirm Button
                            Button(action: handleConfirm) {
                                HStack {
                                    if isConfirming {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Image(systemName: "checkmark")
                                            .font(.callout)
                                    }
                                    Text("Add to \(selectedDateCount) Dates")
                                        .fontWeight(.bold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .foregroundStyle(.white)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                colors: isFormValid && !isConfirming
                                                    ? [ShiftColorPalette.colorForShift(selectedShiftType), ShiftColorPalette.colorForShift(selectedShiftType).opacity(0.8)]
                                                    : [.gray, .gray.opacity(0.8)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .shadow(
                                            color: ShiftColorPalette.colorForShift(selectedShiftType).opacity(0.3),
                                            radius: 8,
                                            x: 0,
                                            y: 4
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(!isFormValid || isConfirming)
                            .opacity(!isFormValid || isConfirming ? 0.5 : 1.0)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
                .scrollDismissesKeyboard(.immediately)
                .dismissKeyboardOnTap()
            }
            .navigationTitle("Select Shift Type")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func handleConfirm() {
        guard let shiftType = selectedShiftType else { return }

        let finalNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        Task {
            isConfirming = true
            await onConfirm(shiftType, finalNotes)
            isConfirming = false
            // Note: Sheet dismissal is handled by the caller based on success/failure
        }
    }
}

// MARK: - Shift Type Option Card

/// Individual selectable card for a shift type option
struct ShiftTypeOptionCard: View {
    let shiftType: ShiftType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Checkbox
                ZStack {
                    Circle()
                        .fill(
                            isSelected
                                ? ShiftColorPalette.colorForShift(shiftType)
                                : Color(.systemGray5)
                        )
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                // Shift type info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(shiftType.symbol)
                            .font(.headline)
                        Text(shiftType.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                        Text(shiftType.timeRangeString)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text(shiftType.location.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        isSelected
                            ? ShiftColorPalette.colorForShift(shiftType).opacity(0.1)
                            : Color(.systemGray6)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(
                                isSelected
                                    ? ShiftColorPalette.colorForShift(shiftType).opacity(0.5)
                                    : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview("Shift Type Selection") {
    let sampleLocation = Location(id: UUID(), name: "Main Office", address: "123 Main St")
    let sampleShiftTypes = [
        ShiftType(
            id: UUID(),
            symbol: "🌅",
            duration: .scheduled(
                from: HourMinuteTime(hour: 9, minute: 0),
                to: HourMinuteTime(hour: 17, minute: 0)
            ),
            title: "Morning Shift",
            description: "Regular morning shift",
            location: sampleLocation
        ),
        ShiftType(
            id: UUID(),
            symbol: "🌙",
            duration: .scheduled(
                from: HourMinuteTime(hour: 17, minute: 0),
                to: HourMinuteTime(hour: 1, minute: 0)
            ),
            title: "Evening Shift",
            description: "Evening shift with late hours",
            location: sampleLocation
        ),
        ShiftType(
            id: UUID(),
            symbol: "🌃",
            duration: .scheduled(
                from: HourMinuteTime(hour: 1, minute: 0),
                to: HourMinuteTime(hour: 9, minute: 0)
            ),
            title: "Night Shift",
            description: "Overnight shift",
            location: sampleLocation
        )
    ]

    ShiftTypeSelectionView(
        isPresented: .constant(true),
        availableShiftTypes: sampleShiftTypes,
        selectedDateCount: 5,
        onConfirm: { shiftType, notes in
            print("Confirming bulk add: \(shiftType.title) with notes: \(notes)")
        },
        onDismiss: {
            print("Dismissing shift type selection")
        }
    )
    .environment(\.reduxStore, previewStore)
}

private let previewStore: Store = {
    let store = Store(
        state: AppState(),
        reducer: appReducer,
        services: ServiceContainer(),
        middlewares: [
            scheduleMiddleware,
            todayMiddleware,
            locationsMiddleware,
            shiftTypesMiddleware,
            changeLogMiddleware,
            settingsMiddleware,
            loggingMiddleware
        ]
    )
    return store
}()
