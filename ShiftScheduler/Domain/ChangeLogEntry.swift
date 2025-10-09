import Foundation
import SwiftData

/// SwiftData model for persisting change log entries
@Model
final class ChangeLogEntry {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var userId: UUID
    var userDisplayName: String
    var changeTypeRaw: String
    var scheduledShiftDate: Date

    // Shift snapshots stored as JSON
    var oldShiftSnapshotData: Data?
    var newShiftSnapshotData: Data?

    var reason: String?

    init(
        id: UUID = UUID(),
        timestamp: Date,
        userId: UUID,
        userDisplayName: String,
        changeType: ChangeType,
        scheduledShiftDate: Date,
        oldShiftSnapshot: ShiftSnapshot?,
        newShiftSnapshot: ShiftSnapshot?,
        reason: String?
    ) {
        self.id = id
        self.timestamp = timestamp
        self.userId = userId
        self.userDisplayName = userDisplayName
        self.changeTypeRaw = changeType.rawValue
        self.scheduledShiftDate = scheduledShiftDate
        self.reason = reason

        // Encode snapshots to JSON
        if let oldSnapshot = oldShiftSnapshot {
            self.oldShiftSnapshotData = try? JSONEncoder().encode(oldSnapshot)
        }
        if let newSnapshot = newShiftSnapshot {
            self.newShiftSnapshotData = try? JSONEncoder().encode(newSnapshot)
        }
    }

    var changeType: ChangeType {
        ChangeType(rawValue: changeTypeRaw) ?? .switched
    }

    var oldShiftSnapshot: ShiftSnapshot? {
        guard let data = oldShiftSnapshotData else { return nil }
        return try? JSONDecoder().decode(ShiftSnapshot.self, from: data)
    }

    var newShiftSnapshot: ShiftSnapshot? {
        guard let data = newShiftSnapshotData else { return nil }
        return try? JSONDecoder().decode(ShiftSnapshot.self, from: data)
    }
}
