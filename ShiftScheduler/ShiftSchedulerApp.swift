import SwiftUI
import OSLog

private let logger = Logger(subsystem: "com.workevents.ShiftScheduler", category: "App")

@main
struct ShiftSchedulerApp: App {
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
        do {
            let repository = ChangeLogRepository()
            let purgeService = ChangeLogPurgeService(repository: repository)

            let purgedCount = try await purgeService.purgeIfNeeded()

            if purgedCount > 0 {
                logger.debug("Purged \(purgedCount) expired change log entries")
            }
        } catch {
            logger.error("Failed to purge change log entries: \(error.localizedDescription)")
        }
    }
}