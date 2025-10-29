import SwiftUI

/// Sheet view for resolving overlapping shifts on the same date
/// User selects which shift to keep, and all others are deleted
struct OverlapResolutionSheet: View {
    @Environment(\.reduxStore) var store

    let date: Date
    let overlappingShifts: [ScheduledShift]

    @State private var selectedShift: ScheduledShift?

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)

                    Text("Overlapping Shifts Detected")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Multiple shifts found on \(date.formatted(date: .abbreviated, time: .omitted))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("Select which shift to keep. All others will be deleted.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top)

                // Shift selection list
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(overlappingShifts) { shift in
                            shiftCard(shift)
                        }
                    }
                    .padding()
                }

                // Action buttons
                HStack(spacing: 16) {
                    Button("Cancel") {
                        store.dispatch(action: .schedule(.overlapResolutionDismissed))
                    }
                    .buttonStyle(.bordered)

                    Button("Keep Selected") {
                        guard let selected = selectedShift else { return }
                        let shiftsToDelete = overlappingShifts.filter { $0.id != selected.id }
                        store.dispatch(action: .schedule(.resolveOverlap(
                            keepShift: selected,
                            deleteShifts: shiftsToDelete
                        )))
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedShift == nil)
                }
                .padding()
            }
            .navigationTitle("Resolve Overlap")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        store.dispatch(action: .schedule(.overlapResolutionDismissed))
                    }
                }
            }
        }
        .dismissKeyboardOnTap()
    }

    @ViewBuilder
    private func shiftCard(_ shift: ScheduledShift) -> some View {
        let isSelected = selectedShift?.id == shift.id

        Button {
            selectedShift = shift
        } label: {
            HStack(spacing: 16) {
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .blue : .gray)

                // Shift info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(shift.shiftType?.symbol ?? "❓")
                            .font(.title2)

                        Text(shift.shiftType?.title ?? "Unknown Shift")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }

                    if let location = shift.shiftType?.location {
                        Label(location.name, systemImage: "mappin.circle.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let shiftType = shift.shiftType {
                        switch shiftType.duration {
                        case .allDay:
                            Text("All Day")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        case .scheduled(let from, let to):
                            Text("\(from.formatted()) - \(to.formatted())")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let sampleLocation = Location(id: UUID(), name: "Main Office", address: "123 Main St")
    let sampleShiftType1 = ShiftType(
        id: UUID(),
        symbol: "🌅",
        duration: .allDay,
        title: "Morning Shift",
        shiftDescription: "Early morning shift",
        location: sampleLocation
    )
    let sampleShiftType2 = ShiftType(
        id: UUID(),
        symbol: "🌙",
        duration: .allDay,
        title: "Night Shift",
        shiftDescription: "Late night shift",
        location: sampleLocation
    )

    let shift1 = ScheduledShift(
        id: UUID(),
        eventIdentifier: "event1",
        shiftType: sampleShiftType1,
        date: Date()
    )
    let shift2 = ScheduledShift(
        id: UUID(),
        eventIdentifier: "event2",
        shiftType: sampleShiftType2,
        date: Date()
    )

    return OverlapResolutionSheet(
        date: Date(),
        overlappingShifts: [shift1, shift2]
    )
    .environment(\.reduxStore, Store(
        initialState: AppState(),
        reducer: appReducer,
        middleware: [],
        services: ServiceContainer(
            calendarService: MockCalendarService(),
            persistenceService: MockPersistenceService(),
            shiftSwitchService: MockShiftSwitchService(),
            currentDayService: MockCurrentDayService()
        )
    ))
}
