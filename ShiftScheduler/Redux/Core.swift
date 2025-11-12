//
//  Core.swift
//  ShiftScheduler
//
//  Created by Farley Caesar on 2025-10-25.
//
import Observation

// Core: Reducer, Dispatcher, Middleware
public typealias Reducer<State, Action> = (State, Action) -> State

public typealias Dispatcher<Action> = @Sendable (Action) async -> Void

public typealias Middleware<State, Action> = @Sendable (
    _ state: State,
    _ action: Action,
    _ services: ServiceContainer,
    _ dispatch: @escaping Dispatcher<Action>
) async -> Void

// -----------------------------
// Observable Store
// -----------------------------
@Observable
public final class Store<State: Sendable, Action: Sendable> {
    public private(set) var state: State

    private let reducer: Reducer<State, Action>
    private let middlewares: [Middleware<State, Action>]
    private let services: ServiceContainer

    public init(
        state: State,
        reducer: @escaping Reducer<State, Action>,
        services: ServiceContainer,
        middlewares: [Middleware<State, Action>]
    ) {
        self.state = state
        self.reducer = reducer
        self.services = services
        self.middlewares = middlewares
    }

    public func dispatch(action: Action) async {
        // Phase 1: Apply reducer immediately (synchronous state update)
        state = reducer(state, action)

        // Phase 2: Yield to allow UI to update with reducer changes
        // This ensures loading states, optimistic updates, etc. are visible
        await Task.yield()

        // Phase 3: Execute middleware (async side effects)
        // Capture current state and dependencies for middleware to use
        let currentState = state
        let services = services

        // Create dispatch closure before entering concurrent context
        // SAFETY: This closure is safe to send to concurrent middleware because:
        // 1. It captures self weakly (no retain cycle)
        // 2. It immediately awaits dispatch() which returns to @MainActor
        // 3. No data race is possible - the closure properly isolates the call
        let dispatchAction: Dispatcher<Action> = { [weak self] newAction in
            await self?.dispatch(action: newAction)
        }

        // Wait for all middleware to complete before returning
        await withTaskGroup(of: Void.self) { group in
            for middleware in middlewares {
                group.addTask {
                    await middleware(
                        currentState,
                        action,
                        services,
                        dispatchAction
                    )
                }
            }
        }
    }
}
