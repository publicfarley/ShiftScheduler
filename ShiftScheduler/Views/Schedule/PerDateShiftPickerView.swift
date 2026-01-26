import SwiftUI

/// Component for picking different shift types for individual dates
/// Used in the "different shift per date" bulk add mode
struct PerDateShiftPickerView: View {
    @Environment(\.reduxStore) var store

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Sorted dates for consistent display
            let sortedDates = store.state.schedule.selectedDates.sorted()

            if sortedDates.isEmpty {
                Text("No dates selected")
                    .font(.system(.subheadline, design: .default))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(16)
            } else {
                ForEach(sortedDates, id: \.self) { date in
                    DateShiftPickerRow(
                        date: date,
                        assignedShiftType: store.state.schedule.dateShiftAssignments[date],
                        availableShiftTypes: store.state.shiftTypes.shiftTypes,
                        onShiftSelected: { shiftType in
                            Task {
                                await store.dispatch(action: .schedule(.assignShiftToDate(date: date, shiftType: shiftType)))
                            }
                        },
                        onShiftRemoved: {
                            Task {
                                await store.dispatch(action: .schedule(.removeShiftAssignment(date: date)))
                            }
                        }
                    )
                    Divider()
                }
            }

            // Progress indicator
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Progress")
                        .font(.system(.caption, design: .default))
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("\(store.state.schedule.dateShiftAssignments.count) of \(sortedDates.count) assigned")
                        .font(.system(.caption2, design: .default))
                        .foregroundColor(.secondary)
                }

                ProgressView(value: Double(store.state.schedule.dateShiftAssignments.count), total: Double(sortedDates.count))
                    .tint(.blue)
            }
            .padding(.top, 8)
        }
    }
}

// MARK: - Date Shift Picker Row

/// Single row for picking a shift type for a specific date
private struct DateShiftPickerRow: View {
    let date: Date
    let assignedShiftType: ShiftType?
    let availableShiftTypes: [ShiftType]
    let onShiftSelected: (ShiftType) -> Void
    let onShiftRemoved: () -> Void

    @State private var showShiftPicker = false

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d, yyyy"
        return formatter
    }

    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Date header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(dayOfWeek)
                        .font(.system(.subheadline, design: .default))
                        .foregroundColor(.secondary)

                    Text(dateFormatter.string(from: date))
                        .font(.system(.body, design: .default))
                        .fontWeight(.semibold)
                }

                Spacer()

                if let shiftType = assignedShiftType {
                    HStack(spacing: 8) {
                        // Shift symbol preview
                        Text(shiftType.symbol)
                            .font(.system(size: 24))
                            .frame(width: 40, height: 40)
                            .background(ShiftColorPalette.colorForShift(shiftType).opacity(0.2))
                            .cornerRadius(8)

                        // Remove button
                        Button(action: onShiftRemoved) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .padding(12)

            // Shift picker menu
            if assignedShiftType == nil {
                Divider()

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(availableShiftTypes, id: \.id) { shiftType in
                            Button(action: { onShiftSelected(shiftType) }) {
                                VStack(spacing: 4) {
                                    Text(shiftType.symbol)
                                        .font(.system(size: 18))

                                    Text(shiftType.title)
                                        .font(.system(.caption2, design: .default))
                                        .lineLimit(1)
                                }
                                .frame(minWidth: 60)
                                .padding(8)
                                .background(ShiftColorPalette.colorForShift(shiftType).opacity(0.1))
                                .foregroundColor(.primary)
                                .cornerRadius(6)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
            }
        }
        .background(Color(UIColor.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    PerDateShiftPickerView()
}
