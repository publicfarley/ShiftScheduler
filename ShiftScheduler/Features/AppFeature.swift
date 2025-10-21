import Foundation
import ComposableArchitecture

/// Root feature coordinating all app functionality
/// This is the entry point for the TCA architecture
@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        /// Currently selected tab
        var selectedTab = Tab.today

        /// User profile information
        var userProfile = UserProfile(userId: UUID(), displayName: "User")

        // TODO: Add sub-feature states as they are implemented
        // var today = TodayFeature.State()
        // var schedule = ScheduleFeature.State()
        // var shiftTypes = ShiftTypesFeature.State()
        // var locations = LocationsFeature.State()
        // var changeLog = ChangeLogFeature.State()
        // var settings = SettingsFeature.State()
        // var about = AboutFeature.State()

        init(
            selectedTab: Tab = .today,
            userProfile: UserProfile = UserProfile(userId: UUID(), displayName: "User")
        ) {
            self.selectedTab = selectedTab
            self.userProfile = userProfile
        }
    }

    enum Action: Equatable {
        /// Tab was selected by user
        case tabSelected(Tab)

        /// App launched and needs initialization
        case onAppear

        /// User profile was updated
        case userProfileUpdated(UserProfile)

        // TODO: Add sub-feature actions as they are implemented
        // case today(TodayFeature.Action)
        // case schedule(ScheduleFeature.Action)
        // case shiftTypes(ShiftTypesFeature.Action)
        // case locations(LocationsFeature.Action)
        // case changeLog(ChangeLogFeature.Action)
        // case settings(SettingsFeature.Action)
        // case about(AboutFeature.Action)
    }

    @Dependency(\.calendarClient) var calendarClient
    @Dependency(\.swiftDataClient) var swiftDataClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .tabSelected(tab):
                state.selectedTab = tab
                return .none

            case .onAppear:
                // Initialize app state
                // Load user profile from UserDefaults
                // Check calendar authorization
                return .none

            case let .userProfileUpdated(profile):
                state.userProfile = profile
                return .none
            }
        }

        // TODO: Add scoped reducers for sub-features as they are implemented
        // Example:
        // Scope(state: \.today, action: \.today) {
        //     TodayFeature()
        // }
    }
}

/// Tab enumeration for main navigation
enum Tab: Equatable, Hashable {
    case today
    case schedule
    case shiftTypes
    case locations
    case changeLog
    case settings
    case about
}
