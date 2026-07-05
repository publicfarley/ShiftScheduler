import Foundation
import OSLog

private let logger = Logger(subsystem: "com.shiftscheduler.redux.services", category: "TestDataSeeder")

/// Seeds a rich sample dataset into Test Data Mode's sandbox so every screen (Today,
/// Schedule, Shift Types, Locations, Change Log, Settings) has realistic content to explore.
///
/// All writes go through the injected `PersistenceServiceProtocol` / `CalendarServiceProtocol`
/// (the same test-container services middleware uses), never raw file writes, so seeded data
/// always matches the current schemas.
enum TestDataSeeder {
    // MARK: - Fixed IDs (deterministic reseeding)

    private enum LocationIDs {
        static let downtown = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        static let westside = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        static let remote = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
        static let airport = UUID(uuidString: "00000000-0000-0000-0000-000000000004")!
    }

    private enum ShiftTypeIDs {
        static let day = UUID(uuidString: "00000000-0000-0000-0000-000000000101")!
        static let evening = UUID(uuidString: "00000000-0000-0000-0000-000000000102")!
        static let night = UUID(uuidString: "00000000-0000-0000-0000-000000000103")!
        static let onCall = UUID(uuidString: "00000000-0000-0000-0000-000000000104")!
        static let halfDay = UUID(uuidString: "00000000-0000-0000-0000-000000000105")!
    }

    // MARK: - Public API

    /// Seeds the sandbox only if it looks fresh (no shift types persisted yet). Safe to call
    /// every time Test Data Mode's startup path runs — a second call is a no-op.
    static func seedIfNeeded(
        persistenceService: PersistenceServiceProtocol,
        calendarService: CalendarServiceProtocol
    ) async throws {
        let existingShiftTypes = try await persistenceService.loadShiftTypes()
        guard existingShiftTypes.isEmpty else {
            logger.debug("Test data already seeded - skipping")
            return
        }

        try await reseed(persistenceService: persistenceService, calendarService: calendarService)
    }

    /// Unconditionally (re)seeds the sandbox. Callers that want a clean baseline should wipe
    /// the test directory first (see `TestDataMode.resetTestData()`).
    static func reseed(
        persistenceService: PersistenceServiceProtocol,
        calendarService: CalendarServiceProtocol
    ) async throws {
        logger.debug("Seeding Test Data Mode sandbox")

        let locations = makeLocations()
        for location in locations {
            try await persistenceService.saveLocation(location)
        }

        let shiftTypes = makeShiftTypes(locations: locations)
        for shiftType in shiftTypes {
            try await persistenceService.saveShiftType(shiftType)
        }

        try await seedScheduledShifts(shiftTypes: shiftTypes, calendarService: calendarService)
        try await seedChangeLog(shiftTypes: shiftTypes, persistenceService: persistenceService)

        let profile = UserProfile(
            userId: UUID(),
            displayName: "Test User",
            retentionPolicy: .forever,
            autoPurgeEnabled: true,
            lastPurgeDate: nil
        )
        try await persistenceService.saveUserProfile(profile)

        logger.debug("Test Data Mode sandbox seeded")
    }

    // MARK: - Locations

    private static func makeLocations() -> [Location] {
        [
            Location(
                id: LocationIDs.downtown,
                name: "Downtown Hospital",
                address: "500 Main Street\nSuite 100\nDowntown, ST 10001"
            ),
            Location(
                id: LocationIDs.westside,
                name: "Westside Clinic",
                address: "220 Westside Avenue\nWestside, ST 10002"
            ),
            Location(
                id: LocationIDs.remote,
                name: "Remote / Home Office",
                address: "Remote"
            ),
            Location(
                id: LocationIDs.airport,
                name: "Airport Branch",
                address: "1 Airport Way\nTerminal B, Level 2\nAirport, ST 10003"
            )
        ]
    }

    // MARK: - Shift Types

