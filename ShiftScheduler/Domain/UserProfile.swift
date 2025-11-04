import Foundation

/// Multi-user support - identifies who made changes
struct UserProfile: Codable, Equatable, Sendable, Hashable {
    let userId: UUID
    var displayName: String
    var retentionPolicy: ChangeLogRetentionPolicy

    init(userId: UUID = UUID(), displayName: String = "User", retentionPolicy: ChangeLogRetentionPolicy = .forever) {
        self.userId = userId
        self.displayName = displayName
        self.retentionPolicy = retentionPolicy
    }
}
