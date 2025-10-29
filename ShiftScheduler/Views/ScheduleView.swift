import SwiftUI
import OSLog

private let logger = Logger(subsystem: "com.shiftscheduler.views", category: "Schedule")

struct ScheduleView: View {
    @Environment(\.reduxStore) var store
    @State private var listOpacity: Double = 1

    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    if !store.state.schedule.isCalendarAuthorized {
                        authorizationRequiredView
                    } else {
                        scheduleContentView
                    }
                }

                // Success Toast
                if store.state.schedule.showSuccessToast, let message = store.state.schedule.successMessage {
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

                            Button(action: { store.dispatch(action: .schedule(.dismissSuccessToast)) }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(16)
                    .background(Color.green.opacity(0.1))
                    .border(Color.green, width: 1)
                    .cornerRadius(12)
                    .padding(16)
                    .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity),
                                           removal: .move(edge: .top).combined(with: .opacity)))
                    .onAppear {
                        // Auto-dismiss after 3 seconds
                        Task {
                            try? await Task.sleep(nanoseconds: 3_000_000_000)
                            await MainActor.run {
                                withAnimation {
                                    store.dispatch(action: .schedule(.dismissSuccessToast))
                                }
                            }
                        }
                    }
                }

                // Loading Overlay
                if store.state.schedule.isLoading || store.state.schedule.isRestoringStacks {
                    LoadingOverlayView(message: nil)
                }
            }
            .navigationTitle("Schedule")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if store.state.schedule.isCalendarAuthorized {
                    ToolbarItem(placement: .navigationBarLeading) {
                        addShiftButton
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        filterButton
                    }
                }
            }
            .sheet(isPresented: Binding(
                get: { store.state.schedule.showAddShiftSheet },
                set: { isPresented in
                    if !isPresented {
                        store.dispatch(action: .schedule(.addShiftSheetDismissed))
                    }
                }
            )) {
                AddShiftModalView(
                    isPresented: Binding(
                        get: { store.state.schedule.showAddShiftSheet },
                        set: { isPresented in
                            if !isPresented {
                                store.dispatch(action: .schedule(.addShiftSheetDismissed))
                            }
                        }
                    ),
                    availableShiftTypes: store.state.shiftTypes.shiftTypes,
                    preselectedDate: store.state.schedule.selectedDate
                )
            }
            .sheet(
                isPresented: .constant(store.state.schedule.showFilterSheet),
                onDismiss: {
                    store.dispatch(action: .schedule(.filterSheetToggled(false)))
                }
            ) {
                ScheduleFilterSheetView()
            }
            .sheet(
                isPresented: .constant(store.state.schedule.showShiftDetail),
                onDismiss: {
                    store.dispatch(action: .schedule(.shiftDetailDismissed))
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
                    store.dispatch(action: .schedule(.overlapResolutionDismissed))
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
            .errorAlert(error: Binding(
                get: { store.state.schedule.currentError },
                set: { _ in store.dispatch(action: .schedule(.dismissError)) }
            ))
            .onAppear {
                logger.debug("ScheduleView appeared - selectedDate: \(store.state.schedule.selectedDate.formatted()), shifts count: \(store.state.schedule.scheduledShifts.count), filtered: \(store.state.schedule.filteredShifts.count)")
                store.dispatch(action: .schedule(.task))
            }
            .onChange(of: store.state.schedule.scheduledShifts) { _, shifts in
                logger.debug("Shifts loaded - count: \(shifts.count), selectedDate: \(store.state.schedule.selectedDate.formatted()), filtered: \(store.state.schedule.filteredShifts.count)")
            }
        }
        .dismissKeyboardOnTap()
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
            // Calendar month view
            CustomCalendarView(
                selectedDate: Binding(
                    get: { store.state.schedule.selectedDate },
                    set: { store.dispatch(action: .schedule(.selectedDateChanged($0))) }
                ),
                scheduledDates: Set(
                    store.state.schedule.scheduledShifts.map { shift in
                        Calendar.current.startOfDay(for: shift.date)
                    }
                )
            )
            .padding()
            .background(Color(.systemGray6))

            // Shifts list or empty state with fade animation
            Group {
                if store.state.schedule.filteredShifts.isEmpty {
                    emptyStateView
                } else {
                    shiftsListView
                }
            }
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
                    Text("Showing \(store.state.schedule.filteredShifts.count) shift(s)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
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
            .padding(.vertical)
        }
    }

    private func resetListAnimation() {
        listOpacity = 0
        Task {
            try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
            await MainActor.run {
                withAnimation(.easeIn(duration: 0.6)) {
                    listOpacity = 1
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "calendar")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            Text("No Shifts Found")
                .font(.headline)
            if store.state.schedule.hasActiveFilters {
                Text("Try adjusting your filters or clearing them to see more shifts.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .font(.body)
                Button(action: clearAllFilters) {
                    Text("Clear Filters")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding()
            } else {
                Text("No shifts scheduled for this date.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .font(.body)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
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
        Button(action: { store.dispatch(action: .schedule(.addShiftSheetToggled(true))) }) {
            Image(systemName: "plus.circle")
                .foregroundColor(.primary)
        }
    }

    private var filterButton: some View {
        Button(action: { store.dispatch(action: .schedule(.filterSheetToggled(true))) }) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .foregroundColor(store.state.schedule.hasActiveFilters ? .blue : .primary)
        }
    }

    private func shiftCard(for shift: ScheduledShift) -> some View {
        UnifiedShiftCard(
            shift: shift,
            onTap: {
                store.dispatch(action: .schedule(.shiftTapped(shift)))
            }
        )
        .padding(.horizontal)
    }

    private func clearAllFilters() {
        // logger.debug("Clearing all filters")
        store.dispatch(action: .schedule(.clearFilters))
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

