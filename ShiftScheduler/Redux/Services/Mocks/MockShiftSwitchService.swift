import Foundation

/// Mock implementation of ShiftSwitchServiceProtocol for testing
final class MockShiftSwitchService: ShiftSwitchServiceProtocol {
    // MARK: - Test Configuration Properties

    /// Mock operations that have been performed
    var performedOperations: [ChangeLogEntry] = []

    /// Whether to throw an error on the next operation
    var shouldThrowError = false

    /// Error to throw if shouldThrowError is true
    var errorToThrow: Error = NSError(domain: "MockError", code: 1, userInfo: nil)

    /// Whether shift switches are allowed
    var canSwitchShiftValue = true

    // MARK: - ShiftSwitchServiceProtocol Implementation

    func switchShift(
        _ shift: ScheduledShift,
        to newShiftType: ShiftType,
        reason: String?
    ) async throws -> ChangeLogEntry {
        if shouldThrowError {
            throw errorToThrow
        }

        let entry = ChangeLogEntry(
            id: UUID(),
            timestamp: Date(),
            userId: UUID(),
            userDisplayName: "Test User",
            changeType: .switched,
            scheduledShiftDate: shift.date,
            reason: reason
        )

        performedOperations.append(entry)
        return entry
    }

    func deleteShift(_ shift: ScheduledShift) async throws -> ChangeLogEntry {
        if shouldThrowError {
            throw errorToThrow
        }

        let entry = ChangeLogEntry(
            id: UUID(),
            timestamp: Date(),
            userId: UUID(),
            userDisplayName: "Test User",
            changeType: .deleted,
            scheduledShiftDate: shift.date,
            reason: "Shift deleted"
        )

        performedOperations.append(entry)
        return entry
    }

    func undoOperation(_ operation: ChangeLogEntry) async throws {
        if shouldThrowError {
            throw errorToThrow
        }

        // Mock undo - just record it was called
    }

    func redoOperation(_ operation: ChangeLogEntry) async throws {
        if shouldThrowError {
            throw errorToThrow
        }

        // Mock redo - just record it was called
    }

    func canSwitchShift(_ shift: ScheduledShift, to newShiftType: ShiftType) async throws -> Bool {
        if shouldThrowError {
            throw errorToThrow
        }

        return canSwitchShiftValue
    }

    // MARK: - Test Helpers

    /// Reset all mock state
    func reset() {
        performedOperations.removeAll()
        shouldThrowError = false
        canSwitchShiftValue = true
    }

    /// Check if a shift switch was performed
    func wasSwitchPerformed(for shiftId: UUID) -> Bool {
        performedOperations.contains { entry in
            entry.changeType == .switched
        }
    }

    /// Get the count of operations performed
    var operationCount: Int {
        performedOperations.count
    }
}
