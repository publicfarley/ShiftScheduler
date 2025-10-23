import SwiftUI

struct ContentView: View {

    var body: some View {
        TabView {
            Text("Hello, World!")
                .tabItem {
                    Label("Today", systemImage: "calendar.badge.clock")
                }

            Text("Hello, World!")
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }

            Text("Hello, World!")
                .tabItem {
                    Label("Shift Types", systemImage: "briefcase")
                }

            Text("Hello, World!")
                .tabItem {
                    Label("Locations", systemImage: "location")
                }

            Text("Hello, World!")
                .tabItem {
                    Label("Change Log", systemImage: "clock.arrow.circlepath")
                }

            Text("Hello, World!")
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }

            Text("Hello, World!")
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
    }
}

#Preview {
    ContentView()
}
