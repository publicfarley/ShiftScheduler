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
        case locationDeleted(TaskResult<Void>)

        /// Add/Edit sheet actions
        case addEditSheet(PresentationAction<AddEditLocationFeature.Action>)

        /// Refresh locations after add/edit
        case refreshLocations
    }

    @Dependency(\.swiftDataClient) var swiftDataClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                // Load locations when view appears
                state.isLoading = true
                return .run { send in
                    await send(.locationsLoaded(
                        TaskResult {
                            try await swiftDataClient.fetchLocations()
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
                    await send(.locationDeleted(
                        TaskResult {
                            try await swiftDataClient.deleteLocation(location)
                        }
                    ))
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
                            try await swiftDataClient.fetchLocations()
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

/// Feature for adding or editing a location
@Reducer
struct AddEditLocationFeature {
    @ObservableState
    struct State: Equatable {
        /// Edit mode: adding new or editing existing
        var mode: Mode

        /// Form fields
        var name: String
        var address: String

        /// Validation
        var validationErrors: [String] = []

        /// Saving state
        var isSaving = false

        enum Mode: Equatable {
            case add
            case edit(Location)
        }

        init(mode: Mode) {
            self.mode = mode
            switch mode {
            case .add:
                self.name = ""
                self.address = ""
            case let .edit(location):
                self.name = location.name
                self.address = location.address
            }
        }
    }

    enum Action: BindableAction, Equatable {
        /// Two-way binding for form fields
        case binding(BindingAction<State>)

        /// Save button tapped
        case saveButtonTapped

        /// Save completed
        case saved(TaskResult<Void>)

        /// Cancel button tapped
        case cancelButtonTapped

        /// Dismiss the sheet
        case dismiss
    }

    @Dependency(\.swiftDataClient) var swiftDataClient
    @Dependency(\.dismiss) var dismiss

    var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                // Clear validation errors when user types
                state.validationErrors = []
                return .none

            case .saveButtonTapped:
                // Validate form
                state.validationErrors = validate(state: state)
                guard state.validationErrors.isEmpty else {
                    return .none
                }

                state.isSaving = true
                return .run { [state] send in
                    await send(.saved(
                        TaskResult {
                            switch state.mode {
                            case .add:
                                let newLocation = Location(
                                    id: UUID(),
                                    name: state.name,
                                    address: state.address
                                )
                                try await swiftDataClient.saveLocation(newLocation)

                            case let .edit(existingLocation):
                                existingLocation.name = state.name
                                existingLocation.address = state.address
                                try await swiftDataClient.updateLocation(existingLocation)
                            }
                        }
                    ))
                }

            case .saved(.success):
                state.isSaving = false
                return .run { _ in
                    await dismiss()
                }

            case let .saved(.failure(error)):
                state.isSaving = false
                state.validationErrors = ["Failed to save: \(error.localizedDescription)"]
                return .none

            case .cancelButtonTapped:
                return .run { _ in
                    await dismiss()
                }

            case .dismiss:
                return .run { _ in
                    await dismiss()
                }
            }
        }
    }

    private func validate(state: State) -> [String] {
        var errors: [String] = []

        if state.name.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append("Location name is required")
        }

        if state.address.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append("Address is required")
        }

        return errors
    }
}
