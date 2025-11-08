import Foundation

/// Value-type model for persisting undo/redo stacks
struct UndoRedoStacks: Codable, Equatable, Sendable {
    let undoStack: [ChangeLogEntry]
    let redoStack: [ChangeLogEntry]

    init(
        undoStack: [ChangeLogEntry] = [],
        redoStack: [ChangeLogEntry] = []
    ) {
        self.undoStack = undoStack
        self.redoStack = redoStack
    }
}
