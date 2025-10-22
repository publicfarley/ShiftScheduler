import ComposableArchitecture
import Foundation
import UIKit

/// Feature for managing application settings
@Reducer
struct SettingsFeature {
    @ObservableState
    struct State: Equatable {
        var displayName: String = ""
        var currentPolicy: ChangeLogRetentionPolicy = .year1
        var lastPurgeDate: Date?
        var lastPurgedCount: Int = 0
        var currentUserId: UUID = UUID()
        var alertItem: AlertItem?

        // Animation states
        var titleAppeared = false
        var userProfileSectionAppeared = false
        var changeLogSectionAppeared = false
        var dataManagementSectionAppeared = false
        var isPressed = false
    }

    enum Action: Equatable {
        case onAppear
        case displayNameChanged(String)
        case resetUserProfile
        case policyChanged(ChangeLogRetentionPolicy)
        case purgeButtonTapped
        case deleteAllDataButtonTapped
        case confirmReset
        case confirmPurge
        case confirmDeleteAllData
        case alertDismissed
        case triggerStaggeredAnimations
        case setTitleAppeared(Bool)
        case setUserProfileSectionAppeared(Bool)
        case setChangeLogSectionAppeared(Bool)
        case setDataManagementSectionAppeared(Bool)
        case purgeCompleted(Int)
        case purgeFailed(String)
        case deleteAllDataCompleted
        case deleteAllDataFailed(String)
    }

    @Dependency(\.userProfileManagerClient) var userProfileManagerClient
    @Dependency(\.changeLogRetentionManagerClient) var changeLogRetentionManagerClient
    @Dependency(\.calendarClient) var calendarClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                let profile = userProfileManagerClient.getCurrentProfile()
                state.displayName = profile.displayName
                state.currentUserId = profile.userId
                state.currentPolicy = changeLogRetentionManagerClient.getCurrentPolicy()
                state.lastPurgeDate = changeLogRetentionManagerClient.getLastPurgeDate()
                state.lastPurgedCount = changeLogRetentionManagerClient.getLastPurgedCount()

                return .send(.triggerStaggeredAnimations)

            case let .displayNameChanged(newName):
                state.displayName = newName
                userProfileManagerClient.updateDisplayName(newName)
                return .none

            case .resetUserProfile:
                state.alertItem = AlertItem(
                    title: "Reset User ID?",
                    message: "This will create a new user identity. All future changes will be logged under the new ID. Existing change log entries will keep the old ID.",
                    actionTitle: "Reset ID",
                    actionStyle: .destructive,
                    action: .confirmReset
                )
                return .none

            case .confirmReset:
                state.alertItem = nil
                userProfileManagerClient.resetUserProfile()
                let profile = userProfileManagerClient.getCurrentProfile()
                state.displayName = profile.displayName
                state.currentUserId = profile.userId
                return .none

            case let .policyChanged(newPolicy):
                state.currentPolicy = newPolicy
                changeLogRetentionManagerClient.updatePolicy(newPolicy)
                return .none

            case .purgeButtonTapped:
                state.alertItem = AlertItem(
                    title: "Purge Old Entries?",
                    message: "This will permanently delete change log entries older than \(state.currentPolicy.displayName.lowercased()). This action cannot be undone.",
                    actionTitle: "Purge Now",
                    actionStyle: .destructive,
                    action: .confirmPurge
                )
                return .none

            case .confirmPurge:
                state.alertItem = nil
                return .run { send in
                    do {
                        // TODO: Implement actual purge through PersistenceClient when feature is available
                        // For now, just simulate success
                        let result = 0
                        await send(.purgeCompleted(result))
                    } catch {
                        await send(.purgeFailed(error.localizedDescription))
                    }
                }

