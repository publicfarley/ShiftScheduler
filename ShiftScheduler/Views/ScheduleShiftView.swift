import SwiftUI
import ComposableArchitecture
import Combine

struct ScheduleShiftView: View {
    @Bindable var store: StoreOf<ScheduleShiftFeature>

    /// Shift types available for selection (provided by parent)
    let availableShiftTypes: [ShiftType]

    /// Callback when shift is created successfully
    let onShiftCreated: ((Date) -> Void)?

    var body: some View {
        NavigationView {
            Form {
                if let errorMessage = store.errorMessage {
                    Section {
                        Text("Error: \(errorMessage)")
                            .foregroundColor(.red)
                    }
                }

                Section("Shift Details") {
                    DatePicker(
                        "Date",
                        selection: Binding(
                            get: { store.shiftDate },
                            set: { store.send(.dateChanged($0)) }
                        ),
                        displayedComponents: [.date]
                    )

                    // Shift type selection
                    if availableShiftTypes.isEmpty {
                        Text("No shift types available")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        Picker("Shift Type", selection: Binding(
                            get: { store.selectedShiftType },
                            set: { store.send(.shiftTypeSelected($0)) }
                        )) {
                            Text("Select a shift type").tag(Optional<ShiftType>.none)
                            ForEach(availableShiftTypes, id: \.id) { shiftType in
                                HStack {
                                    Text(shiftType.symbol)
                                        .font(.headline)
                                    Text(shiftType.title)
                                }
                                .tag(Optional(shiftType))
                            }
                        }
                    }
                }

                if let shiftType = store.selectedShiftType {
                    Section("Shift Preview") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(shiftType.symbol)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)

                                Spacer()

                                Text(shiftType.timeRangeString)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            Text(shiftType.title)
                                .font(.headline)

                            Text(shiftType.shiftDescription)
                                .font(.body)
                                .foregroundColor(.secondary)

                            HStack {
                                Text("📍 \(shiftType.location.name)")
                                    .font(.subheadline)
                                Spacer()
                            }

                            Text(shiftType.location.address)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Schedule Shift")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        store.send(.cancelButtonTapped)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if store.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Button("Save") {
                            store.send(.saveButtonTapped)
                        }
                        .disabled(store.selectedShiftType == nil)
                    }
                }
            }
            .onChange(of: store.shiftDate) { oldValue, newValue in
                store.send(.dateChanged(newValue))
            }
            .onChange(of: store.selectedShiftType) { oldValue, newValue in
                store.send(.shiftTypeSelected(newValue))
            }
        }
        .onReceive(Just(store.isLoading == false && store.errorMessage == nil).filter { $0 }.map { _ in () }, perform: { _ in
            // Notify parent about creation
            if store.isLoading == false && store.errorMessage == nil {
                onShiftCreated?(store.shiftDate)
            }
        })
    }
}

#Preview {
    let mockShiftType = ShiftType(
        id: UUID(),
        symbol: "☀️",
        duration: .scheduled(from: HourMinuteTime(hour: 6, minute: 0), to: HourMinuteTime(hour: 14, minute: 0)),
        title: "Morning Shift",
        description: "Early morning shift",
        location: Location(id: UUID(), name: "Main Store", address: "123 Main St")
    )

    ScheduleShiftView(
        store: Store(
            initialState: ScheduleShiftFeature.State(selectedDate: Date()),
            reducer: { ScheduleShiftFeature() }
        ),
        availableShiftTypes: [mockShiftType],
        onShiftCreated: nil
    )
}
