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

    // MARK: - Calendar Operation Tracking

    /// Count of calendar update operations performed
    private(set) var calendarUpdateCallCount = 0

    /// Count of calendar delete operations performed
    private(set) var calendarDeleteCallCount = 0

    /// The last event identifier that was updated in the calendar
    private(set) var lastUpdatedEventIdentifier: String?

    /// The last event identifier that was deleted from the calendar
    private(set) var lastDeletedEventIdentifier: String?

    // MARK: - ShiftSwitchServiceProtocol Implementation

    func switchShift(
        _ shift: ScheduledShift,
        to newShiftType: ShiftType,
        reason: String?
    ) async throws -> ChangeLogEntry {
        if shouldThrowError {
            throw errorToThrow
        }

        // Track calendar update operation
        calendarUpdateCallCount += 1
        lastUpdatedEventIdentifier = shift.eventIdentifier

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

        // Track calendar delete operation
        calendarDeleteCallCount += 1
        lastDeletedEventIdentifier = shift.eventIdentifier

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
        calendarUpdateCallCount = 0
        calendarDeleteCallCount = 0
        lastUpdatedEventIdentifier = nil
        lastDeletedEventIdentifier = nil
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
