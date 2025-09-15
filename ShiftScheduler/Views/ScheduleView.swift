import SwiftUI
import SwiftData

struct ScheduleView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var shiftTypes: [ShiftType]
    @StateObject private var calendarService = CalendarService.shared
    @State private var showingScheduleShift = false
    @State private var selectedDate = Date()
    @State private var scheduledShifts: [ScheduledShift] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var shiftsForSelectedDate: [ScheduledShift] {
        scheduledShifts.filter { shift in
            Calendar.current.isDate(shift.date, inSameDayAs: selectedDate)
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                if !calendarService.isAuthorized {
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.largeTitle)
                            .foregroundColor(.red)

                        Text("Calendar Access Required")
                            .font(.headline)

                        Text(calendarService.authorizationError ?? "ShiftScheduler needs calendar access to function properly.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)

                        Button("Open Settings") {
                            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(settingsUrl)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    DatePicker("Select Date", selection: $selectedDate, displayedComponents: [.date])
                        .datePickerStyle(GraphicalDatePickerStyle())
                        .padding()
                        .onChange(of: selectedDate) { _, _ in
                            loadShifts()
                        }

                    if isLoading {
                        ProgressView("Loading shifts...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            if let errorMessage = errorMessage {
                                Text("Error: \(errorMessage)")
                                    .foregroundColor(.red)
                                    .italic()
                            } else if shiftsForSelectedDate.isEmpty {
                                Text("No shifts scheduled for this date")
                                    .foregroundColor(.secondary)
                                    .italic()
                            } else {
                                ForEach(shiftsForSelectedDate.sorted { $0.shiftType?.startHour ?? 0 < $1.shiftType?.startHour ?? 0 }) { shift in
                                    ScheduledShiftRow(shift: shift)
                                }
                                .onDelete(perform: deleteShifts)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Schedule")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Shift") {
                        showingScheduleShift = true
                    }
                    .disabled(!calendarService.isAuthorized)
                }
            }
            .sheet(isPresented: $showingScheduleShift) {
                ScheduleShiftView(selectedDate: selectedDate)
            }
            .onAppear {
                loadShifts()
            }
        }
    }

    private func loadShifts() {
        guard calendarService.isAuthorized else { return }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let shiftData = try await calendarService.fetchShifts(for: selectedDate)
                let shifts = shiftData.map { data in
                    let shiftType = shiftTypes.first { $0.id == data.shiftTypeId }
                    return ScheduledShift(from: data, shiftType: shiftType)
                }

                await MainActor.run {
                    self.scheduledShifts = shifts
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    private func deleteShifts(offsets: IndexSet) {
        let shiftsToDelete = shiftsForSelectedDate.sorted { $0.shiftType?.startHour ?? 0 < $1.shiftType?.startHour ?? 0 }

        for index in offsets {
            let shift = shiftsToDelete[index]
            Task {
                do {
                    try await calendarService.deleteShift(withIdentifier: shift.eventIdentifier)
                    await MainActor.run {
                        loadShifts()
                    }
                } catch {
                    await MainActor.run {
                        errorMessage = "Failed to delete shift: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
}

struct ScheduledShiftRow: View {
    let shift: ScheduledShift

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if let shiftType = shift.shiftType {
                    Text(shiftType.symbol)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)

                    Spacer()

                    Text("\(shiftType.startTimeString) - \(shiftType.endTimeString)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            if let shiftType = shift.shiftType {
                Text(shiftType.title)
                    .font(.headline)

                if let location = shiftType.location {
                    Text("📍 \(location.name)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text(shift.date, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    ScheduleView()
        .modelContainer(for: [Location.self, ShiftType.self], inMemory: true)
}