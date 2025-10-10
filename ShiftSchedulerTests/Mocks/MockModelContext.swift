import Foundation
import SwiftData
@testable import ShiftScheduler

/// Mock implementation of ModelContext for unit testing
final class MockModelContext: @unchecked Sendable {
    var insertedModels: [Any] = []
    var deletedModels: [Any] = []
    var mockFetchResults: [Any] = []
    var shouldThrowOnSave = false
    var shouldThrowOnFetch = false
    var saveCallCount = 0
    var fetchCallCount = 0

    func insert<T>(_ model: T) {
        insertedModels.append(model)
    }

    func delete<T>(_ model: T) {
        deletedModels.append(model)
    }

    func fetch<T>(_ descriptor: FetchDescriptor<T>) throws -> [T] {
        fetchCallCount += 1
        if shouldThrowOnFetch {
            throw MockError.fetchFailed
        }
        return mockFetchResults.compactMap { $0 as? T }
    }

    func save() throws {
        saveCallCount += 1
        if shouldThrowOnSave {
            throw MockError.saveFailed
        }
    }

    enum MockError: Error {
        case saveFailed
        case fetchFailed
    }
}
