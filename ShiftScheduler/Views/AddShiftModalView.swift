import SwiftUI

// MARK: - Add Shift Modal View
/// Premium, modern modal view for adding a new scheduled shift
/// Features glass morphism design, improved interactions, and smooth animations
struct AddShiftModalView: View {
    @Environment(\.reduxStore) var store
    @Environment(\.dismiss) var dismiss
    @Binding var isPresented: Bool

    let availableShiftTypes: [ShiftType]
    var preselectedDate: Date = Date()
    var onCancel: () -> Void = { }

    @State private var selectedDate: Date = Date()
    @State private var selectedShiftType: ShiftType?
    @State private var notes: String = ""
    @State private var showDatePicker = false
    @FocusState private var isNotesFocused: Bool

    var isFormValid: Bool {
        selectedShiftType != nil
    }

    private var formattedDate: String {
        selectedDate.formatted(date: .abbreviated, time: .omitted)
    }

    private var relativeDateString: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(selectedDate) {
            return "Today"
        } else if calendar.isDateInTomorrow(selectedDate) {
            return "Tomorrow"
        } else if calendar.isDateInYesterday(selectedDate) {
            return "Yesterday"
        } else {
            let components = calendar.dateComponents([.day], from: Date(), to: selectedDate)
            if let days = components.day {
                if days > 0 {
                    return "In \(days) days"
                } else if days < 0 {
                    return "\(-days) days ago"
                }
            }
            return ""
        }
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
                        // MARK: - Date Selection Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Shift Date")
                                .font(.headline)
                                .foregroundStyle(.secondary)

                            Button(action: {
                                showDatePicker.toggle()
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }) {
                                HStack(spacing: 12) {
                                    // Calendar icon with gradient background
                                    ZStack {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [.blue.opacity(0.2), .blue.opacity(0.1)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 44, height: 44)

                                        Image(systemName: "calendar")
                                            .font(.title3)
                                            .foregroundColor(.blue)
                                    }

                                    // Date display
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(formattedDate)
                                            .font(.headline)
                                            .foregroundColor(.primary)

                                        Text(relativeDateString)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    // Chevron indicator
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
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
                                        .shadow(
                                            color: .black.opacity(0.05),
                                            radius: 8,
                                            x: 0,
                                            y: 4
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())

                            // Graphical DatePicker (shown when expanded)
                            if showDatePicker {
                                DatePicker(
                                    "",
                                    selection: $selectedDate,
                                    displayedComponents: [.date]
                                )
                                .datePickerStyle(.graphical)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .strokeBorder(
                                                    LinearGradient(
                                                        colors: [.blue.opacity(0.2), .clear],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ),
                                                    lineWidth: 1
                                                )
                                        )
                                )
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.95).combined(with: .opacity),
                                    removal: .scale(scale: 0.98).combined(with: .opacity)
                                ))
                            }
                        }

                        // MARK: - Shift Type Selection Card
                        if !availableShiftTypes.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Shift Type")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)

                                Picker("Select Shift Type", selection: $selectedShiftType) {
                                    Text("Choose a shift type").tag(nil as ShiftType?)

                                    ForEach(availableShiftTypes, id: \.id) { shiftType in
                                        HStack(spacing: 8) {
                                            Text(shiftType.symbol)
                                            Text(shiftType.title)
                                            Spacer()
                                            Text(shiftType.timeRangeString)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        .tag(Optional(shiftType))
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .strokeBorder(
                                                    LinearGradient(
                                                        colors: [
                                                            ShiftColorPalette.colorForShift(selectedShiftType).opacity(0.3),
                                                            .clear
                                                        ],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ),
                                                    lineWidth: 1
                                                )
                                        )
                                        .shadow(
                                            color: ShiftColorPalette.colorForShift(selectedShiftType).opacity(0.1),
                                            radius: 8,
                                            x: 0,
                                            y: 4
                                        )
                                )
                                .animation(.easeOut(duration: 0.3), value: selectedShiftType)
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

                        // MARK: - Shift Preview Card
                        if let shiftType = selectedShiftType {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Shift Preview")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)

                                ShiftDisplayCard(
                                    shiftType: shiftType,
                                    date: selectedDate,
                                    label: "New Shift",
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
                                onCancel()
                                Task {
                                    isPresented = false
                                }
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

                            // Save Button
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                handleAddShift()
                            }) {
                                HStack {
                                    if store.state.schedule.isAddingShift {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Image(systemName: "checkmark")
                                            .font(.callout)
                                    }
                                    Text("Add Shift")
                                        .fontWeight(.bold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .foregroundStyle(.white)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                colors: selectedShiftType != nil
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
                            .disabled(selectedShiftType == nil || store.state.schedule.isAddingShift)
                            .opacity(selectedShiftType == nil ? 0.5 : 1.0)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
                .scrollDismissesKeyboard(.immediately)
                .dismissKeyboardOnTap()
            }
            .navigationTitle("Add Shift")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                selectedDate = preselectedDate
            }
            .sheet(isPresented: $showDatePicker) {
                DatePickerSheet(selectedDate: $selectedDate)
            }
        }
    }

    private func handleAddShift() {
        guard let shiftType = selectedShiftType else { return }

        let finalNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        Task {
            await store.dispatch(action: .schedule(.addShift(
                date: selectedDate,
                shiftType: shiftType,
                notes: finalNotes
            )))
        }
    }
}

// MARK: - Date Picker Sheet
/// Sheet presentation for date selection
struct DatePickerSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedDate: Date

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding()

                Spacer()

                Button(action: { dismiss() }) {
                    Text("Done")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
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
        )
    ]

    AddShiftModalView(isPresented: .constant(true), availableShiftTypes: sampleShiftTypes)
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
