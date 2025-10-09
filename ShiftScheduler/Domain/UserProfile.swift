import Foundation

/// Multi-user support - identifies who made changes
struct UserProfile: Codable, Equatable, Sendable, Hashable {
    let userId: UUID
    var displayName: String

    init(userId: UUID = UUID(), displayName: String = "User") {
        self.userId = userId
        self.displayName = displayName
    }
}
