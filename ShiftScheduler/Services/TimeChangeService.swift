import Foundation
import UIKit
import Combine

/// Protocol for observing significant time changes (e.g., midnight crossing, time zone changes)
@MainActor
protocol TimeChangeServiceProtocol: Sendable {
    /// Start observing significant time changes
    /// - Parameter onTimeChange: Callback invoked when a significant time change occurs
    func startObserving(onTimeChange: @escaping @Sendable () -> Void)

    /// Stop observing significant time changes
    func stopObserving()
}

/// Production implementation of TimeChangeServiceProtocol
/// Listens to UIApplication.significantTimeChangeNotification to detect:
/// - Midnight crossing (day change)
/// - Time zone changes
/// - Manual time adjustments by the user
@MainActor
final class TimeChangeService: TimeChangeServiceProtocol, @unchecked Sendable {
    private var cancellable: AnyCancellable?

    nonisolated init() {}

    func startObserving(onTimeChange: @escaping @Sendable () -> Void) {
        // Listen for significant time change notifications from iOS
        cancellable = NotificationCenter.default
            .publisher(for: UIApplication.significantTimeChangeNotification)
            .sink { _ in
                Task { @MainActor in
                    print("[TimeChangeService] Significant time change detected")
                    onTimeChange()
                }
            }

        print("[TimeChangeService] Started observing significant time changes")
    }

    func stopObserving() {
        cancellable?.cancel()
        cancellable = nil
        print("[TimeChangeService] Stopped observing significant time changes")
    }
}
