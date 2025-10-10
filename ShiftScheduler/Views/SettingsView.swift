
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
    @State private var userProfileManager = UserProfileManager.shared
    @State private var retentionManager = ChangeLogRetentionManager.shared
    @State private var alertItem: AlertItem?
    @State private var displayName: String = ""

    // Animation states
    @State private var titleAppeared = false
    @State private var userProfileSectionAppeared = false
    @State private var changeLogSectionAppeared = false
    @State private var dataManagementSectionAppeared = false
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

                    // User Profile section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("User Profile")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 24)

                        GlassCard(cornerRadius: 16, blurMaterial: .regularMaterial) {
                            VStack(spacing: 20) {
                                // Display Name
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "person.fill")
                                            .foregroundStyle(.blue)
                                            .font(.title3)

                                        Text("Display Name")
                                            .font(.headline)
                                            .foregroundStyle(.primary)

                                        Spacer()
                                    }

                                    TextField("Enter your name", text: $displayName)
                                        .textFieldStyle(.roundedBorder)
                                        .onChange(of: displayName) { _, newValue in
                                            userProfileManager.updateDisplayName(newValue)
                                        }
                                }

                                Divider()

                                // User ID
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "key.fill")
                                            .foregroundStyle(.purple)
                                            .font(.title3)

                                        Text("User ID")
                                            .font(.headline)
                                            .foregroundStyle(.primary)

                                        Spacer()
                                    }

                                    HStack {
                                        Text(userProfileManager.currentProfile.userId.uuidString)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                            .truncationMode(.middle)

                                        Button {
                                            UIPasteboard.general.string = userProfileManager.currentProfile.userId.uuidString
                                        } label: {
                                            Image(systemName: "doc.on.doc")
                                                .font(.caption)
                                        }
                                        .buttonStyle(.borderless)
                                    }

                                    Text("This ID tracks your changes in the log")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }

                                Divider()

                                // Reset User ID button
                                Button(action: {
                                    self.alertItem = AlertItem(
                                        title: Text("Reset User ID?"),
                                        message: Text("This will create a new user identity. All future changes will be logged under the new ID. Existing change log entries will keep the old ID."),
                                        primaryButton: .destructive(Text("Reset ID")) {
                                            userProfileManager.resetUserProfile()
                                            displayName = userProfileManager.currentProfile.displayName
                                        },
                                        secondaryButton: .cancel()
                                    )
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.clockwise")
                                        Text("Reset User ID")
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(
                                                LinearGradient(
                                                    colors: [.purple, .purple.opacity(0.8)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                                            .overlay {
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                                            }
                                    }
                                }
                            }
                            .padding(4)
                        }
                        .padding(.horizontal, 24)
                    }
                    .offset(y: userProfileSectionAppeared ? 0 : 30)
                    .opacity(userProfileSectionAppeared ? 1 : 0)
                    .padding(.bottom, 24)

                    // Change Log Settings section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Change Log Settings")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 24)

                        GlassCard(cornerRadius: 16, blurMaterial: .regularMaterial) {
                            VStack(spacing: 20) {
                                // Retention Policy
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "clock.arrow.circlepath")
                                            .foregroundStyle(.cyan)
                                            .font(.title3)

                                        Text("Retention Period")
                                            .font(.headline)
                                            .foregroundStyle(.primary)

                                        Spacer()
                                    }

                                    Picker("Retention Period", selection: Binding(
                                        get: { retentionManager.currentPolicy },
                                        set: { retentionManager.updatePolicy($0) }
                                    )) {
                                        ForEach(ChangeLogRetentionPolicy.allCases) { policy in
                                            Text(policy.displayName).tag(policy)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .background(.ultraThinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))

                                    Text("How long to keep shift change history")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }

                                Divider()

                                // Last Purge Date
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "trash.clock")
                                            .foregroundStyle(.orange)
                                            .font(.title3)

                                        Text("Last Purged")
                                            .font(.headline)
                                            .foregroundStyle(.primary)

                                        Spacer()
                                    }

                                    if let lastPurge = retentionManager.lastPurgeDate {
                                        Text(lastPurge, style: .relative) + Text(" ago")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)

                                        if retentionManager.lastPurgedCount > 0 {
                                            Text("\(retentionManager.lastPurgedCount) entries removed")
                                                .font(.caption2)
                                                .foregroundStyle(.tertiary)
                                        }
                                    } else {
                                        Text("Never")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Divider()

                                // Manual Purge Button
                                Button(action: {
                                    self.alertItem = AlertItem(
                                        title: Text("Purge Old Entries?"),
                                        message: Text("This will permanently delete change log entries older than \(retentionManager.currentPolicy.displayName.lowercased()). This action cannot be undone."),
                                        primaryButton: .destructive(Text("Purge Now")) {
                                            self.purgeChangeLogEntries()
                                        },
                                        secondaryButton: .cancel()
                                    )
                                }) {
                                    HStack {
                                        Image(systemName: "trash.circle")
                                        Text("Purge Old Entries Now")
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(
                                                LinearGradient(
                                                    colors: [.orange, .orange.opacity(0.8)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
                                            .overlay {
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                                            }
                                    }
                                }
                                .disabled(retentionManager.currentPolicy == .forever)
                            }
                            .padding(4)
                        }
                        .padding(.horizontal, 24)
                    }
                    .offset(y: changeLogSectionAppeared ? 0 : 30)
                    .opacity(changeLogSectionAppeared ? 1 : 0)
                    .padding(.bottom, 24)

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
                    .offset(y: dataManagementSectionAppeared ? 0 : 30)
                    .opacity(dataManagementSectionAppeared ? 1 : 0)

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
                displayName = userProfileManager.currentProfile.displayName
                triggerStaggeredAnimations()
            }
            .dismissKeyboardOnTap()
        }
    }

    private func triggerStaggeredAnimations() {
        guard !UIAccessibility.isReduceMotionEnabled else {
            // Immediately show all elements if reduced motion is enabled
            titleAppeared = true
            userProfileSectionAppeared = true
            changeLogSectionAppeared = true
            dataManagementSectionAppeared = true
            return
        }

        // Stagger animations with spring effects
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
            titleAppeared = true
        }

        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4)) {
            userProfileSectionAppeared = true
        }

        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6)) {
            changeLogSectionAppeared = true
        }

        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.8)) {
            dataManagementSectionAppeared = true
        }
    }

    private func purgeChangeLogEntries() {
        logger.debug("Manual purge requested")
        Task {
            do {
                let repository = SwiftDataChangeLogRepository(modelContext: modelContext)
                let purgeService = ChangeLogPurgeService(repository: repository)

                let purgedCount = try await purgeService.purgeExpiredEntries()

                await MainActor.run {
                    logger.debug("Purged \(purgedCount) entries")
                    if purgedCount > 0 {
                        self.alertItem = AlertItem(
                            title: Text("Purge Complete"),
                            message: Text("\(purgedCount) old entries have been permanently deleted."),
                            primaryButton: .default(Text("OK")),
                            secondaryButton: nil
                        )
                    } else {
                        self.alertItem = AlertItem(
                            title: Text("No Entries to Purge"),
                            message: Text("There are no entries older than \(retentionManager.currentPolicy.displayName.lowercased())."),
                            primaryButton: .default(Text("OK")),
                            secondaryButton: nil
                        )
                    }
                }
            } catch {
                await MainActor.run {
                    logger.error("Failed to purge entries: \(error.localizedDescription)")
                    self.alertItem = AlertItem(
                        title: Text("Purge Failed"),
                        message: Text("Failed to purge entries: \(error.localizedDescription)"),
                        primaryButton: .default(Text("OK")),
                        secondaryButton: nil
                    )
                }
            }
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
