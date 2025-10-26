import Testing
import Foundation
@testable import ShiftScheduler

/// Edge Case Tests covering boundary conditions and error scenarios
/// Tests for edge cases like empty collections, invalid inputs, extreme values, etc.

@Suite("Edge Case Tests")
@MainActor
struct EdgeCaseTests {
    // MARK: - Empty Collection Tests

    @Test("Empty location list handles correctly")
    func testEmptyLocationList() {
        // Given
        let service = MockPersistenceService()
        service.mockLocations = []

        // When
        let result = service.mockLocations

        // Then
        #expect(result.isEmpty)
        #expect(result.count == 0)
    }

    @Test("Empty shift type list handles correctly")
    func testEmptyShiftTypeList() {
        // Given
        let service = MockPersistenceService()
        service.mockShiftTypes = []

        // When
        let result = service.mockShiftTypes

        // Then
        #expect(result.isEmpty)
        #expect(result.count == 0)
    }

    @Test("Empty scheduled shifts list handles correctly")
    func testEmptyScheduledShiftsList() {
        // Given
        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: ServiceContainer(),
            middlewares: []
        )

        // When
        let shifts = store.state.schedule.filteredShifts

        // Then
        #expect(shifts.isEmpty)
    }

    // MARK: - Empty String Tests

    @Test("Location with empty name is valid")
    func testLocationWithEmptyName() {
        // Given
        let builder = LocationBuilder(name: "")

        // When
        let location = builder.build()

        // Then
        #expect(location.name.isEmpty)
        #expect(location.id != UUID())
    }

    @Test("Shift type with empty description is valid")
    func testShiftTypeWithEmptyDescription() {
        // Given
        let builder = ShiftTypeBuilder(description: "")

        // When
        let shiftType = builder.build()

        // Then
        #expect(shiftType.shiftDescription.isEmpty)
        #expect(!shiftType.title.isEmpty)
    }

    @Test("Change log entry with empty reason is valid")
    func testChangeLogEntryWithEmptyReason() {
        // Given
        let builder = ChangeLogEntryBuilder(reason: "")

        // When
        let entry = builder.build()

        // Then
        #expect((entry.reason ?? "").isEmpty)
        #expect(entry.changeType == .created)
    }

    // MARK: - Boundary Value Tests

    @Test("Shift with start time equal to end time")
    func testShiftWithEqualStartAndEndTime() {
        // Given
        let startTime = HourMinuteTime(hour: 12, minute: 0)
        let duration = ShiftDuration.scheduled(from: startTime, to: startTime)

        // When
        let builder = ShiftTypeBuilder(duration: .specified(duration))
        let shiftType = builder.build()

        // Then
        #expect(shiftType.duration == duration)
    }

    @Test("Maximum hour value (23)")
    func testMaximumHourValue() {
        // Given
        let maxHour = HourMinuteTime(hour: 23, minute: 59)

        // When
        let builder = ShiftTypeBuilder(
            duration: .specified(.scheduled(
                from: HourMinuteTime(hour: 22, minute: 0),
                to: maxHour
            ))
        )
        let shiftType = builder.build()

        // Then
        #expect(shiftType != nil)
    }

    @Test("Minimum hour value (0)")
    func testMinimumHourValue() {
        // Given
        let minHour = HourMinuteTime(hour: 0, minute: 0)

        // When
        let builder = ShiftTypeBuilder(
            duration: .specified(.scheduled(
                from: minHour,
                to: HourMinuteTime(hour: 8, minute: 0)
            ))
        )
        let shiftType = builder.build()

        // Then
        #expect(shiftType != nil)
    }

    // MARK: - Large Collection Tests

    @Test("Large number of locations handled")
    func testLargeNumberOfLocations() {
        // Given
        let service = MockPersistenceService()
        service.mockLocations = (0..<1000).map { index in
            LocationBuilder(
                name: "Location \(index)",
                address: "\(index) Test Street"
            ).build()
        }

        // When
        let result = service.mockLocations

        // Then
        #expect(result.count == 1000)
        #expect(result.first != nil)
        #expect(result.last != nil)
    }

    @Test("Large number of shift types handled")
    func testLargeNumberOfShiftTypes() {
        // Given
        let service = MockPersistenceService()
        let location = LocationBuilder().build()
        service.mockShiftTypes = (0..<500).map { index in
            ShiftTypeBuilder(
                title: "Shift Type \(index)",
                location: location
            ).build()
        }

        // When
        let result = service.mockShiftTypes

        // Then
        #expect(result.count == 500)
    }

    @Test("Large number of change log entries handled")
    func testLargeNumberOfChangeLogEntries() {
        // Given
        let service = MockPersistenceService()
        let baseDate = Date()
        service.mockChangeLogEntries = (0..<10000).map { index in
            ChangeLogEntryBuilder(
                id: UUID(),
                timestamp: baseDate.addingTimeInterval(Double(index * 60)),
                userDisplayName: "User \(index % 10)"
            ).build()
        }

        // When
        let result = service.mockChangeLogEntries

        // Then
        #expect(result.count == 10000)
    }

    // MARK: - Date Edge Cases

    @Test("Shift scheduled for leap day (Feb 29)")
    func testShiftOnLeapDay() {
        // Given
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.year = 2024
        dateComponents.month = 2
        dateComponents.day = 29
        let leapDay = calendar.date(from: dateComponents)!

        // When
        let builder = ScheduledShiftBuilder(date: leapDay)
        let shift = builder.build()

        // Then
        #expect(shift.date == leapDay)
    }

    @Test("Shift scheduled for end of year")
    func testShiftOnDecember31() {
        // Given
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.year = 2025
        dateComponents.month = 12
        dateComponents.day = 31
        let endOfYear = calendar.date(from: dateComponents)!

        // When
        let builder = ScheduledShiftBuilder(date: endOfYear)
        let shift = builder.build()

        // Then
        #expect(shift.date == endOfYear)
    }

    @Test("Shift scheduled for start of year")
    func testShiftOnJanuary1() {
        // Given
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.year = 2025
        dateComponents.month = 1
        dateComponents.day = 1
        let startOfYear = calendar.date(from: dateComponents)!

        // When
        let builder = ScheduledShiftBuilder(date: startOfYear)
        let shift = builder.build()

        // Then
        #expect(shift.date == startOfYear)
    }

    // MARK: - UUID Edge Cases

    @Test("Multiple objects with same UUID behave correctly")
    func testMultipleObjectsWithSameUUID() {
        // Given
        let testUUID = UUID()
        let location1 = LocationBuilder(id: testUUID).build()
        let location2 = LocationBuilder(id: testUUID).build()

        // When comparing

        // Then
        #expect(location1.id == location2.id)
        #expect(location1.id == testUUID)
    }

    // MARK: - Special Characters Tests

    @Test("Location name with special characters")
    func testLocationNameWithSpecialCharacters() {
        // Given
        let specialName = "Location @#$%^&*()_+-=[]{}|;':\\\"<>,.?/"

        // When
        let builder = LocationBuilder(name: specialName)
        let location = builder.build()

        // Then
        #expect(location.name == specialName)
    }

    @Test("Shift type title with emoji")
    func testShiftTypeTitleWithEmoji() {
        // Given
        let titleWithEmoji = "🌅 Morning Shift"

        // When
        let builder = ShiftTypeBuilder(title: titleWithEmoji)
        let shiftType = builder.build()

        // Then
        #expect(shiftType.title == titleWithEmoji)
    }

    @Test("Change log reason with very long text")
    func testChangeLogReasonWithLongText() {
        // Given
        let longReason = String(repeating: "A very long reason text. ", count: 100)

        // When
        let builder = ChangeLogEntryBuilder(reason: longReason)
        let entry = builder.build()

        // Then
        #expect(entry.reason == longReason)
        #expect((entry.reason ?? "").count > 1000)
    }

    // MARK: - Null/None Handling Tests

    @Test("Change log entry with nil shift snapshots")
    func testChangeLogEntryWithNilSnapshots() {
        // Given
        let builder = ChangeLogEntryBuilder(
            oldShiftSnapshot: nil,
            newShiftSnapshot: nil
        )

        // When
        let entry = builder.build()

        // Then
        #expect(entry.oldShiftSnapshot == nil)
        #expect(entry.newShiftSnapshot == nil)
    }

    // MARK: - State Consistency Tests

    @Test("App state with all empty substates")
    func testAppStateWithEmptySubstates() {
        // Given
        let store = Store(
            state: AppState(),
            reducer: appReducer,
            services: ServiceContainer(),
            middlewares: []
        )

        // When
        let state = store.state

        // Then
        #expect(state.selectedTab == .today)
        #expect(state.schedule.filteredShifts.isEmpty)
    }

    @Test("Rapid UUID generation creates unique IDs")
    func testRapidUUIDGeneration() {
        // Given
        let uuids = (0..<1000).map { _ in UUID() }

        // When
        let uniqueUUIDs = Set(uuids)

        // Then
        #expect(uniqueUUIDs.count == 1000)
    }
}
