import SwiftUI

struct ReduxStoreEnvironmentKey: EnvironmentKey {
    static let defaultValue: Store<AppState, AppAction> = Store(
        state: AppState(),
        reducer: appReducer,
        services: ServiceContainer(),
        middlewares: [
            loggingMiddleware,
            scheduleMiddleware,
            todayMiddleware,
            locationsMiddleware,
            shiftTypesMiddleware,
            changeLogMiddleware,
            settingsMiddleware
        ]
    )
}

extension EnvironmentValues {
    var reduxStore: Store<AppState, AppAction> {
        get { self[ReduxStoreEnvironmentKey.self] }
        set { self[ReduxStoreEnvironmentKey.self] = newValue }
    }
}
