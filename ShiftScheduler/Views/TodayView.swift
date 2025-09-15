import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var shiftTypes: [ShiftType]
    @StateObject private var calendarService = CalendarService.shared
    @State private var scheduledShifts: [ScheduledShift] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var todayShift: ScheduledShift? {
        scheduledShifts.first { shift in
            Calendar.current.isDate(shift.date, inSameDayAs: Date())
        }
    }

    private var tomorrowShift: ScheduledShift? {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        return scheduledShifts.first { shift in
            Calendar.current.isDate(shift.date, inSameDayAs: tomorrow)
        }
    }

    private var thisWeekShifts: [ScheduledShift] {
        let startOfWeek = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        let endOfWeek = Calendar.current.date(byAdding: .day, value: 6, to: startOfWeek) ?? Date()

        return scheduledShifts.filter { shift in
            shift.date >= startOfWeek && shift.date <= endOfWeek
        }
    }

    private var completedThisWeek: Int {
        // For now, return 0 as we don't have a completion tracking system yet
        0
    }

    private var cancelledThisWeek: Int {
        // For now, return 0 as we don't have a cancellation tracking system yet
        0
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
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
                        // Today Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text(Date(), style: .date)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                Spacer()

                                if isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                }
                            }

                            if let errorMessage = errorMessage {
                                Text("Error: \(errorMessage)")
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }

                            TodayShiftCard(shift: todayShift)
                        }
                        .padding(.horizontal)

                        // Quick Actions Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Quick Actions")
                                .font(.title3)
                                .fontWeight(.semibold)

                            if todayShift != nil {
                                // Show quick actions when there's a shift
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        QuickActionButton(title: "Clock In", icon: "clock", action: {})
                                        QuickActionButton(title: "Break", icon: "pause.circle", action: {})
                                        QuickActionButton(title: "Clock Out", icon: "clock.badge.checkmark", action: {})
                                    }
                                    .padding(.horizontal)
                                }
                            } else {
                                Text("No shift scheduled for quick actions")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color(UIColor.systemGray6))
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)

                        // Upcoming Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Upcoming")
                                .font(.title3)
                                .fontWeight(.semibold)

                            HStack {
                                Text("Tomorrow")
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                Spacer()

                                if let tomorrowShift = tomorrowShift {
                                    Text(tomorrowShift.shiftType?.title ?? "Shift")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("No shift scheduled")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)

                        // This Week Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("This Week")
                                .font(.title3)
                                .fontWeight(.semibold)

                            HStack(spacing: 0) {
                                WeekStatView(count: thisWeekShifts.count, label: "Scheduled", color: .blue)
                                WeekStatView(count: completedThisWeek, label: "Completed", color: .green)
                                WeekStatView(count: cancelledThisWeek, label: "Cancelled", color: .red)
                            }
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)

                        Spacer(minLength: 100) // Space for tab bar
                    }
                }
                .padding(.top)
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
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
                let startOfWeek = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
                let endOfWeek = Calendar.current.date(byAdding: .day, value: 6, to: startOfWeek) ?? Date()

                let shiftData = try await calendarService.fetchShifts(from: startOfWeek, to: endOfWeek)
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
}

struct TodayShiftCard: View {
    let shift: ScheduledShift?

    var body: some View {
        VStack(spacing: 16) {
            if let shift = shift, let shiftType = shift.shiftType {
                // Has shift scheduled
                VStack(spacing: 8) {
                    Text(shiftType.symbol)
                        .font(.system(size: 40))

                    Text(shiftType.title)
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text(shiftType.timeRangeString)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if let location = shiftType.location {
                        Text("📍 \(location.name)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                // No shift scheduled
                VStack(spacing: 8) {
                    Text("😴")
                        .font(.system(size: 40))

                    Text("No shift scheduled")
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text("Enjoy your day off!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(16)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            .frame(width: 80, height: 80)
            .background(Color.blue)
            .cornerRadius(12)
        }
    }
}

struct WeekStatView: View {
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text("\(count)")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

#Preview {
    TodayView()
        .modelContainer(for: [Location.self, ShiftType.self], inMemory: true)
}