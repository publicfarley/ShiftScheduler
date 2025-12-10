import SwiftUI

/// Main view for displaying and resolving sync conflicts
struct ConflictResolutionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.reduxStore) private var store

    var body: some View {
        NavigationStack {
            Group {
                if store.state.sync.pendingConflicts.isEmpty {
                    emptyStateView
                } else {
                    conflictsList
                }
            }
            .navigationTitle("Sync Conflicts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }

                if !store.state.sync.pendingConflicts.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Clear All") {
                            Task {
                                await store.dispatch(action: .sync(.clearAllConflicts))
                            }
                        }
                        .foregroundStyle(.red)
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text("No Conflicts")
                .font(.title2)
                .fontWeight(.semibold)

            Text("All data is synced successfully")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    // MARK: - Conflicts List

    private var conflictsList: some View {
        List {
            Section {
                Text("The following items have sync conflicts that require your attention. Review each conflict and choose how to resolve it.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            ForEach(store.state.sync.pendingConflicts) { conflict in
                conflictRow(for: conflict)
            }
        }
    }

    @ViewBuilder
    private func conflictRow(for conflict: PendingConflict) -> some View {
        switch conflict {
        case .location(let id, let info):
            NavigationLink {
                LocationConflictDetailView(
                    conflictId: id,
                    info: info
                )
            } label: {
                ConflictRowView(
                    icon: "mappin.circle.fill",
                    iconColor: .blue,
                    title: "Location Conflict",
                    subtitle: "'\(info.local.name)' has conflicting changes"
                )
            }

        case .shiftType(let id, let info):
            NavigationLink {
                ShiftTypeConflictDetailView(
                    conflictId: id,
                    info: info
                )
            } label: {
                ConflictRowView(
                    icon: "calendar.badge.clock",
                    iconColor: .purple,
                    title: "Shift Type Conflict",
                    subtitle: "'\(info.local.title)' has conflicting changes"
                )
            }
        }
    }
}

// MARK: - Conflict Row View

struct ConflictRowView: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(iconColor)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    ConflictResolutionView()
}
