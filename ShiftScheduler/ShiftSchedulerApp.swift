import SwiftUI
import OSLog
import EventKit

private let logger = Logger(subsystem: "com.workevents.ShiftScheduler", category: "App")

@main
struct ShiftSchedulerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    
                        let eventStore = EKEventStore()
                        
                        let startDate = Date()
                        let endDate = Calendar.current.date(byAdding: .year, value: 1, to: startDate)!
                        let calendarId = try! await EventKitClient.liveValue.getOrCreateAppCalendar()
                        let calendar = eventStore.calendar(withIdentifier: calendarId)!
                        
                        let a = EKEventStore.authorizationStatus(for: .event)
                        
                        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: [calendar])
                        let events = eventStore.events(matching: predicate)

                    // Run purge when the app becomes active
                    await performBackgroundTasks()
                }
        }
    }

    // MARK: - Background Tasks

    private func performBackgroundTasks() async {
        await logger.debug("Running background tasks...")

        // Run change log purge if needed
        await purgeExpiredChangeLogEntries()
    }

    private func purgeExpiredChangeLogEntries() async {
        do {
            let repository = ChangeLogRepository()
            let retentionManager = UserDefaultsRetentionPolicyManager()
            let purgeService = ChangeLogPurgeService(repository: repository, retentionManager: retentionManager)

            let purgedCount = try await purgeService.purgeIfNeeded()

            if purgedCount > 0 {
                await logger.debug("Purged \(purgedCount) expired change log entries")
            }
        } catch {
            await logger.error("Failed to purge change log entries: \(error.localizedDescription)")
        }
    }
}
