import Foundation

/// Domain-specific errors for Schedule feature operations
/// Provides user-friendly error messages and recovery suggestions
enum ScheduleError: Error, LocalizedError, Sendable, Equatable {
    case calendarAccessDenied
    case calendarEventCreationFailed(String)
    case calendarEventDeletionFailed(String)
    case duplicateShift(date: Date)
    case shiftNotFound
    case persistenceFailed(String)
    case undoStackEmpty
    case redoStackEmpty
    case invalidShiftData(String)
    case stackRestorationFailed(String)
    case shiftSwitchFailed(String)

    // MARK: - LocalizedError Implementation

    var errorDescription: String? {
        switch self {
        case .calendarAccessDenied:
            return "Calendar access denied"
        case .calendarEventCreationFailed:
            return "Failed to create calendar event"
        case .calendarEventDeletionFailed:
            return "Failed to delete calendar event"
        case .duplicateShift:
            return "A shift already exists on this date"
        case .shiftNotFound:
            return "Shift not found"
        case .persistenceFailed(let reason):
            return "Failed to save data: \(reason)"
        case .undoStackEmpty:
            return "No operations to undo"
        case .redoStackEmpty:
            return "No operations to redo"
        case .invalidShiftData(let reason):
            return "Invalid shift data: \(reason)"
        case .stackRestorationFailed(let reason):
            return "Failed to restore undo/redo history: \(reason)"
        case .shiftSwitchFailed(let reason):
            return "Failed to switch shift: \(reason)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .calendarAccessDenied:
            return "Please grant calendar access in Settings > ShiftScheduler to manage shifts."
        case .calendarEventCreationFailed:
            return "Please check your calendar settings and try again."
        case .calendarEventDeletionFailed:
            return "Please check your calendar settings and try again."
        case .duplicateShift:
            return "Delete the existing shift or choose a different date."
        case .shiftNotFound:
            return "The shift may have been deleted. Please refresh your calendar."
        case .persistenceFailed:
            return "Please try again. If the problem persists, restart the app."
        case .undoStackEmpty:
            return "No previous operations to undo."
        case .redoStackEmpty:
            return "No operations to redo."
        case .invalidShiftData:
            return "The shift data is invalid. Please try creating the shift again."
        case .stackRestorationFailed:
            return "Undo/redo history could not be restored. Your recent operations are still available."
        case .shiftSwitchFailed:
            return "Please ensure the shift type is valid and try again."
        }
    }

    // MARK: - Equatable Implementation

    static func == (lhs: ScheduleError, rhs: ScheduleError) -> Bool {
        switch (lhs, rhs) {
        case (.calendarAccessDenied, .calendarAccessDenied),
             (.shiftNotFound, .shiftNotFound),
             (.undoStackEmpty, .undoStackEmpty),
             (.redoStackEmpty, .redoStackEmpty):
            return true
        case let (.calendarEventCreationFailed(lhsReason), .calendarEventCreationFailed(rhsReason)):
            return lhsReason == rhsReason
        case let (.calendarEventDeletionFailed(lhsReason), .calendarEventDeletionFailed(rhsReason)):
            return lhsReason == rhsReason
        case let (.duplicateShift(lhsDate), .duplicateShift(rhsDate)):
            return Calendar.current.isDate(lhsDate, inSameDayAs: rhsDate)
        case let (.persistenceFailed(lhsReason), .persistenceFailed(rhsReason)):
            return lhsReason == rhsReason
        case let (.invalidShiftData(lhsReason), .invalidShiftData(rhsReason)):
            return lhsReason == rhsReason
        case let (.stackRestorationFailed(lhsReason), .stackRestorationFailed(rhsReason)):
            return lhsReason == rhsReason
        case let (.shiftSwitchFailed(lhsReason), .shiftSwitchFailed(rhsReason)):
            return lhsReason == rhsReason
        default:
            return false
        }
    }
}
