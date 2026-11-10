import Foundation

/// Errors raised by CLI commands. Each error carries a human-readable message
/// and, where possible, an actionable suggestion for how to proceed.
enum CLIError: Error {
    case shiftTypeNotFound(String)
    case locationNotFound(String)
    case shiftNotFound(String)
    case ambiguous(kind: String, reference: String, candidates: [String])
    case invalidDate(String)
    case invalidTime(String)
    case invalidWeekday(String)
    case locationInUse(name: String, usedBy: [String])
    case nothingToUndo
    case nothingToRedo
    case cannotRevert(String)
    case invalidOperation(String)
    case confirmationRequired(String)
    case calendarNotAuthorized
    case cloudKitUnavailable
    case cancelled

    var message: String {
        switch self {
        case .shiftTypeNotFound(let reference):
            return "No shift type matches '\(reference)'"
        case .locationNotFound(let reference):
            return "No location matches '\(reference)'"
        case .shiftNotFound(let eventId):
            return "No scheduled shift found with event ID '\(eventId)'"
        case .ambiguous(let kind, let reference, let candidates):
            return "'\(reference)' matches multiple \(kind)s:\n  " + candidates.joined(separator: "\n  ")
        case .invalidDate(let input):
            return "Cannot parse date '\(input)'"
        case .invalidTime(let input):
            return "Cannot parse time '\(input)'"
        case .invalidWeekday(let input):
            return "Cannot parse weekday '\(input)'"
        case .locationInUse(let name, let usedBy):
            return "Location '\(name)' is used by shift type(s): \(usedBy.joined(separator: ", "))"
        case .nothingToUndo:
            return "Nothing to undo"
        case .nothingToRedo:
            return "Nothing to redo"
        case .cannotRevert(let reason):
            return reason
        case .invalidOperation(let reason):
            return reason
        case .confirmationRequired(let action):
            return "Confirmation required: \(action)"
        case .calendarNotAuthorized:
            return "Calendar access is not authorized"
        case .cloudKitUnavailable:
            return "CloudKit is not available to this build"
        case .cancelled:
            return "Cancelled"
        }
    }

    var suggestion: String? {
        switch self {
        case .shiftTypeNotFound:
            return "Run 'shift-scheduler types list' to see available shift types. You can reference a type by UUID, title, or symbol."
        case .locationNotFound:
            return "Run 'shift-scheduler locations list' to see available locations. You can reference a location by UUID or name."
        case .shiftNotFound:
            return "Run 'shift-scheduler schedule list' to see scheduled shifts and their event IDs."
        case .ambiguous:
            return "Use the UUID to reference it unambiguously."
        case .invalidDate:
            return "Supported formats: YYYY-MM-DD, today, tomorrow, yesterday, +3d, -1w."
        case .invalidTime:
            return "Use 24-hour HH:MM format, e.g. 07:00 or 22:30."
        case .invalidWeekday:
            return "Use a weekday name such as sat or saturday. Repeat --weekday or separate names with commas for several days."
        case .locationInUse:
            return "Edit or delete those shift types first, or point them at a different location."
        case .confirmationRequired:
            return "Re-run with --force to skip the confirmation prompt (no interactive terminal is available)."
        case .calendarNotAuthorized:
            return "Run 'shift-scheduler auth request' to grant calendar access, or check System Settings > Privacy & Security > Calendars."
        case .cloudKitUnavailable:
            return "Use the signed build (the ShiftSchedulerCLI scheme in Xcode) and sign in to iCloud. A build from 'swift build' has no CloudKit entitlement."
        default:
            return nil
        }
    }
}
