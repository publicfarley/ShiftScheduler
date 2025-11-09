import SwiftUI
import OSLog

private let logger = Logger(subsystem: "com.shiftscheduler.views", category: "Schedule")

struct ScheduleView: View {
    @Environment(\.reduxStore) var store
    @State private var listOpacity: Double = 1

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Title
                Text("Schedule")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()

                if !store.state.schedule.isCalendarAuthorized {
                    authorizationRequiredView
                } else {
                    scheduleContentView
                }
            }

            // Success Toast - Centered overlay
            if store.state.schedule.showSuccessToast, let message = store.state.schedule.successMessage {
                VStack {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.headline)
                                .foregroundColor(.green)

                            Text(message)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)

                            Spacer()

                            Button(action: {
                                Task {
                                    await store.dispatch(action: .schedule(.dismissSuccessToast))
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(16)
                    .background(Color.green.opacity(0.9))
                    .border(Color.green, width: 1)
                    .cornerRadius(12)
                    .padding(16)
                    .frame(maxWidth: 400)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .offset(y: 80)
                .transition(.asymmetric(insertion: .scale.combined(with: .opacity),
                                       removal: .scale.combined(with: .opacity)))
                .task {
                    // Auto-dismiss after 3 seconds
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    await store.dispatch(action: .schedule(.dismissSuccessToast))
                }
            }

            // Loading Overlay
            if store.state.schedule.isLoading || store.state.schedule.isRestoringStacks {
                LoadingOverlayView(message: nil)
            } else if store.state.schedule.isLoadingAdditionalShifts {
                LoadingOverlayView(message: "Loading additional shifts...")
            }
        }
        .sheet(
            isPresented: Binding(
                get: { store.state.schedule.showAddShiftSheet },
                set: { _ in
                    // Binding is read-only - reducer controls sheet presentation
                    // Sheet only closes via Cancel button or successful save
                }
            ),
            onDismiss: {
                Task {
                    await store.dispatch(action: .schedule(.addShiftSheetDismissed))
                }
            }
        ) {
            AddShiftModalView(
                isPresented: Binding(
                    get: { store.state.schedule.showAddShiftSheet },
                    set: { _ in
                        // Binding is read-only - reducer controls sheet state
                        // based on .addShiftResponse success/failure
                    }
                ),
                availableShiftTypes: store.state.shiftTypes.shiftTypes,
                preselectedDate: store.state.schedule.selectedDate,
                currentError: store.state.schedule.currentError,
                onAddShift: { date, shiftType, notes in
                    await store.dispatch(action: .schedule(.addShift(date: date, shiftType: shiftType, notes: notes)))
                },
                onDismissError: {
                    await store.dispatch(action: .schedule(.dismissError))
                },
                onCancel: {
                    Task {
                        await store.dispatch(action: .schedule(.addShiftSheetDismissed))
                    }
                }
            )
        }
        .sheet(
            isPresented: .constant(store.state.schedule.showFilterSheet),
            onDismiss: {
                Task {
                    await store.dispatch(action: .schedule(.filterSheetToggled(false)))
                }
            }
        ) {
            ScheduleFilterSheetView()
        }
        .sheet(
            isPresented: .constant(store.state.schedule.showShiftDetail),
            onDismiss: {
                Task {
                    await store.dispatch(action: .schedule(.shiftDetailDismissed))
                }
            }
        ) {
            if let shiftId = store.state.schedule.selectedShiftId {
                ShiftDetailsView(initialShiftId: shiftId)
                    .environment(\.reduxStore, store)
            }
        }
        .sheet(
            isPresented: .constant(store.state.schedule.showOverlapResolution),
            onDismiss: {
                Task {
                    await store.dispatch(action: .schedule(.overlapResolutionDismissed))
                }
            }
        ) {
            if let date = store.state.schedule.overlapDate,
               !store.state.schedule.overlappingShifts.isEmpty {
                OverlapResolutionSheet(
                    date: date,
                    overlappingShifts: store.state.schedule.overlappingShifts
                )
                .environment(\.reduxStore, store)
            }
        }
        .onAppear {
            logger.debug("ScheduleView appeared - selectedDate: \(store.state.schedule.selectedDate.formatted()), shifts count: \(store.state.schedule.scheduledShifts.count), filtered: \(store.state.schedule.filteredShifts.count)")
            Task {
                await store.dispatch(action: .schedule(.initializeAndLoadScheduleData))
            }
        }
        .onChange(of: store.state.schedule.scheduledShifts) { _, shifts in
            logger.debug("Shifts loaded - count: \(shifts.count), selectedDate: \(store.state.schedule.selectedDate.formatted()), filtered: \(store.state.schedule.filteredShifts.count)")
        }
        .dismissKeyboardOnTap()
    }

    // MARK: - Computed Properties

    private var formattedSelectedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: store.state.schedule.selectedDate)
    }

    // MARK: - View Components

    private var authorizationRequiredView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundColor(.red)
            Text("Calendar Access Required")
                .font(.headline)
            Text("ShiftScheduler needs calendar access to view your schedule.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .font(.body)
            Button("Open Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private var scheduleContentView: some View {
        VStack(spacing: 0) {
            // Header with buttons
            HStack(spacing: 16) {
                addShiftButton
                Spacer()
                todayButton
                filterButton
            }
            .padding(.horizontal)
            .padding(.vertical, 12)

            // Calendar month view - FIXED SIZE
            VStack(spacing: 0) {
                CustomCalendarView(
                    selectedDate: Binding(
                        get: { store.state.schedule.selectedDate },
                        set: { date in
                            Task {
                                await store.dispatch(action: .schedule(.selectedDateChanged(date)))
                            }
                        }
                    ),
                    scheduledDates: Set(
                        store.state.schedule.scheduledShifts.map { shift in
                            Calendar.current.startOfDay(for: shift.date)
                        }
                    )
                )
                .padding()
                .background(Color(.systemGray6))

                // Selected date display
                Text(formattedSelectedDate)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.vertical, 12)
            }
            .fixedSize(horizontal: false, vertical: true)

            // Shifts list or empty state - FILLS REMAINING SPACE
            Group {
                if store.state.schedule.filteredShifts.isEmpty {
                    emptyStateView
                } else {
                    shiftsListView
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .opacity(listOpacity)
            .onChange(of: store.state.schedule.selectedDate) { _, _ in
                resetListAnimation()
            }
        }
    }

    private var shiftsListView: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Active filters indicator
                if store.state.schedule.hasActiveFilters {
                    activeFiltersIndicator
                }

                // Shift count
                HStack {
                    if store.state.schedule.hasActiveFilters {
                        Button(action: clearAllFilters) {
                            Text("Clear filters")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal)

                // Shifts
                VStack(spacing: 12) {
                    ForEach(store.state.schedule.filteredShifts, id: \.id) { shift in
                        shiftCard(for: shift)
                    }
                }
            }
        }
    }

    private func resetListAnimation() {
        listOpacity = 0
        Task {
            try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
            withAnimation(.easeIn(duration: 0.6)) {
                listOpacity = 1
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 0) {
            Spacer()

            if store.state.schedule.hasActiveFilters {
                // Filter-specific empty state
                VStack(spacing: 16) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)

                    VStack(spacing: 4) {
                        Text("No Shifts Found")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text("Try adjusting your filters or clearing them to see more shifts.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Button(action: clearAllFilters) {
                        HStack(spacing: 8) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))

                            Text("Clear Filters")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundColor(.white)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .cyan]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(8)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray4), lineWidth: 2)
                        )
                        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                )
                .padding(.horizontal, 16)
            } else {
                // No filter - standard "No shift scheduled" state matching TodayView
                VStack(spacing: 16) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)

                    VStack(spacing: 4) {
                        Text("No shift scheduled")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text("Add today's shift or enjoy your day off")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Button(action: {
                        Task {
                            await store.dispatch(action: .schedule(.addShiftButtonTapped))
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18))

                            Text("Add Shift")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundColor(.white)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.purple, .indigo]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(8)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray4), lineWidth: 2)
                        )
                        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                )
                .padding(.horizontal, 16)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var activeFiltersIndicator: some View {
        HStack(spacing: 8) {
            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                .font(.caption)
            Text("Filters applied")
                .font(.caption)
                .fontWeight(.semibold)
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.blue.opacity(0.1))
        .foregroundColor(.blue)
        .cornerRadius(6)
        .padding(.horizontal)
    }

    private var addShiftButton: some View {
        Button(action: {
            Task {
                await store.dispatch(action: .schedule(.addShiftSheetToggled(true)))
            }
        }) {
            Image(systemName: "plus.circle")
                .foregroundColor(.primary)
        }
    }

    private var todayButton: some View {
        Button(action: {
            Task {
                await store.dispatch(action: .schedule(.jumpToToday))
            }
        }) {
            Image(systemName: "calendar.badge.clock")
                .foregroundColor(.primary)
        }
        .transaction { transaction in
            transaction.animation = .easeInOut(duration: 0.3)
        }
    }

    private var filterButton: some View {
        Button(action: {
            Task {
                await store.dispatch(action: .schedule(.filterSheetToggled(true)))
            }
        }) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .foregroundColor(store.state.schedule.hasActiveFilters ? .blue : .primary)
        }
    }

    private func shiftCard(for shift: ScheduledShift) -> some View {
        UnifiedShiftCard(
            shift: shift,
            onTap: {
                Task {
                    await store.dispatch(action: .schedule(.shiftTapped(shift)))
                }
            }
        )
        .padding(.horizontal)
    }

    private func clearAllFilters() {
        // logger.debug("Clearing all filters")
        Task {
            await store.dispatch(action: .schedule(.clearFilters))
        }
    }
}

#Preview {
    ScheduleView()
        .environment(\.reduxStore, previewStore)
}

private let previewStore: Store = {
    let store = Store(
        state: AppState(),
        reducer: appReducer,
        services: ServiceContainer(),
        middlewares: [
            scheduleMiddleware,
            todayMiddleware,
            locationsMiddleware,
            shiftTypesMiddleware,
            changeLogMiddleware,
            settingsMiddleware,
            loggingMiddleware
        ]
    )
    return store
}()

