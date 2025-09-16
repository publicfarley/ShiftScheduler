import SwiftUI
import SwiftData

struct ScheduleView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var shiftTypes: [ShiftType]
    @StateObject private var calendarService = CalendarService.shared
    @State private var showingScheduleShift = false
    @State private var selectedDate = Date()
    @State private var scheduledShifts: [ScheduledShift] = []
    @State private var scheduledDates: Set<Date> = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var shiftsForSelectedDate: [ScheduledShift] {
        scheduledShifts.filter { shift in
            Calendar.current.isDate(shift.date, inSameDayAs: selectedDate)
        }
    }

    private var mainContentView: some View {
        VStack(spacing: 0) {
            // Calendar section with dedicated background
            VStack {
                CustomCalendarView(selectedDate: $selectedDate, scheduledDates: scheduledDates)
                    .padding(.horizontal)
                    .padding(.top)
                    .onChange(of: selectedDate) { _, _ in
                        loadShifts()
                    }
            }
            .background(Color(.systemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
            .padding(.top)

            // Spacer for visual separation
            Spacer()
                .frame(height: 24)

            // Shifts section
            VStack(alignment: .leading, spacing: 12) {
                // Section header
                HStack {
                    Text(dateHeaderText)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Spacer()

                    if !shiftsForSelectedDate.isEmpty {
                        Text("\(shiftsForSelectedDate.count) shift\(shiftsForSelectedDate.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)

                // Content area
                if isLoading {
                    ProgressView("Loading shifts...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                } else {
                    List {
                        if let errorMessage = errorMessage {
                            Text("Error: \(errorMessage)")
                                .foregroundColor(.red)
                                .italic()
                        } else if shiftsForSelectedDate.isEmpty {
                            HStack {
                                Image(systemName: "calendar.badge.plus")
                                    .foregroundColor(.secondary)
                                    .font(.title3)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("No shifts scheduled")
                                        .font(.subheadline)
                                        .fontWeight(.medium)

                                    Text("Tap \"Add Shift\" to schedule a shift for this date")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()
                            }
                            .padding(.vertical, 8)
                            .listRowBackground(Color(.systemGroupedBackground))
                        } else {
                            ForEach(shiftsForSelectedDate.sorted { shift1, shift2 in
                                let startTime1 = shift1.shiftType?.duration.startTime?.hour ?? 0
                                let startTime2 = shift2.shiftType?.duration.startTime?.hour ?? 0
                                return startTime1 < startTime2
                            }) { shift in
                                ScheduledShiftRow(shift: shift)
                                    .listRowBackground(Color(.systemBackground))
                            }
                            .onDelete(perform: deleteShifts)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
        }
    }

    private var dateHeaderText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: selectedDate)
    }

    private var calendarAccessView: some View {
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
    }

    var body: some View {
        NavigationView {
            VStack {
                if !calendarService.isAuthorized {
                    calendarAccessView
                } else {
                    mainContentView
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
            .sheet(isPresented: $showingScheduleShift, onDismiss: {
                // Reload shifts when the schedule sheet is dismissed
                // This ensures newly scheduled shifts appear immediately
                loadShifts()
                loadScheduledDates()
            }) {
                ScheduleShiftView(selectedDate: selectedDate)
            }
            .onAppear {
                loadShifts()
                loadScheduledDates()
            }
        }
    }

    private func loadShifts() {
        guard calendarService.isAuthorized else { return }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                // Use date range to ensure we get all shifts for the selected date
                let startOfDay = Calendar.current.startOfDay(for: selectedDate)
                let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? selectedDate

                let shiftData = try await calendarService.fetchShifts(from: startOfDay, to: endOfDay)
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

    private func loadScheduledDates() {
        guard calendarService.isAuthorized else { return }

        Task {
            do {
                // Load shifts for a wider date range to get all scheduled dates for highlighting
                let startDate = Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
                let endDate = Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()

                let allShiftData = try await calendarService.fetchShifts(from: startDate, to: endDate)
                let uniqueDates = Set(allShiftData.map { Calendar.current.startOfDay(for: $0.date) })

                await MainActor.run {
                    self.scheduledDates = uniqueDates
                }
            } catch {
                // Silently fail for scheduled dates - this is just for highlighting
                print("Failed to load scheduled dates for highlighting: \(error)")
            }
        }
    }

    private func deleteShifts(offsets: IndexSet) {
        let shiftsToDelete = shiftsForSelectedDate.sorted { shift1, shift2 in
            let startTime1 = shift1.shiftType?.duration.startTime?.hour ?? 0
            let startTime2 = shift2.shiftType?.duration.startTime?.hour ?? 0
            return startTime1 < startTime2
        }

        for index in offsets {
            let shift = shiftsToDelete[index]
            Task {
                do {
                    try await calendarService.deleteShift(withIdentifier: shift.eventIdentifier)
                    await MainActor.run {
                        loadShifts()
                        loadScheduledDates()
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
        HStack(spacing: 16) {
            // Shift symbol with background circle
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 48, height: 48)

                if let shiftType = shift.shiftType {
                    Text(shiftType.symbol)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
            }

            // Shift details
            VStack(alignment: .leading, spacing: 6) {
                if let shiftType = shift.shiftType {
                    // Title and time
                    HStack {
                        Text(shiftType.title)
                            .font(.headline)
                            .fontWeight(.semibold)

                        Spacer()

                        Text(shiftType.timeRangeString)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Capsule())
                    }

                    // Location
                    if let location = shiftType.location {
                        HStack(spacing: 6) {
                            Image(systemName: "location.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text(location.name)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

#Preview {
    ScheduleView()
        .modelContainer(for: [Location.self, ShiftType.self], inMemory: true)
}