import Testing
import Foundation
@testable import ShiftScheduler

/// Performance Tests for measuring and validating execution times
/// Tests ensure that critical operations complete within acceptable time bounds
///
/// These tests can be skipped in CI environments by setting the environment variable:
/// `SKIP_PERFORMANCE_TESTS=1`
///
/// To run only performance tests:
/// `xcodebuild test -scheme ShiftScheduler -testPlan PerformanceTests`
///
/// To skip performance tests locally:
/// `SKIP_PERFORMANCE_TESTS=1 xcodebuild test -scheme ShiftScheduler`

@Suite("Performance Tests")
@MainActor
struct PerformanceTests {
    // MARK: - Environment Variables

    /// Check if performance tests should be skipped (useful in CI environments)
    private static let shouldSkipPerformanceTests: Bool = {
        ProcessInfo.processInfo.environment["SKIP_PERFORMANCE_TESTS"] == "1"
    }()

    // MARK: - Store Dispatch Performance

    @Test("Store dispatch completes in reasonable time", .disabled(if: shouldSkipPerformanceTests))
    func testStoreDispatchPerformance() async {
        // Given
        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: ServiceContainer(),
            middlewares: []
        )
        
        let iterations = 1000
        let startTime = Date()

        // When
        for _ in 0..<iterations {
            await store.dispatch(action: .appLifecycle(.tabSelected(.today)))
        }

