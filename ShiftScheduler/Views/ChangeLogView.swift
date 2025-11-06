import SwiftUI

struct ChangeLogView: View {
    @Environment(\.reduxStore) var store

    // Current date for relative time calculations (deterministic)
    private let currentDate = Date()

    // State for confirmation dialog
    @State private var showPurgeConfirmation = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    if store.state.changeLog.filteredEntries.isEmpty {
                        emptyStateView
                    } else {
                        changeLogEntriesView
                    }
                }
                .padding()
            }
            .navigationTitle("Change Log")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showPurgeConfirmation = true
                    }) {
                        Label("Purge Old Entries", systemImage: "trash")
                    }
                    .disabled(store.state.settings.retentionPolicy == .forever)
                }
            }
            .alert("Purge Old Entries?", isPresented: $showPurgeConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Purge", role: .destructive) {
                    store.dispatch(action: .changeLog(.purgeOldEntries))
                    // Reload entries after a short delay
                    Task {
                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                        store.dispatch(action: .changeLog(.loadChangeLogEntries))
                    }
                }
            } message: {
                if let cutoffDate = store.state.settings.retentionPolicy.cutoffDate {
                    Text("This will delete all change log entries older than \(cutoffDate, style: .date) according to your retention policy (\(store.state.settings.retentionPolicy.displayName)).")
                } else {
                    Text("Your retention policy is set to Forever. No entries will be deleted.")
                }
            }
            .onAppear {
                store.dispatch(action: .changeLog(.loadChangeLogEntries))
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(.systemGray5), Color(.systemGray6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 44))
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 8) {
                Text("No Changes Yet")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text("Your shift changes and modifications will appear here")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Change Log Entries

    private var changeLogEntriesView: some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(store.state.changeLog.filteredEntries.enumerated()), id: \.element.id) { index, entry in
                VStack(spacing: 0) {
                    EnhancedChangeLogCard(entry: entry, currentDate: currentDate)

                    // Timeline connector (except for last item)
                    if index < store.state.changeLog.filteredEntries.count - 1 {
                        TimelineConnector()
                    }
                }
            }
        }
    }
}

// MARK: - Enhanced Change Log Card

struct EnhancedChangeLogCard: View {
    let entry: ChangeLogEntry
    let currentDate: Date

    var changeTypeColor: Color {
        switch entry.changeType {
        case .switched: return .blue
        case .deleted: return .red
        case .created: return .green
        case .undo: return .orange
        case .redo: return .purple
        }
    }

    var changeTypeIcon: String {
        switch entry.changeType {
        case .switched: return "arrow.triangle.2.circlepath"
        case .deleted: return "trash.fill"
        case .created: return "plus.circle.fill"
        case .undo: return "arrow.uturn.backward.circle.fill"
        case .redo: return "arrow.uturn.forward.circle.fill"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Card Content
            VStack(alignment: .leading, spacing: 14) {
                // Header: Change Type Badge + Timestamp
                HStack(alignment: .center, spacing: 12) {
                    ChangeTypeBadge(
                        changeType: entry.changeType,
                        color: changeTypeColor,
                        icon: changeTypeIcon
                    )

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(relativeTimeString(from: entry.timestamp))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        Text(entry.timestamp, style: .time)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                // Date of the shift
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(changeTypeColor)

                    Text(entry.scheduledShiftDate, style: .date)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(changeTypeColor.opacity(0.1))
                        .overlay(
                            Capsule()
                                .stroke(changeTypeColor.opacity(0.3), lineWidth: 1)
                        )
                )

                // Shift Details
                shiftDetailsView

                // Reason (if present)
                if let reason = entry.reason, !reason.isEmpty {
                    reasonView(reason: reason)
                }

                // User Attribution
                HStack(spacing: 6) {
                    Image(systemName: "person.circle.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("by \(entry.userDisplayName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                LinearGradient(
                                    colors: [changeTypeColor.opacity(0.3), changeTypeColor.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: changeTypeColor.opacity(0.1), radius: 8, x: 0, y: 4)
            )

            // Bottom accent bar
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [changeTypeColor.opacity(0.6), changeTypeColor.opacity(0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 3)
                .cornerRadius(1.5)
                .padding(.horizontal, 16)
        }
    }

    // MARK: - Shift Details View

    @ViewBuilder
    private var shiftDetailsView: some View {
        switch entry.changeType {
        case .switched:
            if let oldSnapshot = entry.oldShiftSnapshot,
               let newSnapshot = entry.newShiftSnapshot {
                ShiftComparisonView(oldShift: oldSnapshot, newShift: newSnapshot)
            }

        case .deleted:
            if let oldSnapshot = entry.oldShiftSnapshot {
                DeletedShiftView(shift: oldSnapshot)
            }

        case .created:
            if let newSnapshot = entry.newShiftSnapshot {
                CreatedShiftView(shift: newSnapshot)
            }

        case .undo, .redo:
            if let oldSnapshot = entry.oldShiftSnapshot,
               let newSnapshot = entry.newShiftSnapshot {
                ShiftComparisonView(oldShift: oldSnapshot, newShift: newSnapshot)
            }
        }
    }

    // MARK: - Reason View

    private func reasonView(reason: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "note.text")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("Reason")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }

            Text(reason)
                .font(.body)
                .foregroundColor(.primary)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                )
        }
    }

    // MARK: - Relative Time String

    func relativeTimeString(from date: Date) -> String {
        let interval = currentDate.timeIntervalSince(date)

        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else if interval < 604800 {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        } else {
            let weeks = Int(interval / 604800)
            return "\(weeks)w ago"
        }
    }
}

// MARK: - Change Type Badge

struct ChangeTypeBadge: View {
    let changeType: ChangeType
    let color: Color
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: color.opacity(0.4), radius: 6, x: 0, y: 3)
                )

            Text(changeType.displayName)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(changeType.displayName) operation")
    }
}

