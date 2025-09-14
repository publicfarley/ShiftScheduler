import SwiftUI
import SwiftData

struct ScheduleShiftView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var shiftTypes: [ShiftType]

    let selectedDate: Date
    @State private var selectedShiftType: ShiftType?
    @State private var shiftDate: Date

    init(selectedDate: Date) {
        self.selectedDate = selectedDate
        self._shiftDate = State(initialValue: selectedDate)
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Shift Details") {
                    DatePicker("Date", selection: $shiftDate, displayedComponents: [.date])

                    if shiftTypes.isEmpty {
                        Text("No shift types available")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        Picker("Shift Type", selection: $selectedShiftType) {
                            Text("Select a shift type").tag(nil as ShiftType?)
                            ForEach(shiftTypes) { shiftType in
                                VStack(alignment: .leading) {
                                    Text("\(shiftType.symbol) - \(shiftType.title)")
                                    Text("\(shiftType.startTimeString) - \(shiftType.endTimeString)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .tag(shiftType as ShiftType?)
                            }
                        }
                    }
                }

                if let shiftType = selectedShiftType {
                    Section("Shift Preview") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(shiftType.symbol)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)

                                Spacer()

                                Text("\(shiftType.startTimeString) - \(shiftType.endTimeString)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            Text(shiftType.title)
                                .font(.headline)

                            Text(shiftType.shiftDescription)
                                .font(.body)
                                .foregroundColor(.secondary)

                            if let location = shiftType.location {
                                HStack {
                                    Text("📍 \(location.name)")
                                        .font(.subheadline)
                                    Spacer()
                                }

                                Text(location.address)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
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
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        scheduleShift()
                    }
                    .disabled(selectedShiftType == nil)
                }
            }
        }
    }

    private func scheduleShift() {
        guard let shiftType = selectedShiftType else { return }

        let fetchDescriptor = FetchDescriptor<ScheduledShift>()
        let scheduledShifts = (try? modelContext.fetch(fetchDescriptor)) ?? []
        let existingShift = scheduledShifts.first { scheduledShift in
            guard let scheduledShiftType = scheduledShift.shiftType else { return false }
            return scheduledShiftType.id == shiftType.id &&
                   Calendar.current.isDate(scheduledShift.date, inSameDayAs: shiftDate)
        }

        if existingShift != nil {
            return
        }

        let scheduledShift = ScheduledShift(shiftType: shiftType, date: shiftDate)
        modelContext.insert(scheduledShift)

        dismiss()
    }
}

#Preview {
    ScheduleShiftView(selectedDate: Date())
        .modelContainer(for: [Location.self, ShiftType.self, ScheduledShift.self], inMemory: true)
}
