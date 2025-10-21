import Foundation
import ComposableArchitecture

/// TCA Dependency Client for ChangeLog repository operations
/// Wraps the existing ChangeLogRepository for use within TCA reducers
@DependencyClient
struct ChangeLogRepositoryClient: Sendable {
    /// Save a new change log entry
    var save: @Sendable (ChangeLogEntry) async throws -> Void

    /// Fetch all change log entries
    var fetchAll: @Sendable () async throws -> [ChangeLogEntry] = { [] }

    /// Fetch change log entries within a date range
    var fetchInRange: @Sendable (Date, Date) async throws -> [ChangeLogEntry] = { _, _ in [] }

    /// Fetch the most recent change log entries
    var fetchRecent: @Sendable (Int) async throws -> [ChangeLogEntry] = { _ in [] }

    /// Delete change log entries older than a specific date
    var deleteOlderThan: @Sendable (Date) async throws -> Void

    /// Delete all change log entries
    var deleteAll: @Sendable () async throws -> Void
}

extension ChangeLogRepositoryClient: DependencyKey {
    /// Live implementation using the real repository
    /// Note: The repository needs to be injected or accessed from SwiftData context
    static let liveValue = ChangeLogRepositoryClient(
        save: { entry in
            // TODO: Implement live repository access
            // This will need to be wired up with SwiftDataChangeLogRepository
            fatalError("Live ChangeLogRepositoryClient not yet implemented")
        },
        fetchAll: {
            fatalError("Live ChangeLogRepositoryClient not yet implemented")
        },
        fetchInRange: { _, _ in
            fatalError("Live ChangeLogRepositoryClient not yet implemented")
        },
        fetchRecent: { _ in
            fatalError("Live ChangeLogRepositoryClient not yet implemented")
        },
        deleteOlderThan: { _ in
            fatalError("Live ChangeLogRepositoryClient not yet implemented")
        },
        deleteAll: {
            fatalError("Live ChangeLogRepositoryClient not yet implemented")
        }
    )

    /// Test value with unimplemented methods
    static let testValue = ChangeLogRepositoryClient()

    /// Preview value with mock data
    static let previewValue = ChangeLogRepositoryClient(
        save: { _ in },
        fetchAll: { [] },
        fetchInRange: { _, _ in [] },
        fetchRecent: { _ in [] },
        deleteOlderThan: { _ in },
        deleteAll: { }
    )
}

extension DependencyValues {
    var changeLogRepository: ChangeLogRepositoryClient {
        get { self[ChangeLogRepositoryClient.self] }
        set { self[ChangeLogRepositoryClient.self] = newValue }
    }
}
