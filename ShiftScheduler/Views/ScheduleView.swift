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
        VStack(spacing: 12) {
            // Calendar section with dedicated background
            CustomCalendarView(selectedDate: $selectedDate, scheduledDates: scheduledDates)
                .padding(.vertical, 12)
                .background(Color(.systemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 16)
                .onChange(of: selectedDate) { _, _ in
                    loadShifts()
                }

            // Shifts section
            VStack(alignment: .leading, spacing: 8) {
                // Section header
                HStack {
                    Text(dateHeaderText)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Spacer()

                    if !shiftsForSelectedDate.isEmpty {
                        Text("\(shiftsForSelectedDate.count) shift\(shiftsForSelectedDate.count == 1 ? "" : "s")")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16)

                // Content area with enhanced design
                if isLoading {
                    EnhancedLoadingState()
                        .padding(.horizontal, 16)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            if let errorMessage = errorMessage {
                                ErrorStateView(message: errorMessage)
                                    .padding(.horizontal, 16)
                            } else if shiftsForSelectedDate.isEmpty {
                                EnhancedEmptyState(selectedDate: selectedDate)
                                    .padding(.horizontal, 16)
                            } else {
                                ForEach(shiftsForSelectedDate.sorted { shift1, shift2 in
                                    let startTime1 = shift1.shiftType?.duration.startTime?.hour ?? 0
                                    let startTime2 = shift2.shiftType?.duration.startTime?.hour ?? 0
                                    return startTime1 < startTime2
                                }) { shift in
                                    EnhancedShiftCard(shift: shift) {
                                        deleteShift(shift)
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .background(Color(.systemGroupedBackground).ignoresSafeArea())
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
            deleteShift(shift)
        }
    }

    private func deleteShift(_ shift: ScheduledShift) {
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

// MARK: - Error State Component
struct ErrorStateView: View {
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.red.opacity(0.1), .red.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.red)
            }

            VStack(spacing: 6) {
                Text("Something went wrong")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.red.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview {
    ScheduleView()
        .modelContainer(for: [Location.self, ShiftType.self], inMemory: true)
}
