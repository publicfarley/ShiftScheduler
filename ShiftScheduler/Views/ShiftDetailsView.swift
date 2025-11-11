import SwiftUI

// MARK: - Shift Details View
/// Modal sheet view displaying detailed information about a scheduled shift
/// Allows viewing shift details and performing actions (switch, delete)
/// Automatically updates when the shift data changes in Redux state
struct ShiftDetailsView: View {
    @Environment(\.reduxStore) var store

    let initialShiftId: UUID

    @State private var showingDeleteConfirmation = false

    /// Computed property that always reads the latest shift data from Redux store
    private var shift: ScheduledShift? {
        store.state.schedule.selectedShiftForDetail
    }

    private var shiftStatus: ShiftStatus {
        guard let shift = shift,
              let shiftType = shift.shiftType else { return .upcoming }

        let now = Date()

        // Use actual start/end date-times for multi-day shift support
        let shiftStart = shift.actualStartDateTime()
        let shiftEnd = shift.actualEndDateTime()

        // Determine status based on current time relative to shift date-time range
        if now < shiftStart {
            return .upcoming
        } else if now >= shiftStart && now <= shiftEnd {
            return .active
        } else {
            return .completed
        }
    }

    private var cardColor: Color {
        guard let shift = shift,
              let shiftType = shift.shiftType else { return .blue }
        return ShiftColorPalette.colorForShift(shiftType)
    }

    private var formattedDate: String {
        guard let shift = shift else { return "" }
        return shift.date.formatted(date: .abbreviated, time: .omitted)
    }

    private var formattedTime: String {
        guard let shift = shift,
              let shiftType = shift.shiftType else { return "All Day" }

        // Use timeRangeString which includes +1 indicator for overnight shifts
        return shiftType.duration.timeRangeString
    }

    var body: some View {
        NavigationStack {
            Group {
                if let currentShift = shift {
                    shiftContentView(for: currentShift)
                } else {
                    // Fallback if shift data is unavailable
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        Text("Shift Not Found")
                            .font(.headline)
                        Text("The shift data could not be loaded.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        Task {
                            await store.dispatch(action: .schedule(.shiftDetailDismissed))
                        }
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text("Shift Details")
                        .font(.headline)
                }
            }
        }
        .sheet(isPresented: .constant(store.state.schedule.showSwitchShiftSheet), onDismiss: {
            Task {
                await store.dispatch(action: .schedule(.switchShiftSheetToggled(false)))
            }
        }) {
            if let currentShift = shift {
                ShiftChangeSheet(currentShift: currentShift, feature: .schedule)
                    .environment(\.reduxStore, store)
            }
        }
        .alert("Delete Shift?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let currentShift = shift {
                    Task {
                        await store.dispatch(action: .schedule(.deleteShift(currentShift)))
                        await store.dispatch(action: .schedule(.shiftDetailDismissed))
                    }
                }
            }
        } message: {
            Text("This shift will be permanently deleted. This action cannot be undone.")
        }
    }

    // MARK: - Content Views

    @ViewBuilder
    private func shiftContentView(for currentShift: ScheduledShift) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with shift symbol and status
                VStack(spacing: 16) {
                    HStack {
                        StatusBadge(status: shiftStatus)
                        Spacer()
                    }

                    HStack(spacing: 16) {
                        // Shift symbol
                        if let shiftType = currentShift.shiftType {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [cardColor.opacity(0.2), cardColor.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )

                                Text(shiftType.symbol)
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(cardColor)
                            }
                            .frame(width: 80, height: 80)

                            VStack(alignment: .leading, spacing: 8) {
                                Text(shiftType.title)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.primary)

                                Text(formattedDate)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.white)
                        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                )

                // Details section
                VStack(spacing: 16) {
                    DetailRow(
                        icon: "clock.fill",
                        label: "Time",
                        value: formattedTime,
                        color: cardColor
                    )

                    Divider()

                    if let location = currentShift.shiftType?.location {
                        DetailRow(
                            icon: "mappin.circle.fill",
                            label: "Location",
                            value: location.name,
                            color: cardColor
                        )

                        Divider()
                    }

                    DetailRow(
                        icon: "calendar",
                        label: "Date",
                        value: formattedDate,
                        color: cardColor
                    )
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.white)
                        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                )

                // Description if available
                if let shiftType = currentShift.shiftType,
                   !shiftType.shiftDescription.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Description")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text(shiftType.shiftDescription)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineLimit(nil)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.white)
                            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                    )
                }

                // Action buttons
                VStack(spacing: 12) {
                    Button(action: {
                        Task {
                            await store.dispatch(action: .schedule(.switchShiftTapped(currentShift)))
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.left.arrow.right")
                                .font(.body)
                            Text("Switch Shift")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(
                            LinearGradient(
                                colors: [cardColor, cardColor.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }

                    Button(action: { showingDeleteConfirmation = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "trash")
                                .font(.body)
                            Text("Delete Shift")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(10)
                    }
                }

                Spacer()
            }
            .padding(16)
        }
        .background(Color(.systemGray6))
    }
}

// MARK: - Detail Row Component
/// Reusable component for displaying key-value pairs in shift details
struct DetailRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)

                Text(value)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }

            Spacer()
        }
    }
}

#Preview {
    let sampleLocation = Location(id: UUID(), name: "Main Office", address: "123 Main St")
    let sampleShiftType = ShiftType(
        id: UUID(),
        symbol: "🌅",
        duration: .scheduled(
            from: HourMinuteTime(hour: 9, minute: 0),
            to: HourMinuteTime(hour: 17, minute: 0)
        ),
        title: "Morning Shift",
        description: "Regular morning shift with breaks",
        location: sampleLocation
    )
    let sampleShift = ScheduledShift(
        id: UUID(),
        eventIdentifier: UUID().uuidString,
        shiftType: sampleShiftType,
        date: Date()
    )

    let store = shiftDetailsPreviewStore
    // Configure preview store with sample shift
    var previewState = store.state
    previewState.schedule.selectedShiftId = sampleShift.id
    previewState.schedule.selectedShiftForDetail = sampleShift
    previewState.schedule.showShiftDetail = true

    return ShiftDetailsView(initialShiftId: sampleShift.id)
        .environment(\.reduxStore, store)
}

private let shiftDetailsPreviewStore: Store = {
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
