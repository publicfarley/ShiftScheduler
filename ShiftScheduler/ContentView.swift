import SwiftUI
import ComposableArchitecture

struct ContentView: View {
    let todayStore = Store(initialState: TodayFeature.State()) {
        TodayFeature()
    }

    var body: some View {
        TabView {
            TodayView(store: todayStore)
                .tabItem {
                    Label("Today", systemImage: "calendar.badge.clock")
                }

            ScheduleView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }

            ShiftTypesView()
                .tabItem {
                    Label("Shift Types", systemImage: "briefcase")
                }

            LocationsView(store: Store(initialState: LocationsFeature.State(), reducer: {
                LocationsFeature()
            }))
                .tabItem {
                    Label("Locations", systemImage: "location")
                }

            ChangeLogView()
                .tabItem {
                    Label("Change Log", systemImage: "clock.arrow.circlepath")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }

            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
    }
}

#Preview {
    ContentView()
}
