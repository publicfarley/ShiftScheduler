import Foundation
import OSLog

private let logger = os.Logger(subsystem: "com.shiftscheduler.redux.services", category: "ShiftSwitchService")

/// Production implementation of ShiftSwitchServiceProtocol
/// Handles shift switching operations and change log recording
final class ShiftSwitchService: ShiftSwitchServiceProtocol {
    private let calendarService: CalendarServiceProtocol
    private let persistenceService: PersistenceServiceProtocol
    private let currentDayService: CurrentDayServiceProtocol

    init(
        calendarService: CalendarServiceProtocol,
        persistenceService: PersistenceServiceProtocol,
        currentDayService: CurrentDayServiceProtocol
    ) {
        self.calendarService = calendarService
        self.persistenceService = persistenceService
        self.currentDayService = currentDayService
    }

    // MARK: - ShiftSwitchServiceProtocol Implementation

    func switchShift(
        _ shift: ScheduledShift,
        to newShiftType: ShiftType,
        reason: String?
    ) async throws -> ChangeLogEntry {
        logger.debug("Switching shift from \(shift.shiftType?.title ?? "unknown") to \(newShiftType.title)")

        // Validate the switch is possible
        guard try await canSwitchShift(shift, to: newShiftType) else {
            throw ShiftSwitchServiceError.invalidSwitch("Cannot switch to this shift type")
        }

        // Create shift snapshots
        let oldSnapshot = shift.shiftType.map { ShiftSnapshot(from: $0) }
        let newSnapshot = ShiftSnapshot(from: newShiftType)

        // Create change log entry
        let entry = ChangeLogEntry(
            id: UUID(),
            timestamp: Date(),
            userId: UUID(),
            userDisplayName: "Current User",
            changeType: .switched,
            scheduledShiftDate: shift.date,
            oldShiftSnapshot: oldSnapshot,
            newShiftSnapshot: newSnapshot,
            reason: reason
        )

        // Record the change in change log
        try await persistenceService.addChangeLogEntry(entry)

        logger.debug("Successfully switched shift and recorded entry: \(entry.id)")
        return entry
    }

    func deleteShift(_ shift: ScheduledShift) async throws -> ChangeLogEntry {
        logger.debug("Deleting shift: \(shift.shiftType?.title ?? "unknown")")

        // Create snapshot of deleted shift
        let deletedSnapshot = shift.shiftType.map { ShiftSnapshot(from: $0) }

        // Create change log entry
        let entry = ChangeLogEntry(
            id: UUID(),
            timestamp: Date(),
            userId: UUID(),
            userDisplayName: "Current User",
            changeType: .deleted,
            scheduledShiftDate: shift.date,
            oldShiftSnapshot: deletedSnapshot,
            newShiftSnapshot: nil,
            reason: "Shift deleted by user"
        )

        // Record the change in change log
        try await persistenceService.addChangeLogEntry(entry)

        logger.debug("Successfully deleted shift and recorded entry: \(entry.id)")
        return entry
    }

    func undoOperation(_ operation: ChangeLogEntry) async throws {
        logger.debug("Undoing operation: \(operation.id)")

        // For now, just log the operation
        // TODO: Implement actual undo logic based on change type
    }

    func redoOperation(_ operation: ChangeLogEntry) async throws {
        logger.debug("Redoing operation: \(operation.id)")

        // For now, just log the operation
        // TODO: Implement actual redo logic based on change type
    }

    func canSwitchShift(_ shift: ScheduledShift, to newShiftType: ShiftType) async throws -> Bool {
        logger.debug("Validating shift switch")

        // Basic validation: can't switch to the same type
        if shift.shiftType?.id == newShiftType.id {
            return false
        }

        // Check if the shift is in the future
        let today = currentDayService.getTodayDate()
        if shift.date < today {
            return false
        }

        return true
    }
}

// MARK: - Error Types

enum ShiftSwitchServiceError: LocalizedError {
    case invalidSwitch(String)
    case undoFailed(String)
    case redoFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidSwitch(let reason):
            return "Cannot switch shift: \(reason)"
        case .undoFailed(let reason):
            return "Undo failed: \(reason)"
        case .redoFailed(let reason):
            return "Redo failed: \(reason)"
        }
    }
}
