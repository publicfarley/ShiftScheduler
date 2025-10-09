import SwiftUI
import SwiftData

struct ChangeLogView: View {
    @Query(sort: \ChangeLogEntry.timestamp, order: .reverse) private var allEntries: [ChangeLogEntry]
    @State private var searchText = ""
    @State private var selectedChangeType: ChangeType?
    @State private var showFilters = false

    var filteredEntries: [ChangeLogEntry] {
        var entries = allEntries

        // Filter by change type
        if let type = selectedChangeType {
            entries = entries.filter { $0.changeType == type }
        }

        // Filter by search text
        if !searchText.isEmpty {
            entries = entries.filter { entry in
                entry.userDisplayName.localizedCaseInsensitiveContains(searchText) ||
                entry.reason?.localizedCaseInsensitiveContains(searchText) == true ||
                entry.oldShiftSnapshot?.title.localizedCaseInsensitiveContains(searchText) == true ||
                entry.newShiftSnapshot?.title.localizedCaseInsensitiveContains(searchText) == true
            }
        }

        return entries
    }

    var groupedEntries: [(String, [ChangeLogEntry])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredEntries) { entry -> String in
            if calendar.isDateInToday(entry.timestamp) {
                return "Today"
            } else if calendar.isDateInYesterday(entry.timestamp) {
                return "Yesterday"
            } else if calendar.isDate(entry.timestamp, equalTo: Date(), toGranularity: .weekOfYear) {
                return "This Week"
            } else if calendar.isDate(entry.timestamp, equalTo: Date(), toGranularity: .month) {
                return "This Month"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM yyyy"
                return formatter.string(from: entry.timestamp)
            }
        }

        let sortedKeys = grouped.keys.sorted { key1, key2 in
            let order = ["Today", "Yesterday", "This Week", "This Month"]
            if let index1 = order.firstIndex(of: key1), let index2 = order.firstIndex(of: key2) {
                return index1 < index2
            } else if order.contains(key1) {
                return true
            } else if order.contains(key2) {
                return false
            } else {
                return key1 > key2
            }
        }

        return sortedKeys.map { key in
            (key, grouped[key] ?? [])
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if filteredEntries.isEmpty {
                    emptyState
                } else {
                    changeLogList
                }
            }
            .navigationTitle("Change Log")
            .searchable(text: $searchText, prompt: "Search changes...")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showFilters.toggle()
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundStyle(selectedChangeType != nil ? .blue : .primary)
                    }
                }
            }
            .sheet(isPresented: $showFilters) {
                filterSheet
            }
        }
    }

    // MARK: - View Components

    private var changeLogList: some View {
        List {
            ForEach(groupedEntries, id: \.0) { section, entries in
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
            if searchText.isEmpty && selectedChangeType == nil {
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
                        selectedChangeType = nil
                    } label: {
                        HStack {
                            Text("All")
                            Spacer()
                            if selectedChangeType == nil {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }

                    ForEach(ChangeType.allCases, id: \.self) { type in
                        Button {
                            selectedChangeType = type
                        } label: {
                            HStack {
                                Text(type.displayName)
                                Spacer()
                                if selectedChangeType == type {
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
                        showFilters = false
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