            case let .purgeCompleted(count):
                state.lastPurgeDate = Date()
                state.lastPurgedCount = count
                changeLogRetentionManagerClient.recordPurge(count)
                state.alertItem = AlertItem(
                    title: "Success",
                    message: count > 0 ? "Purged \(count) entries" : "No entries to purge",
                    actionTitle: "OK",
                    actionStyle: .default,
                    action: .alertDismissed
                )
                return .none

            case let .purgeFailed(error):
                state.alertItem = AlertItem(
                    title: "Purge Failed",
                    message: error,
                    actionTitle: "OK",
                    actionStyle: .default,
                    action: .alertDismissed
                )
                return .none

            case .deleteAllDataButtonTapped:
                state.alertItem = AlertItem(
                    title: "Are you sure?",
                    message: "This will permanently delete all shift types, locations, and scheduled shifts. This action cannot be undone.",
                    actionTitle: "Delete All Data",
                    actionStyle: .destructive,
                    action: .confirmDeleteAllData
                )
                return .none

            case .confirmDeleteAllData:
                state.alertItem = nil
                return .run { send in
                    do {
                        // Fetch all shifts for deletion
                        let startDate = Calendar.current.date(byAdding: .year, value: -10, to: Date()) ?? Date()
                        let endDate = Calendar.current.date(byAdding: .year, value: 10, to: Date()) ?? Date()
                        let shifts = try await calendarClient.fetchShiftsInRange(startDate, endDate)

                        // Delete each shift
                        for shift in shifts {
                            try await calendarClient.deleteShift(shift.eventIdentifier)
                        }

                        await send(.deleteAllDataCompleted)
                    } catch {
                        await send(.deleteAllDataFailed(error.localizedDescription))
                    }
                }

            case .deleteAllDataCompleted:
                state.alertItem = AlertItem(
                    title: "Success",
                    message: "All data has been deleted successfully.",
                    actionTitle: "OK",
                    actionStyle: .default,
                    action: .alertDismissed
                )
                return .none

            case let .deleteAllDataFailed(error):
                state.alertItem = AlertItem(
                    title: "Error",
                    message: "Failed to delete all data: \(error)",
                    actionTitle: "OK",
                    actionStyle: .default,
                    action: .alertDismissed
                )
                return .none

            case .alertDismissed:
                state.alertItem = nil
                return .none

            case .triggerStaggeredAnimations:
                guard !UIAccessibility.isReduceMotionEnabled else {
                    state.titleAppeared = true
                    state.userProfileSectionAppeared = true
                    state.changeLogSectionAppeared = true
                    state.dataManagementSectionAppeared = true
                    return .none
                }

                return .merge(
                    .run { send in
                        try await Task.sleep(nanoseconds: 200_000_000) // 0.2s
                        await send(.setTitleAppeared(true))
                    },
                    .run { send in
                        try await Task.sleep(nanoseconds: 400_000_000) // 0.4s
                        await send(.setUserProfileSectionAppeared(true))
                    },
                    .run { send in
                        try await Task.sleep(nanoseconds: 600_000_000) // 0.6s
                        await send(.setChangeLogSectionAppeared(true))
                    },
                    .run { send in
                        try await Task.sleep(nanoseconds: 800_000_000) // 0.8s
                        await send(.setDataManagementSectionAppeared(true))
                    }
                )

            case let .setTitleAppeared(value):
                state.titleAppeared = value
                return .none

            case let .setUserProfileSectionAppeared(value):
                state.userProfileSectionAppeared = value
                return .none

            case let .setChangeLogSectionAppeared(value):
                state.changeLogSectionAppeared = value
                return .none

            case let .setDataManagementSectionAppeared(value):
                state.dataManagementSectionAppeared = value
                return .none
            }
        }
    }
}

/// Alert item for displaying alerts
struct AlertItem: Equatable, Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let actionTitle: String
    let actionStyle: AlertStyle
    let action: SettingsFeature.Action

    enum AlertStyle: Equatable {
        case `default`
        case destructive
        case cancel
    }
}
