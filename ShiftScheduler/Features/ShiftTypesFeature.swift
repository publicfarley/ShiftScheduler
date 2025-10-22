import Foundation
import ComposableArchitecture

/// Feature managing the shift types list and CRUD operations
/// This feature handles loading, filtering, and managing shift type catalog
@Reducer
struct ShiftTypesFeature {
    @ObservableState
    struct State: Equatable {
        /// All shift types loaded from persistence
        var shiftTypes: IdentifiedArrayOf<ShiftType> = []

        /// Search text for filtering shift types
        var searchText = ""

        /// Filtered shift types based on search text
        var filteredShiftTypes: IdentifiedArrayOf<ShiftType> {
            if searchText.isEmpty {
                return shiftTypes
            }
            return shiftTypes.filter { shiftType in
                shiftType.title.localizedCaseInsensitiveContains(searchText) ||
                shiftType.symbol.localizedCaseInsensitiveContains(searchText) ||
                shiftType.location.name.localizedCaseInsensitiveContains(searchText)
            }
        }

        /// Loading state
        var isLoading = false

        /// Error message if any
        var errorMessage: String?

        /// Presented add/edit sheet
        @Presents var addEditSheet: AddEditShiftTypeFeature.State?

        init(
            shiftTypes: IdentifiedArrayOf<ShiftType> = [],
            searchText: String = "",
            isLoading: Bool = false,
            errorMessage: String? = nil,
            addEditSheet: AddEditShiftTypeFeature.State? = nil
        ) {
            self.shiftTypes = shiftTypes
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

        /// Edit button tapped for a shift type
        case editShiftType(ShiftType)

        /// Delete button tapped for a shift type
        case deleteShiftType(ShiftType)

        /// Shift types loaded from database
        case shiftTypesLoaded(TaskResult<[ShiftType]>)

        /// Shift type deleted
        case shiftTypeDeleted(Result<Void, Error>)

        /// Add/Edit sheet actions
        case addEditSheet(PresentationAction<AddEditShiftTypeFeature.Action>)

        /// Refresh shift types after add/edit
        case refreshShiftTypes

        static func == (lhs: Action, rhs: Action) -> Bool {
            switch (lhs, rhs) {
            case (.task, .task):
                return true
            case let (.searchTextChanged(lhs), .searchTextChanged(rhs)):
                return lhs == rhs
            case (.addButtonTapped, .addButtonTapped):
                return true
            case let (.editShiftType(lhs), .editShiftType(rhs)):
                return lhs.id == rhs.id
            case let (.deleteShiftType(lhs), .deleteShiftType(rhs)):
                return lhs.id == rhs.id
            case let (.shiftTypesLoaded(lhs), .shiftTypesLoaded(rhs)):
                return lhs == rhs
            case (.shiftTypeDeleted(.success), .shiftTypeDeleted(.success)):
                return true
            case let (.shiftTypeDeleted(.failure(lhs)), .shiftTypeDeleted(.failure(rhs))):
                return lhs.localizedDescription == rhs.localizedDescription
            case let (.addEditSheet(lhs), .addEditSheet(rhs)):
                return lhs == rhs
            case (.refreshShiftTypes, .refreshShiftTypes):
                return true
            default:
                return false
            }
        }
    }

    @Dependency(\.persistenceClient) var persistenceClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .task:
                state.isLoading = true
                return .run { send in
                    await send(.shiftTypesLoaded(
                        TaskResult {
                            try await persistenceClient.fetchShiftTypes()
                        }
                    ))
                }

            case let .searchTextChanged(text):
                state.searchText = text
                return .none

            case .addButtonTapped:
                // For adding a shift type, we need a default location
                // This will be improved when we integrate with LocationsFeature
                let defaultLocation = Location(id: UUID(), name: "Default", address: "")
                state.addEditSheet = AddEditShiftTypeFeature.State(mode: .add(defaultLocation))
                return .none

            case let .editShiftType(shiftType):
                state.addEditSheet = AddEditShiftTypeFeature.State(mode: .edit(shiftType))
                return .none

            case let .deleteShiftType(shiftType):
                return .run { send in
                    await send(.shiftTypeDeleted(
                        Result {
                            try await persistenceClient.deleteShiftType(shiftType)
                        }
                    ))
                } catch: { error, send in
                    await send(.shiftTypeDeleted(.failure(error)))
                }

            case let .shiftTypesLoaded(.success(shiftTypes)):
                state.shiftTypes = IdentifiedArrayOf(uniqueElements: shiftTypes)
                state.isLoading = false
                state.errorMessage = nil
                return .none

