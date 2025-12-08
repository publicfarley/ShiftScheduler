import SwiftUI
import OSLog

private let logger = Logger(subsystem: "com.shiftscheduler.views", category: "Schedule")

struct ScheduleView: View {
    @Environment(\.reduxStore) var store
    @State private var listOpacity: Double = 1
    @State private var showBulkDeleteConfirmation = false
    @State private var showBulkAddSheet = false

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Title
                Text("Schedule")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.vertical, 6)

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
        .sheet(
            isPresented: $showBulkAddSheet,
            onDismiss: {
                Task {
                    await store.dispatch(action: .schedule(.clearSelectedDates))
                }
            }
        ) {
            ShiftTypeSelectionView(
                isPresented: $showBulkAddSheet,
                availableShiftTypes: store.state.shiftTypes.shiftTypes,
                selectedDateCount: store.state.schedule.selectedDates.count,
                onConfirm: { shiftType, notes in
                    Task {
                        await store.dispatch(action: .schedule(.bulkAddConfirmed(shiftType: shiftType, notes: notes)))
                        showBulkAddSheet = false
                    }
                },
                onDismiss: {
                    Task {
                        await store.dispatch(action: .schedule(.clearSelectedDates))
                    }
                }
            )
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
        .bulkDeleteConfirmationAlert(
            isPresented: $showBulkDeleteConfirmation,
            count: store.state.schedule.selectionCount,
            onConfirm: {
                Task {
                    await store.dispatch(action: .schedule(.bulkDeleteConfirmed(Array(store.state.schedule.selectedShiftIds))))
                }
            },
            onCancel: {}
        )
    }

    // MARK: - Computed Properties

    private var formattedSelectedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: store.state.schedule.selectedDate)
    }

    private var scheduledShiftsByDate: [Date: [ScheduledShift]] {
        var shiftsByDate: [Date: [ScheduledShift]] = [:]
        let calendar = Calendar.current

        for shift in store.state.schedule.scheduledShifts {
            let dateKey = calendar.startOfDay(for: shift.date)
            shiftsByDate[dateKey, default: []].append(shift)
        }
        return shiftsByDate
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
            // TOOLBAR - Always visible at top
            if store.state.schedule.isInSelectionMode {
                SelectionToolbarView(
                    selectionCount: store.state.schedule.selectionCount,
                    canDelete: store.state.schedule.canDeleteSelectedShifts,
                    isDeleting: store.state.schedule.isDeletingShift,
                    selectionMode: store.state.schedule.selectionMode,
                    onDelete: {
                        // Show confirmation dialog before deleting
                        showBulkDeleteConfirmation = true
                    },
                    onAdd: {
                        // Show shift type selection sheet for bulk add
                        showBulkAddSheet = true
                    },
                    onClear: {
                        Task {
                            await store.dispatch(action: .schedule(.clearSelection))
                        }
                    },
                    onExit: {
                        Task {
                            await store.dispatch(action: .schedule(.exitSelectionMode))
                        }
                    }
                )
            } else {
                // Normal header buttons
                HStack(spacing: 16) {
                    // Menu with add and bulk add options
                    Menu {
                        Button(action: {
                            Task {
                                await store.dispatch(action: .schedule(.addShiftButtonTapped))
                            }
                        }) {
                            Label("Add Single Shift", systemImage: "plus.circle")
                        }

                        Button(action: {
                            Task {
                                await store.dispatch(action: .schedule(.enterSelectionMode(mode: .add, firstId: UUID())))
                                showBulkAddSheet = false  // Reset to prepare for bulk add
                            }
                        }) {
                            Label("Add Multiple Shifts", systemImage: "plus.circle.fill")
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "plus.circle")
                                .font(.title2)
                                .foregroundColor(.primary)
                            Text("Add")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity)
                    }

                    Spacer()
                    todayButton
                    filterButton
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 6)
                .background(
                    Color(.systemBackground)
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                )
            }

            // SCROLLABLE CONTENT
            ScrollView {
                VStack(spacing: 0) {
                    // CALENDAR SECTION - Scrollable month views
                    VStack(spacing: 0) {
                        // Horizontally scrollable month views
                        ScrollableMonthView(
                            selectedDate: Binding(
                                get: { store.state.schedule.selectedDate },
                                set: { date in
                                    Task {
                                        await store.dispatch(action: .schedule(.selectedDateChanged(date)))
                                    }
                                }
                            ),
                            displayedMonth: Binding(
                                get: { store.state.schedule.displayedMonth },
                                set: { month in
                                    Task {
                                        // Normalize month to first day at start-of-day
                                        let calendar = Calendar.current
                                        let components = calendar.dateComponents([.year, .month], from: month)
                                        let normalizedMonth = calendar.date(from: components) ?? month
                                        await store.dispatch(action: .schedule(.displayedMonthChanged(normalizedMonth)))
                                    }
                                }
                            ),
                            scrollToDateTrigger: Binding(
                                get: { store.state.schedule.scrollToDateTrigger },
                                set: { _ in
                                    // Binding is read-only - reducer controls scroll trigger
                                }
                            ),
                            scheduledShiftsByDate: scheduledShiftsByDate,
                            selectionMode: store.state.schedule.selectionMode,
                            selectedDates: store.state.schedule.selectedDates
                        )

                        // Selected date display - fixed position at bottom
                        Text(formattedSelectedDate)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 40)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // SHIFTS SECTION
                    VStack(spacing: 12) {
                        // Shifts list or empty state
                        Group {
                            if store.state.schedule.filteredShifts.isEmpty {
                                emptyStateView
                            } else {
                                shiftsContentView
                            }
                        }
                        .opacity(listOpacity)
                    }
                    .padding(.bottom, 20)
                }
                .padding(.vertical, 4)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .onChange(of: store.state.schedule.selectedDate) { _, _ in
            resetListAnimation()
        }
    }

    private var shiftsContentView: some View {
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
                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.title2)
                        .foregroundColor(.secondary)

                    VStack(spacing: 2) {
                        Text("No Shifts Found")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        Text("Try adjusting your filters or clearing them to see more shifts.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Button(action: clearAllFilters) {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))

                            Text("Clear Filters")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .foregroundColor(.white)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .cyan]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(6)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray4), lineWidth: 2)
                        )
                        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                )
                .padding(.horizontal, 40)
            } else {
                // No filter - standard "No shift scheduled" state matching TodayView
                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.title2)
                        .foregroundColor(.secondary)

                    VStack(spacing: 2) {
                        Text("No shift scheduled")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        Text("Add today's shift or enjoy your day off")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Button(action: {
                        Task {
                            await store.dispatch(action: .schedule(.addShiftButtonTapped))
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 14))

                            Text("Add Shift")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .foregroundColor(.white)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.purple, .indigo]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(6)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray4), lineWidth: 2)
                        )
                        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                )
                .padding(.horizontal, 40)
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
            VStack(spacing: 4) {
                Image(systemName: "calendar.badge.clock")
                    .font(.title2)
                    .foregroundColor(.primary)
                Text("Today")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
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
            VStack(spacing: 4) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.title2)
                    .foregroundColor(store.state.schedule.hasActiveFilters ? .blue : .primary)
                Text("Filter")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(store.state.schedule.hasActiveFilters ? .blue : .primary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func shiftCard(for shift: ScheduledShift) -> some View {
        UnifiedShiftCard(
            shift: shift,
            onTap: {
                Task {
                    await store.dispatch(action: .schedule(.shiftTapped(shift)))
                }
            },
            isSelected: store.state.schedule.selectedShiftIds.contains(shift.id),
            onSelectionToggle: { shiftId in
                Task {
                    if store.state.schedule.isInSelectionMode {
                        // Already in selection mode - toggle selection
                        await store.dispatch(action: .schedule(.toggleShiftSelection(shiftId)))
                    } else {
                        // Not in selection mode - enter it
                        await store.dispatch(action: .schedule(.enterSelectionMode(mode: .delete, firstId: shiftId)))
                    }
                }
            },
            isInSelectionMode: store.state.schedule.isInSelectionMode
        )
        .padding(.horizontal, 40)  // Match peekWidth from ScrollableMonthView
    }

    private func clearAllFilters() {
        // logger.debug("Clearing all filters")
        Task {
            await store.dispatch(action: .schedule(.clearFilters))
        }
    }
}

