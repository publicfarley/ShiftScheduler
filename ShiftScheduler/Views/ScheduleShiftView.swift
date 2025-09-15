import SwiftUI
import SwiftData

struct ScheduleShiftView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var shiftTypes: [ShiftType]
    @StateObject private var calendarService = CalendarService.shared

    let selectedDate: Date
    @State private var selectedShiftType: ShiftType?
    @State private var shiftDate: Date
    @State private var isLoading = false
    @State private var errorMessage: String?

    init(selectedDate: Date) {
        self.selectedDate = selectedDate
        self._shiftDate = State(initialValue: selectedDate)
    }

    var body: some View {
        NavigationView {
            Form {
                if let errorMessage = errorMessage {
                    Section {
                        Text("Error: \(errorMessage)")
                            .foregroundColor(.red)
                    }
                }

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
                                    Text(shiftType.timeRangeString)
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

                                Text(shiftType.timeRangeString)
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
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Button("Save") {
                            scheduleShift()
                        }
                        .disabled(selectedShiftType == nil || !calendarService.isAuthorized)
                    }
                }
            }
        }
    }

    private func scheduleShift() {
        guard let shiftType = selectedShiftType else { return }
        guard calendarService.isAuthorized else { return }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let hasDuplicate = try await calendarService.checkForDuplicateShift(shiftTypeId: shiftType.id, on: shiftDate)

                if hasDuplicate {
                    await MainActor.run {
                        self.errorMessage = "A shift of this type is already scheduled for this date."
                        self.isLoading = false
                    }
                    return
                }

                _ = try await calendarService.createShiftEvent(from: shiftType, on: shiftDate)

                await MainActor.run {
                    self.isLoading = false
                    self.dismiss()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}

#Preview {
    ScheduleShiftView(selectedDate: Date())
        .modelContainer(for: [Location.self, ShiftType.self], inMemory: true)
}
