import SwiftUI

struct SettingsView: View {
    @Environment(\.reduxStore) var store
    @State private var displayName: String = ""
    @State private var saveStatus: SaveStatus = .idle
    @State private var showPurgeConfirmation = false
    @State private var saveTask: Task<Void, Never>? = nil

    private enum SaveStatus: Equatable {
        case idle
        case saving
        case saved
        case error(String)
    }

    private let debounceDelay: UInt64 = 500_000_000 // 500ms in nanoseconds
    private let saveSuccessDuration: UInt64 = 2_000_000_000 // 2 seconds in nanoseconds

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - User Profile Section
                    profileSection

                    Divider()

                    // MARK: - Change Log Management Section
                    changeLogManagementSection
                }
                .padding()
            }
            .scrollDismissesKeyboard(.immediately)
            .dismissKeyboardOnTap()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                Task {
                    await store.dispatch(action: .settings(.loadSettings))
                    // Explicitly load purge statistics when Settings view appears
                    await store.dispatch(action: .settings(.loadPurgeStatistics))
                }
                displayName = store.state.userProfile.displayName
            }
            .onChange(of: store.state.userProfile.displayName) { _, newValue in
                // Sync local state when Redux store updates (e.g., from onboarding)
                displayName = newValue
            }
            .onDisappear {
                // Cancel any pending save task when view disappears
                saveTask?.cancel()
            }
            .alert("Purge Old Entries?", isPresented: $showPurgeConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Purge", role: .destructive) {
                    Task {
                        await store.dispatch(action: .settings(.manualPurgeTriggered))
                    }
                }
            } message: {
                purgeConfirmationMessage
            }
            .toast(Binding(
                get: { store.state.settings.toastMessage },
                set: { newValue in
                    if newValue == nil {
                        Task {
                            await store.dispatch(action: .settings(.toastMessageCleared))
                        }
                    }
                }
            ))
        }
    }

    // MARK: - Profile Section

    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("User Profile")
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 8) {
                Text("Display Name")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack(spacing: 8) {
                    TextField("Enter your name", text: $displayName)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: displayName) { _, newValue in
                            // Update app state immediately for reactive UI
                            Task {
                                await store.dispatch(action: .appLifecycle(.displayNameChanged(newValue)))
                            }

                            // Debounce the save: cancel previous save task and schedule new one
                            saveTask?.cancel()
                            saveTask = Task {
                                try? await Task.sleep(nanoseconds: debounceDelay)
                                if !Task.isCancelled {
                                    await saveDisplayName()
                                }
                            }
                        }

                    // Save status indicator
                    Group {
                        switch saveStatus {
                        case .idle:
                            EmptyView()
                        case .saving:
                            ProgressView()
                                .progressViewStyle(.circular)
                                .scaleEffect(0.8)
                        case .saved:
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        case .error(let message):
                            Button(action: {}) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                            .help(message)
                        }
                    }
                    .frame(width: 24)
                }
            }
        }
    }

    // MARK: - Change Log Management Section

    private var changeLogManagementSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Change Log Management")
                .font(.title2)
                .fontWeight(.bold)

            // Statistics Card
            statisticsCard

            // Retention Policy
            retentionPolicySection

            // Manual Purge Button
            manualPurgeButton

            // Auto-Purge Settings
            autoPurgeSection

            // Calendar Resync
            calendarResyncSection
        }
    }

    // MARK: - Statistics Card

    private var statisticsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                Text("Statistics")
                    .font(.headline)
                Spacer()
            }

            if store.state.settings.totalChangeLogEntries == 0 {
                Text("No change log entries yet.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 12) {
                    statRow(
                        icon: "doc.text.fill",
                        label: "Total Entries",
                        value: "\(store.state.settings.totalChangeLogEntries)",
                        color: .blue
                    )

                    if let oldestDate = store.state.settings.oldestEntryDate {
                        statRow(
                            icon: "calendar",
                            label: "Oldest Entry",
                            value: oldestDate.formatted(date: .abbreviated, time: .omitted),
                            color: .purple
                        )
                    }

                    if store.state.settings.retentionPolicy != .forever {
                        statRow(
                            icon: "trash.fill",
                            label: "To Be Purged",
                            value: "\(store.state.settings.entriesToBePurged)",
                            color: store.state.settings.entriesToBePurged > 0 ? .orange : .green
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6).opacity(0.5))
        )
    }

    private func statRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
    }

    // MARK: - Retention Policy Section

    private var retentionPolicySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Retention Period")
                .font(.headline)

            Picker("Retention Period", selection: Binding(
                get: { store.state.settings.retentionPolicy },
                set: { newValue in
                    Task {
                        await store.dispatch(action: .settings(.retentionPolicyChanged(newValue)))
                        // Reload statistics when policy changes
                        await store.dispatch(action: .settings(.loadPurgeStatistics))
                        // Immediately save the policy to disk
                        await saveRetentionPolicy()
                    }
                }
            )) {
                ForEach(ChangeLogRetentionPolicy.allCases) { policy in
                    Text(policy.displayName).tag(policy)
                }
            }
            .pickerStyle(.menu)
            .tint(.primary)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(.systemGray6))
            .cornerRadius(8)

            // Policy Description
            policyDescription
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
        }
    }

    private var policyDescription: some View {
        Group {
            if store.state.settings.retentionPolicy == .forever {
                Text("No entries will be automatically deleted. Change log will grow indefinitely.")
            } else if let cutoffDate = store.state.settings.retentionPolicy.cutoffDate {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Entries older than \(cutoffDate.formatted(date: .abbreviated, time: .omitted)) will be automatically deleted.")
                    if store.state.settings.entriesToBePurged > 0 {
                        Text("⚠️ \(store.state.settings.entriesToBePurged) entries would be deleted with this policy")
                            .foregroundColor(.orange)
                            .fontWeight(.medium)
                    }
                }
            }
        }
    }

    // MARK: - Manual Purge Button

    private var manualPurgeButton: some View {
        Button(action: {
            showPurgeConfirmation = true
        }) {
            HStack {
                if store.state.settings.isPurging {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "trash.fill")
                }
                Text(store.state.settings.isPurging ? "Purging..." : "Purge Old Entries Now")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
        .tint(.red)
        .disabled(
            store.state.settings.retentionPolicy == .forever ||
            store.state.settings.entriesToBePurged == 0 ||
            store.state.settings.isPurging
        )
    }

    // MARK: - Auto-Purge Section

    private var autoPurgeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: Binding(
                get: { store.state.settings.autoPurgeEnabled },
                set: { newValue in
                    Task {
                        await store.dispatch(action: .settings(.autoPurgeToggled(newValue)))
                    }
                }
            )) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Automatic Purge on App Launch")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("Automatically delete old entries when the app starts")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .tint(.blue)

            // Last Purge Timestamp
            if let lastPurgeDate = store.state.settings.lastPurgeDate {
                HStack(spacing: 8) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    Text("Last purge: \(relativeDateString(from: lastPurgeDate))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.leading, 4)
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    Text("Last purge: Never")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.leading, 4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6).opacity(0.3))
        )
    }

    // MARK: - Calendar Resync Section

    private var calendarResyncSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundColor(.blue)
                Text("Calendar Sync")
                    .font(.headline)
                Spacer()
            }

            Text("Update all calendar events with current shift type formatting (symbol and location address).")
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: {
                Task {
                    await store.dispatch(action: .settings(.resyncCalendarEventsRequested))
                }
            }) {
                HStack {
                    if store.state.settings.isResyncingCalendar {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                    Text(store.state.settings.isResyncingCalendar ? "Resyncing..." : "Resync Calendar Events")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .disabled(store.state.settings.isResyncingCalendar || !store.state.isCalendarAuthorized)

            if !store.state.isCalendarAuthorized {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Calendar access required")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6).opacity(0.3))
        )
    }

    // MARK: - Purge Confirmation Message

    private var purgeConfirmationMessage: Text {
        if let cutoffDate = store.state.settings.retentionPolicy.cutoffDate {
            return Text("This will permanently delete \(store.state.settings.entriesToBePurged) entries older than \(cutoffDate.formatted(date: .abbreviated, time: .omitted)).\n\nRetention Policy: \(store.state.settings.retentionPolicy.displayName)\n\nThis action cannot be undone.")
        } else {
            return Text("Your retention policy is set to Forever. No entries will be deleted.")
        }
    }

    // MARK: - Save Methods

    private func saveDisplayName() async {
        saveStatus = .saving

        do {
            // Dispatch save settings action to middleware
            await store.dispatch(action: .settings(.saveSettings))

            // Wait for the save to complete by checking state changes
            // In a real app, you might want to track a separate "isSaving" state
            try await Task.sleep(nanoseconds: 300_000_000) // 300ms for save to complete

            saveStatus = .saved

            // Auto-dismiss the "saved" indicator after 2 seconds
            try await Task.sleep(nanoseconds: saveSuccessDuration)
            if saveStatus == .saved {
                saveStatus = .idle
            }
        } catch {
            saveStatus = .error("Failed to save")

            // Reset error after 3 seconds
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if case .error = saveStatus {
                saveStatus = .idle
            }
        }
    }

    private func saveRetentionPolicy() async {
        // Dispatch save settings action to middleware
        // This persists the current retention policy to disk
        await store.dispatch(action: .settings(.saveSettings))
    }

    // MARK: - Helper Functions

    private func relativeDateString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)

        if interval < 60 {
            return "just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else if interval < 604800 {
            let days = Int(interval / 86400)
            return "\(days) day\(days == 1 ? "" : "s") ago"
        } else {
            let weeks = Int(interval / 604800)
            return "\(weeks) week\(weeks == 1 ? "" : "s") ago"
        }
    }
}

#Preview {
    SettingsView()
}
