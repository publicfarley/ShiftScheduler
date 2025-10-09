import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            TodayView()
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

            LocationsView()
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
        .modelContainer(for: [Location.self, ShiftType.self, ChangeLogEntry.self], inMemory: true)
}
