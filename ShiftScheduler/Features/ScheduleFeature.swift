import Foundation
import ComposableArchitecture

/// Feature managing the Schedule view with shift calendar and schedule management
@Reducer
struct ScheduleFeature {
    @ObservableState
    struct State: Equatable {
        /// All scheduled shifts for the current date range
        var scheduledShifts: [ScheduledShift] = []

        /// The currently selected date
        var selectedDate: Date = Date()

        /// Loading state
        var isLoading: Bool = false

        /// Error message if any
        var errorMessage: String?

        /// Search/filter text
        var searchText: String = ""

        /// Toast notification
        var toastMessage: ToastMessage?

        /// Sheet presentation for adding a new shift
        var showAddShiftSheet: Bool = false

        /// Undo/redo stacks for shift switching operations
        var undoStack: [ShiftSwitchOperation] = []
        var redoStack: [ShiftSwitchOperation] = []

        /// Undo/redo button states
        var canUndo: Bool { !undoStack.isEmpty }
        var canRedo: Bool { !redoStack.isEmpty }

        /// Filtered shifts based on search text
        var filteredShifts: [ScheduledShift] {
            if searchText.isEmpty {
                return shiftsForSelectedDate
            }
            return shiftsForSelectedDate.filter { shift in
                shift.shiftType?.title.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }

        /// Shifts for the currently selected date
        var shiftsForSelectedDate: [ScheduledShift] {
            scheduledShifts.filter { shift in
                Calendar.current.isDate(shift.date, inSameDayAs: selectedDate)
            }
        }

        /// Initialize with default values
        init(
            scheduledShifts: [ScheduledShift] = [],
            selectedDate: Date = Date(),
            isLoading: Bool = false,
            errorMessage: String? = nil,
            searchText: String = "",
            toastMessage: ToastMessage? = nil,
            showAddShiftSheet: Bool = false,
            undoStack: [ShiftSwitchOperation] = [],
            redoStack: [ShiftSwitchOperation] = []
        ) {
            self.scheduledShifts = scheduledShifts
            self.selectedDate = selectedDate
            self.isLoading = isLoading
            self.errorMessage = errorMessage
            self.searchText = searchText
            self.toastMessage = toastMessage
            self.showAddShiftSheet = showAddShiftSheet
            self.undoStack = undoStack
            self.redoStack = redoStack
        }

        static func == (lhs: State, rhs: State) -> Bool {
            lhs.scheduledShifts == rhs.scheduledShifts &&
            lhs.selectedDate == rhs.selectedDate &&
            lhs.isLoading == rhs.isLoading &&
            lhs.errorMessage == rhs.errorMessage &&
            lhs.searchText == rhs.searchText &&
            lhs.toastMessage == rhs.toastMessage &&
            lhs.showAddShiftSheet == rhs.showAddShiftSheet &&
            lhs.undoStack == rhs.undoStack &&
            lhs.redoStack == rhs.redoStack
        }
    }

    enum Action: Equatable {
        /// View appeared, load initial data and restore undo/redo stacks
        case task

        /// Load shifts from calendar for the current month
        case loadShifts

        /// Selected date changed
        case selectedDateChanged(Date)

        /// Search text changed
        case searchTextChanged(String)

        /// Add shift button tapped
        case addShiftButtonTapped

        /// Shift deleted
        case deleteShift(ScheduledShift)

        /// Handle shift deleted result
        case shiftDeleted(Result<Void, Error>)

        /// User tapped to switch a shift
        case switchShiftTapped(ScheduledShift)

        /// Perform the actual shift switch
        case performSwitchShift(ScheduledShift, ShiftType, String?)

        /// Handle shift switch result
        case shiftSwitched(Result<Void, Error>)

        /// Shifts loaded from calendar
        case shiftsLoaded(TaskResult<[ScheduledShift]>)

        /// Handle undo/redo stacks restored from persistence
        case stacksRestored(TaskResult<(undo: [ShiftSwitchOperation], redo: [ShiftSwitchOperation])>)

        /// Undo operation
        case undo

        /// Redo operation
        case redo

