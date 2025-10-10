import SwiftUI
import SwiftData

struct ScheduleView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var shiftTypes: [ShiftType]
    @State private var dataManager = ScheduleDataManager.shared
    @State private var showingScheduleShift = false
    @State private var shiftToSwitch: ScheduledShift?
    @State private var shiftSwitchService: ShiftSwitchService?

    private var contentKey: String {
        // Create a key that changes whenever shift content changes (not just count)
        let shifts = dataManager.shiftsForSelectedDate
        let shiftKeys = shifts.map { "\($0.eventIdentifier)-\($0.shiftType?.id.uuidString ?? "nil")" }.joined(separator: ",")
        return "\(dataManager.selectedDate)-\(shiftKeys)"
    }

    private var mainContentView: some View {
        VStack(spacing: 12) {
            // Calendar section with dedicated background
            CustomCalendarView(selectedDate: $dataManager.selectedDate, scheduledDates: dataManager.scheduledDates)
                .padding(.vertical, 12)
                .background(Color(.systemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 16)

            // Shifts section
            VStack(alignment: .leading, spacing: 8) {
                // Section header
                HStack {
                    Text(dateHeaderText)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Spacer()

                    if !dataManager.shiftsForSelectedDate.isEmpty {
                        Text("\(dataManager.shiftsForSelectedDate.count) shift\(dataManager.shiftsForSelectedDate.count == 1 ? "" : "s")")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16)

                // Content area with fade-in animation for new data
                ScrollView {
                    SmoothedContentView(contentKey: contentKey) {
                        LazyVStack(spacing: 10) {
                            if let errorMessage = dataManager.errorMessage {
                                ErrorStateView(message: errorMessage)
                                    .padding(.horizontal, 16)
                            } else if !dataManager.shiftsForSelectedDate.isEmpty {
                                // Show shifts when available - with fade-in animation
                                ForEach(dataManager.shiftsForSelectedDate.sorted { shift1, shift2 in
                                    let startTime1 = shift1.shiftType?.duration.startTime?.hour ?? 0
                                    let startTime2 = shift2.shiftType?.duration.startTime?.hour ?? 0
                                    return startTime1 < startTime2
                                }) { shift in
                                    FadeInShiftCard(shift: shift, onDelete: {
                                        deleteShift(shift)
                                    }, onSwitch: {
                                        shiftToSwitch = shift
                                    })
                                    .padding(.horizontal, 16)
                                }
                            } else if dataManager.hasDataForSelectedDate {
                                // Only show empty state when we've confirmed there's no data for this date
                                EnhancedEmptyState(selectedDate: dataManager.selectedDate)
                                    .padding(.horizontal, 16)
                            }
                            // If neither condition is met, show nothing (while loading)
                        }
                        .padding(.vertical, 8)
                    }
                }
                .background(Color(.systemGroupedBackground).ignoresSafeArea())
            }
        }
    }

    private var dateHeaderText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: dataManager.selectedDate)
    }

    private var calendarAccessView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.largeTitle)
                .foregroundColor(.red)

            Text("Calendar Access Required")
                .font(.headline)

            Text(CalendarService.shared.authorizationError ?? "ShiftScheduler needs calendar access to function properly.")
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
                if !CalendarService.shared.isAuthorized {
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
                    .disabled(!CalendarService.shared.isAuthorized)
                }
            }
            .sheet(isPresented: $showingScheduleShift) {
                ScheduleShiftView(selectedDate: dataManager.selectedDate) { createdDate in
                    // Called when a shift is successfully created
                    dataManager.shiftWasCreated(on: createdDate)
                }
            }
            .sheet(item: $shiftToSwitch) { shift in
                ShiftChangeSheet(currentShift: shift) { newShiftType, reason in
                    try await switchShift(shift, to: newShiftType, reason: reason)
                }
            }
            .onAppear {
                // Set selected date to today when view appears
                dataManager.selectedDate = Date()
                // Update shift types in data manager
                dataManager.updateShiftTypes(shiftTypes)
                // Initialize shift switch service
                initializeShiftSwitchService()
            }
            .onChange(of: shiftTypes) { _, newShiftTypes in
                // Update shift types when they change
                dataManager.updateShiftTypes(newShiftTypes)
            }
        }
    }

    private func deleteShift(_ shift: ScheduledShift) {
        Task {
            do {
                try await dataManager.deleteShift(shift)
            } catch {
                await MainActor.run {
                    dataManager.errorMessage = "Failed to delete shift: \(error.localizedDescription)"
                }
            }
        }
    }

    private func initializeShiftSwitchService() {
        let calendarService = CalendarService.shared
        let repository = SwiftDataChangeLogRepository(modelContext: modelContext)
        shiftSwitchService = ShiftSwitchService(
            calendarService: calendarService,
            changeLogRepository: repository
        )
    }

    private func switchShift(_ shift: ScheduledShift, to newShiftType: ShiftType, reason: String?) async throws {
        guard let service = shiftSwitchService,
              let oldShiftType = shift.shiftType else {
            throw ShiftSwitchError.shiftNotFound
        }

        try await service.switchShift(
            eventIdentifier: shift.eventIdentifier,
            scheduledDate: shift.date,
            from: oldShiftType,
            to: newShiftType,
            reason: reason
        )

        // Update the cache immediately with the new shift type
        await dataManager.updateShift(shift, with: newShiftType)
    }
}

// MARK: - Fade-In Shift Card Component
struct FadeInShiftCard: View {
    let shift: ScheduledShift
    let onDelete: (() -> Void)?
    let onSwitch: (() -> Void)?

    @State private var opacity: Double = 0.0
    @State private var scale: Double = 0.95
    @State private var hasAppeared = false

    var body: some View {
        EnhancedShiftCard(shift: shift, onDelete: onDelete, onSwitch: onSwitch)
            .opacity(opacity)
            .scaleEffect(scale)
            .onAppear {
                // Only animate on first appearance to prevent re-animation on scroll
                guard !hasAppeared else {
                    opacity = 1.0
                    scale = 1.0
                    return
                }
                hasAppeared = true

                // Delay the fade-in animation by 0.05 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                        opacity = 1.0
                        scale = 1.0
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
