import Foundation
import OSLog

private let logger = Logger(subsystem: "com.functioncraft.shiftscheduler", category: "ShiftSwitchService")

/// Service for handling shift type switching with undo/redo support
///
/// DEPRECATED: This service is no longer used in TCA-migrated features.
/// Use ShiftSwitchClient dependency instead. Undo/redo state is now managed
/// by TCA reducers, not by this service.
actor ShiftSwitchService {
    private let calendarService: CalendarServiceProtocol
    private let changeLogRepository: ChangeLogRepositoryProtocol
    private let dateProvider: DateProviderProtocol
    private let userProfileManager: UserProfileManager
    private let persistence: UndoRedoPersistence

    // Undo/Redo stacks
    private var undoStack: [ShiftSwitchOperation] = []
    private var redoStack: [ShiftSwitchOperation] = []
    private let maxUndoStackSize = 50
    private var isRestoringFromPersistence = false

    init(
        calendarService: CalendarServiceProtocol,
        changeLogRepository: ChangeLogRepositoryProtocol,
        dateProvider: DateProviderProtocol = SystemDateProvider(),
        userProfileManager: UserProfileManager = .shared,
        persistence: UndoRedoPersistence = UndoRedoPersistence()
    ) {
        self.calendarService = calendarService
        self.changeLogRepository = changeLogRepository
        self.dateProvider = dateProvider
        self.userProfileManager = userProfileManager
        self.persistence = persistence
    }

    /// Restores undo/redo stacks from persistent storage
    func restoreFromPersistence() async {
        guard !isRestoringFromPersistence else { return }
        isRestoringFromPersistence = true

        let stacks = await persistence.loadBothStacks()
        self.undoStack = stacks.undo
        self.redoStack = stacks.redo

        logger.debug("Restored \(self.undoStack.count) undo and \(self.redoStack.count) redo operations from persistence")
        isRestoringFromPersistence = false
    }

    /// Switches a shift to a new shift type
    func switchShift(
        eventIdentifier: String,
        scheduledDate: Date,
        from oldShiftType: ShiftType,
        to newShiftType: ShiftType,
        reason: String?
    ) async throws {
        logger.debug("Switching shift on \(scheduledDate) from \(oldShiftType.title) to \(newShiftType.title)")

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

        // Add to undo stack
        let operation = ShiftSwitchOperation(
            eventIdentifier: eventIdentifier,
            scheduledDate: scheduledDate,
            oldShiftType: oldShiftType,
            newShiftType: newShiftType,
            changeLogEntryId: entry.id,
            reason: reason
        )
        addToUndoStack(operation)

        // Clear redo stack when new action is performed
        redoStack.removeAll()

        // Persist stacks
        await persistence.saveBothStacks(undo: undoStack, redo: redoStack)

        logger.debug("Shift switched successfully")
    }

    /// Undoes the last shift switch
    func undo() async throws {
        guard let operation = undoStack.popLast() else {
            throw ShiftSwitchError.noOperationToUndo
        }

        logger.debug("Undoing shift switch for \(operation.scheduledDate)")

        // Revert the calendar event
        try await calendarService.updateShiftEvent(
            identifier: operation.eventIdentifier,
            to: operation.oldShiftType
        )

        // Log the undo
        let oldSnapshot = ShiftSnapshot(from: operation.newShiftType)
        let newSnapshot = ShiftSnapshot(from: operation.oldShiftType)

        // Get current user profile
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

        // Add to redo stack
        redoStack.append(operation)

        // Persist stacks
        await persistence.saveBothStacks(undo: undoStack, redo: redoStack)

        logger.debug("Undo completed successfully")
    }

    /// Redoes the last undone shift switch
    func redo() async throws {
        guard let operation = redoStack.popLast() else {
            throw ShiftSwitchError.noOperationToRedo
        }

        logger.debug("Redoing shift switch for \(operation.scheduledDate)")

        // Reapply the calendar event change
        try await calendarService.updateShiftEvent(
            identifier: operation.eventIdentifier,
            to: operation.newShiftType
        )

        // Log the redo
        let oldSnapshot = ShiftSnapshot(from: operation.oldShiftType)
        let newSnapshot = ShiftSnapshot(from: operation.newShiftType)

        // Get current user profile
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

        // Add back to undo stack
        addToUndoStack(operation)

        // Persist stacks
        await persistence.saveBothStacks(undo: undoStack, redo: redoStack)

        logger.debug("Redo completed successfully")
    }

    /// Returns whether undo is available
    func canUndo() -> Bool {
        !undoStack.isEmpty
    }

    /// Returns whether redo is available
    func canRedo() -> Bool {
        !redoStack.isEmpty
    }

    /// Clears both undo and redo stacks
    func clearUndoRedoHistory() async {
        undoStack.removeAll()
        redoStack.removeAll()

        // Clear persistence
        await persistence.clearBothStacks()

        logger.debug("Undo/redo history cleared")
    }

    // MARK: - Private Helpers

    private func addToUndoStack(_ operation: ShiftSwitchOperation) {
        undoStack.append(operation)
        if undoStack.count > maxUndoStackSize {
            undoStack.removeFirst()
        }
    }
}

// MARK: - Supporting Types

struct ShiftSwitchOperation: Sendable {
    let eventIdentifier: String
    let scheduledDate: Date
    let oldShiftType: ShiftType
    let newShiftType: ShiftType
    let changeLogEntryId: UUID
    let reason: String?
}

enum ShiftSwitchError: LocalizedError {
    case noOperationToUndo
    case noOperationToRedo
    case shiftNotFound
    case updateFailed(Error)

    var errorDescription: String? {
        switch self {
        case .noOperationToUndo:
            return "No operation to undo"
        case .noOperationToRedo:
            return "No operation to redo"
        case .shiftNotFound:
            return "Shift not found"
        case .updateFailed(let error):
            return "Failed to update shift: \(error.localizedDescription)"
        }
    }
}
