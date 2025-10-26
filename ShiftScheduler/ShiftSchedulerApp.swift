import SwiftUI
import OSLog
import EventKit

private let logger = Logger(subsystem: "com.workevents.ShiftScheduler", category: "App")

@main
struct ShiftSchedulerApp: App {
    // Redux store with service integration
    @State private var reduxStore = Store(
        state: AppState(),
        reducer: appReducer,
        services: ServiceContainer(),
        middlewares: [
            loggingMiddleware,
            scheduleMiddleware,
            todayMiddleware,
            locationsMiddleware,
            shiftTypesMiddleware,
            changeLogMiddleware,
            settingsMiddleware
        ]
    )

    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView(reduxStore: reduxStore)
                    .task {
                        // Run purge when the app becomes active
                        await performBackgroundTasks()
                    }
                    .opacity(showSplash ? 0 : 1)

                if showSplash {
                    SplashScreenView()
                        .transition(.opacity)
                        .zIndex(1)
                        .onAppear {
                            // Hide splash screen after 2.5 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                withAnimation(.easeOut(duration: 0.5)) {
                                    showSplash = false
                                }
                            }
                        }
                }
            }
        }
    }

    // MARK: - Background Tasks

    private func performBackgroundTasks() async {
        // logger.debug("Running background tasks...")

        // Run change log purge if needed
        await purgeExpiredChangeLogEntries()
    }

    private func purgeExpiredChangeLogEntries() async {
//        do {
//            let repository = ChangeLogRepository()
//            let retentionManager = UserDefaultsRetentionPolicyManager()
//            let purgeService = ChangeLogPurgeService(repository: repository, retentionManager: retentionManager)
//
//            let purgedCount = try await purgeService.purgeIfNeeded()
//
//            if purgedCount > 0 {
//                await logger.debug("Purged \(purgedCount) expired change log entries")
//            }
//        } catch {
//            await logger.error("Failed to purge change log entries: \(error.localizedDescription)")
//        }
    }
}
