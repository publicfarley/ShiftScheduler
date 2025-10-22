import Foundation
import ComposableArchitecture

/// Feature managing the Today view with shift information and undo/redo operations
@Reducer
struct TodayFeature {
    @ObservableState
    struct State: Equatable {
        /// All scheduled shifts loaded from calendar
        var scheduledShifts: [ScheduledShift] = []

        /// Loading state
        var isLoading: Bool = false

        /// Error message if any
        var errorMessage: String?

        /// Sheet presentation for shift switching
        var showSwitchShiftSheet: Bool = false

        /// Toast notification
        var toastMessage: ToastMessage?

        /// Cached today's shift
        var todayShift: ScheduledShift?

        /// Cached tomorrow's shift
        var tomorrowShift: ScheduledShift?

        /// Count of shifts this week
        var thisWeekShiftsCount: Int = 0

        /// Count of completed shifts this week
        var completedThisWeek: Int = 0

        /// Undo availability state
        var canUndo: Bool = false

        /// Redo availability state
        var canRedo: Bool = false

        /// Selected shift for switching operations
        var selectedShift: ScheduledShift?

        /// Undo/redo stacks for persistence
        var undoStack: [ShiftSwitchOperation] = []
        var redoStack: [ShiftSwitchOperation] = []

        /// Initialize with optional initial shifts
        init(
            scheduledShifts: [ScheduledShift] = [],
            isLoading: Bool = false,
            errorMessage: String? = nil,
            showSwitchShiftSheet: Bool = false,
            toastMessage: ToastMessage? = nil,
            todayShift: ScheduledShift? = nil,
            tomorrowShift: ScheduledShift? = nil,
            thisWeekShiftsCount: Int = 0,
            completedThisWeek: Int = 0,
            canUndo: Bool = false,
            canRedo: Bool = false,
            selectedShift: ScheduledShift? = nil,
            undoStack: [ShiftSwitchOperation] = [],
            redoStack: [ShiftSwitchOperation] = []
        ) {
            self.scheduledShifts = scheduledShifts
            self.isLoading = isLoading
            self.errorMessage = errorMessage
            self.showSwitchShiftSheet = showSwitchShiftSheet
            self.toastMessage = toastMessage
            self.todayShift = todayShift
            self.tomorrowShift = tomorrowShift
            self.thisWeekShiftsCount = thisWeekShiftsCount
            self.completedThisWeek = completedThisWeek
            self.canUndo = canUndo
            self.canRedo = canRedo
            self.selectedShift = selectedShift
            self.undoStack = undoStack
            self.redoStack = redoStack
        }

        static func == (lhs: State, rhs: State) -> Bool {
            lhs.scheduledShifts == rhs.scheduledShifts &&
            lhs.isLoading == rhs.isLoading &&
            lhs.errorMessage == rhs.errorMessage &&
            lhs.showSwitchShiftSheet == rhs.showSwitchShiftSheet &&
            lhs.toastMessage == rhs.toastMessage &&
            lhs.todayShift == rhs.todayShift &&
            lhs.tomorrowShift == rhs.tomorrowShift &&
            lhs.thisWeekShiftsCount == rhs.thisWeekShiftsCount &&
            lhs.completedThisWeek == rhs.completedThisWeek &&
            lhs.canUndo == rhs.canUndo &&
            lhs.canRedo == rhs.canRedo &&
            lhs.selectedShift == rhs.selectedShift &&
            lhs.undoStack == rhs.undoStack &&
            lhs.redoStack == rhs.redoStack
        }
    }

    enum Action: Equatable {
        /// View appeared, load initial data and restore undo/redo stacks
        case task

        /// Load shifts from calendar for a specific date range
        case loadShifts

        /// Handle shifts loaded result
        case shiftsLoaded(TaskResult<[ScheduledShift]>)

        /// Handle undo/redo stacks restored from persistence
        case stacksRestored(TaskResult<(undo: [ShiftSwitchOperation], redo: [ShiftSwitchOperation])>)

        /// User tapped to switch a shift
        case switchShiftTapped(ScheduledShift)

        /// Perform the actual shift switch
        case performSwitchShift(ScheduledShift, ShiftType, String?)

        /// Handle shift switch result
        case shiftSwitched(Result<Void, Error>)

        /// Perform undo operation
        case undo

        /// Handle undo result
        case undoCompleted(Result<Void, Error>)

        /// Perform redo operation
        case redo

        /// Handle redo result
        case redoCompleted(Result<Void, Error>)

        /// Clear the toast message
        case toastMessageCleared

        /// Sheet was dismissed
        case switchShiftSheetDismissed

        /// Update cached shift computations
        case updateCachedShifts

        /// Update undo/redo button states
        case updateUndoRedoStates

