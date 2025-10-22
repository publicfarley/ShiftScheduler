import Foundation
import ComposableArchitecture

/// TCA Dependency Client for Change Log Retention Policy management
/// Wraps the existing ChangeLogRetentionManager for use within TCA reducers
@DependencyClient
struct ChangeLogRetentionManagerClient {
    /// Get the current retention policy
    var getCurrentPolicy: @Sendable () -> ChangeLogRetentionPolicy = { .year1 }

    /// Update the retention policy
    var updatePolicy: @Sendable (ChangeLogRetentionPolicy) -> Void

    /// Get the last purge date
    var getLastPurgeDate: @Sendable () -> Date? = { nil }

    /// Get the number of entries purged in the last operation
    var getLastPurgedCount: @Sendable () -> Int = { 0 }

    /// Record a purge operation
    var recordPurge: @Sendable (Int) -> Void
}

extension ChangeLogRetentionManagerClient: DependencyKey {
    /// Live implementation using the real ChangeLogRetentionManager
    static let liveValue: ChangeLogRetentionManagerClient = {
        // Note: We suppress the deprecation warning here because the client is the proper TCA
        // abstraction that wraps the singleton. The singleton itself is deprecated, but
        // its usage within the client is acceptable during the transition period.
        nonisolated(unsafe) var manager: ChangeLogRetentionManager {
            @available(*, deprecated)
            get { ChangeLogRetentionManager.shared }
        }

        return ChangeLogRetentionManagerClient(
            getCurrentPolicy: {
                manager.currentPolicy
            },
            updatePolicy: { newPolicy in
                manager.updatePolicy(newPolicy)
            },
            getLastPurgeDate: {
                manager.lastPurgeDate
            },
            getLastPurgedCount: {
                manager.lastPurgedCount
            },
            recordPurge: { entriesPurged in
                manager.recordPurge(entriesPurged: entriesPurged)
            }
        )
    }()

    /// Test value with unimplemented methods
    static let testValue = ChangeLogRetentionManagerClient()

    /// Preview value with mock data
    static let previewValue = ChangeLogRetentionManagerClient(
        getCurrentPolicy: { .year1 },
        updatePolicy: { _ in },
        getLastPurgeDate: { Date(timeIntervalSinceNow: -86400) }, // 1 day ago
        getLastPurgedCount: { 42 },
        recordPurge: { _ in }
    )
}

extension DependencyValues {
    var changeLogRetentionManagerClient: ChangeLogRetentionManagerClient {
        get { self[ChangeLogRetentionManagerClient.self] }
        set { self[ChangeLogRetentionManagerClient.self] = newValue }
    }
}
