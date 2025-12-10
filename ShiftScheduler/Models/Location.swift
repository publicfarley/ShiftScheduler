import Foundation

/// Value-type model for a location where shifts can occur
struct Location: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: UUID
    var name: String
    var address: String

    // MARK: - Conflict Resolution Fields
    /// Timestamp of when this location was last synced with CloudKit
    var lastSyncedAt: Date?
    /// CloudKit change token for tracking server-side changes
    var changeToken: String?

    init(
        id: UUID = UUID(),
        name: String,
        address: String,
        lastSyncedAt: Date? = nil,
        changeToken: String? = nil
    ) {
        self.id = id
        self.name = name
        self.address = address
        self.lastSyncedAt = lastSyncedAt
        self.changeToken = changeToken
    }
}
