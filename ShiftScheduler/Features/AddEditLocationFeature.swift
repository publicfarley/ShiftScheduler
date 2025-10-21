import Foundation
import ComposableArchitecture

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
        case saved(Result<Void, Error>)

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
            case (.saved(.success), .saved(.success)):
                return true
            case let (.saved(.failure(lhs)), .saved(.failure(rhs))):
                return lhs.localizedDescription == rhs.localizedDescription
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

    var reducer: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .binding(_):
                // BindingAction is automatically handled by TCA
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
                    do {
                        switch state.mode {
                        case .add:
                            let newLocation = Location(
                                id: UUID(),
                                name: state.name,
                                address: state.address
                            )
                            try await persistenceClient.saveLocation(newLocation)

                        case let .edit(existingLocation):
                            let updatedLocation = Location(
                                id: existingLocation.id,
                                name: state.name,
                                address: state.address
                            )
                            try await persistenceClient.updateLocation(updatedLocation)
                        }
                        await send(.saved(.success(())))
                    } catch {
                        await send(.saved(.failure(error)))
                    }
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