        static func == (lhs: Action, rhs: Action) -> Bool {
            switch (lhs, rhs) {
            case (.task, .task), (.loadShifts, .loadShifts),
                 (.undo, .undo), (.redo, .redo),
                 (.toastMessageCleared, .toastMessageCleared),
                 (.switchShiftSheetDismissed, .switchShiftSheetDismissed),
                 (.updateCachedShifts, .updateCachedShifts),
                 (.updateUndoRedoStates, .updateUndoRedoStates):
                return true
            case let (.shiftsLoaded(a), .shiftsLoaded(b)):
                return a == b
            case let (.stacksRestored(a), .stacksRestored(b)):
                switch (a, b) {
                case let (.success(aStacks), .success(bStacks)):
                    return aStacks.undo == bStacks.undo && aStacks.redo == bStacks.redo
                case (.failure, .failure):
                    return true
                default:
                    return false
                }
            case let (.switchShiftTapped(a), .switchShiftTapped(b)):
                return a.id == b.id
            case let (.performSwitchShift(aShift, aType, aReason), .performSwitchShift(bShift, bType, bReason)):
                return aShift.id == bShift.id && aType.id == bType.id && aReason == bReason
            case (.shiftSwitched(.success), .shiftSwitched(.success)),
                 (.shiftSwitched(.failure), .shiftSwitched(.failure)),
                 (.undoCompleted(.success), .undoCompleted(.success)),
                 (.undoCompleted(.failure), .undoCompleted(.failure)),
                 (.redoCompleted(.success), .redoCompleted(.success)),
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
                    .run { @Sendable send in
                        let result = await TaskResult(catching: {
                            try await shiftSwitchClient.restoreStacks()
                        })
                        await send(.stacksRestored(result))
                    },
                    .send(.loadShifts)
                )

            case .loadShifts:
                state.isLoading = true
                return .run { send in
                    let today = Calendar.current.startOfDay(for: Date())
                    let endDate = Calendar.current.date(byAdding: .day, value: 30, to: today) ?? today

                    let result: TaskResult<[ScheduledShift]> = await TaskResult {
                        let shiftDataList = try await calendarClient.fetchShiftsInRange(today, endDate)
                        return shiftDataList.map { data in
                            ScheduledShift(
                                id: UUID(),
                                eventIdentifier: data.eventIdentifier,
                                shiftType: nil,
                                date: data.date
                            )
                        }
                    }

                    await send(.shiftsLoaded(result))
                }

            case let .shiftsLoaded(.success(shifts)):
                state.isLoading = false
                state.scheduledShifts = shifts
                state.errorMessage = nil
                return .send(.updateCachedShifts)

            case let .shiftsLoaded(.failure(error)):
                state.isLoading = false
                state.errorMessage = "Failed to load shifts: \(error.localizedDescription)"
                return .none

            case let .stacksRestored(.success((undoStack, redoStack))):
                state.undoStack = undoStack
                state.redoStack = redoStack
                return .send(.updateUndoRedoStates)

            case let .stacksRestored(.failure(error)):
                state.errorMessage = "Failed to restore undo/redo stacks: \(error.localizedDescription)"
                return .none

            case let .switchShiftTapped(shift):
                state.selectedShift = shift
                state.showSwitchShiftSheet = true
                return .none

            case let .performSwitchShift(shift, newShiftType, reason):
                guard let oldShiftType = shift.shiftType else {
                    state.toastMessage = .error("Cannot switch: Current shift type not found")
                    return .none
                }

                state.isLoading = true
                let eventId = shift.eventIdentifier
                let date = shift.date

                return .run { send in
                    await send(.shiftSwitched(
                        Result {
                            _ = try await shiftSwitchClient.switchShift(
                                eventId,
                                date,
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
                state.showSwitchShiftSheet = false
                state.selectedShift = nil
                state.toastMessage = .success("Shift switched successfully")

                // Reload shifts and update undo/redo states
                return .merge(
                    .send(.loadShifts),
                    .send(.updateUndoRedoStates)
                )

            case let .shiftSwitched(.failure(error)):
                state.isLoading = false
                state.toastMessage = .error("Failed to switch shift: \(error.localizedDescription)")
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

                // Capture stacks before returning to avoid state capture issues
                let undoStack = state.undoStack
                let redoStack = state.redoStack

                // Persist updated stacks and reload
                return .merge(
                    .run { _ in
                        await shiftSwitchClient.persistStacks(undoStack, redoStack)
                    },
                    .send(.loadShifts),
                    .send(.updateUndoRedoStates)
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

                // Capture stacks before returning to avoid state capture issues
                let undoStack = state.undoStack
                let redoStack = state.redoStack

                // Persist updated stacks and reload
                return .merge(
                    .run { _ in
                        await shiftSwitchClient.persistStacks(undoStack, redoStack)
                    },
                    .send(.loadShifts),
                    .send(.updateUndoRedoStates)
                )

            case let .redoCompleted(.failure(error)):
                state.isLoading = false
                state.toastMessage = .error("Redo failed: \(error.localizedDescription)")
                return .none

            case .toastMessageCleared:
                state.toastMessage = nil
                return .none

            case .switchShiftSheetDismissed:
                state.showSwitchShiftSheet = false
                state.selectedShift = nil
                return .none

            case .updateCachedShifts:
                let today = Calendar.current.startOfDay(for: Date())
                let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today

                // Find today's shift
                state.todayShift = state.scheduledShifts.first { shift in
                    Calendar.current.isDate(shift.date, inSameDayAs: today)
                }

                // Find tomorrow's shift
                state.tomorrowShift = state.scheduledShifts.first { shift in
                    Calendar.current.isDate(shift.date, inSameDayAs: tomorrow)
                }

                // Calculate this week's shifts
                let weekStart = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
                let weekEnd = Calendar.current.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart

                let thisWeekShifts = state.scheduledShifts.filter { shift in
                    shift.date >= weekStart && shift.date < weekEnd
                }

                state.thisWeekShiftsCount = thisWeekShifts.count
                // Note: completedThisWeek would need additional logic to determine if a shift is "completed"
                // For now, we'll leave it as 0 or calculate based on date comparison
                let completedCount = thisWeekShifts.filter { shift in
                    shift.date < today
                }.count
                state.completedThisWeek = completedCount

                return .none

            case .updateUndoRedoStates:
                state.canUndo = !state.undoStack.isEmpty
                state.canRedo = !state.redoStack.isEmpty
                return .none
            }
        }
    }
}
