import Foundation

/// Mock implementation of TimeChangeServiceProtocol for testing
@MainActor
final class MockTimeChangeService: TimeChangeServiceProtocol, @unchecked Sendable {
    private(set) var isObserving = false
    private var onTimeChangeCallback: (@Sendable () -> Void)?

    nonisolated init() {}

    func startObserving(onTimeChange: @escaping @Sendable () -> Void) {
        isObserving = true
        onTimeChangeCallback = onTimeChange
        print("[MockTimeChangeService] Started observing (mock)")
    }

    func stopObserving() {
        isObserving = false
        onTimeChangeCallback = nil
        print("[MockTimeChangeService] Stopped observing (mock)")
    }

    /// Simulate a significant time change event for testing
    func simulateTimeChange() {
        guard isObserving, let callback = onTimeChangeCallback else {
            print("[MockTimeChangeService] Cannot simulate - not observing")
            return
        }
        print("[MockTimeChangeService] Simulating significant time change")
        callback()
    }
}
