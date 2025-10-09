import Foundation
@testable import ShiftScheduler

/// Mock implementation of UserDefaultsProtocol for unit testing
final class MockUserDefaults: UserDefaultsProtocol, @unchecked Sendable {
    private var storage: [String: Any] = [:]

    func integer(forKey key: String) -> Int {
        storage[key] as? Int ?? 0
    }

    func set(_ value: Int, forKey key: String) {
        storage[key] = value
    }

    func string(forKey key: String) -> String? {
        storage[key] as? String
    }

    func set(_ value: String?, forKey key: String) {
        storage[key] = value
    }

    func data(forKey key: String) -> Data? {
        storage[key] as? Data
    }

    func set(_ value: Data?, forKey key: String) {
        storage[key] = value
    }

    func bool(forKey key: String) -> Bool {
        storage[key] as? Bool ?? false
    }

    func set(_ value: Bool, forKey key: String) {
        storage[key] = value
    }

    func reset() {
        storage.removeAll()
    }
}