        // Then
        let elapsed = Date().timeIntervalSince(startTime)
        #expect(elapsed < 1.0, "1000 store dispatches should complete in under 1 second")
    }

    @Test("Reducer execution is fast", .disabled(if: shouldSkipPerformanceTests))
    func testReducerExecutionSpeed() {
        // Given
        var state = AppState()
        let action = AppAction.appLifecycle(.tabSelected(.schedule))
        let iterations = 10000
        let startTime = Date()

        // When
        for _ in 0..<iterations {
            state = appReducer(state: state, action: action)
        }

        // Then
        let elapsed = Date().timeIntervalSince(startTime)
        #expect(elapsed < 0.5, "10000 reducer calls should complete in under 0.5 seconds")
    }

    // MARK: - Data Collection Performance

    @Test("Building large location collection is fast", .disabled(if: shouldSkipPerformanceTests))
    func testBuildingLargeLocationCollection() {
        // Given
        let locationCount = 10000
        let startTime = Date()

        // When
        let locations = (0..<locationCount).map { index in
            LocationBuilder(
                name: "Location \(index)",
                address: "\(index) Street"
            ).build()
        }

        // Then
        let elapsed = Date().timeIntervalSince(startTime)
        #expect(locations.count == locationCount)
        #expect(elapsed < 1.0, "Building 10000 locations should complete in under 1 second")
    }

    @Test("Building large shift type collection is fast", .disabled(if: shouldSkipPerformanceTests))
    func testBuildingLargeShiftTypeCollection() {
        // Given
        let shiftTypeCount = 5000
        let location = LocationBuilder().build()
        let startTime = Date()

        // When
        let shiftTypes = (0..<shiftTypeCount).map { index in
            ShiftTypeBuilder(
                title: "Shift Type \(index)",
                location: location
            ).build()
        }

        // Then
        let elapsed = Date().timeIntervalSince(startTime)
        #expect(shiftTypes.count == shiftTypeCount)
        #expect(elapsed < 1.0, "Building 5000 shift types should complete in under 1 second")
    }

    @Test("Building large scheduled shift collection is fast", .disabled(if: shouldSkipPerformanceTests))
    func testBuildingLargeScheduledShiftCollection() {
        // Given
        let shiftCount = 10000
        let baseDate = Date()
        let startTime = Date()

        // When
        let shifts = (0..<shiftCount).map { index in
            let shiftDate = baseDate.addingTimeInterval(TimeInterval(index * 86400))
            return ScheduledShiftBuilder(
                id: UUID(),
                date: shiftDate
            ).build()
        }

        // Then
        let elapsed = Date().timeIntervalSince(startTime)
        #expect(shifts.count == shiftCount)
        #expect(elapsed < 2.0, "Building 10000 scheduled shifts should complete in under 2 seconds")
    }

    // MARK: - Mock Service Performance

    @Test("MockPersistenceService handles large data sets efficiently", .disabled(if: shouldSkipPerformanceTests))
    func testMockPersistenceServicePerformance() {
        // Given
        let service = MockPersistenceService()
        let locationCount = 5000
        service.mockLocations = TestDataCollections.standardLocations() +
            (0..<(locationCount - 3)).map { index in
                LocationBuilder(
                    name: "Location \(index)"
                ).build()
            }

        let startTime = Date()

        // When
        let _ = service.mockLocations.count
        let elapsed1 = Date().timeIntervalSince(startTime)

        // Then
        #expect(service.mockLocations.count == locationCount)
        #expect(elapsed1 < 0.5, "Accessing 5000 locations should complete in under 0.5 seconds")
    }

    // MARK: - Filter Performance

    @Test("Filtering large shift collection is fast", .disabled(if: shouldSkipPerformanceTests))
    func testFilteringLargeShiftCollection() {
        // Given
        let allShifts = TestDataCollections.weekOfShifts() +
            (0..<1000).map { index in
                ScheduledShiftBuilder(
                    date: Date().addingTimeInterval(TimeInterval(index * 86400))
                ).build()
            }

        let startTime = Date()

        // When
        let _ = allShifts.filter { shift in
            Calendar.current.isDateInToday(shift.date)
        }

        // Then
        let elapsed = Date().timeIntervalSince(startTime)
        #expect(elapsed < 0.1, "Filtering 1000+ shifts should complete in under 0.1 seconds")
    }

    // MARK: - Collection Operations Performance

    @Test("Sorting large shift collection is fast", .disabled(if: shouldSkipPerformanceTests))
    func testSortingLargeShiftCollection() {
        // Given
        var shifts = (0..<1000).map { index in
            ScheduledShiftBuilder(
                date: Date().addingTimeInterval(TimeInterval(Int.random(in: 0..<(365*86400))))
            ).build()
        }
        let startTime = Date()

        // When
        shifts.sort { $0.date < $1.date }

        // Then
        let elapsed = Date().timeIntervalSince(startTime)
        #expect(elapsed < 0.1, "Sorting 1000 shifts should complete in under 0.1 seconds")
    }

    @Test("UUID generation performance", .disabled(if: shouldSkipPerformanceTests))
    func testUUIDGenerationPerformance() {
        // Given
        let generationCount = 100000
        let startTime = Date()

        // When
        let uuids = (0..<generationCount).map { _ in UUID() }

        // Then
        let elapsed = Date().timeIntervalSince(startTime)
        #expect(uuids.count == generationCount)
        #expect(elapsed < 0.5, "Generating 100000 UUIDs should complete in under 0.5 seconds")
    }

    // MARK: - Date Calculation Performance

    @Test("Date arithmetic operations are fast", .disabled(if: shouldSkipPerformanceTests))
    func testDateArithmeticPerformance() throws {
        // Given
        let calendar = Calendar.current
        let baseDate = Date()
        let iterations = 10000
        let startTime = Date()

        // When
        var computedDate = baseDate
        for _ in 0..<iterations {
            computedDate = try #require(calendar.date(byAdding: .day, value: 1, to: computedDate))
        }

        // Then
        let elapsed = Date().timeIntervalSince(startTime)
        #expect(elapsed < 0.5, "10000 date arithmetic operations should complete in under 0.5 seconds")
    }

    @Test("Finding date boundaries is fast", .disabled(if: shouldSkipPerformanceTests))
    func testDateBoundaryCalculationPerformance() {
        // Given
        let calendar = Calendar.current
        let testDates = (0..<1000).map { index in
            Date().addingTimeInterval(TimeInterval(index * 86400))
        }
        let startTime = Date()

        // When
        let startOfDays = testDates.map { date in
            calendar.startOfDay(for: date)
        }

        // Then
        let elapsed = Date().timeIntervalSince(startTime)
        #expect(startOfDays.count == 1000)
        #expect(elapsed < 0.1, "Computing start of day for 1000 dates should complete in under 0.1 seconds")
    }

    // MARK: - String Operations Performance

    @Test("Building large shift snapshot collection with descriptions", .disabled(if: shouldSkipPerformanceTests))
    func testBuildingLargeShiftSnapshotsWithText() {
        // Given
        let snapshotCount = 5000
        let longDescription = String(repeating: "A", count: 100)
        let startTime = Date()

        // When
        let snapshots = (0..<snapshotCount).map { index in
            ShiftSnapshotBuilder(
                shiftType: ShiftTypeBuilder(
                    description: longDescription + String(index)
                ).build()
            ).build()
        }

        // Then
        let elapsed = Date().timeIntervalSince(startTime)
        #expect(snapshots.count == snapshotCount)
        #expect(elapsed < 1.0, "Building 5000 shift snapshots with descriptions should complete in under 1 second")
    }

    // MARK: - Set/Dictionary Performance

    @Test("Converting large collection to set is fast", .disabled(if: shouldSkipPerformanceTests))
    func testConvertingToSetPerformance() {
        // Given
        let locations = (0..<5000).map { index in
            LocationBuilder(
                id: UUID(),
                name: "Location \(index)"
            ).build()
        }
        let startTime = Date()

        // When
        let locationIds = Set(locations.map { $0.id })

        // Then
        let elapsed = Date().timeIntervalSince(startTime)
        #expect(locationIds.count == 5000)
        #expect(elapsed < 0.1, "Converting 5000 items to set should complete in under 0.1 seconds")
    }

    @Test("Large dictionary lookup is fast", .disabled(if: shouldSkipPerformanceTests))
    func testDictionaryLookupPerformance() {
        // Given
        let locations = (0..<10000).map { index in
            LocationBuilder(id: UUID()).build()
        }
        let locationDictionary: [UUID: Location] = Dictionary(uniqueKeysWithValues: locations.map { ($0.id, $0) })
        let lookupIds = locations.prefix(1000).map { $0.id }
        let startTime = Date()

        // When
        let foundLocations = lookupIds.compactMap { id in
            locationDictionary[id]
        }

        // Then
        let elapsed = Date().timeIntervalSince(startTime)
        #expect(foundLocations.count == 1000)
        #expect(elapsed < 0.01, "1000 dictionary lookups should complete in under 0.01 seconds")
    }

    // MARK: - Encoding/Decoding Performance (if applicable)

    @Test("Change log entry creation with all fields is fast", .disabled(if: shouldSkipPerformanceTests))
    func testChangeLogEntryCreationPerformance() {
        // Given
        let entryCount = 10000
        let startTime = Date()

        // When
        let entries = (0..<entryCount).map { index in
            ChangeLogEntryBuilder(
                id: UUID(),
                timestamp: Date(),
                userId: UUID(),
                userDisplayName: "User \(index)",
                reason: "Change reason \(index)"
            ).build()
        }

        // Then
        let elapsed = Date().timeIntervalSince(startTime)
        #expect(entries.count == entryCount)
        #expect(elapsed < 1.0, "Creating 10000 change log entries should complete in under 1 second")
    }
}
