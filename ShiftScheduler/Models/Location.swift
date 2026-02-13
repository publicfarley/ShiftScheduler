import Foundation

/// Value-type model for a location where shifts can occur
struct Location: Identifiable, Equatable, Hashable, Sendable {
    let id: UUID
    var name: String
    var address: String

    nonisolated init(id: UUID = UUID(), name: String, address: String) {
        self.id = id
        self.name = name
        self.address = address
    }
}

// MARK: - Codable (nonisolated encoding/decoding)
extension Location: Codable {
    enum CodingKeys: String, CodingKey {
        case id, name, address
    }

    nonisolated func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(address, forKey: .address)
    }

    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        address = try container.decode(String.self, forKey: .address)
    }
}
