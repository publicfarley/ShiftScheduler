import SwiftUI

struct ContentView: View {
    var reduxStore: Store<AppState, AppAction>

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

            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
                .tag(Tab.about)
                .environment(\.reduxStore, reduxStore)
        }
        .environment(\.reduxStore, reduxStore)
        .onAppear {
            reduxStore.dispatch(action: .appLifecycle(.onAppear))
        }
    }
}

//#Preview {
//    ContentView(reduxStore: Store(initialState: .init(), reducer: appReducer))
//}
