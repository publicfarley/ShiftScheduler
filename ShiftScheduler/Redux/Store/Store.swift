import Foundation
import Observation
import OSLog

/// Middleware type for handling side effects
/// Receives current state, action, dispatch closure, and service container
typealias Middleware = @MainActor @Sendable (AppState, AppAction, @escaping (AppAction) -> Void, ServiceContainer) -> Void

// MARK: - Logging Helper

/// Thread-safe logger wrapper for Store logging
/// Uses nonisolated(unsafe) since logging is a benign side effect
private struct StoreLoggerHelper {
    nonisolated(unsafe) private static let logger = os.Logger(subsystem: "com.shiftscheduler.redux", category: "Store")

    nonisolated static func debug(_ message: String) {
        // Safely log without MainActor isolation
        DispatchQueue.main.async {
            logger.debug("\(message, privacy: .public)")
        }
    }
}

/// Redux Store - Single source of truth for application state
/// Implements unidirectional data flow: dispatch(action) -> reducer -> state -> UI
@Observable
@MainActor
class Store {
    /// Current application state
    private(set) var state: AppState

    /// Pure reducer function that transforms state based on actions
    private let reducer: @MainActor (AppState, AppAction) -> AppState

    /// Middleware functions that handle side effects
    private let middlewares: [Middleware]

    /// Service container for dependency injection
    private let services: ServiceContainer

    /// Initialize store with initial state, reducer, middleware, and services
    /// - Parameters:
    ///   - state: Initial application state
    ///   - reducer: Pure function to transform state based on actions
    ///   - services: Service container for dependency injection (default: production)
    ///   - middlewares: Array of middleware functions for side effects (default: empty)
    init(
        state: AppState,
        reducer: @escaping @MainActor (AppState, AppAction) -> AppState,
        services: ServiceContainer = ServiceContainer(),
        middlewares: [Middleware] = []
    ) {
        self.state = state
        self.reducer = reducer
        self.services = services
        self.middlewares = middlewares
    }

    /// Dispatch an action to trigger state updates and side effects
    /// This is the main entry point for all state changes
    ///
    /// Two-phase execution:
    /// 1. Reducer phase: Pure state transformation (synchronous)
    /// 2. Middleware phase: Side effects handling (can be asynchronous)
    ///
    /// - Parameter action: The action to dispatch
    func dispatch(action: AppAction) {
        let actionDesc = String(describing: action)
        StoreLoggerHelper.debug("[Redux] Dispatching action: \(actionDesc)")

        // Phase 1: Update state with reducer (pure, synchronous)
        state = reducer(state, action)

        // Phase 2: Execute middlewares for side effects (can be asynchronous)
        middlewares.forEach { middleware in
            middleware(state, action, dispatch, services)
        }
    }
}
