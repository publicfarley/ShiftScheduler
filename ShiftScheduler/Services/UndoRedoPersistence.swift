import Foundation
import OSLog

/// Manages persistence of undo/redo stacks to UserDefaults
actor UndoRedoPersistence {
    private let logger = Logger(subsystem: "com.functioncraft.shiftscheduler", category: "UndoRedoPersistence")
    private static let undoStackKey = "com.functioncraft.shiftscheduler.undoStack"
    private static let redoStackKey = "com.functioncraft.shiftscheduler.redoStack"
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // MARK: - Save Operations

    /// Saves the undo stack to UserDefaults
    /// NOTE: Disabled for now as ShiftType cannot be serialized without SwiftData context
    func saveUndoStack(_ operations: [ShiftSwitchOperation]) {
        // Persistence disabled - ShiftType is a SwiftData model that cannot be easily serialized
        logger.debug("Persistence disabled - stack not saved")
    }

    /// Saves the redo stack to UserDefaults
    /// NOTE: Disabled for now as ShiftType cannot be serialized without SwiftData context
    func saveRedoStack(_ operations: [ShiftSwitchOperation]) {
        // Persistence disabled - ShiftType is a SwiftData model that cannot be easily serialized
        logger.debug("Persistence disabled - stack not saved")
    }

    /// Saves both undo and redo stacks
    /// NOTE: Disabled for now as ShiftType cannot be serialized without SwiftData context
    func saveBothStacks(undo: [ShiftSwitchOperation], redo: [ShiftSwitchOperation]) {
        // Persistence disabled - ShiftType is a SwiftData model that cannot be easily serialized
        logger.debug("Persistence disabled - stacks not saved")
    }

    // MARK: - Load Operations

    /// Loads the undo stack from UserDefaults
    /// NOTE: Disabled for now as ShiftType cannot be serialized without SwiftData context
    func loadUndoStack() -> [ShiftSwitchOperation] {
        logger.debug("Persistence disabled - no stack to load")
        return []
    }

    /// Loads the redo stack from UserDefaults
    /// NOTE: Disabled for now as ShiftType cannot be serialized without SwiftData context
    func loadRedoStack() -> [ShiftSwitchOperation] {
        logger.debug("Persistence disabled - no stack to load")
        return []
    }

    /// Loads both undo and redo stacks
    /// NOTE: Disabled for now as ShiftType cannot be serialized without SwiftData context
    func loadBothStacks() -> (undo: [ShiftSwitchOperation], redo: [ShiftSwitchOperation]) {
        logger.debug("Persistence disabled - no stacks to load")
        return (undo: [], redo: [])
    }

    // MARK: - Clear Operations

    /// Clears the undo stack from UserDefaults
    func clearUndoStack() {
        userDefaults.removeObject(forKey: Self.undoStackKey)
        logger.debug("Cleared undo stack from UserDefaults")
    }

    /// Clears the redo stack from UserDefaults
    func clearRedoStack() {
        userDefaults.removeObject(forKey: Self.redoStackKey)
        logger.debug("Cleared redo stack from UserDefaults")
    }

    /// Clears both undo and redo stacks from UserDefaults
    func clearBothStacks() {
        clearUndoStack()
        clearRedoStack()
    }
}

// MARK: - Codable Support

/// Serializable representation of ShiftSwitchOperation for persistence
struct SerializableShiftSwitchOperation: Codable, Sendable {
    let eventIdentifier: String
    let scheduledDate: Date
    let oldShiftSnapshot: ShiftSnapshot
    let newShiftSnapshot: ShiftSnapshot
    let changeLogEntryId: UUID
    let reason: String?

    init(from operation: ShiftSwitchOperation) {
        self.eventIdentifier = operation.eventIdentifier
        self.scheduledDate = operation.scheduledDate
        self.oldShiftSnapshot = ShiftSnapshot(from: operation.oldShiftType)
        self.newShiftSnapshot = ShiftSnapshot(from: operation.newShiftType)
        self.changeLogEntryId = operation.changeLogEntryId
        self.reason = operation.reason
    }
}

extension UndoRedoPersistence {
    /// Converts operations to serializable form and saves them
    func saveSerializableUndoStack(_ operations: [ShiftSwitchOperation]) {
        let serializable = operations.map { SerializableShiftSwitchOperation(from: $0) }
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(serializable)
            userDefaults.set(data, forKey: Self.undoStackKey)
            logger.debug("Saved \(operations.count) undo operations to UserDefaults")
        } catch {
            logger.error("Failed to save undo stack: \(error.localizedDescription)")
        }
    }

    /// Converts operations to serializable form and saves them
    func saveSerializableRedoStack(_ operations: [ShiftSwitchOperation]) {
        let serializable = operations.map { SerializableShiftSwitchOperation(from: $0) }
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(serializable)
            userDefaults.set(data, forKey: Self.redoStackKey)
            logger.debug("Saved \(operations.count) redo operations to UserDefaults")
        } catch {
            logger.error("Failed to save redo stack: \(error.localizedDescription)")
        }
    }

    /// Loads serializable operations from UserDefaults
    func loadSerializableUndoStack() -> [SerializableShiftSwitchOperation] {
        guard let data = userDefaults.data(forKey: Self.undoStackKey) else {
            logger.debug("No undo stack found in UserDefaults")
            return []
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let operations = try decoder.decode([SerializableShiftSwitchOperation].self, from: data)
            logger.debug("Loaded \(operations.count) undo operations from UserDefaults")
            return operations
        } catch {
            logger.error("Failed to load undo stack: \(error.localizedDescription)")
            return []
        }
    }

    /// Loads serializable operations from UserDefaults
    func loadSerializableRedoStack() -> [SerializableShiftSwitchOperation] {
        guard let data = userDefaults.data(forKey: Self.redoStackKey) else {
            logger.debug("No redo stack found in UserDefaults")
            return []
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let operations = try decoder.decode([SerializableShiftSwitchOperation].self, from: data)
            logger.debug("Loaded \(operations.count) redo operations from UserDefaults")
            return operations
        } catch {
            logger.error("Failed to load redo stack: \(error.localizedDescription)")
            return []
        }
    }
}
