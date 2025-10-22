import Foundation

/// Error types for EventKit operations
enum EventKitError: LocalizedError {
    case notAuthorized
    case calendarNotFound
    case invalidDate
    case eventNotFound
    case saveFailed(Error)
    case deleteFailed(Error)
    case authorizationFailed(Error)

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Calendar access is not authorized. Please enable calendar access in Settings."
        case .calendarNotFound:
            return "Could not find or create the ShiftScheduler calendar."
        case .invalidDate:
            return "Invalid date provided."
        case .eventNotFound:
            return "Shift event not found in calendar."
        case .saveFailed(let error):
            return "Failed to save shift: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete shift: \(error.localizedDescription)"
        case .authorizationFailed(let error):
            return "Failed to request calendar authorization: \(error.localizedDescription)"
        }
    }
}
