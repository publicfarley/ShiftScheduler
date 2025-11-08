import SwiftUI

struct ReduxStoreEnvironmentKey: EnvironmentKey {
    static let defaultValue: Store<AppState, AppAction> = createReduxStore(includeStartup: false)
}

extension EnvironmentValues {
    var reduxStore: Store<AppState, AppAction> {
        get { self[ReduxStoreEnvironmentKey.self] }
        set { self[ReduxStoreEnvironmentKey.self] = newValue }
    }
}
