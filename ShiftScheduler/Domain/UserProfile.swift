import Foundation

/// Multi-user support - identifies who made changes
struct UserProfile: Codable, Equatable, Sendable, Hashable {
    let userId: UUID
    var displayName: String
    var retentionPolicy: ChangeLogRetentionPolicy
    var autoPurgeEnabled: Bool
    var lastPurgeDate: Date?

    init(
        userId: UUID = UUID(),
        displayName: String = "",
        retentionPolicy: ChangeLogRetentionPolicy = .forever,
        autoPurgeEnabled: Bool = true,
        lastPurgeDate: Date? = nil
    ) {
        self.userId = userId
        self.displayName = displayName
        self.retentionPolicy = retentionPolicy
        self.autoPurgeEnabled = autoPurgeEnabled
        self.lastPurgeDate = lastPurgeDate
    }
}
