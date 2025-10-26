import Foundation

extension Double {
    /// Converts a duration in seconds to nanoseconds for use with Task.sleep
    ///
    /// Example:
    /// ```swift
    /// try await Task.sleep(nanoseconds: 0.1.nanoseconds)  // Sleep for 100ms
    /// try await Task.sleep(nanoseconds: 3.5.nanoseconds)  // Sleep for 3.5 seconds
    /// ```
    var nanoseconds: UInt64 {
        UInt64(self * Double(NSEC_PER_SEC))
    }
}
