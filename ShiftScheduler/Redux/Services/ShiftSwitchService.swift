import Foundation
import OSLog

private let logger = Logger(subsystem: "com.shiftscheduler.redux.services", category: "ShiftSwitchService")

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
        // logger.debug("Switching shift from \(shift.shiftType?.title ?? "unknown") to \(newShiftType.title)")

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

        // Update the shift in the calendar
        try await calendarService.updateShiftEvent(
            eventIdentifier: shift.eventIdentifier,
            newShiftType: newShiftType,
            date: shift.date
        )

        // Record the change in change log
        try await persistenceService.addChangeLogEntry(entry)

        // logger.debug("Successfully switched shift and recorded entry: \(entry.id)")
        return entry
    }

    func deleteShift(_ shift: ScheduledShift) async throws -> ChangeLogEntry {
        // logger.debug("Deleting shift: \(shift.shiftType?.title ?? "unknown")")

        // Delete the shift from the calendar
        try await calendarService.deleteShiftEvent(eventIdentifier: shift.eventIdentifier)

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

        // logger.debug("Successfully deleted shift and recorded entry: \(entry.id)")
        return entry
    }

    func undoOperation(_ operation: ChangeLogEntry) async throws {
        logger.debug("Undoing operation: \(operation.id) - type: \(operation.changeType.displayName)")

        switch operation.changeType {
        case .switched:
            // For switched operations, revert to the old shift type
            guard let oldSnapshot = operation.oldShiftSnapshot else {
                throw ShiftSwitchServiceError.undoFailed("No old snapshot available for switched operation")
            }

            // Reconstruct location from snapshot
            let location = Location(
                name: oldSnapshot.locationName ?? "Unknown Location",
                address: oldSnapshot.locationAddress ?? ""
            )

            // Reconstruct the old ShiftType from the snapshot
            let oldShiftType = ShiftType(
                id: oldSnapshot.shiftTypeId,
                symbol: oldSnapshot.symbol,
                duration: oldSnapshot.duration,
                title: oldSnapshot.title,
                description: oldSnapshot.shiftDescription,
                location: location
            )

            // Update the shift back to the old type
            try await calendarService.updateShiftEvent(
                eventIdentifier: operation.id.uuidString,
                newShiftType: oldShiftType,
                date: operation.scheduledShiftDate
            )

        case .deleted:
            // For deleted operations, restore the shift from the old snapshot
            guard let oldSnapshot = operation.oldShiftSnapshot else {
                throw ShiftSwitchServiceError.undoFailed("No old snapshot available for deleted operation")
            }

            // Reconstruct location from snapshot
            let location = Location(
                name: oldSnapshot.locationName ?? "Unknown Location",
                address: oldSnapshot.locationAddress ?? ""
            )

            // Reconstruct the old ShiftType from the snapshot
            let restoredShiftType = ShiftType(
                id: oldSnapshot.shiftTypeId,
                symbol: oldSnapshot.symbol,
                duration: oldSnapshot.duration,
                title: oldSnapshot.title,
                description: oldSnapshot.shiftDescription,
                location: location
            )

            // Recreate the shift in the calendar
            _ = try await calendarService.createShiftEvent(
                date: operation.scheduledShiftDate,
                shiftType: restoredShiftType,
                notes: operation.reason
            )

        case .created:
            // For created operations, delete the shift
            try await calendarService.deleteShiftEvent(eventIdentifier: operation.id.uuidString)

        case .markedAsSick, .unmarkedAsSick:
            // Sick day marking doesn't need undo through shift switch service
            // The calendar service handles marking/unmarking directly
            throw ShiftSwitchServiceError.undoFailed("Sick day operations should be handled through calendar service")

        case .undo, .redo:
            // These are meta operations, not directly undoable
            throw ShiftSwitchServiceError.undoFailed("Cannot undo \(operation.changeType.displayName) operations")
        }

        logger.debug("Successfully undid operation: \(operation.id)")
    }

    func redoOperation(_ operation: ChangeLogEntry) async throws {
        logger.debug("Redoing operation: \(operation.id) - type: \(operation.changeType.displayName)")

        switch operation.changeType {
        case .switched:
            // For switched operations, reapply the new shift type
            guard let newSnapshot = operation.newShiftSnapshot else {
                throw ShiftSwitchServiceError.redoFailed("No new snapshot available for switched operation")
            }

            // Reconstruct location from snapshot
            let location = Location(
                name: newSnapshot.locationName ?? "Unknown Location",
                address: newSnapshot.locationAddress ?? ""
            )

            // Reconstruct the new ShiftType from the snapshot
            let newShiftType = ShiftType(
                id: newSnapshot.shiftTypeId,
                symbol: newSnapshot.symbol,
                duration: newSnapshot.duration,
                title: newSnapshot.title,
                description: newSnapshot.shiftDescription,
                location: location
            )

            // Update the shift to the new type
            try await calendarService.updateShiftEvent(
                eventIdentifier: operation.id.uuidString,
                newShiftType: newShiftType,
                date: operation.scheduledShiftDate
            )

        case .deleted:
            // For deleted operations, delete the shift again
            try await calendarService.deleteShiftEvent(eventIdentifier: operation.id.uuidString)

        case .created:
            // For created operations, recreate the shift
            guard let newSnapshot = operation.newShiftSnapshot else {
                throw ShiftSwitchServiceError.redoFailed("No new snapshot available for created operation")
            }

            // Reconstruct location from snapshot
            let location = Location(
                name: newSnapshot.locationName ?? "Unknown Location",
                address: newSnapshot.locationAddress ?? ""
            )

            // Reconstruct the ShiftType from the snapshot
            let shiftType = ShiftType(
                id: newSnapshot.shiftTypeId,
                symbol: newSnapshot.symbol,
                duration: newSnapshot.duration,
                title: newSnapshot.title,
                description: newSnapshot.shiftDescription,
                location: location
            )

            // Recreate the shift in the calendar
            _ = try await calendarService.createShiftEvent(
                date: operation.scheduledShiftDate,
                shiftType: shiftType,
                notes: operation.reason
            )

        case .markedAsSick, .unmarkedAsSick:
            // Sick day marking doesn't need redo through shift switch service
            // The calendar service handles marking/unmarking directly
            throw ShiftSwitchServiceError.redoFailed("Sick day operations should be handled through calendar service")

        case .undo, .redo:
            // These are meta operations, not directly redoable
            throw ShiftSwitchServiceError.redoFailed("Cannot redo \(operation.changeType.displayName) operations")
        }

        logger.debug("Successfully redid operation: \(operation.id)")
    }

    func canSwitchShift(_ shift: ScheduledShift, to newShiftType: ShiftType) async throws -> Bool {
        // logger.debug("Validating shift switch")

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
