import SwiftUI

struct AddEditShiftTypeView: View {
    @Environment(\.reduxStore) var store
    @Binding var isPresented: Bool

    let shiftType: ShiftType?

    @State private var title: String = ""
    @State private var symbol: String = ""
    @State private var shiftDescription: String = ""
    @State private var isAllDay: Bool = false
    @State private var startTime: Date = {
        var components = DateComponents()
        components.hour = 8
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()
    @State private var endTime: Date = {
        var components = DateComponents()
        components.hour = 16
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()
    @State private var selectedLocation: Location?

    var availableLocations: [Location] {
        store.state.locations.locations
    }

    var isValid: Bool {
        let hasTrimmedTitle = !title.trimmingCharacters(in: .whitespaces).isEmpty
        let hasTrimmedSymbol = !symbol.trimmingCharacters(in: .whitespaces).isEmpty
        let hasLocation = selectedLocation != nil
        let hasValidTimes = isAllDay || (endTime > startTime)

        return hasTrimmedTitle && hasTrimmedSymbol && hasLocation && hasValidTimes
    }

    var formTitle: String {
        shiftType != nil ? "Edit Shift Type" : "Add Shift Type"
    }

    var body: some View {
        NavigationView {
            Form {
                // Warning banner if no locations available
                if availableLocations.isEmpty {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("No locations available. Please create a location first.")
                                    .font(.callout)
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding()
                        .background(Color(.systemYellow).opacity(0.2))
                    }
                }

                Section("Shift Type Details") {
                    TextField("Symbol (e.g., M, N, D)", text: $symbol)
                        .textInputAutocapitalization(.characters)
                        .onChange(of: symbol) { oldValue, newValue in
                            if newValue.count > 20 {
                                symbol = String(newValue.prefix(20))
                            }
                        }

                    TextField("Title", text: $title)
                        .textInputAutocapitalization(.words)
                        .onChange(of: title) { oldValue, newValue in
                            if newValue.count > 100 {
                                title = String(newValue.prefix(100))
                            }
                        }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Description (optional)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextEditor(text: $shiftDescription)
                            .frame(minHeight: 100)
                            .scrollContentBackground(.hidden)
                            .onChange(of: shiftDescription) { oldValue, newValue in
                                if newValue.count > 500 {
                                    shiftDescription = String(newValue.prefix(500))
                                }
                            }
                    }
                }

                Section("Duration") {
                    Toggle("All Day", isOn: $isAllDay)

                    if !isAllDay {
                        DatePicker(
                            "Start Time",
                            selection: $startTime,
                            displayedComponents: .hourAndMinute
                        )

                        DatePicker(
                            "End Time",
                            selection: $endTime,
                            displayedComponents: .hourAndMinute
                        )

                        if endTime <= startTime {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundColor(.red)
                                    Text("End time must be after start time")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }

                Section("Location") {
                    if availableLocations.isEmpty {
                        Text("No locations available")
                            .foregroundColor(.secondary)
                    } else {
                        Picker("Select Location", selection: $selectedLocation) {
                            Text("Select Location")
                                .tag(nil as Location?)

                            ForEach(availableLocations) { location in
                                Text(location.name)
                                    .tag(location as Location?)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }

                if let error = store.state.shiftTypes.errorMessage {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.red)
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        .padding()
                        .background(Color(.systemRed).opacity(0.1))
                    }
                }
            }
            .navigationTitle(formTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        store.dispatch(action: .shiftTypes(.addEditSheetDismissed))
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveShiftType()
                    }
                    .disabled(!isValid || store.state.shiftTypes.isLoading)
                }
            }
            .onAppear {
                if let shiftType = shiftType {
                    title = shiftType.title
                    symbol = shiftType.symbol
                    shiftDescription = shiftType.shiftDescription
                    selectedLocation = shiftType.location

                    switch shiftType.duration {
                    case .allDay:
                        isAllDay = true
                    case .scheduled(let from, let to):
                        isAllDay = false
                        startTime = from.toDate()
                        endTime = to.toDate()
                    }
                } else {
                    // Auto-select first location for new shifts
                    selectedLocation = availableLocations.first
                }
            }
            .dismissKeyboardOnTap()
            .scrollDismissesKeyboard(.immediately)
        }
    }

    private func saveShiftType() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        let trimmedSymbol = symbol.trimmingCharacters(in: .whitespaces)

        guard !trimmedTitle.isEmpty, !trimmedSymbol.isEmpty else {
            return
        }

        guard let location = selectedLocation else {
            return
        }

        let duration: ShiftDuration
        if isAllDay {
            duration = .allDay
        } else {
            let startTime = HourMinuteTime(from: self.startTime)
            let endTime = HourMinuteTime(from: self.endTime)
            duration = .scheduled(from: startTime, to: endTime)
        }

        let newShiftType = ShiftType(
            id: shiftType?.id ?? UUID(),
            symbol: trimmedSymbol,
            duration: duration,
            title: trimmedTitle,
            description: shiftDescription,
            location: location
        )

        store.dispatch(action: .shiftTypes(.saveShiftType(newShiftType)))
    }
}

#Preview {
    AddEditShiftTypeView(isPresented: .constant(true), shiftType: nil)
}
