import Foundation

// MARK: - Middleware Configuration

/// Core middlewares used by the Store (without startup initialization)
let baseMiddlewares: [Middleware<AppState, AppAction>] = [
    loggingMiddleware,
    scheduleMiddleware,
    todayMiddleware,
    locationsMiddleware,
    shiftTypesMiddleware,
    changeLogMiddleware,
    settingsMiddleware
]

/// Production middlewares with startup initialization
let productionMiddlewares: [Middleware<AppState, AppAction>] = [
    loggingMiddleware,
    appStartupMiddleware,
    scheduleMiddleware,
    todayMiddleware,
    locationsMiddleware,
    shiftTypesMiddleware,
    changeLogMiddleware,
    settingsMiddleware
]

// MARK: - Store Factory

/// Creates a configured Redux Store instance
/// - Parameters:
///   - includeStartup: If true, includes appStartupMiddleware for initial data loading.
///                    Use true for production app, false for testing and environment defaults.
///   - state: Initial state (defaults to AppState())
///   - services: Service container (defaults to ServiceContainer())
/// - Returns: A configured Store instance
func createReduxStore(
    includeStartup: Bool = false,
    state: AppState = AppState(),
    services: ServiceContainer = ServiceContainer()
) -> Store<AppState, AppAction> {
    let middlewares = includeStartup ? productionMiddlewares : baseMiddlewares

    return Store(
        state: state,
        reducer: appReducer,
        services: services,
        middlewares: middlewares
    )
}
