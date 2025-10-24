import Foundation

/// Value-type model for a location where shifts can occur
struct Location: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: UUID
    var name: String
    var address: String

    init(id: UUID = UUID(), name: String, address: String) {
        self.id = id
        self.name = name
        self.address = address
    }
}
