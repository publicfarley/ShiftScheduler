import Foundation
import ComposableArchitecture

/// TCA Dependency Client for shift switching with undo/redo support
/// Wraps the existing ShiftSwitchService for use within TCA reducers
@DependencyClient
struct ShiftSwitchClient: Sendable {
    /// Switches a shift to a new shift type and records it for undo/redo
    var switchShift: @Sendable (
        String,      // eventIdentifier
        Date,        // scheduledDate
        ShiftType,   // oldShiftType
        ShiftType,   // newShiftType
        String?      // reason
    ) async throws -> Void

    /// Checks if an undo operation is available
    var canUndo: @Sendable () -> Bool = { false }

    /// Checks if a redo operation is available
    var canRedo: @Sendable () -> Bool = { false }

    /// Undoes the last shift switch operation
    var undo: @Sendable () async throws -> Void

    /// Redoes the last undone shift switch operation
    var redo: @Sendable () async throws -> Void

    /// Clears all undo and redo history
    var clearHistory: @Sendable () async -> Void = { }

    /// Restores undo/redo stacks from persistent storage
    var restoreFromPersistence: @Sendable () async -> Void = { }
}

extension ShiftSwitchClient: DependencyKey {
    /// Live implementation using the real ShiftSwitchService
    static let liveValue: ShiftSwitchClient = {
        let service = ShiftSwitchService.shared

        return ShiftSwitchClient(
            switchShift: { @Sendable eventIdentifier, scheduledDate, oldShiftType, newShiftType, reason in
                try await service.switchShift(
                    eventIdentifier: eventIdentifier,
                    scheduledDate: scheduledDate,
                    from: oldShiftType,
                    to: newShiftType,
                    reason: reason
                )
            },
            canUndo: {
                service.canUndo()
            },
            canRedo: {
                service.canRedo()
            },
            undo: {
                try await service.undo()
            },
            redo: {
                try await service.redo()
            },
            clearHistory: { @Sendable in
                await service.clearUndoRedoHistory()
            },
            restoreFromPersistence: { @Sendable in
                await service.restoreFromPersistence()
            }
        )
    }()

    /// Test value with unimplemented methods
    static let testValue = ShiftSwitchClient()

    /// Preview value with mock data
    static let previewValue = ShiftSwitchClient(
        switchShift: { @Sendable _, _, _, _, _ in },
        canUndo: { false },
        canRedo: { false },
        undo: { },
        redo: { },
        clearHistory: { },
        restoreFromPersistence: { }
    )
}

extension DependencyValues {
    var shiftSwitchClient: ShiftSwitchClient {
        get { self[ShiftSwitchClient.self] }
        set { self[ShiftSwitchClient.self] = newValue }
    }
}
