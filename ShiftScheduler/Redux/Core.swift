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

    public func dispatch(action: Action) {
        // Apply reducer immediately
        state = reducer(state, action)

        // Capture current state for middleware
        let currentState = state

        // Run middlewares
        for middleware in middlewares {
            Task {
                await middleware(currentState, action, services, { [weak self] newAction in
                    await self?.dispatch(action: newAction)
                })
            }
        }
    }
}
