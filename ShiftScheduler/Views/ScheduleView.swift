import SwiftUI

struct ScheduleView: View {
    @Environment(\.reduxStore) var store

    var body: some View {
        NavigationView {
            VStack {
                if !store.state.schedule.isCalendarAuthorized {
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.largeTitle)
                            .foregroundColor(.red)
                        Text("Calendar Access Required")
                            .font(.headline)
                        Text("ShiftScheduler needs calendar access to view your schedule.")
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
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            Text("Schedule View")
                                .font(.headline)

                            Text("Shifts: \(store.state.schedule.scheduledShifts.count)")
                                .foregroundColor(.secondary)

                            ForEach(store.state.schedule.scheduledShifts.prefix(5)) { shift in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(shift.shiftType?.title ?? "Unknown")
                                        .font(.headline)
                                    Text(shift.date, style: .date)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                        .padding()
                    }
                    .navigationTitle("Schedule")
                    .navigationBarTitleDisplayMode(.large)
                }
            }
            .onAppear {
                store.dispatch(action: .schedule(.task))
            }
        }
    }
}

#Preview {
    ScheduleView()
}
