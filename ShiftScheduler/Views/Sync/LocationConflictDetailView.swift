import SwiftUI

/// Detail view for resolving Location sync conflicts
struct LocationConflictDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.reduxStore) private var store

    let conflictId: UUID
    let info: ConflictInfo<Location>

    @State private var showingResolveConfirmation = false
    @State private var selectedResolution: ConflictResolution?

    var body: some View {
        List {
            // Conflict Information
            Section("Conflict Information") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("A sync conflict was detected for this location.")
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
                LocationDetailRow(location: info.local)
            }

            // Remote Version
            Section("Remote Version (iCloud)") {
                LocationDetailRow(location: info.remote)
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
        .navigationTitle("Location Conflict")
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

// MARK: - Location Detail Row

struct LocationDetailRow: View {
    let location: Location

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            LabeledContent("Name") {
                Text(location.name)
                    .fontWeight(.medium)
            }

            LabeledContent("Address") {
                Text(location.address)
                    .foregroundStyle(.primary)
            }

            if let syncDate = location.lastSyncedAt {
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
        LocationConflictDetailView(
            conflictId: UUID(),
            info: ConflictInfo(
                local: Location(
                    id: UUID(),
                    name: "Office A",
                    address: "123 Main St",
                    lastSyncedAt: Date().addingTimeInterval(-3600)
                ),
                remote: Location(
                    id: UUID(),
                    name: "Office B",
                    address: "456 Oak Ave",
                    lastSyncedAt: Date()
                ),
                conflictType: .requiresManualResolution(conflictingFields: ["name", "address"]),
                conflictingFields: ["name", "address"]
            )
        )
    }
}
