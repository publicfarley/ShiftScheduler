import SwiftUI

// MARK: - Shift Details View
/// Modal sheet view displaying detailed information about a scheduled shift
/// Allows viewing shift details and performing actions (switch, delete)
struct ShiftDetailsView: View {
    @Environment(\.reduxStore) var store
    @Environment(\.dismiss) var dismiss

    let shift: ScheduledShift

    @State private var showingDeleteConfirmation = false
    @State private var showingSwitchSheet = false

    private var shiftStatus: ShiftStatus {
        guard let shiftType = shift.shiftType else { return .upcoming }

        let now = Date()
        let calendar = Calendar.current

        // Check if shift is today
        if calendar.isDate(shift.date, inSameDayAs: now) {
            switch shiftType.duration {
            case .allDay:
                return .active
            case .scheduled(let startTime, let endTime):
                let shiftStart = startTime.toDate(on: shift.date)
                let shiftEnd = endTime.toDate(on: shift.date)

                if now < shiftStart {
                    return .upcoming
                } else if now >= shiftStart && now <= shiftEnd {
                    return .active
                } else {
                    return .completed
                }
            }
        } else if shift.date < now {
            return .completed
        } else {
            return .upcoming
        }
    }

    private var cardColor: Color {
        guard let shiftType = shift.shiftType else { return .blue }
        return ShiftColorPalette.colorForShift(shiftType)
    }

    private var formattedDate: String {
        shift.date.formatted(date: .abbreviated, time: .omitted)
    }

    private var formattedTime: String {
        guard let shiftType = shift.shiftType else { return "All Day" }

        switch shiftType.duration {
        case .allDay:
            return "All Day"
        case .scheduled(let from, let to):
            let startStr = from.timeString
            let endStr = to.timeString
            return "\(startStr) - \(endStr)"
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with shift symbol and status
                    VStack(spacing: 16) {
                        HStack {
                            StatusBadge(status: shiftStatus)
                            Spacer()

                            Button(action: { dismiss() }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.gray.opacity(0.6))
                            }
                        }

                        HStack(spacing: 16) {
                            // Shift symbol
                            if let shiftType = shift.shiftType {
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

                        if let location = shift.shiftType?.location {
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
                    if let shiftType = shift.shiftType,
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
                        Button(action: { showingSwitchSheet = true }) {
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text("Shift Details")
                        .font(.headline)
                }
            }
        }
        .sheet(isPresented: $showingSwitchSheet) {
            ShiftChangeSheet(currentShift: shift, feature: .schedule)
                .environment(\.reduxStore, store)
        }
        .alert("Delete Shift?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                store.dispatch(action: .schedule(.deleteShift(shift)))
                dismiss()
            }
        } message: {
            Text("This shift will be permanently deleted. This action cannot be undone.")
        }
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

    ShiftDetailsView(shift: sampleShift)
        .environment(\.reduxStore, shiftDetailsPreviewStore)
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
