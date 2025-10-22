import SwiftUI
import ComposableArchitecture

struct ChangeLogView: View {
    @Bindable var store: StoreOf<ChangeLogFeature>

    var body: some View {
        NavigationStack {
            Group {
                if store.filteredEntries.isEmpty {
                    emptyState
                } else {
                    changeLogList
                }
            }
            .navigationTitle("Change Log")
            .task {
                await store.send(.task).finish()
            }
            .searchable(
                text: Binding(
                    get: { store.searchText },
                    set: { store.send(.searchTextChanged($0)) }
                ),
                prompt: "Search changes..."
            )
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        store.send(.toggleFilters)
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundStyle(store.selectedChangeType != nil ? .blue : .primary)
                    }
                }
            }
            .sheet(
                isPresented: Binding(
                    get: { store.showFilters },
                    set: { newValue in
                        if !newValue {
                            store.send(.dismissFilters)
                        } else {
                            store.send(.toggleFilters)
                        }
                    }
                )
            ) {
                filterSheet
            }
        }
    }

    // MARK: - View Components

    private var changeLogList: some View {
        List {
            ForEach(store.groupedEntries, id: \.0) { section, entries in
                Section {
                    ForEach(entries, id: \.id) { entry in
                        ChangeLogEntryCard(entry: entry)
                    }
                } header: {
                    Text(section)
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Changes", systemImage: "clock.arrow.circlepath")
        } description: {
            if store.searchText.isEmpty && store.selectedChangeType == nil {
                Text("Your shift changes will appear here")
            } else {
                Text("No changes match your filters")
            }
        }
    }

    private var filterSheet: some View {
        NavigationStack {
            List {
                Section("Change Type") {
                    Button {
                        store.send(.changeTypeSelected(nil))
                    } label: {
                        HStack {
                            Text("All")
                            Spacer()
                            if store.selectedChangeType == nil {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }

                    ForEach(ChangeType.allCases, id: \.self) { type in
                        Button {
                            store.send(.changeTypeSelected(type))
                        } label: {
                            HStack {
                                Text(type.displayName)
                                Spacer()
                                if store.selectedChangeType == type {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        store.send(.dismissFilters)
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct ChangeLogEntryCard: View {
    let entry: ChangeLogEntry

    var changeTypeColor: Color {
        switch entry.changeType {
        case .switched: return .blue
        case .deleted: return .red
        case .created: return .green
        case .undo: return .orange
        case .redo: return .purple
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: changeTypeIcon)
                    .foregroundStyle(changeTypeColor)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.changeType.displayName)
                        .font(.headline)
                        .foregroundStyle(changeTypeColor)

                    Text(entry.timestamp, style: .relative) + Text(" ago")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(entry.userDisplayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(entry.scheduledShiftDate, style: .date)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            // Shift change details
            if let oldSnapshot = entry.oldShiftSnapshot,
               let newSnapshot = entry.newShiftSnapshot {
                HStack(spacing: 8) {
                    // Old shift
                    ShiftSnapshotMini(snapshot: oldSnapshot)
                        .frame(maxWidth: .infinity)

                    Image(systemName: "arrow.right")
                        .foregroundStyle(.secondary)
                        .font(.caption)

                    // New shift
                    ShiftSnapshotMini(snapshot: newSnapshot)
                        .frame(maxWidth: .infinity)
                }
            } else if let snapshot = entry.newShiftSnapshot {
                ShiftSnapshotMini(snapshot: snapshot)
            } else if let snapshot = entry.oldShiftSnapshot {
                ShiftSnapshotMini(snapshot: snapshot)
            }

            // Reason
            if let reason = entry.reason, !reason.isEmpty {
                Text(reason)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var changeTypeIcon: String {
        switch entry.changeType {
        case .switched: return "arrow.left.arrow.right"
        case .deleted: return "trash"
        case .created: return "plus.circle"
        case .undo: return "arrow.uturn.backward"
        case .redo: return "arrow.uturn.forward"
        }
    }
}

struct ShiftSnapshotMini: View {
    let snapshot: ShiftSnapshot

    var body: some View {
        VStack(spacing: 4) {
            Text(snapshot.symbol)
                .font(.title2)

            Text(snapshot.title)
                .font(.caption)
                .fontWeight(.semibold)
                .lineLimit(1)

            Text(snapshot.duration.timeRangeString)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