    private static func makeShiftTypes(locations: [Location]) -> [ShiftType] {
        let downtown = locations[0]
        let westside = locations[1]
        let remote = locations[2]
        let airport = locations[3]

        return [
            ShiftType(
                id: ShiftTypeIDs.day,
                symbol: "🌞",
                duration: .scheduled(from: HourMinuteTime(hour: 7, minute: 0), to: HourMinuteTime(hour: 15, minute: 0)),
                title: "Day",
                description: "Standard day shift",
                location: downtown
            ),
            ShiftType(
                id: ShiftTypeIDs.evening,
                symbol: "🌆",
                duration: .scheduled(from: HourMinuteTime(hour: 15, minute: 0), to: HourMinuteTime(hour: 23, minute: 0)),
                title: "Evening",
                description: "Evening shift",
                location: westside
            ),
            ShiftType(
                id: ShiftTypeIDs.night,
                symbol: "🌙",
                duration: .scheduled(from: HourMinuteTime(hour: 23, minute: 0), to: HourMinuteTime(hour: 7, minute: 0)),
                title: "Night",
                description: "Overnight shift",
                location: downtown
            ),
            ShiftType(
                id: ShiftTypeIDs.onCall,
                symbol: "📱",
                duration: .allDay,
                title: "On-Call",
                description: "On-call availability",
                location: remote
            ),
            ShiftType(
                id: ShiftTypeIDs.halfDay,
                symbol: "🌤",
                duration: .scheduled(from: HourMinuteTime(hour: 9, minute: 0), to: HourMinuteTime(hour: 13, minute: 0)),
                title: "Half Day",
                description: "Half-day shift",
                location: airport
            )
        ]
    }

    // MARK: - Scheduled Shifts

    /// Seeds a repeating Day/Day/Evening/Night/off/off rotation spanning -30...+45 days
    /// relative to today, with a sick day in the past week and a couple of shifts with notes.
    private static func seedScheduledShifts(
        shiftTypes: [ShiftType],
        calendarService: CalendarServiceProtocol
    ) async throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        guard let rangeStart = calendar.date(byAdding: .day, value: -30, to: today) else {
            return
        }

        // Day, Day, Evening, Night, off, off (Night's "next day" lands on an "off" slot,
        // so the overnight shift never conflicts with the following day's shift).
        let dayShift = shiftTypes[0]
        let eveningShift = shiftTypes[1]
        let nightShift = shiftTypes[2]
        let rotation: [ShiftType?] = [dayShift, dayShift, eveningShift, nightShift, nil, nil]

        var createdShifts: [(date: Date, eventIdentifier: String)] = []

