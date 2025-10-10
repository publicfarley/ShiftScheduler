import SwiftUI
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.workevents.ShiftScheduler", category: "App")

@main
struct ShiftSchedulerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Location.self,
            ShiftType.self,
            ChangeLogEntry.self
        ])

        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    // Run purge when the app becomes active
                    await performBackgroundTasks()
                }
        }
        .modelContainer(sharedModelContainer)
    }

    // MARK: - Background Tasks

    private func performBackgroundTasks() async {
        logger.debug("Running background tasks...")

        // Run change log purge if needed
        await purgeExpiredChangeLogEntries()
    }

    private func purgeExpiredChangeLogEntries() async {
        do {
            let repository = SwiftDataChangeLogRepository(modelContext: sharedModelContainer.mainContext)
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