import SwiftUI

// MARK: - Add Shift Modal View
/// Modal view for adding a new scheduled shift to the calendar
/// Allows selection of date, shift type, and optional notes
struct AddShiftModalView: View {
    @Environment(\.reduxStore) var store
    @Environment(\.dismiss) var dismiss

    let availableShiftTypes: [ShiftType]
    var preselectedDate: Date = Date()

    @State private var selectedDate: Date = Date()
    @State private var selectedShiftType: ShiftType?
    @State private var notes: String = ""
    @State private var showDatePicker = false

    var isFormValid: Bool {
        selectedShiftType != nil
    }

    private var formattedDate: String {
        selectedDate.formatted(date: .abbreviated, time: .omitted)
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Date Selection Section
                Section("Date") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(formattedDate)
                            .font(.headline)
                            .foregroundColor(.primary)

                        Button(action: { showDatePicker.toggle() }) {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.blue)
                                Text("Change Date")
                                    .foregroundColor(.blue)
                                Spacer()
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                // MARK: - Shift Type Selection Section
                Section("Shift Type") {
                    if availableShiftTypes.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.title3)
                                .foregroundColor(.orange)
                            Text("No shift types available")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("Create a shift type first in Shift Types view")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 12)
                    } else {
                        Picker("Select Shift Type", selection: $selectedShiftType) {
                            Text("Choose a shift type...").tag(nil as ShiftType?)

                            ForEach(availableShiftTypes, id: \.id) { shiftType in
                                HStack(spacing: 8) {
                                    Text(shiftType.symbol)
                                        .font(.body)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(shiftType.title)
                                            .font(.body)
                                        HStack(spacing: 4) {
                                            Image(systemName: "mappin.circle.fill")
                                                .font(.caption2)
                                            Text(shiftType.location.name)
                                                .font(.caption)
                                        }
                                        .foregroundColor(.secondary)
                                    }
                                }
                                .tag(shiftType as ShiftType?)
                            }
                        }
                        .pickerStyle(.automatic)

                        // Selected shift type details
                        if let selectedType = selectedShiftType {
                            VStack(alignment: .leading, spacing: 8) {
                                Divider()
                                    .padding(.vertical, 4)

                                HStack(spacing: 8) {
                                    Image(systemName: "clock.fill")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    Text(selectedType.startTimeString)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                HStack(spacing: 8) {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    Text(selectedType.location.name)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                if !selectedType.shiftDescription.isEmpty {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Description")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                            .textCase(.uppercase)
                                        Text(selectedType.shiftDescription)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }

                // MARK: - Notes Section
                Section("Notes (Optional)") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                        .font(.body)
                }
            }
            .navigationTitle("Add Shift")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        handleAddShift()
                    }
                    .disabled(!isFormValid || store.state.schedule.isAddingShift)
                }
            }
            .onAppear {
                selectedDate = preselectedDate
            }
        }
        .sheet(isPresented: $showDatePicker) {
            DatePickerSheet(selectedDate: $selectedDate)
        }
        .dismissKeyboardOnTap()
    }

    private func handleAddShift() {
        guard let shiftType = selectedShiftType else { return }

        let finalNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        store.dispatch(action: .schedule(.addShift(
            date: selectedDate,
            shiftType: shiftType,
            location: shiftType.location,
            startTime: Date(),  // Not used for all-day shifts
            notes: finalNotes
        )))

        dismiss()
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

    AddShiftModalView(availableShiftTypes: sampleShiftTypes)
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
