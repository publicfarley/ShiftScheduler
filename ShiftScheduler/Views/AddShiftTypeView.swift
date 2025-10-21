import SwiftUI

struct AddShiftTypeView: View {
    @Environment(\.dismiss) private var dismiss
    // // @Query private var locations: [Location]

    @State private var symbol = ""
    @State private var title = ""
    @State private var description = ""
    @State private var isAllDay = false
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var selectedLocation: Location?
    @State private var showingAddLocation = false

    @State private var newLocationName = ""
    @State private var newLocationAddress = ""

    private var isFormValid: Bool {
        !symbol.isEmpty && !title.isEmpty && selectedLocation != nil
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("BASIC INFORMATION")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fontWeight(.medium)

                            VStack(spacing: 0) {
                                VStack(spacing: 0) {
                                    HStack {
                                        Text("Symbol")
                                            .foregroundColor(.primary)
                                        Spacer()
                                        TextField("e.g., M, E, N", text: $symbol)
                                            .textInputAutocapitalization(.characters)
                                            .multilineTextAlignment(.trailing)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 12)

                                    Divider()

                                    HStack {
                                        Text("Title")
                                            .foregroundColor(.primary)
                                        Spacer()
                                        TextField("", text: $title)
                                            .multilineTextAlignment(.trailing)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 12)

                                    Divider()

                                    HStack(alignment: .top) {
                                        Text("Description")
                                            .foregroundColor(.primary)
                                        Spacer()
                                        TextField("", text: $description, axis: .vertical)
                                            .multilineTextAlignment(.trailing)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1...3)
                                    }
                                    .padding(.vertical, 12)
                                }
                                .padding(.horizontal, 16)
                                .background(Color(UIColor.systemBackground))
                                .cornerRadius(10)
                            }
                        }

                        VStack(alignment: .leading, spacing: 16) {
                            Text("SCHEDULE")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fontWeight(.medium)

                            VStack(spacing: 0) {
                                HStack {
                                    Text("All Day")
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Toggle("", isOn: $isAllDay)
                                        .labelsHidden()
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)

                                if !isAllDay {
                                    Divider()

                                    HStack {
                                        Text("Start Time")
                                            .foregroundColor(.primary)
                                        Spacer()
                                        DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                                            .labelsHidden()
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)

                                    Divider()

                                    HStack {
                                        Text("End Time")
                                            .foregroundColor(.primary)
                                        Spacer()
                                        DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                                            .labelsHidden()
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                }
                            }
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(10)
                        }

                        VStack(alignment: .leading, spacing: 16) {
                            Text("LOCATION")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fontWeight(.medium)

                            VStack(spacing: 0) {
                                if locations.isEmpty {
                                    VStack(spacing: 12) {
                                        Text("No locations available")
                                            .foregroundColor(.secondary)
                                            .padding(.vertical, 20)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .background(Color(UIColor.systemBackground))
                                    .cornerRadius(10)
                                } else {
                                    Menu {
                                        ForEach(locations) { location in
                                            Button("\(location.name) - \(location.address)") {
                                                selectedLocation = location
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Text("Location")
                                                .foregroundColor(.primary)
                                            Spacer()
                                            if let selectedLocation = selectedLocation {
                                                Text(selectedLocation.name)
                                                    .foregroundColor(.secondary)
                                            } else {
                                                Text("Select location")
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 16)
                                        .background(Color(UIColor.systemBackground))
                                        .cornerRadius(10)
                                    }
                                }
                            }
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                }
                .scrollDismissesKeyboard(.immediately)
            }
            .dismissKeyboardOnTap()
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("New Shift Type")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        saveShiftType()
                    }
                    .disabled(!isFormValid)
                }
            }
            .alert("Add Location", isPresented: $showingAddLocation) {
                TextField("Name", text: $newLocationName)
                TextField("Address", text: $newLocationAddress)
                Button("Cancel", role: .cancel) {
                    newLocationName = ""
                    newLocationAddress = ""
                }
                Button("Add") {
                    addLocation()
                }
                .disabled(newLocationName.isEmpty || newLocationAddress.isEmpty)
            } message: {
                Text("Enter the location name and address")
            }
        }
        .onAppear {
            let calendar = Calendar.current
            startTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
            endTime = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: Date()) ?? Date()
        }
    }

    private func addLocation() {
        let location = Location(name: newLocationName, address: newLocationAddress)
        selectedLocation = location
        newLocationName = ""
        newLocationAddress = ""
        // TODO: Persist location through PersistenceClient when feature is available (Task 7)
    }

    private func saveShiftType() {
        guard let location = selectedLocation else { return }

        let duration: ShiftDuration
        if isAllDay {
            duration = .allDay
        } else {
            let startHourMinute = HourMinuteTime(from: startTime)
            let endHourMinute = HourMinuteTime(from: endTime)
            duration = .scheduled(from: startHourMinute, to: endHourMinute)
        }

        let shiftType = ShiftType(
            symbol: symbol,
            duration: duration,
            title: title,
            description: description,
            location: location
        )

        // TODO: Persist shiftType through PersistenceClient when feature is available (Task 7)
        dismiss()
    }
}

#Preview {
    AddShiftTypeView()
}