
import SwiftUI
import SwiftData

struct EditShiftTypeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var locations: [Location]

    @State private var symbol: String
    @State private var title: String
    @State private var description: String
    @State private var isAllDay: Bool
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var selectedLocation: Location?
    @State private var showingAddLocation = false

    @State private var newLocationName = ""
    @State private var newLocationAddress = ""

    private var isFormValid: Bool {
        !symbol.isEmpty && !title.isEmpty && selectedLocation != nil
    }

    let shiftType: ShiftType

    init(shiftType: ShiftType) {
        self.shiftType = shiftType
        _symbol = State(initialValue: shiftType.symbol)
        _title = State(initialValue: shiftType.title)
        _description = State(initialValue: shiftType.shiftDescription)
        _isAllDay = State(initialValue: shiftType.isAllDay)

        let calendar = Calendar.current
        switch shiftType.duration {
        case .allDay:
            _startTime = State(initialValue: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date())
            _endTime = State(initialValue: calendar.date(bySettingHour: 17, minute: 0, second: 0, of: Date()) ?? Date())
        case .scheduled(let from, let to):
            _startTime = State(initialValue: calendar.date(bySettingHour: from.hour, minute: from.minute, second: 0, of: Date()) ?? Date())
            _endTime = State(initialValue: calendar.date(bySettingHour: to.hour, minute: to.minute, second: 0, of: Date()) ?? Date())
        }
        _selectedLocation = State(initialValue: shiftType.location)
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
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Edit Shift Type")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Update") {
                        updateShiftType()
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
    }

    private func addLocation() {
        let location = Location(name: newLocationName, address: newLocationAddress)
        modelContext.insert(location)
        selectedLocation = location
        newLocationName = ""
        newLocationAddress = ""
    }

    private func updateShiftType() {
        guard let location = selectedLocation else { return }

        let duration: ShiftDuration
        if isAllDay {
            duration = .allDay
        } else {
            let startHourMinute = HourMinuteTime(from: startTime)
            let endHourMinute = HourMinuteTime(from: endTime)
            duration = .scheduled(from: startHourMinute, to: endHourMinute)
        }

        shiftType.update(symbol: symbol, duration: duration, title: title, description: description, location: location)

        dismiss()
    }
}
