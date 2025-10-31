import SwiftUI

/// Quick Actions section for managing today's shift
/// Displays three action buttons: Switch Shift, Delete Shift, and Edit Notes
struct QuickActionsView: View {
    @Environment(\.reduxStore) var store

    let shift: ScheduledShift

    @State private var showDeleteConfirmation = false
    @State private var showEditNotesSheet = false

    var body: some View {
        VStack(spacing: 12) {
            // Three action buttons in a row
            HStack(spacing: 12) {
                // Switch Shift Button
                Button(action: {
                    store.dispatch(action: .today(.switchShiftTapped(shift)))
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Switch")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.8), Color.blue.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }

                // Delete Shift Button
                Button(action: {
                    store.dispatch(action: .today(.deleteShiftRequested(shift)))
                    showDeleteConfirmation = true
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "trash")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Delete")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color.red.opacity(0.8), Color.red.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }

                // Edit Notes Button
                Button(action: {
                    showEditNotesSheet = true
                    // Initialize notes with existing shift notes
                    store.dispatch(action: .today(.quickActionsNotesChanged(shift.notes ?? "")))
                    store.dispatch(action: .today(.editNotesSheetToggled(true)))
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "note.text")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Notes")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color.green.opacity(0.8), Color.green.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            .frame(height: 60)
        }
        .alert("Delete Shift", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                store.dispatch(action: .today(.deleteShiftCancelled))
            }
            Button("Delete", role: .destructive) {
                store.dispatch(action: .today(.deleteShiftConfirmed))
                showDeleteConfirmation = false
            }
        } message: {
            Text("Are you sure you want to delete this shift? This action cannot be undone.")
        }
        .sheet(isPresented: $showEditNotesSheet) {
            EditNotesSheetView(isPresented: $showEditNotesSheet, shift: shift)
        }
        .transition(.opacity.combined(with: .scale))
    }
}

// MARK: - Edit Notes Sheet View

/// Sheet view for editing shift notes
struct EditNotesSheetView: View {
    @Environment(\.reduxStore) var store
    @Binding var isPresented: Bool

    let shift: ScheduledShift

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Notes Editor
                VStack(alignment: .leading, spacing: 8) {
                    Text("Shift Notes")
                        .font(.headline)
                        .foregroundColor(.primary)

                    TextEditor(text: Binding(
                        get: { store.state.today.quickActionsNotes },
                        set: { newValue in
                            store.dispatch(action: .today(.quickActionsNotesChanged(newValue)))
                        }
                    ))
                    .font(.body)
                    .lineSpacing(2)
                    .frame(minHeight: 120)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                }
                .padding(16)

                Spacer()
            }
            .navigationTitle("Edit Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        store.dispatch(action: .today(.editNotesSheetToggled(false)))
                        isPresented = false
                    }
                }
            }
            .dismissKeyboardOnTap()
        }
    }
}

#Preview {
    let testShift = ScheduledShift(
        id: UUID(),
        eventIdentifier: "test-event",
        shiftType: ShiftType(
            id: UUID(),
            symbol: "sun.max.fill",
            duration: .scheduled(
                from: HourMinuteTime(hour: 6, minute: 0),
                to: HourMinuteTime(hour: 14, minute: 0)
            ),
            title: "Morning Shift",
            description: "Morning shift at main office",
            location: Location(id: UUID(), name: "Main Office", address: "123 Main St")
        ),
        date: Date(),
        notes: "Remember to bring extra coffee"
    )

    let mockState = AppState(
        today: TodayState(
            scheduledShifts: [testShift],
            todayShift: testShift
        )
    )

    let mockStore = Store(
        state: mockState,
        reducer: appReducer,
        services: ServiceContainer(),
        middlewares: []
    )

    QuickActionsView(shift: testShift)
        .environment(\.reduxStore, mockStore)
}
