import Foundation
import ComposableArchitecture

/// TCA Dependency Client for shift switching operations
/// Provides stateless operations for switching shifts and recording changes
/// State management (undo/redo stacks) is handled by the TCA reducer, not this client
@DependencyClient
struct ShiftSwitchClient: Sendable {
    /// Switches a shift to a new shift type and logs the change
    /// Returns the change log entry ID for undo/redo tracking
    var switchShift: @Sendable (
        String,      // eventIdentifier
        Date,        // scheduledDate
        ShiftType,   // oldShiftType
        ShiftType,   // newShiftType
        String?      // reason
    ) async throws -> UUID

    /// Performs an undo operation by reverting a shift switch
    /// Called when user triggers undo from feature state
    var undoOperation: @Sendable (ShiftSwitchOperation) async throws -> Void

    /// Performs a redo operation by reapplying a shift switch
    /// Called when user triggers redo from feature state
    var redoOperation: @Sendable (ShiftSwitchOperation) async throws -> Void

    /// Saves undo/redo stacks to persistent storage
    /// Called by the feature to persist state changes
    var persistStacks: @Sendable ([ShiftSwitchOperation], [ShiftSwitchOperation]) async -> Void = { _, _ in }

    /// Loads undo/redo stacks from persistent storage
    /// Called during feature initialization to restore user history
    var restoreStacks: @Sendable () async throws -> (undo: [ShiftSwitchOperation], redo: [ShiftSwitchOperation]) = { ([], []) }

    /// Clears all undo/redo history from persistent storage
    var clearHistory: @Sendable () async throws -> Void = { }
}

extension ShiftSwitchClient: DependencyKey {
    /// Live implementation using the real services
    /// Note: ShiftSwitchService is no longer used directly; its logic is now in the reducer
    static let liveValue: ShiftSwitchClient = {
        let calendarService = CalendarService.shared
        let changeLogRepository = ChangeLogRepository()
        let dateProvider = SystemDateProvider()
        let userProfileManager = UserProfileManager.shared
        let persistence = UndoRedoPersistence()

        return ShiftSwitchClient(
            switchShift: { @Sendable eventIdentifier, scheduledDate, oldShiftType, newShiftType, reason in
                // Update the calendar event
                try await calendarService.updateShiftEvent(identifier: eventIdentifier, to: newShiftType)

                // Create snapshots
                let oldSnapshot = ShiftSnapshot(from: oldShiftType)
                let newSnapshot = ShiftSnapshot(from: newShiftType)

                // Get current user profile
                let currentUser = userProfileManager.getCurrentProfile()

                // Log the change
                let entry = ChangeLogEntry(
                    timestamp: dateProvider.now(),
                    userId: currentUser.userId,
                    userDisplayName: currentUser.displayName,
                    changeType: .switched,
                    scheduledShiftDate: scheduledDate,
                    oldShiftSnapshot: oldSnapshot,
                    newShiftSnapshot: newSnapshot,
                    reason: reason
                )
                try await changeLogRepository.save(entry)

                return entry.id
            },
            undoOperation: { @Sendable operation in
                // Revert the calendar event
                try await calendarService.updateShiftEvent(
                    identifier: operation.eventIdentifier,
                    to: operation.oldShiftType
                )

                // Log the undo
                let oldSnapshot = ShiftSnapshot(from: operation.newShiftType)
                let newSnapshot = ShiftSnapshot(from: operation.oldShiftType)

                let currentUser = userProfileManager.getCurrentProfile()

                let entry = ChangeLogEntry(
                    timestamp: dateProvider.now(),
                    userId: currentUser.userId,
                    userDisplayName: currentUser.displayName,
                    changeType: .undo,
                    scheduledShiftDate: operation.scheduledDate,
                    oldShiftSnapshot: oldSnapshot,
                    newShiftSnapshot: newSnapshot,
                    reason: "Undo: \(operation.reason ?? "")"
                )
                try await changeLogRepository.save(entry)
            },
            redoOperation: { @Sendable operation in
                // Reapply the calendar event change
                try await calendarService.updateShiftEvent(
                    identifier: operation.eventIdentifier,
                    to: operation.newShiftType
                )

                // Log the redo
                let oldSnapshot = ShiftSnapshot(from: operation.oldShiftType)
                let newSnapshot = ShiftSnapshot(from: operation.newShiftType)

                let currentUser = userProfileManager.getCurrentProfile()

                let entry = ChangeLogEntry(
                    timestamp: dateProvider.now(),
                    userId: currentUser.userId,
                    userDisplayName: currentUser.displayName,
                    changeType: .redo,
                    scheduledShiftDate: operation.scheduledDate,
                    oldShiftSnapshot: oldSnapshot,
                    newShiftSnapshot: newSnapshot,
                    reason: "Redo: \(operation.reason ?? "")"
                )
                try await changeLogRepository.save(entry)
            },
            persistStacks: { @Sendable undoStack, redoStack in
                await persistence.saveBothStacks(undo: undoStack, redo: redoStack)
            },
            restoreStacks: {
                let stacks = await persistence.loadBothStacks()
                return (undo: stacks.undo, redo: stacks.redo)
            },
            clearHistory: {
                await persistence.clearBothStacks()
            }
        )
    }()

    /// Test value with unimplemented methods
    static let testValue = ShiftSwitchClient()

    /// Preview value with mock data
    static let previewValue = ShiftSwitchClient(
        switchShift: { @Sendable _, _, _, _, _ in UUID() },
        undoOperation: { @Sendable _ in },
        redoOperation: { @Sendable _ in },
        persistStacks: { @Sendable _, _ in },
        restoreStacks: { (undo: [], redo: []) },
        clearHistory: { }
    )
}

extension DependencyValues {
    var shiftSwitchClient: ShiftSwitchClient {
        get { self[ShiftSwitchClient.self] }
        set { self[ShiftSwitchClient.self] = newValue }
    }
}