// MARK: - Preview
#Preview("Schedule View with Animations") {
    let sampleLocation = Location(id: UUID(), name: "Main Office", address: "123 Main St")

    // Create multiple shift types for visual variety
    let morningShift = ShiftType(
        id: UUID(),
        symbol: "🌅",
        duration: .scheduled(
            from: HourMinuteTime(hour: 6, minute: 0),
            to: HourMinuteTime(hour: 14, minute: 0)
        ),
        title: "Morning Shift",
        description: "Early morning shift with team briefing",
        location: sampleLocation
    )

    let eveningShift = ShiftType(
        id: UUID(),
        symbol: "🌆",
        duration: .scheduled(
            from: HourMinuteTime(hour: 14, minute: 0),
            to: HourMinuteTime(hour: 22, minute: 0)
        ),
        title: "Evening Shift",
        description: "Evening shift with handover",
        location: sampleLocation
    )

    // Today's shift
    let todayShift = ScheduledShift(
        id: UUID(),
        eventIdentifier: UUID().uuidString,
        shiftType: morningShift,
        date: Date()
    )

    // Tomorrow's shift
    let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    let tomorrowShift = ScheduledShift(
        id: UUID(),
        eventIdentifier: UUID().uuidString,
        shiftType: eveningShift,
        date: tomorrowDate
    )

    // Create preview store with sample data
    let previewStore: Store = {
        var state = AppState()
        state.today.scheduledShifts = [todayShift, tomorrowShift]
        state.today.isLoading = false
        state.isCalendarAuthorized = true
        state.isCalendarAuthorizationVerified = true
        state.locations.locations = [sampleLocation]
        state.shiftTypes.shiftTypes = [morningShift, eveningShift]

        return Store(
            state: state,
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
    }()

    ScheduleView()
        .environment(\.reduxStore, previewStore)
}
