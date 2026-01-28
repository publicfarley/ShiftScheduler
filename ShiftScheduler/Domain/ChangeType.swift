import Foundation

/// Types of changes that can be logged
enum ChangeType: String, Codable, Sendable, CaseIterable {
    case switched = "Switched"
    case deleted = "Deleted"
    case created = "Created"
    case undo = "Undo"
    case redo = "Redo"
    case markedAsSick = "Marked as Sick"
    case unmarkedAsSick = "Unmarked as Sick"

    var displayName: String {
        rawValue
    }
}