        /// Handle undo result
        case undoCompleted(Result<Void, Error>)

        /// Handle redo result
        case redoCompleted(Result<Void, Error>)

        static func == (lhs: Action, rhs: Action) -> Bool {
            switch (lhs, rhs) {
            case (.task, .task), (.loadShifts, .loadShifts),
                 (.addShiftButtonTapped, .addShiftButtonTapped),
                 (.undo, .undo), (.redo, .redo):
                return true
            case let (.selectedDateChanged(lhs), .selectedDateChanged(rhs)):
                return lhs == rhs
            case let (.searchTextChanged(lhs), .searchTextChanged(rhs)):
                return lhs == rhs
            case let (.deleteShift(lhs), .deleteShift(rhs)):
                return lhs.eventIdentifier == rhs.eventIdentifier
            case let (.switchShiftTapped(lhs), .switchShiftTapped(rhs)):
                return lhs.eventIdentifier == rhs.eventIdentifier
            case let (.performSwitchShift(lhs, newLhs, reasonLhs), .performSwitchShift(rhs, newRhs, reasonRhs)):
                return lhs.eventIdentifier == rhs.eventIdentifier &&
                       newLhs.id == newRhs.id &&
                       reasonLhs == reasonRhs
            case let (.shiftsLoaded(lhs), .shiftsLoaded(rhs)):
                return lhs == rhs
            case let (.stacksRestored(lhs), .stacksRestored(rhs)):
                switch (lhs, rhs) {
                case let (.success(lhsStacks), .success(rhsStacks)):
                    return lhsStacks.undo == rhsStacks.undo && lhsStacks.redo == rhsStacks.redo
                case (.failure, .failure):
                    return true
                default:
                    return false
                }
            case (.shiftDeleted(.success), .shiftDeleted(.success)),
                 (.shiftSwitched(.success), .shiftSwitched(.success)),
                 (.undoCompleted(.success), .undoCompleted(.success)),
                 (.redoCompleted(.success), .redoCompleted(.success)):
                return true
            case (.shiftDeleted(.failure), .shiftDeleted(.failure)),
                 (.shiftSwitched(.failure), .shiftSwitched(.failure)),
                 (.undoCompleted(.failure), .undoCompleted(.failure)),
                 (.redoCompleted(.failure), .redoCompleted(.failure)):
                return true
            default:
                return false
            }
        }
    }

    @Dependency(\.calendarClient) var calendarClient
    @Dependency(\.shiftSwitchClient) var shiftSwitchClient

    var reducer: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                state.isLoading = true
                return .merge(
                    .run { send in
                        let result = await TaskResult(catching: {
                            try await shiftSwitchClient.restoreStacks()
                        })
                        await send(.stacksRestored(result))
                    },
                    .send(.loadShifts)
                )

            case .loadShifts:
                state.isLoading = true
                state.errorMessage = nil
                let selectedDate = state.selectedDate
                return .run { send in
                    let calendar = Calendar.current
                    let startOfMonth = calendar.dateComponents([.year, .month], from: selectedDate)
                    let startDate = calendar.date(from: startOfMonth) ?? selectedDate
                    let endDate = calendar.date(byAdding: .month, value: 1, to: startDate) ?? selectedDate

                    let result = await TaskResult(catching: {
                        let shiftData = try await calendarClient.fetchShiftsInRange(startDate, endDate)
                        return shiftData.map { data -> ScheduledShift in
                            ScheduledShift(from: data, shiftType: nil)
                        }
                    })
                    await send(.shiftsLoaded(result))
                }

            case let .selectedDateChanged(newDate):
                state.selectedDate = newDate
                state.searchText = ""
                return .send(.loadShifts)

            case let .searchTextChanged(text):
                state.searchText = text
                return .none

            case .addShiftButtonTapped:
                state.showAddShiftSheet = true
                return .none

            case let .deleteShift(shift):
                return .run { send in
                    await send(.shiftDeleted(
                        Result {
                            try await calendarClient.deleteShift(shift.eventIdentifier)
                        }
                    ))
                }

