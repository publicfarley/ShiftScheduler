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
///   - state: Initial state (defaults to AppState() with `settings.isTestDataModeActive`
///            pre-set from the persisted `TestDataMode.isEnabled` flag)
///   - services: Service container (defaults to the container matching `TestDataMode.isEnabled`)
/// - Returns: A configured Store instance
func createReduxStore(
    includeStartup: Bool = false,
    state: AppState = defaultInitialState(),
    services: ServiceContainer = ServiceContainer.makeContainer(testDataMode: TestDataMode.isEnabled)
) -> Store<AppState, AppAction> {
    let middlewares = includeStartup ? productionMiddlewares : baseMiddlewares

    return Store(
        state: state,
        reducer: appReducer,
        services: services,
        middlewares: middlewares
    )
}

/// Builds the default initial `AppState`, mirroring the persisted Test Data Mode flag so
/// the UI (banner, Settings toggle) is correct from the very first render.
///
/// Not `private`: default argument expressions must be at least as accessible as the
/// function they default for, and `createReduxStore` is internal.
func defaultInitialState() -> AppState {
    var state = AppState()
    state.settings.isTestDataModeActive = TestDataMode.isEnabled
    return state
}
