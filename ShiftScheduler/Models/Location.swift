import Foundation
import SwiftData

@Model
final class Location: Identifiable {
    var id: UUID
    var name: String
    var address: String

    init(id: UUID = UUID(), name: String, address: String) {
        self.id = id
        self.name = name
        self.address = address
    }
}