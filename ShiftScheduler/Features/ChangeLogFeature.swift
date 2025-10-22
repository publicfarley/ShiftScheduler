import Foundation
import ComposableArchitecture

@Reducer
struct ChangeLogFeature {
    @ObservableState
    struct State: Equatable {
        var entries: [ChangeLogEntry] = []
        var searchText: String = ""
        var selectedChangeType: ChangeType?
        var showFilters: Bool = false
        var isLoading: Bool = false
        var errorMessage: String?

        var filteredEntries: [ChangeLogEntry] {
            var filtered = entries

            // Filter by change type
            if let type = selectedChangeType {
                filtered = filtered.filter { $0.changeType == type }
            }

            // Filter by search text
            if !searchText.isEmpty {
                filtered = filtered.filter { entry in
                    entry.userDisplayName.localizedCaseInsensitiveContains(searchText) ||
                    entry.reason?.localizedCaseInsensitiveContains(searchText) == true ||
                    entry.oldShiftSnapshot?.title.localizedCaseInsensitiveContains(searchText) == true ||
                    entry.newShiftSnapshot?.title.localizedCaseInsensitiveContains(searchText) == true
                }
            }

            return filtered
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
    }

    enum Action: Equatable {
        case task
        case loadEntries
        case entriesLoaded([ChangeLogEntry])
        case loadingFailed(String)
        case searchTextChanged(String)
        case changeTypeSelected(ChangeType?)
        case toggleFilters
        case dismissFilters
    }

    @Dependency(\.persistenceClient) var persistenceClient

    var reducer: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                return .send(.loadEntries)

            case .loadEntries:
                state.isLoading = true
                state.errorMessage = nil
                return .run { send in
                    do {
                        let entries = try await persistenceClient.fetchChangeLogEntries()
                        await send(.entriesLoaded(entries))
                    } catch {
                        await send(.loadingFailed(error.localizedDescription))
                    }
                }

            case .entriesLoaded(let entries):
                state.isLoading = false
                state.entries = entries
                return .none

            case .loadingFailed(let error):
                state.isLoading = false
                state.errorMessage = error
                state.entries = []
                return .none

            case .searchTextChanged(let text):
                state.searchText = text
                return .none

            case .changeTypeSelected(let type):
                state.selectedChangeType = type
                return .none

            case .toggleFilters:
                state.showFilters.toggle()
                return .none

            case .dismissFilters:
                state.showFilters = false
                return .none
            }
        }
    }
}
