//
//  Core.swift
//  ShiftScheduler
//
//  Created by Farley Caesar on 2025-10-25.
//


public typealias Reducer_ = @Sendable (AppState_, AppAction_) -> AppState_

nonisolated public let appReducer: Reducer_ = { state, action in AppState_() }

public typealias Middleware_ = @Sendable (_ state: AppState_, _ action: AppAction_, _ dispatch: @escaping @Sendable (AppAction_) async -> Void) async -> Void

public struct AppState_: Sendable, Equatable { }

public enum AppAction_: Sendable, Equatable { }

