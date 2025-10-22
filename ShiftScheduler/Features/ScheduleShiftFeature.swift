import Foundation
import ComposableArchitecture

/// Feature for scheduling a new shift
/// Handles shift type selection, date picking, and creation via calendar service
@Reducer
struct ScheduleShiftFeature {
    @ObservableState
    struct State: Equatable, Sendable {
        /// The initially selected date for the shift
        let initialDate: Date

        /// Currently selected date for the shift
        var shiftDate: Date

        /// All available shift types
        var availableShiftTypes: [ShiftType] = []

        /// Currently selected shift type
        var selectedShiftType: ShiftType?

        /// Loading state while creating shift
        var isLoading = false

        /// Error message if creation fails
        var errorMessage: String?

        init(selectedDate: Date) {
            self.initialDate = selectedDate
            self.shiftDate = selectedDate
        }
    }

    enum Action: Equatable {
        /// View appeared, load initial data
        case task

        /// Date changed
        case dateChanged(Date)

        /// Shift type selected
        case shiftTypeSelected(ShiftType?)

        /// Shift types loaded
        case shiftTypesLoaded([ShiftType])

        /// Save button tapped
        case saveButtonTapped

        /// Cancel button tapped
        case cancelButtonTapped

        /// Shift created successfully
        case shiftCreated

        /// Error occurred during shift creation
        case creationError(String)

        static func == (lhs: Action, rhs: Action) -> Bool {
            switch (lhs, rhs) {
            case (.task, .task):
                return true
            case let (.dateChanged(lhs), .dateChanged(rhs)):
                return lhs == rhs
            case let (.shiftTypeSelected(lhs), .shiftTypeSelected(rhs)):
                return lhs == rhs
            case let (.shiftTypesLoaded(lhs), .shiftTypesLoaded(rhs)):
                return lhs.count == rhs.count && zip(lhs, rhs).allSatisfy({ $0.id == $1.id })
            case (.saveButtonTapped, .saveButtonTapped):
                return true
            case (.cancelButtonTapped, .cancelButtonTapped):
                return true
            case (.shiftCreated, .shiftCreated):
                return true
            case let (.creationError(lhs), .creationError(rhs)):
                return lhs == rhs
            default:
                return false
            }
        }
    }

    @Dependency(\.calendarClient) var calendarClient
    @Dependency(\.dismiss) var dismiss

    var reducer: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                // Load initial shift types (in real app, would come from parent feature)
                // For now, just initialize empty - parent will provide via binding
                return .none

            case let .dateChanged(newDate):
                state.shiftDate = newDate
                return .none

            case let .shiftTypeSelected(shiftType):
                state.selectedShiftType = shiftType
                state.errorMessage = nil
                return .none

            case let .shiftTypesLoaded(shiftTypes):
                state.availableShiftTypes = shiftTypes
                return .none

            case .saveButtonTapped:
                guard let shiftType = state.selectedShiftType else {
                    state.errorMessage = "Please select a shift type"
                    return .none
                }

                state.isLoading = true
                state.errorMessage = nil

                // Capture values before async block
                let shiftTypeId = shiftType.id
                let shiftDate = state.shiftDate

                return .run { send in
                    do {
                        let hasDuplicate = try await calendarClient.checkForDuplicate(
                            shiftTypeId,
                            shiftDate
                        )

                        if hasDuplicate {
                            await send(.creationError("A shift of this type is already scheduled for this date."))
                            return
                        }

                        _ = try await calendarClient.createShift(shiftType, shiftDate)
                        await send(.shiftCreated)
                    } catch {
                        await send(.creationError(error.localizedDescription))
                    }
                }

            case let .creationError(message):
                state.isLoading = false
                state.errorMessage = message
                return .none

            case .shiftCreated:
                state.isLoading = false
                return .run { _ in
                    await dismiss()
                }

            case .cancelButtonTapped:
                return .run { _ in
                    await dismiss()
                }
            }
        }
    }
}