            case let .shiftTypesLoaded(.failure(error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none

            case let .shiftTypeDeleted(.success):
                // Refresh the list after successful deletion
                return .send(.task)

            case let .shiftTypeDeleted(.failure(error)):
                state.errorMessage = error.localizedDescription
                return .none

            case .addEditSheet(.presented(.binding(_))):
                return .none

            case let .addEditSheet(.presented(.saved(shiftType))):
                // Update the local state with the new/updated shift type
                state.shiftTypes[id: shiftType.id] = shiftType
                state.addEditSheet = nil
                return .none

            case .addEditSheet(.presented(.saveButtonTapped)):
                return .none

            case .addEditSheet(.presented(.cancelButtonTapped)):
                state.addEditSheet = nil
                return .none

            case .addEditSheet(.presented(.dismiss)):
                state.addEditSheet = nil
                return .none

            case .addEditSheet(.dismiss):
                state.addEditSheet = nil
                return .none

            case .refreshShiftTypes:
                return .send(.task)
            }
        }
        .ifLet(\.$addEditSheet, action: \.addEditSheet) {
            AddEditShiftTypeFeature()
        }
    }
}

/// Feature for adding or editing a shift type
@Reducer
struct AddEditShiftTypeFeature {
    @ObservableState
    struct State: Equatable {
        enum Mode: Equatable {
            case add(Location)
            case edit(ShiftType)
        }

        var mode: Mode
        var title: String = ""
        var symbol: String = ""
        var shiftDescription: String = ""
        var startTime: HourMinuteTime? = nil
        var endTime: HourMinuteTime? = nil
        var location: Location

        /// Validation
        var validationErrors: [String] = []

        /// Saving state
        var isSaving = false

        init(mode: Mode) {
            self.mode = mode
            switch mode {
            case let .add(location):
                self.location = location
            case let .edit(shiftType):
                self.title = shiftType.title
                self.symbol = shiftType.symbol
                self.shiftDescription = shiftType.shiftDescription
                self.startTime = shiftType.duration.startTime
                self.endTime = shiftType.duration.endTime
                self.location = shiftType.location
            }
        }
    }

    enum Action: BindableAction, Equatable {
        /// Two-way binding for form fields
        case binding(BindingAction<State>)

        /// Save button tapped
        case saveButtonTapped

        /// Save completed
        case saved(ShiftType)

        /// Cancel button tapped
        case cancelButtonTapped

        /// Dismiss the sheet
        case dismiss

        static func == (lhs: Action, rhs: Action) -> Bool {
            switch (lhs, rhs) {
            case let (.binding(lhs), .binding(rhs)):
                return lhs == rhs
            case (.saveButtonTapped, .saveButtonTapped):
                return true
            case let (.saved(lhs), .saved(rhs)):
                return lhs.id == rhs.id
            case (.cancelButtonTapped, .cancelButtonTapped):
                return true
            case (.dismiss, .dismiss):
                return true
            default:
                return false
            }
        }
    }

    @Dependency(\.persistenceClient) var persistenceClient
    @Dependency(\.dismiss) var dismiss

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .binding(_):
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
                let shiftTypeID: UUID
                if case let .edit(existing) = state.mode {
                    shiftTypeID = existing.id
                } else {
                    shiftTypeID = UUID()
                }

                let duration: ShiftDuration
                if let start = state.startTime, let end = state.endTime {
                    duration = .scheduled(from: start, to: end)
                } else {
                    duration = .allDay
                }

                let formData = (
                    id: shiftTypeID,
                    symbol: state.symbol,
                    duration: duration,
                    title: state.title,
                    description: state.shiftDescription,
                    location: state.location,
                    mode: state.mode
                )

                return .run { send in
                    do {
                        let shiftType = ShiftType(
                            id: formData.id,
                            symbol: formData.symbol,
                            duration: formData.duration,
                            title: formData.title,
                            description: formData.description,
                            location: formData.location
                        )

                        switch formData.mode {
                        case .add:
                            try await persistenceClient.saveShiftType(shiftType)
                        case .edit:
                            try await persistenceClient.updateShiftType(shiftType)
                        }
                        await send(.saved(shiftType))
                    } catch {
                        // Note: We can't modify state in the async block, so we'll handle error in action response
                        // This will be handled in a separate error action if needed
                    }
                }

            case let .saved(shiftType):
                state.isSaving = false
                return .run { _ in
                    await dismiss()
                }

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

        if state.title.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append("Shift type name is required")
        }

        if state.symbol.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append("Symbol is required")
        }

        if state.startTime == nil {
            errors.append("Start time is required")
        }

        if state.endTime == nil {
            errors.append("End time is required")
        }

        return errors
    }
}