// MARK: - Shift Comparison View (Switched/Undo/Redo)

struct ShiftComparisonView: View {
    let oldShift: ShiftSnapshot
    let newShift: ShiftSnapshot

    var body: some View {
        VStack(spacing: 12) {
            // From
            ShiftSnapshotCard(snapshot: oldShift, label: "From", color: .red)

            // Arrow
            HStack {
                Spacer()
                Image(systemName: "arrow.down")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                Spacer()
            }

            // To
            ShiftSnapshotCard(snapshot: newShift, label: "To", color: .green)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6).opacity(0.5))
        )
    }
}

// MARK: - Single Shift View (Deleted/Created)

struct SingleShiftView: View {
    let shift: ShiftSnapshot
    let label: String
    let color: Color

    var body: some View {
        ShiftSnapshotCard(snapshot: shift, label: label, color: color)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray6).opacity(0.5))
            )
    }
}

// MARK: - Deleted Shift View

struct DeletedShiftView: View {
    let shift: ShiftSnapshot

    var body: some View {
        SingleShiftView(shift: shift, label: "Deleted", color: .red)
    }
}

// MARK: - Created Shift View

struct CreatedShiftView: View {
    let shift: ShiftSnapshot

    var body: some View {
        SingleShiftView(shift: shift, label: "Created", color: .green)
    }
}

// MARK: - Shift Snapshot Card

struct ShiftSnapshotCard: View {
    let snapshot: ShiftSnapshot
    let label: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label
            Text(label)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(color)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(color.opacity(0.15))
                )

            // Shift Info
            HStack(spacing: 10) {
                // Symbol
                Text(snapshot.symbol)
                    .font(.title3)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(color.opacity(0.15))
                            .overlay(
                                Circle()
                                    .stroke(color.opacity(0.3), lineWidth: 1)
                            )
                    )

                // Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(snapshot.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    if !snapshot.shiftDescription.isEmpty {
                        Text(snapshot.shiftDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    // Duration
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.caption2)
                            .foregroundColor(color)

                        Text(snapshot.duration.timeRangeString)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(color)
                    }

                    // Location
                    if let locationName = snapshot.locationName {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.caption2)
                                .foregroundColor(.secondary)

                            Text(locationName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }

                Spacer()
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Timeline Connector

struct TimelineConnector: View {
    var body: some View {
        VStack(spacing: 0) {
            Circle()
                .fill(Color(.systemGray4))
                .frame(width: 6, height: 6)

            Rectangle()
                .fill(Color(.systemGray5))
                .frame(width: 2, height: 24)

            Circle()
                .fill(Color(.systemGray4))
                .frame(width: 6, height: 6)
        }
        .padding(.vertical, 6)
        .accessibilityHidden(true) // Decorative only
    }
}

#Preview {
    ChangeLogView()
}
