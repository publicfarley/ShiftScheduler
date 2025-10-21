import Foundation

/// Value-type model for persisting change log entries
struct ChangeLogEntry: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let timestamp: Date
    let userId: UUID
    let userDisplayName: String
    let changeType: ChangeType
    let scheduledShiftDate: Date
    let oldShiftSnapshot: ShiftSnapshot?
    let newShiftSnapshot: ShiftSnapshot?
    let reason: String?

    init(
        id: UUID = UUID(),
        timestamp: Date,
        userId: UUID,
        userDisplayName: String,
        changeType: ChangeType,
        scheduledShiftDate: Date,
        oldShiftSnapshot: ShiftSnapshot? = nil,
        newShiftSnapshot: ShiftSnapshot? = nil,
        reason: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.userId = userId
        self.userDisplayName = userDisplayName
        self.changeType = changeType
        self.scheduledShiftDate = scheduledShiftDate
        self.oldShiftSnapshot = oldShiftSnapshot
        self.newShiftSnapshot = newShiftSnapshot
        self.reason = reason
    }
}
