import Foundation

/// Application tabs for navigation
enum Tab: String, Equatable, CaseIterable {
    case today
    case schedule
    case shiftTypes
    case locations
    case changeLog
    case settings
    case about

    var displayName: String {
        switch self {
        case .today:
            return "Today"
        case .schedule:
            return "Schedule"
        case .shiftTypes:
            return "Shift Types"
        case .locations:
            return "Locations"
        case .changeLog:
            return "Change Log"
        case .settings:
            return "Settings"
        case .about:
            return "About"
        }
    }

    var iconName: String {
        switch self {
        case .today:
            return "calendar.badge.clock"
        case .schedule:
            return "calendar"
        case .shiftTypes:
            return "briefcase"
        case .locations:
            return "location"
        case .changeLog:
            return "clock.arrow.circlepath"
        case .settings:
            return "gearshape"
        case .about:
            return "info.circle"
        }
    }
}