            case let .shiftDeleted(result):
                switch result {
                case .success:
                    state.toastMessage = .success("Shift deleted")
                    return .send(.loadShifts)
                case let .failure(error):
                    state.toastMessage = .error("Failed to delete shift: \(error.localizedDescription)")
                    return .none
                }

            case .switchShiftTapped:
                // This will be handled by the view sending performSwitchShift
                return .none

            case let .performSwitchShift(shift, newShiftType, reason):
                guard let oldShiftType = shift.shiftType else {
                    state.toastMessage = .error("Cannot switch: Current shift type not found")
                    return .none
                }

                state.isLoading = true
                return .run { send in
                    await send(.shiftSwitched(
                        Result {
                            _ = try await shiftSwitchClient.switchShift(
                                shift.eventIdentifier,
                                shift.date,
                                oldShiftType,
                                newShiftType,
                                reason
                            )
                            return ()
                        }
                    ))
                }

            case .shiftSwitched(.success):
                state.isLoading = false
                state.toastMessage = .success("Shift switched successfully")
                return .merge(
                    .send(.loadShifts),
                    .run { send in
                        let result = await TaskResult(catching: {
                            try await shiftSwitchClient.restoreStacks()
                        })
                        await send(.stacksRestored(result))
                    }
                )

            case let .shiftSwitched(.failure(error)):
                state.isLoading = false
                state.toastMessage = .error("Failed to switch shift: \(error.localizedDescription)")
                return .none

            case let .shiftsLoaded(result):
                state.isLoading = false
                switch result {
                case let .success(shifts):
                    state.scheduledShifts = shifts
                    state.errorMessage = nil
                case let .failure(error):
                    state.errorMessage = error.localizedDescription
                }
                return .none

            case let .stacksRestored(result):
                switch result {
                case let .success((undoStack, redoStack)):
                    state.undoStack = undoStack
                    state.redoStack = redoStack
                case let .failure(error):
                    state.errorMessage = "Failed to restore undo/redo: \(error.localizedDescription)"
                }
                return .none

            case .undo:
                guard !state.undoStack.isEmpty else {
                    state.toastMessage = .error("No operation to undo")
                    return .none
                }

                guard let operation = state.undoStack.last else {
                    return .none
                }

                state.isLoading = true
                return .run { send in
                    await send(.undoCompleted(
                        Result {
                            try await shiftSwitchClient.undoOperation(operation)
                            return ()
                        }
                    ))
                }

            case .undoCompleted(.success):
                state.isLoading = false
                if !state.undoStack.isEmpty {
                    let operation = state.undoStack.removeLast()
                    state.redoStack.append(operation)
                }
                state.toastMessage = .success("Undo successful")

                let undoStack = state.undoStack
                let redoStack = state.redoStack

                return .merge(
                    .run { _ in
                        await shiftSwitchClient.persistStacks(undoStack, redoStack)
                    },
                    .send(.loadShifts)
                )

            case let .undoCompleted(.failure(error)):
                state.isLoading = false
                state.toastMessage = .error("Undo failed: \(error.localizedDescription)")
                return .none

            case .redo:
                guard !state.redoStack.isEmpty else {
                    state.toastMessage = .error("No operation to redo")
                    return .none
                }

                guard let operation = state.redoStack.last else {
                    return .none
                }

                state.isLoading = true
                return .run { send in
                    await send(.redoCompleted(
                        Result {
                            try await shiftSwitchClient.redoOperation(operation)
                            return ()
                        }
                    ))
                }

            case .redoCompleted(.success):
                state.isLoading = false
                if !state.redoStack.isEmpty {
                    let operation = state.redoStack.removeLast()
                    state.undoStack.append(operation)
                }
                state.toastMessage = .success("Redo successful")

                let undoStack = state.undoStack
                let redoStack = state.redoStack

                return .merge(
                    .run { _ in
                        await shiftSwitchClient.persistStacks(undoStack, redoStack)
                    },
                    .send(.loadShifts)
                )

            case let .redoCompleted(.failure(error)):
                state.isLoading = false
                state.toastMessage = .error("Redo failed: \(error.localizedDescription)")
                return .none
            }
        }
    }
}
