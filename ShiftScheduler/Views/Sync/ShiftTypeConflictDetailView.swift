import SwiftUI

/// Detail view for resolving ShiftType sync conflicts
struct ShiftTypeConflictDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.reduxStore) private var store

    let conflictId: UUID
    let info: ConflictInfo<ShiftType>

    @State private var showingResolveConfirmation = false
    @State private var selectedResolution: ConflictResolution?

    var body: some View {
        List {
            // Conflict Information
            Section("Conflict Information") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("A sync conflict was detected for this shift type.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if !info.conflictingFields.isEmpty {
                        Text("Conflicting fields: \(info.conflictingFields.joined(separator: ", "))")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .fontWeight(.medium)
                    }
                }
            }

            // Local Version
            Section("Local Version (This Device)") {
                ShiftTypeDetailRow(shiftType: info.local)
            }

            // Remote Version
            Section("Remote Version (iCloud)") {
                ShiftTypeDetailRow(shiftType: info.remote)
            }

            // Resolution Options
            Section("Resolution Options") {
                resolutionButton(
                    title: "Keep Local Version",
                    subtitle: "Use the version on this device",
                    icon: "iphone",
                    color: .blue,
                    resolution: .keepLocal
                )

                resolutionButton(
                    title: "Keep Remote Version",
                    subtitle: "Use the version from iCloud",
                    icon: "icloud.fill",
                    color: .purple,
                    resolution: .keepRemote
                )

                if info.conflictType == .autoMergeable {
                    resolutionButton(
                        title: "Merge Changes",
                        subtitle: "Automatically combine both versions",
                        icon: "arrow.triangle.merge",
                        color: .green,
                        resolution: .merge
                    )
                }

                resolutionButton(
                    title: "Decide Later",
                    subtitle: "Keep this conflict for now",
                    icon: "clock",
                    color: .gray,
                    resolution: .deferred
                )
            }
        }
        .navigationTitle("Shift Type Conflict")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Resolve Conflict",
            isPresented: $showingResolveConfirmation,
            presenting: selectedResolution
        ) { resolution in
            Button("Confirm") {
                resolveConflict(with: resolution)
            }

            Button("Cancel", role: .cancel) {
                selectedResolution = nil
            }
        } message: { resolution in
            Text(confirmationMessage(for: resolution))
        }
    }

    // MARK: - Resolution Button

    private func resolutionButton(
        title: String,
        subtitle: String,
        icon: String,
        color: Color,
        resolution: ConflictResolution
    ) -> some View {
        Button {
            selectedResolution = resolution
            showingResolveConfirmation = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Helper Methods

    private func confirmationMessage(for resolution: ConflictResolution) -> String {
        switch resolution {
        case .keepLocal:
            return "The local version will be kept and synced to iCloud."
        case .keepRemote:
            return "The remote version will be downloaded and replace the local version."
        case .merge:
            return "Both versions will be automatically merged."
        case .deferred:
            return "This conflict will remain unresolved for now."
        }
    }

    private func resolveConflict(with resolution: ConflictResolution) {
        Task {
            await store.dispatch(action: .sync(.resolveConflict(id: conflictId, resolution: resolution)))
        }
        dismiss()
    }
}

// MARK: - ShiftType Detail Row

struct ShiftTypeDetailRow: View {
    let shiftType: ShiftType

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Symbol and Title
            HStack(spacing: 12) {
                Text(shiftType.symbol)
                    .font(.title)
                    .frame(width: 44, height: 44)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 4) {
                    Text(shiftType.title)
                        .font(.headline)

                    Text(shiftType.duration.timeRangeString)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            // Description
            if !shiftType.shiftDescription.isEmpty {
                LabeledContent("Description") {
                    Text(shiftType.shiftDescription)
                        .font(.body)
                        .multilineTextAlignment(.trailing)
                }
            }

            // Location
            LabeledContent("Location") {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(shiftType.location.name)
                        .fontWeight(.medium)

                    if !shiftType.location.address.isEmpty {
                        Text(shiftType.location.address)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Duration
            if let hours = shiftType.duration.durationInHours {
                LabeledContent("Duration") {
                    Text("\(hours, specifier: "%.1f") hours")
                }
            }

            // Last Synced
            if let syncDate = shiftType.lastSyncedAt {
                LabeledContent("Last Synced") {
                    Text(syncDate, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ShiftTypeConflictDetailView(
            conflictId: UUID(),
            info: ConflictInfo(
                local: ShiftType(
                    id: UUID(),
                    symbol: "🌅",
                    duration: .scheduled(
                        from: HourMinuteTime(hour: 8, minute: 0),
                        to: HourMinuteTime(hour: 16, minute: 0)
                    ),
                    title: "Morning Shift",
                    description: "Early morning shift",
                    location: Location(id: UUID(), name: "Office A", address: "123 Main St"),
                    lastSyncedAt: Date().addingTimeInterval(-3600)
                ),
                remote: ShiftType(
                    id: UUID(),
                    symbol: "🌄",
                    duration: .scheduled(
                        from: HourMinuteTime(hour: 9, minute: 0),
                        to: HourMinuteTime(hour: 17, minute: 0)
                    ),
                    title: "Day Shift",
                    description: "Regular day shift",
                    location: Location(id: UUID(), name: "Office B", address: "456 Oak Ave"),
                    lastSyncedAt: Date()
                ),
                conflictType: .requiresManualResolution(conflictingFields: ["symbol", "title", "duration", "location"]),
                conflictingFields: ["symbol", "title", "duration", "location"]
            )
        )
    }
}
