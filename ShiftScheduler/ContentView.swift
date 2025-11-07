import SwiftUI

struct ContentView: View {
    var reduxStore: Store<AppState, AppAction>

    var body: some View {
        // Check initialization error first (prevents app startup entirely)
        if let initializationError = reduxStore.state.initializationError {
            InitializationErrorView(errorMessage: initializationError)
                .environment(\.reduxStore, reduxStore)
        }
        // Show loading state while initializing
        else if !reduxStore.state.isInitializationComplete {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemBackground),
                        Color(.systemGray6)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.blue)

                    Text("Initializing App...")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
        }
        // Show normal app content after successful initialization
        else {
            ZStack {
                TabView(selection: Binding(
                    get: { reduxStore.state.selectedTab },
                    set: { tab in
                        Task {
                            await reduxStore.dispatch(action: .appLifecycle(.tabSelected(tab)))
                        }
                    }
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
                .disabled(!reduxStore.state.isNameConfigured)
                .opacity(reduxStore.state.isNameConfigured ? 1.0 : 0.5)

                // Onboarding modal - blocks interaction until name is set
                // Only show after profile is loaded to prevent flash
                if !reduxStore.state.isNameConfigured && reduxStore.state.isProfileLoaded {
                    UserNameOnboardingView()
                        .environment(\.reduxStore, reduxStore)
                }
            }
            .onAppear {
                Task {
                    await reduxStore.dispatch(action: .appLifecycle(.onAppAppear))
                }
            }
        }
    }
}

//#Preview {
//    ContentView(reduxStore: Store(initialState: .init(), reducer: appReducer))
//}
