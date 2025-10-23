import Foundation

/// Protocol for shift switching operations in Redux middleware
/// Handles the business logic of switching shifts and recording changes
protocol ShiftSwitchServiceProtocol: Sendable {
    /// Switch a scheduled shift to a different shift type
    /// - Parameters:
    ///   - shift: The shift to switch
    ///   - newShiftType: The new shift type
    ///   - reason: Optional reason for the switch
    /// - Returns: ChangeLogEntry recording the operation
    func switchShift(
        _ shift: ScheduledShift,
        to newShiftType: ShiftType,
        reason: String?
    ) async throws -> ChangeLogEntry

    /// Delete a scheduled shift and record the operation
    /// - Parameter shift: The shift to delete
    /// - Returns: ChangeLogEntry recording the deletion
    func deleteShift(_ shift: ScheduledShift) async throws -> ChangeLogEntry

    /// Undo a previous shift operation
    /// - Parameter operation: The change log entry to undo
    func undoOperation(_ operation: ChangeLogEntry) async throws

    /// Redo a previously undone operation
    /// - Parameter operation: The change log entry to redo
    func redoOperation(_ operation: ChangeLogEntry) async throws

    /// Validate if a shift switch is possible
    /// - Parameters:
    ///   - shift: The shift to check
    ///   - newShiftType: The proposed new shift type
    /// - Returns: true if the switch is valid
    func canSwitchShift(_ shift: ScheduledShift, to newShiftType: ShiftType) async throws -> Bool
}