        // -30...+45 inclusive is 76 days.
        for dayOffset in 0..<76 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: rangeStart) else {
                continue
            }

            guard let shiftType = rotation[dayOffset % rotation.count] else {
                continue
            }

            // Offsets 6 and 60 both land on a "Day" slot in the rotation (offset % 6 == 0),
            // guaranteeing these notes actually get attached to a created shift.
            var notes: String?
            if dayOffset == 6 {
                notes = "Covering for a colleague"
            } else if dayOffset == 60 {
                notes = "Requested early start"
            }

            do {
                let shift = try await calendarService.createShiftEvent(date: date, shiftType: shiftType, notes: notes)
                createdShifts.append((date: date, eventIdentifier: shift.eventIdentifier))
            } catch {
                // Defensive: seeding should never crash the app even if the rotation
                // produces an unexpected overlap.
                logger.warning("Skipped seeding shift on \(date.formatted()): \(error.localizedDescription)")
            }
        }

        // Mark one shift in the past week as a sick day.
        if let sickDayEntry = createdShifts.first(where: { entry in
            let daysAgo = calendar.dateComponents([.day], from: entry.date, to: today).day ?? 0
            return daysAgo >= 1 && daysAgo <= 7
        }) {
            try? await calendarService.markShiftAsSick(
                eventIdentifier: sickDayEntry.eventIdentifier,
                isSickDay: true,
                reason: "Feeling unwell"
            )
        }
    }

    // MARK: - Change Log

    /// Seeds ~8 change log entries with a mix of `ChangeType` values spread over the past
    /// 60 days, exercising the retention/purge UI.
    private static func seedChangeLog(
        shiftTypes: [ShiftType],
        persistenceService: PersistenceServiceProtocol
    ) async throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let userId = UUID()
        let userDisplayName = "Test User"

        let dayShift = shiftTypes[0]
        let eveningShift = shiftTypes[1]
        let nightShift = shiftTypes[2]

        func daysAgo(_ n: Int) -> Date {
            calendar.date(byAdding: .day, value: -n, to: today) ?? today
        }

        let entries: [ChangeLogEntry] = [
            ChangeLogEntry(
                timestamp: daysAgo(58),
                userId: userId,
                userDisplayName: userDisplayName,
                changeType: .created,
                scheduledShiftDate: daysAgo(58),
                oldShiftSnapshot: nil,
                newShiftSnapshot: ShiftSnapshot(from: dayShift),
                reason: nil
            ),
            ChangeLogEntry(
                timestamp: daysAgo(50),
                userId: userId,
                userDisplayName: userDisplayName,
                changeType: .switched,
                scheduledShiftDate: daysAgo(50),
                oldShiftSnapshot: ShiftSnapshot(from: dayShift),
                newShiftSnapshot: ShiftSnapshot(from: eveningShift),
                reason: "Schedule swap"
            ),
            ChangeLogEntry(
                timestamp: daysAgo(45),
                userId: userId,
                userDisplayName: userDisplayName,
                changeType: .deleted,
                scheduledShiftDate: daysAgo(45),
                oldShiftSnapshot: ShiftSnapshot(from: nightShift),
                newShiftSnapshot: nil,
                reason: "Cancelled"
            ),
            ChangeLogEntry(
                timestamp: daysAgo(35),
                userId: userId,
                userDisplayName: userDisplayName,
                changeType: .created,
                scheduledShiftDate: daysAgo(35),
                oldShiftSnapshot: nil,
                newShiftSnapshot: ShiftSnapshot(from: eveningShift),
                reason: nil
            ),
            ChangeLogEntry(
                timestamp: daysAgo(20),
                userId: userId,
                userDisplayName: userDisplayName,
                changeType: .markedAsSick,
                scheduledShiftDate: daysAgo(20),
                oldShiftSnapshot: ShiftSnapshot(from: dayShift),
                newShiftSnapshot: ShiftSnapshot(from: dayShift),
                reason: "Flu"
            ),
            ChangeLogEntry(
                timestamp: daysAgo(15),
                userId: userId,
                userDisplayName: userDisplayName,
                changeType: .unmarkedAsSick,
                scheduledShiftDate: daysAgo(15),
                oldShiftSnapshot: ShiftSnapshot(from: dayShift),
                newShiftSnapshot: ShiftSnapshot(from: dayShift),
                reason: nil
            ),
            ChangeLogEntry(
                timestamp: daysAgo(8),
                userId: userId,
                userDisplayName: userDisplayName,
                changeType: .undo,
                scheduledShiftDate: daysAgo(8),
                oldShiftSnapshot: ShiftSnapshot(from: nightShift),
                newShiftSnapshot: ShiftSnapshot(from: dayShift),
                reason: nil
            ),
            ChangeLogEntry(
                timestamp: daysAgo(3),
                userId: userId,
                userDisplayName: userDisplayName,
                changeType: .redo,
                scheduledShiftDate: daysAgo(3),
                oldShiftSnapshot: ShiftSnapshot(from: dayShift),
                newShiftSnapshot: ShiftSnapshot(from: nightShift),
                reason: nil
            )
        ]

        try await persistenceService.addMultipleChangeLogEntries(entries)
    }
}
