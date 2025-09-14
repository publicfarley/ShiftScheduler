import SwiftUI
import SwiftData

struct ScheduleView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var scheduledShifts: [ScheduledShift]
    @State private var showingScheduleShift = false
    @State private var selectedDate = Date()

    private var shiftsForSelectedDate: [ScheduledShift] {
        scheduledShifts.filter { shift in
            Calendar.current.isDate(shift.date, inSameDayAs: selectedDate)
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: [.date])
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding()

                List {
                    if shiftsForSelectedDate.isEmpty {
                        Text("No shifts scheduled for this date")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(shiftsForSelectedDate.sorted { $0.shiftType?.startHour ?? 0 < $1.shiftType?.startHour ?? 0 }) { shift in
                            ScheduledShiftRow(shift: shift)
                        }
                        .onDelete(perform: deleteShifts)
                    }
                }
            }
            .navigationTitle("Schedule")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Shift") {
                        showingScheduleShift = true
                    }
                }
            }
            .sheet(isPresented: $showingScheduleShift) {
                ScheduleShiftView(selectedDate: selectedDate)
            }
        }
    }

    private func deleteShifts(offsets: IndexSet) {
        withAnimation {
            let shiftsToDelete = shiftsForSelectedDate.sorted { $0.shiftType?.startHour ?? 0 < $1.shiftType?.startHour ?? 0 }
            for index in offsets {
                if let shiftToDelete = scheduledShifts.first(where: { $0.id == shiftsToDelete[index].id }) {
                    modelContext.delete(shiftToDelete)
                }
            }
        }
    }
}

struct ScheduledShiftRow: View {
    let shift: ScheduledShift

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if let shiftType = shift.shiftType {
                    Text(shiftType.symbol)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)

                    Spacer()

                    Text("\(shiftType.startTimeString) - \(shiftType.endTimeString)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            if let shiftType = shift.shiftType {
                Text(shiftType.title)
                    .font(.headline)

                if let location = shiftType.location {
                    Text("📍 \(location.name)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text(shift.date, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    ScheduleView()
        .modelContainer(for: [Location.self, ShiftType.self, ScheduledShift.self], inMemory: true)
}