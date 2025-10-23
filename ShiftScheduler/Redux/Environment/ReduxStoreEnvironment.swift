import SwiftUI

struct ReduxStoreEnvironmentKey: EnvironmentKey {
    static let defaultValue: Store = Store(
        state: AppState(),
        reducer: appReducer,
        services: ServiceContainer(),
        middlewares: [
            loggingMiddleware,
            { state, action, dispatch, services in
                scheduleMiddleware(state: state, action: action, dispatch: dispatch, services: services)
            },
            { state, action, dispatch, services in
                todayMiddleware(state: state, action: action, dispatch: dispatch, services: services)
            },
            { state, action, dispatch, services in
                locationsMiddleware(state: state, action: action, dispatch: dispatch, services: services)
            },
            { state, action, dispatch, services in
                shiftTypesMiddleware(state: state, action: action, dispatch: dispatch, services: services)
            },
            { state, action, dispatch, services in
                changeLogMiddleware(state: state, action: action, dispatch: dispatch, services: services)
            },
            { state, action, dispatch, services in
                settingsMiddleware(state: state, action: action, dispatch: dispatch, services: services)
            }
        ]
    )
}

extension EnvironmentValues {
    var reduxStore: Store {
        get { self[ReduxStoreEnvironmentKey.self] }
        set { self[ReduxStoreEnvironmentKey.self] = newValue }
    }
}
