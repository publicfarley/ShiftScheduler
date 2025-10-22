import SwiftUI
import ComposableArchitecture

struct ScheduleView: View {
    @Bindable var store: StoreOf<ScheduleFeature>

    @State private var shiftToSwitch: ScheduledShift?

    private var contentKey: String {
        // Create a key that changes whenever shift content changes (not just count)
        let shifts = store.shiftsForSelectedDate
        let shiftKeys = shifts.map { "\($0.eventIdentifier)-\($0.shiftType?.id.uuidString ?? "nil")" }.joined(separator: ",")
        return "\(store.selectedDate)-\(shiftKeys)"
    }

    private var mainContentView: some View {
        VStack(spacing: 12) {
            // Calendar section with dedicated background
            CustomCalendarView(
                selectedDate: Binding(
                    get: { store.selectedDate },
                    set: { store.send(.selectedDateChanged($0)) }
                ),
                scheduledDates: Set(store.scheduledShifts.map { $0.date })
            )
                .padding(.vertical, 12)
                .background(Color(.systemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 16)

            // Shifts section
            VStack(alignment: .leading, spacing: 8) {
                // Section header
                HStack {
                    Text(dateHeaderText)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Spacer()

                    if !store.shiftsForSelectedDate.isEmpty {
                        Text("\(store.shiftsForSelectedDate.count) shift\(store.shiftsForSelectedDate.count == 1 ? "" : "s")")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16)

                // Content area with fade-in animation for new data
                ScrollView {
                    SmoothedContentView(contentKey: contentKey) {
                        LazyVStack(spacing: 10) {
                            if let errorMessage = store.errorMessage {
                                ErrorStateView(message: errorMessage)
                                    .padding(.horizontal, 16)
                            } else if !store.shiftsForSelectedDate.isEmpty {
                                // Show shifts when available - with fade-in animation
                                ForEach(store.shiftsForSelectedDate.sorted { shift1, shift2 in
                                    let startTime1 = shift1.shiftType?.duration.startTime?.hour ?? 0
                                    let startTime2 = shift2.shiftType?.duration.startTime?.hour ?? 0
                                    return startTime1 < startTime2
                                }) { shift in
                                    FadeInShiftCard(shift: shift, onDelete: {
                                        store.send(.deleteShift(shift))
                                    }, onSwitch: {
                                        shiftToSwitch = shift
                                    })
                                    .padding(.horizontal, 16)
                                }
                            } else {
                                // Only show empty state when we've confirmed there's no data for this date
                                EnhancedEmptyState(selectedDate: store.selectedDate)
                                    .padding(.horizontal, 16)
                            }
                            // If neither condition is met, show nothing (while loading)
                        }
                        .padding(.vertical, 8)
                    }
                }
                .background(Color(.systemGroupedBackground).ignoresSafeArea())
            }
        }
    }

    private var dateHeaderText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: store.selectedDate)
    }

    private var calendarAccessView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.largeTitle)
                .foregroundColor(.red)

            Text("Calendar Access Required")
                .font(.headline)

            Text("ShiftScheduler needs calendar access to function properly.")
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
    }

    var body: some View {
        NavigationView {
            VStack {
                if !store.isCalendarAuthorized {
                    calendarAccessView
                } else {
                    mainContentView
                }
            }
            .navigationTitle("Schedule")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    // Undo/Redo buttons
                    if store.canUndo || store.canRedo {
                        CompactUndoRedoButtons(
                            canUndo: store.canUndo,
                            canRedo: store.canRedo,
                            onUndo: {
                                store.send(.undo)
                            },
                            onRedo: {
                                store.send(.redo)
                            }
                        )
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Shift") {
                        store.send(.addShiftButtonTapped)
                    }
                    .disabled(!store.isCalendarAuthorized)
                }
            }
            .sheet(isPresented: Binding(
                get: { store.showAddShiftSheet },
                set: { _ in store.send(.addShiftButtonTapped) }
            )) {
                AddShiftSheetContainer(selectedDate: store.selectedDate) {
                    // Called when a shift is successfully created - reload shifts
                    store.send(.loadShifts)
                }
            }
            .sheet(item: $shiftToSwitch) { shift in
                ShiftChangeSheet(currentShift: shift) { newShiftType, reason in
                    store.send(.performSwitchShift(shift, newShiftType, reason))
                }
            }
            .task {
                await store.send(.task).finish()
            }
            .toast(Binding(
                get: { store.toastMessage },
                set: { _ in }
            ))
        }
    }

}

// MARK: - Fade-In Shift Card Component
struct FadeInShiftCard: View {
    let shift: ScheduledShift
    let onDelete: (() -> Void)?
    let onSwitch: (() -> Void)?

    @State private var opacity: Double = 0.0
    @State private var scale: Double = 0.95
    @State private var hasAppeared = false

    var body: some View {
        EnhancedShiftCard(shift: shift, onDelete: onDelete, onSwitch: onSwitch)
            .opacity(opacity)
            .scaleEffect(scale)
            .onAppear {
                // Only animate on first appearance to prevent re-animation on scroll
                guard !hasAppeared else {
                    opacity = 1.0
                    scale = 1.0
                    return
                }
                hasAppeared = true

                // Delay the fade-in animation by 0.05 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                        opacity = 1.0
                        scale = 1.0
                    }
                }
            }
    }
}

// MARK: - Error State Component
struct ErrorStateView: View {
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.red.opacity(0.1), .red.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.red)
            }

            VStack(spacing: 6) {
                Text("Something went wrong")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.red.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Add Shift Sheet Container
struct AddShiftSheetContainer: View {
    @Environment(\.dismiss) private var dismiss
    @Dependency(\.persistenceClient) var persistenceClient

    let selectedDate: Date
    let onShiftCreated: (() -> Void)?

    @State private var shiftTypes: [ShiftType] = []
    @State private var isLoading = true

    var body: some View {
        if isLoading {
            ProgressView()
                .task {
                    do {
                        shiftTypes = try await persistenceClient.fetchShiftTypes()
                        isLoading = false
                    } catch {
                        isLoading = false
                    }
                }
        } else {
            ScheduleShiftView(
                store: Store(
                    initialState: ScheduleShiftFeature.State(selectedDate: selectedDate),
                    reducer: { ScheduleShiftFeature() }
                ),
                availableShiftTypes: shiftTypes,
                onShiftCreated: { _ in
                    onShiftCreated?()
                    dismiss()
                }
            )
        }
    }
}

#Preview {
    ScheduleView(
        store: Store(
            initialState: ScheduleFeature.State(),
            reducer: { ScheduleFeature() }
        )
    )
}
