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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    // Run purge when the app becomes active
                    await performBackgroundTasks()
                }
        }
    }

    // MARK: - Background Tasks

    private func performBackgroundTasks() async {
        logger.debug("Running background tasks...")

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
