import SwiftUI
import OSLog
import EventKit

private let logger = Logger(subsystem: "com.workevents.ShiftScheduler", category: "App")

@main
struct ShiftSchedulerApp: App {
    // Redux store with service integration and startup initialization
    @State private var reduxStore = createReduxStore(includeStartup: true)

    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            Group {
                if showSplash {
                    SplashScreenView()
                        .environment(\.reduxStore, reduxStore)
                        .onAppear {
                            Task {
                                // Wait for initialization to complete (locations and shift types loaded)
                                let startTime = Date()

                                // Wait for initialization or timeout after 30 seconds

                                for _ in 0..<300 { // Check every 100ms for up to 30 seconds
                                    if reduxStore.state.isInitializationComplete {
                                        break
                                    }
                                    try await Task.sleep(nanoseconds: 100_000_000) // 100ms
                                }

                                // Ensure we show splash for at least 2 seconds
                                let elapsedTime = Date().timeIntervalSince(startTime)
                                let remainingTime = max(0, 2.0 - elapsedTime)

                                try await Task.sleep(nanoseconds: UInt64(remainingTime * 1_000_000_000))

                                // Hide splash screen with animation
                                withAnimation(.easeOut(duration: 0.5)) {
                                    showSplash = false
                                }
                            }
                        }
                } else {
                    ContentView(reduxStore: reduxStore)
                        .task {
                            // Set up time change observer
                            await setupTimeChangeObserver()

                            // Run purge when the app becomes active
                            await performBackgroundTasks()
                        }
                        .transition(.opacity)
                }
            }
        }
    }

    // MARK: - Time Change Observer Setup

    @MainActor
    private func setupTimeChangeObserver() async {
        logger.debug("Setting up time change observer")

        // Get the time change service from the service container
        let timeChangeService = reduxStore.services.timeChangeService

        // Start observing time changes
        timeChangeService.startObserving { [weak reduxStore] in
            guard let reduxStore = reduxStore else { return }

            logger.debug("Time change detected - dispatching significantTimeChange action")

            // Dispatch action to Redux to refresh Today and Schedule views
            Task { @MainActor in
                await reduxStore.dispatch(action: .appLifecycle(.significantTimeChange))
            }
        }

        logger.debug("Time change observer started successfully")
    }

    // MARK: - Background Tasks

    private func performBackgroundTasks() async {
         logger.debug("Running background tasks...")

        // Run change log purge if needed
        await purgeExpiredChangeLogEntries()
    }

    private func purgeExpiredChangeLogEntries() async {
        // Check if auto-purge is enabled
        guard reduxStore.state.settings.autoPurgeEnabled else {
            logger.debug("Auto-purge is disabled - skipping automatic purge")
            return
        }

        logger.debug("Dispatching change log purge action (respects user retention policy)")
        await reduxStore.dispatch(action: .changeLog(.purgeOldEntries))
    }
}
