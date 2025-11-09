import SwiftUI
import OSLog

private let logger = Logger(subsystem: "com.shiftscheduler.views", category: "ScheduleFilterSheet")

/// Filter sheet view for Schedule view
/// Allows users to filter shifts by date range, location, and shift type
struct ScheduleFilterSheetView: View {
    @Environment(\.reduxStore) var store
    @Environment(\.dismiss) var dismiss

    // Local state for form inputs
    @State private var startDate: Date?
    @State private var endDate: Date?
    @State private var selectedLocation: Location?
    @State private var selectedShiftType: ShiftType?

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Date Range Section

                Section("Date Range") {
                    HStack {
                        Text("From")
                        Spacer()
                        DatePicker(
                            "Start Date",
                            selection: Binding(
                                get: { startDate ?? Date() },
                                set: { startDate = $0 }
                            ),
                            displayedComponents: [.date]
                        )
                        .labelsHidden()
                    }

                    HStack {
                        Text("To")
                        Spacer()
                        DatePicker(
                            "End Date",
                            selection: Binding(
                                get: { endDate ?? Date() },
                                set: { endDate = $0 }
                            ),
                            displayedComponents: [.date]
                        )
                        .labelsHidden()
                    }

                    // Clear date range button
                    if startDate != nil || endDate != nil {
                        Button(action: clearDateRange) {
                            Text("Clear Date Range")
                                .foregroundColor(.red)
                        }
                    }
                }

                // MARK: - Location Section

                Section("Location Filter") {
                    if store.state.locations.locations.isEmpty {
                        Text("No locations available")
                            .foregroundColor(.gray)
                    } else {
                        Picker("Location", selection: Binding(
                            get: { selectedLocation ?? store.state.locations.locations.first },
                            set: { selectedLocation = $0 }
                        )) {
                            Text("Any Location")
                                .tag(Optional<Location>.none)

                            ForEach(store.state.locations.locations) { location in
                                Text(location.name)
                                    .tag(Optional(location))
                            }
                        }
                    }
                }

                // MARK: - Shift Type Section

                Section("Shift Type Filter") {
                    if store.state.shiftTypes.shiftTypes.isEmpty {
                        Text("No shift types available")
                            .foregroundColor(.gray)
                    } else {
                        Picker("Shift Type", selection: Binding(
                            get: { selectedShiftType ?? store.state.shiftTypes.shiftTypes.first },
                            set: { selectedShiftType = $0 }
                        )) {
                            Text("Any Shift Type")
                                .tag(Optional<ShiftType>.none)

                            ForEach(store.state.shiftTypes.shiftTypes) { shiftType in
                                Text(shiftType.title)
                                    .tag(Optional(shiftType))
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filter Shifts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        cancelFilters()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: applyFilters) {
                        Text("Apply")
                            .fontWeight(.semibold)
                    }
                }
            }
            .onAppear(perform: loadCurrentFilters)
            .dismissKeyboardOnTap()
        }
    }

    // MARK: - Helper Methods

    private func loadCurrentFilters() {
        startDate = store.state.schedule.filterDateRangeStart
        endDate = store.state.schedule.filterDateRangeEnd
        selectedLocation = store.state.schedule.filterSelectedLocation
        selectedShiftType = store.state.schedule.filterSelectedShiftType
    }

    private func applyFilters() {
        // logger.debug("Applying filters: dates \(String(describing: startDate))-\(String(describing: endDate)), location: \(selectedLocation?.name ?? "None"), type: \(selectedShiftType?.title ?? "None")")

        Task {
            // Dispatch filter actions
            if let start = startDate, let end = endDate {
                await store.dispatch(action: .schedule(.filterDateRangeChanged(startDate: start, endDate: end)))
            } else {
                await store.dispatch(action: .schedule(.filterDateRangeChanged(startDate: nil, endDate: nil)))
            }

            await store.dispatch(action: .schedule(.filterLocationChanged(selectedLocation)))
            await store.dispatch(action: .schedule(.filterShiftTypeChanged(selectedShiftType)))
            await store.dispatch(action: .schedule(.filterSheetToggled(false)))

            dismiss()
        }
    }

    private func clearDateRange() {
        startDate = nil
        endDate = nil
    }

    private func cancelFilters() {
        Task {
            await store.dispatch(action: .schedule(.filterSheetToggled(false)))
            dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    ScheduleFilterSheetView()
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
