
import SwiftUI
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.workevents.ShiftScheduler", category: "SettingsView")

struct AlertItem: Identifiable {
    let id = UUID()
    let title: Text
    let message: Text
    let primaryButton: Alert.Button
    let secondaryButton: Alert.Button?
}

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var calendarService = CalendarService.shared
    @State private var alertItem: AlertItem?

    // Animation states
    @State private var titleAppeared = false
    @State private var sectionAppeared = false
    @State private var isPressed = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Spacer for top breathing room
                    Spacer()
                        .frame(height: 20)

                    // Settings header with glass effect
                    GlassCard(cornerRadius: 20, blurMaterial: .ultraThinMaterial) {
                        VStack(spacing: 12) {
                            HStack(spacing: 10) {
                                Image(systemName: "gearshape.fill")
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.cyan, .blue],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .font(.title2)

                                Text("App Settings")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }

                            Text("Manage your app preferences and data")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                    .padding(.horizontal, 24)
                    .offset(y: titleAppeared ? 0 : 30)
                    .opacity(titleAppeared ? 1 : 0)
                    .padding(.bottom, 32)

                    // Data Management section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Data Management")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 24)

                        GlassCard(cornerRadius: 16, blurMaterial: .regularMaterial) {
                            VStack(spacing: 20) {
                                HStack(spacing: 12) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.orange)
                                        .font(.title3)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Danger Zone")
                                            .font(.headline)
                                            .foregroundStyle(.primary)

                                        Text("Irreversible actions that affect your data")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()
                                }

                                Divider()

                                // Delete All Data button
                                Button(action: {
                                    self.alertItem = AlertItem(
                                        title: Text("Are you sure?"),
                                        message: Text("This will permanently delete all shift types, locations, and scheduled shifts. This action cannot be undone."),
                                        primaryButton: .destructive(Text("Delete All Data")) {
                                            self.deleteAllData()
                                        },
                                        secondaryButton: .cancel()
                                    )
                                }) {
                                    HStack {
                                        Image(systemName: "trash.fill")
                                        Text("Delete All Data")
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(
                                                LinearGradient(
                                                    colors: [.red, .red.opacity(0.8)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .shadow(color: .red.opacity(0.3), radius: 8, x: 0, y: 4)
                                            .overlay {
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                                            }
                                    }
                                }
                                .scaleEffect(isPressed ? 0.95 : 1.0)
                                .simultaneousGesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { _ in
                                            guard !UIAccessibility.isReduceMotionEnabled else { return }
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                                isPressed = true
                                            }
                                        }
                                        .onEnded { _ in
                                            guard !UIAccessibility.isReduceMotionEnabled else { return }
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                                isPressed = false
                                            }
                                        }
                                )
                            }
                            .padding(4)
                        }
                        .padding(.horizontal, 24)
                    }
                    .offset(y: sectionAppeared ? 0 : 30)
                    .opacity(sectionAppeared ? 1 : 0)

                    Spacer()
                        .frame(height: 40)
                }
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert(item: $alertItem) { alertItem in
                if let secondaryButton = alertItem.secondaryButton {
                    return Alert(title: alertItem.title, message: alertItem.message, primaryButton: alertItem.primaryButton, secondaryButton: secondaryButton)
                } else {
                    return Alert(title: alertItem.title, message: alertItem.message, dismissButton: alertItem.primaryButton)
                }
            }
            .onAppear {
                triggerStaggeredAnimations()
            }
        }
    }

    private func triggerStaggeredAnimations() {
        guard !UIAccessibility.isReduceMotionEnabled else {
            // Immediately show all elements if reduced motion is enabled
            titleAppeared = true
            sectionAppeared = true
            return
        }

        // Stagger animations with spring effects
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
            titleAppeared = true
        }

        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4)) {
            sectionAppeared = true
        }
    }

    private func deleteAllData() {
        logger.debug("Delete all data requested")
        Task {
            do {
                // Delete all calendar events (shifts)
                if calendarService.isAuthorized {
                    let startDate = Calendar.current.date(byAdding: .year, value: -10, to: Date()) ?? Date()
                    let endDate = Calendar.current.date(byAdding: .year, value: 10, to: Date()) ?? Date()
                    let shifts = try await calendarService.fetchShifts(from: startDate, to: endDate)

                    logger.debug("Deleting \(shifts.count) shifts from calendar")
                    for shift in shifts {
                        try await calendarService.deleteShift(withIdentifier: shift.eventIdentifier)
                    }
                }

                // Delete SwiftData models
                logger.debug("Deleting SwiftData models")
                try modelContext.delete(model: ShiftType.self)
                try modelContext.delete(model: Location.self)

                await MainActor.run {
                    logger.debug("All data deleted successfully")
                    self.alertItem = AlertItem(title: Text("Success"), message: Text("All data has been deleted successfully."), primaryButton: .default(Text("OK")), secondaryButton: nil)
                }
            } catch {
                await MainActor.run {
                    logger.error("Failed to delete all data: \(error.localizedDescription)")
                    self.alertItem = AlertItem(title: Text("Error"), message: Text("Failed to delete all data: \(error.localizedDescription)"), primaryButton: .default(Text("OK")), secondaryButton: nil)
                }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
