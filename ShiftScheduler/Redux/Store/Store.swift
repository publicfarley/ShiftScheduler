import Foundation
import Observation
import OSLog

/// Middleware type for handling side effects
/// Receives current state, action, and dispatch closure
typealias Middleware = @MainActor @Sendable (AppState, AppAction, @escaping (AppAction) -> Void) -> Void

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

    /// Logger for debugging Redux actions and state changes
    private let logger = os.Logger(subsystem: "com.shiftscheduler.redux", category: "Store")

    /// Initialize store with initial state, reducer, and middleware
    /// - Parameters:
    ///   - state: Initial application state
    ///   - reducer: Pure function to transform state based on actions
    ///   - middlewares: Array of middleware functions for side effects (default: empty)
    init(
        state: AppState,
        reducer: @escaping @MainActor (AppState, AppAction) -> AppState,
        middlewares: [Middleware] = []
    ) {
        self.state = state
        self.reducer = reducer
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
        logger.debug("[Redux] Dispatching action: \(String(describing: action))")

        // Phase 1: Update state with reducer (pure, synchronous)
        state = reducer(state, action)

        // Phase 2: Execute middlewares for side effects (can be asynchronous)
        middlewares.forEach { middleware in
            middleware(state, action, dispatch)
        }
    }
}
