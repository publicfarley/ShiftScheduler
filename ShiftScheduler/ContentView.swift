import SwiftUI
import ComposableArchitecture

struct ContentView: View {
    let todayStore = Store(initialState: TodayFeature.State()) {
        TodayFeature()
    }

    let scheduleStore = Store(initialState: ScheduleFeature.State()) {
        ScheduleFeature()
    }

    let changeLogStore = Store(initialState: ChangeLogFeature.State()) {
        ChangeLogFeature()
    }

    let settingsStore = Store(initialState: SettingsFeature.State()) {
        SettingsFeature()
    }

    var body: some View {
        TabView {
            TodayView(store: todayStore)
                .tabItem {
                    Label("Today", systemImage: "calendar.badge.clock")
                }

            ScheduleView(store: scheduleStore)
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }

            ShiftTypesView(store: Store(initialState: ShiftTypesFeature.State(), reducer: {
                ShiftTypesFeature()
            }))
                .tabItem {
                    Label("Shift Types", systemImage: "briefcase")
                }

            LocationsView(store: Store(initialState: LocationsFeature.State(), reducer: {
                LocationsFeature()
            }))
                .tabItem {
                    Label("Locations", systemImage: "location")
                }

            ChangeLogView(store: changeLogStore)
                .tabItem {
                    Label("Change Log", systemImage: "clock.arrow.circlepath")
                }

            SettingsView(store: settingsStore)
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
