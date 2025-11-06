//
//  Core.swift
//  ShiftScheduler
//
//  Created by Farley Caesar on 2025-10-25.
//
import Observation

// Core: Reducer, Dispatcher, Middleware
public typealias Reducer<State, Action> = @Sendable (State, Action) -> State

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
@MainActor
@Observable
public final class Store<State, Action: Sendable> {
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
        // Capture current state for middleware to use
        let currentState = state

        // Wait for all middleware to complete before returning
        await withTaskGroup(of: Void.self) { group in
            for middleware in middlewares {
                group.addTask {
                    await middleware(
                        currentState,
                        action,
                        services,
                        { [weak self] newAction in
                            await self?.dispatch(action: newAction)
                        }
                    )
                }
            }
        }
    }
}
