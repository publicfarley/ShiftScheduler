import SwiftUI

struct ContentView: View {
    @State private var reduxStore = Store(
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

    var body: some View {
        TabView(selection: Binding(
            get: { reduxStore.state.selectedTab },
            set: { reduxStore.dispatch(action: .appLifecycle(.tabSelected($0))) }
        )) {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "calendar.badge.clock")
                }
                .tag(Tab.today)
                .environment(\.reduxStore, reduxStore)

            ScheduleView()
                .tabItem {
                    Label("Schedule", systemImage: "calendar")
                }
                .tag(Tab.schedule)
                .environment(\.reduxStore, reduxStore)

            ShiftTypesView()
                .tabItem {
                    Label("Shift Types", systemImage: "briefcase")
                }
                .tag(Tab.shiftTypes)
                .environment(\.reduxStore, reduxStore)

            LocationsView()
                .tabItem {
                    Label("Locations", systemImage: "location")
                }
                .tag(Tab.locations)
                .environment(\.reduxStore, reduxStore)

            ChangeLogView()
                .tabItem {
                    Label("Change Log", systemImage: "clock.arrow.circlepath")
                }
                .tag(Tab.changeLog)
                .environment(\.reduxStore, reduxStore)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(Tab.settings)
                .environment(\.reduxStore, reduxStore)
        }
        .environment(\.reduxStore, reduxStore)
    }
}

#Preview {
    ContentView()
}
