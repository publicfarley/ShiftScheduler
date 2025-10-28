import Foundation

extension Double {
    /// Converts a duration in seconds to nanoseconds for use with Task.sleep
    ///
    /// Example:
    /// ```swift
    /// try await Task.sleep(nanoseconds: 0.1.seconds)  // Sleep for 100ms
    /// try await Task.sleep(nanoseconds: 3.5.seconds)  // Sleep for 3.5 seconds
    /// ```
    var seconds: UInt64 {
        UInt64(self * Double(NSEC_PER_SEC))
    }
}

extension Task where Success == Never, Failure == Never {
    /// Sleeps for a specified duration in seconds
    ///
    /// A convenience method that provides a more ergonomic API than the standard
    /// `Task.sleep(nanoseconds:)` method.
    ///
    /// Example:
    /// ```swift
    /// try await Task.sleep(seconds: 3.5)    // Sleep for 3.5 seconds
    /// try await Task.sleep(seconds: 0.1)    // Sleep for 100ms
    /// ```
    static func sleep(seconds: Double) async throws {
        try await Self.sleep(nanoseconds: seconds.seconds)
    }
}
