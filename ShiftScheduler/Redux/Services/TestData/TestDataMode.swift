import Foundation

/// Stateless namespace over `UserDefaults` (an external store) that controls whether the
/// app is running against the sandboxed Test Data Mode directory or the real user data.
///
/// This is intentionally NOT a singleton holding app state — it holds no state of its own,
/// it only reads/writes a flag in `UserDefaults` and computes a directory URL. The flag must
/// live outside the sandboxed data it switches so it can be read before any `ServiceContainer`
/// is constructed (see `StoreConfiguration.createReduxStore`).
enum TestDataMode {
    /// UserDefaults key backing the Test Data Mode flag.
    static let userDefaultsKey = "testDataModeEnabled"

    /// Whether Test Data Mode is currently enabled.
    static var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: userDefaultsKey) }
        set { UserDefaults.standard.set(newValue, forKey: userDefaultsKey) }
    }

    /// Sandboxed directory used for all Test Data Mode persistence
    /// (`Documents/ShiftSchedulerData-Test`). Survives app restarts like the real data
    /// directory, but is entirely separate from it.
    static var testDataDirectory: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("ShiftSchedulerData-Test", isDirectory: true)
    }

    /// Deletes the entire test data directory (shift types, locations, change log, user
    /// profile, and simulated calendar). The next seed pass recreates it from scratch.
    static func resetTestData() {
        try? FileManager.default.removeItem(at: testDataDirectory)
    }
}
