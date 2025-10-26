//
//  Core.swift
//  ShiftScheduler
//
//  Created by Farley Caesar on 2025-10-25.
//
import Observation

// Core: Reducer, Dispatcher, Middleware
public typealias AReducer<State, Action> = @Sendable (State, Action) -> State

public typealias Dispatcher<Action> = @Sendable (Action) async -> Void

public typealias AMiddleware<State, Action> = @Sendable (
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

    private let reducer: AReducer<State, Action>
    private let middlewares: [AMiddleware<State, Action>]
    private let services: ServiceContainer

    public init(
        state: State,
        reducer: @escaping AReducer<State, Action>,
        services: ServiceContainer,
        middlewares: [AMiddleware<State, Action>]
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



// App Instantiation
//public struct AppState_: Sendable, Equatable { }
//
//public enum AppAction_: Sendable, Equatable {
//    case dummyAction
//}
//
//nonisolated public let appReducer: AReducer<AppState_, AppAction_> = { state, action in AppState_() }

