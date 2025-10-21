import Foundation
import ComposableArchitecture

/// Feature managing the locations list and CRUD operations
/// This is a simple feature that demonstrates the TCA pattern
@Reducer
struct LocationsFeature {
    @ObservableState
    struct State: Equatable {
        /// All locations loaded from SwiftData
        var locations: IdentifiedArrayOf<Location> = []

        /// Search text for filtering locations
        var searchText = ""

        /// Filtered locations based on search text
        var filteredLocations: IdentifiedArrayOf<Location> {
            if searchText.isEmpty {
                return locations
            }
            return locations.filter { location in
                location.name.localizedCaseInsensitiveContains(searchText) ||
                location.address.localizedCaseInsensitiveContains(searchText)
            }
        }

        /// Loading state
        var isLoading = false

        /// Error message if any
        var errorMessage: String?

        /// Presented add/edit sheet
        @Presents var addEditSheet: AddEditLocationFeature.State?

        init(
            locations: IdentifiedArrayOf<Location> = [],
            searchText: String = "",
            isLoading: Bool = false,
            errorMessage: String? = nil,
            addEditSheet: AddEditLocationFeature.State? = nil
        ) {
            self.locations = locations
            self.searchText = searchText
            self.isLoading = isLoading
            self.errorMessage = errorMessage
            self.addEditSheet = addEditSheet
        }
    }

    enum Action: Equatable {
        /// View appeared, load initial data
        case task

        /// Search text changed
        case searchTextChanged(String)

        /// Add button tapped
        case addButtonTapped

        /// Edit button tapped for a location
        case editLocation(Location)

        /// Delete button tapped for a location
        case deleteLocation(Location)

        /// Locations loaded from database
        case locationsLoaded(TaskResult<[Location]>)

        /// Location deleted
        case locationDeleted(Result<Void, Error>)

        /// Add/Edit sheet actions
        case addEditSheet(PresentationAction<AddEditLocationFeature.Action>)

        /// Refresh locations after add/edit
        case refreshLocations

        static func == (lhs: Action, rhs: Action) -> Bool {
            switch (lhs, rhs) {
            case (.task, .task):
                return true
            case let (.searchTextChanged(lhs), .searchTextChanged(rhs)):
                return lhs == rhs
            case (.addButtonTapped, .addButtonTapped):
                return true
            case let (.editLocation(lhs), .editLocation(rhs)):
                return lhs.id == rhs.id
            case let (.deleteLocation(lhs), .deleteLocation(rhs)):
                return lhs.id == rhs.id
            case let (.locationsLoaded(lhs), .locationsLoaded(rhs)):
                return lhs == rhs
            case (.locationDeleted(.success), .locationDeleted(.success)):
                return true
            case let (.locationDeleted(.failure(lhs)), .locationDeleted(.failure(rhs))):
                return lhs.localizedDescription == rhs.localizedDescription
            case let (.addEditSheet(lhs), .addEditSheet(rhs)):
                return lhs == rhs
            case (.refreshLocations, .refreshLocations):
                return true
            default:
                return false
            }
        }
    }

    @Dependency(\.persistenceClient) var persistenceClient

    var reducer: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                // Load locations when view appears
                state.isLoading = true
                return .run { send in
                    await send(.locationsLoaded(
                        TaskResult {
                            try await persistenceClient.fetchLocations()
                        }
                    ))
                }

            case let .searchTextChanged(text):
                state.searchText = text
                return .none

            case .addButtonTapped:
                state.addEditSheet = AddEditLocationFeature.State(mode: .add)
                return .none

            case let .editLocation(location):
                state.addEditSheet = AddEditLocationFeature.State(mode: .edit(location))
                return .none

            case let .deleteLocation(location):
                state.isLoading = true
                return .run { send in
                    do {
                        try await persistenceClient.deleteLocation(location)
                        await send(.locationDeleted(.success(())))
                    } catch {
                        await send(.locationDeleted(.failure(error)))
                    }
                }

            case let .locationsLoaded(.success(locations)):
                state.isLoading = false
                state.locations = IdentifiedArray(uniqueElements: locations)
                state.errorMessage = nil
                return .none

            case let .locationsLoaded(.failure(error)):
                state.isLoading = false
                state.errorMessage = "Failed to load locations: \(error.localizedDescription)"
                return .none

            case .locationDeleted(.success):
                state.isLoading = false
                // Refresh the list after deletion
                return .send(.refreshLocations)

            case let .locationDeleted(.failure(error)):
                state.isLoading = false
                state.errorMessage = "Failed to delete location: \(error.localizedDescription)"
                return .none

            case .addEditSheet(.presented(.saved)):
                // Location was saved, refresh the list
                return .send(.refreshLocations)

            case .addEditSheet:
                return .none

            case .refreshLocations:
                state.isLoading = true
                return .run { send in
                    await send(.locationsLoaded(
                        TaskResult {
                            try await persistenceClient.fetchLocations()
                        }
                    ))
                }
            }
        }
        .ifLet(\.$addEditSheet, action: \.addEditSheet) {
            AddEditLocationFeature()
        }
    }
}
