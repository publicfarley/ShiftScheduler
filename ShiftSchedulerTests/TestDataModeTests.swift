import Testing
import Foundation
@testable import ShiftScheduler

/// Tests for Test Data Mode: the simulated calendar service, the seeder, the sandboxed
/// service container, and the legacy-migration guard in `PersistenceService`.
///
/// These tests use temporary directories (never the real `ShiftSchedulerData` directory)
/// with fixed, deterministic dates, and clean up after themselves per the project's
/// test-quality conventions.
@Suite("Test Data Mode Tests")
@MainActor
struct TestDataModeTests {
    // MARK: - Setup Helpers

    /// Create a temporary directory for testing
    static func createTemporaryDirectory() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        return tempDir
    }

    /// Clean up temporary directory
    static func cleanupTemporaryDirectory(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    /// Fixed date for deterministic tests: October 29, 2025
    static func fixedDate(year: Int = 2025, month: Int = 10, day: Int = 29) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
    }

    /// A simple shift type for testing, backed by a disabled (no CloudKit traffic) manager.
    static func createTestShiftType(duration: ShiftDuration = .allDay, id: UUID = UUID()) -> ShiftType {
        let location = Location(id: UUID(), name: "Test Location", address: "1 Test Way")
        return ShiftType(id: id, symbol: "🌞", duration: duration, title: "Day", description: "Test shift", location: location)
    }

    /// Creates a `SimulatedCalendarService` backed by a temporary directory, with the given
    /// shift types already persisted to the (test-only, CloudKit-disabled) shift type repository.
    static func createTestService(shiftTypes: [ShiftType]) async throws -> (
        service: SimulatedCalendarService,
        tempDir: URL,
        shiftTypeRepository: ShiftTypeRepository
    ) {
        let tempDir = createTemporaryDirectory()
        let shiftTypeRepository = ShiftTypeRepository(directoryURL: tempDir, cloudKitManager: CloudKitManager(isEnabled: false))
        for shiftType in shiftTypes {
            try await shiftTypeRepository.save(shiftType)
        }
        let service = SimulatedCalendarService(directoryURL: tempDir, shiftTypeRepository: shiftTypeRepository)
        return (service, tempDir, shiftTypeRepository)
    }

    /// Creates the persistence + calendar services `TestDataSeeder` writes through, backed by
    /// a temporary directory (mirrors `ServiceContainer.createTestDataContainer()`, but sandboxed).
    static func createSeederServices(tempDir: URL) -> (
        persistenceService: PersistenceService,
        calendarService: SimulatedCalendarService
    ) {
        let cloudKitManager = CloudKitManager(isEnabled: false)
        let shiftTypeRepository = ShiftTypeRepository(directoryURL: tempDir, cloudKitManager: cloudKitManager)
        let locationRepository = LocationRepository(directoryURL: tempDir, cloudKitManager: cloudKitManager)
        let changeLogRepository = ChangeLogRepository(directoryURL: tempDir)
        let userProfileRepository = UserProfileRepository(directoryURL: tempDir)

        let persistenceService = PersistenceService(
            shiftTypeRepository: shiftTypeRepository,
            locationRepository: locationRepository,
            changeLogRepository: changeLogRepository,
            userProfileRepository: userProfileRepository,
            skipLegacyMigration: true
        )

        let calendarService = SimulatedCalendarService(directoryURL: tempDir, shiftTypeRepository: shiftTypeRepository)

        return (persistenceService, calendarService)
    }

    // MARK: - SimulatedCalendarService: Create / Load

    @Test("createShiftEvent then loadShifts returns the created shift")
    func testCreateThenLoadReturnsShift() async throws {
        let shiftType = Self.createTestShiftType()
        let (service, tempDir, _) = try await Self.createTestService(shiftTypes: [shiftType])
        defer { Self.cleanupTemporaryDirectory(tempDir) }

        let date = Self.fixedDate()
        let created = try await service.createShiftEvent(date: date, shiftType: shiftType, notes: nil)

        let rangeEnd = try #require(Calendar.current.date(byAdding: .day, value: 1, to: date))
        let loaded = try await service.loadShifts(from: date, to: rangeEnd)

        #expect(loaded.count == 1)
        #expect(loaded.first?.eventIdentifier == created.eventIdentifier)
        #expect(loaded.first?.shiftType?.id == shiftType.id)
    }

    @Test("createShiftEvent throws overlappingShifts for a conflicting second shift")
    func testCreateShiftEventThrowsOnOverlap() async throws {
        let shiftType = Self.createTestShiftType()
        let (service, tempDir, _) = try await Self.createTestService(shiftTypes: [shiftType])
        defer { Self.cleanupTemporaryDirectory(tempDir) }

        let date = Self.fixedDate()
        _ = try await service.createShiftEvent(date: date, shiftType: shiftType, notes: nil)

        do {
            _ = try await service.createShiftEvent(date: date, shiftType: shiftType, notes: nil)
            #expect(Bool(false), "Expected overlappingShifts error to be thrown")
        } catch let error as ScheduleError {
            if case .overlappingShifts = error {
                #expect(true)
            } else {
                throw error
            }
        }
    }

    // MARK: - SimulatedCalendarService: Update / Delete Round-Trip

    @Test("updateShiftEvent changes the shift type and recalculates endDate")
    func testUpdateShiftEventRoundTrip() async throws {
        let dayShiftType = Self.createTestShiftType(duration: .allDay)
        let (service, tempDir, shiftTypeRepository) = try await Self.createTestService(shiftTypes: [dayShiftType])
        defer { Self.cleanupTemporaryDirectory(tempDir) }

        let nightShiftType = ShiftType(
            id: UUID(),
            symbol: "🌙",
            duration: .scheduled(from: HourMinuteTime(hour: 23, minute: 0), to: HourMinuteTime(hour: 7, minute: 0)),
            title: "Night",
            description: "Test overnight shift",
            location: dayShiftType.location
        )
        try await shiftTypeRepository.save(nightShiftType)

        let date = Self.fixedDate()
        let created = try await service.createShiftEvent(date: date, shiftType: dayShiftType, notes: nil)

        try await service.updateShiftEvent(eventIdentifier: created.eventIdentifier, newShiftType: nightShiftType, date: date)

        let rangeEnd = try #require(Calendar.current.date(byAdding: .day, value: 2, to: date))
        let loaded = try await service.loadShifts(from: date, to: rangeEnd)
        let updated = try #require(loaded.first(where: { $0.eventIdentifier == created.eventIdentifier }))

        #expect(updated.shiftType?.id == nightShiftType.id)
        let expectedEndDate = try #require(Calendar.current.date(byAdding: .day, value: 1, to: date))
        #expect(updated.endDate == expectedEndDate)
    }

    @Test("deleteShiftEvent removes the shift")
    func testDeleteShiftEventRemovesShift() async throws {
        let shiftType = Self.createTestShiftType()
        let (service, tempDir, _) = try await Self.createTestService(shiftTypes: [shiftType])
        defer { Self.cleanupTemporaryDirectory(tempDir) }

        let date = Self.fixedDate()
        let created = try await service.createShiftEvent(date: date, shiftType: shiftType, notes: nil)

        try await service.deleteShiftEvent(eventIdentifier: created.eventIdentifier)

        let rangeEnd = try #require(Calendar.current.date(byAdding: .day, value: 1, to: date))
        let loaded = try await service.loadShifts(from: date, to: rangeEnd)
        #expect(loaded.isEmpty)
    }

    // MARK: - SimulatedCalendarService: Sick Day + Notes

    @Test("markShiftAsSick sets and clears the sick day flag and reason")
    func testMarkShiftAsSickRoundTrip() async throws {
        let shiftType = Self.createTestShiftType()
        let (service, tempDir, _) = try await Self.createTestService(shiftTypes: [shiftType])
        defer { Self.cleanupTemporaryDirectory(tempDir) }

        let date = Self.fixedDate()
        let created = try await service.createShiftEvent(date: date, shiftType: shiftType, notes: nil)
        let rangeEnd = try #require(Calendar.current.date(byAdding: .day, value: 1, to: date))

        try await service.markShiftAsSick(eventIdentifier: created.eventIdentifier, isSickDay: true, reason: "Flu")
        var loaded = try await service.loadShifts(from: date, to: rangeEnd)
        #expect(loaded.first?.isSickDay == true)
        #expect(loaded.first?.reason == "Flu")

        try await service.markShiftAsSick(eventIdentifier: created.eventIdentifier, isSickDay: false, reason: nil)
        loaded = try await service.loadShifts(from: date, to: rangeEnd)
        #expect(loaded.first?.isSickDay == false)
        #expect(loaded.first?.reason == nil)
    }

    @Test("updateShiftNotes updates and clears notes")
    func testUpdateShiftNotesRoundTrip() async throws {
        let shiftType = Self.createTestShiftType()
        let (service, tempDir, _) = try await Self.createTestService(shiftTypes: [shiftType])
        defer { Self.cleanupTemporaryDirectory(tempDir) }

        let date = Self.fixedDate()
        let created = try await service.createShiftEvent(date: date, shiftType: shiftType, notes: nil)
        let rangeEnd = try #require(Calendar.current.date(byAdding: .day, value: 1, to: date))

        try await service.updateShiftNotes(eventIdentifier: created.eventIdentifier, notes: "Covering a shift")
        var loaded = try await service.loadShifts(from: date, to: rangeEnd)
        #expect(loaded.first?.notes == "Covering a shift")

        try await service.updateShiftNotes(eventIdentifier: created.eventIdentifier, notes: "")
        loaded = try await service.loadShifts(from: date, to: rangeEnd)
        #expect(loaded.first?.notes == nil)
    }

    // MARK: - SimulatedCalendarService: Range Filtering

    @Test("loadShifts filters out shifts outside the requested range")
    func testLoadShiftsRangeFiltering() async throws {
        let shiftType = Self.createTestShiftType()
        let (service, tempDir, _) = try await Self.createTestService(shiftTypes: [shiftType])
        defer { Self.cleanupTemporaryDirectory(tempDir) }

        let baseDate = Self.fixedDate(month: 10, day: 1)
        let inRangeDate = try #require(Calendar.current.date(byAdding: .day, value: 5, to: baseDate))
        let outOfRangeDate = try #require(Calendar.current.date(byAdding: .day, value: 20, to: baseDate))

        _ = try await service.createShiftEvent(date: inRangeDate, shiftType: shiftType, notes: nil)
        _ = try await service.createShiftEvent(date: outOfRangeDate, shiftType: shiftType, notes: nil)

        let rangeEnd = try #require(Calendar.current.date(byAdding: .day, value: 10, to: baseDate))
        let loaded = try await service.loadShifts(from: baseDate, to: rangeEnd)

        #expect(loaded.count == 1)
        #expect(loaded.first?.date == inRangeDate)
    }

    // MARK: - TestDataSeeder

    @Test("seedIfNeeded populates locations, shift types, past/future shifts, and change log entries")
    func testSeedIfNeededPopulatesSandbox() async throws {
        let tempDir = Self.createTemporaryDirectory()
        defer { Self.cleanupTemporaryDirectory(tempDir) }
        let (persistenceService, calendarService) = Self.createSeederServices(tempDir: tempDir)

        try await TestDataSeeder.seedIfNeeded(persistenceService: persistenceService, calendarService: calendarService)

        let locations = try await persistenceService.loadLocations()
        let shiftTypes = try await persistenceService.loadShiftTypes()
        let changeLogEntries = try await persistenceService.loadChangeLogEntries()

        #expect(locations.count > 0)
        #expect(shiftTypes.count > 0)
        #expect(changeLogEntries.count > 0)

        let today = Calendar.current.startOfDay(for: Date())
        let pastStart = try #require(Calendar.current.date(byAdding: .day, value: -31, to: today))
        let futureEnd = try #require(Calendar.current.date(byAdding: .day, value: 46, to: today))
        let allShifts = try await calendarService.loadShifts(from: pastStart, to: futureEnd)

        #expect(allShifts.contains(where: { $0.date < today }))
        #expect(allShifts.contains(where: { $0.date >= today }))
    }

    @Test("seedIfNeeded is idempotent - a second call adds nothing")
    func testSeedIfNeededIsIdempotent() async throws {
        let tempDir = Self.createTemporaryDirectory()
        defer { Self.cleanupTemporaryDirectory(tempDir) }
        let (persistenceService, calendarService) = Self.createSeederServices(tempDir: tempDir)

        try await TestDataSeeder.seedIfNeeded(persistenceService: persistenceService, calendarService: calendarService)
        let shiftTypesAfterFirst = try await persistenceService.loadShiftTypes()
        let locationsAfterFirst = try await persistenceService.loadLocations()
        let changeLogAfterFirst = try await persistenceService.loadChangeLogEntries()

        try await TestDataSeeder.seedIfNeeded(persistenceService: persistenceService, calendarService: calendarService)
        let shiftTypesAfterSecond = try await persistenceService.loadShiftTypes()
        let locationsAfterSecond = try await persistenceService.loadLocations()
        let changeLogAfterSecond = try await persistenceService.loadChangeLogEntries()

        #expect(shiftTypesAfterFirst.count == shiftTypesAfterSecond.count)
        #expect(locationsAfterFirst.count == locationsAfterSecond.count)
        #expect(changeLogAfterFirst.count == changeLogAfterSecond.count)
    }

    @Test("reseed after mutation restores the baseline dataset")
    func testReseedRestoresBaseline() async throws {
        let tempDir = Self.createTemporaryDirectory()
        defer { Self.cleanupTemporaryDirectory(tempDir) }
        let (persistenceService, calendarService) = Self.createSeederServices(tempDir: tempDir)

        try await TestDataSeeder.seedIfNeeded(persistenceService: persistenceService, calendarService: calendarService)
        let baselineShiftTypeCount = try await persistenceService.loadShiftTypes().count
        let baselineLocationCount = try await persistenceService.loadLocations().count

        // Mutate: delete a shift type, simulating the user poking around in Test Data Mode
        if let firstShiftType = try await persistenceService.loadShiftTypes().first {
            try await persistenceService.deleteShiftType(id: firstShiftType.id)
        }
        let mutatedShiftTypeCount = try await persistenceService.loadShiftTypes().count
        #expect(mutatedShiftTypeCount == baselineShiftTypeCount - 1)

        // Mirrors SettingsMiddleware's resetTestDataRequested flow: wipe the directory, then reseed
        try? FileManager.default.removeItem(at: tempDir)
        try await TestDataSeeder.reseed(persistenceService: persistenceService, calendarService: calendarService)

        let restoredShiftTypeCount = try await persistenceService.loadShiftTypes().count
        let restoredLocationCount = try await persistenceService.loadLocations().count

        #expect(restoredShiftTypeCount == baselineShiftTypeCount)
        #expect(restoredLocationCount == baselineLocationCount)
    }

    // MARK: - ServiceContainer.createTestDataContainer()

    @Test("createTestDataContainer persists writes under the ShiftSchedulerData-Test directory")
    func testCreateTestDataContainerUsesSandboxDirectory() async throws {
        let testDir = TestDataMode.testDataDirectory
        try? FileManager.default.removeItem(at: testDir)
        defer { try? FileManager.default.removeItem(at: testDir) }

        #expect(testDir.lastPathComponent == "ShiftSchedulerData-Test")

        let container = ServiceContainer.createTestDataContainer()
        let location = Location(id: UUID(), name: "Sandbox Location", address: "123 Sandbox Way")
        try await container.persistenceService.saveLocation(location)

        let locationsFileURL = testDir.appendingPathComponent("locations.json")
        #expect(FileManager.default.fileExists(atPath: locationsFileURL.path))

        let loadedLocations = try await container.persistenceService.loadLocations()
        #expect(loadedLocations.contains(where: { $0.id == location.id }))
    }

    // MARK: - PersistenceService.skipLegacyMigration

    @Test("skipLegacyMigration leaves legacy UserDefaults keys untouched when profile is missing")
    func testSkipLegacyMigrationLeavesUserDefaultsUntouched() async throws {
        let displayNameKey = "displayName"
        let autoPurgeKey = "autoPurgeEnabled"

        // Preserve whatever is really there so we can restore it afterward
        let originalDisplayName = UserDefaults.standard.string(forKey: displayNameKey)
        let originalAutoPurge = UserDefaults.standard.object(forKey: autoPurgeKey) as? Bool

        UserDefaults.standard.set("Real User", forKey: displayNameKey)
        UserDefaults.standard.set(false, forKey: autoPurgeKey)

        defer {
            if let originalDisplayName {
                UserDefaults.standard.set(originalDisplayName, forKey: displayNameKey)
            } else {
                UserDefaults.standard.removeObject(forKey: displayNameKey)
            }
            if let originalAutoPurge {
                UserDefaults.standard.set(originalAutoPurge, forKey: autoPurgeKey)
            } else {
                UserDefaults.standard.removeObject(forKey: autoPurgeKey)
            }
        }

        let tempDir = Self.createTemporaryDirectory()
        defer { Self.cleanupTemporaryDirectory(tempDir) }

        let cloudKitManager = CloudKitManager(isEnabled: false)
        let service = PersistenceService(
            shiftTypeRepository: ShiftTypeRepository(directoryURL: tempDir, cloudKitManager: cloudKitManager),
            locationRepository: LocationRepository(directoryURL: tempDir, cloudKitManager: cloudKitManager),
            changeLogRepository: ChangeLogRepository(directoryURL: tempDir),
            userProfileRepository: UserProfileRepository(directoryURL: tempDir),
            skipLegacyMigration: true
        )

        let profile = try await service.loadUserProfile()

        // No persisted profile exists yet, and migration is skipped, so we get a fresh
        // default profile - the legacy UserDefaults keys must remain exactly as set above.
        #expect(profile.displayName.isEmpty)
        #expect(UserDefaults.standard.string(forKey: displayNameKey) == "Real User")
        #expect(UserDefaults.standard.object(forKey: autoPurgeKey) as? Bool == false)
    }
}
