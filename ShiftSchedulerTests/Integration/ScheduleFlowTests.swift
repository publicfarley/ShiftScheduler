import Foundation
import Testing
import ComposableArchitecture
@testable import ShiftScheduler

@Suite("ScheduleFlow Integration Tests")
struct ScheduleFlowTests {
    // MARK: - Test Helpers

    func makeLocation(name: String = "Office", address: String = "123 Main St") -> Location {
        Location(name: name, address: address)
    }

    func makeShiftType(
        symbol: String = "☀️",
        title: String = "Morning Shift",
        duration: ShiftDuration = .allDay,
        location: Location? = nil,
        id: UUID = UUID()
    ) -> ShiftType {
        let loc = location ?? makeLocation()
        return ShiftType(
            id: id,
            symbol: symbol,
            duration: duration,
            title: title,
            description: "Test shift type",
            location: loc
        )
    }

    func makeScheduledShift(
        eventIdentifier: String = "event-001",
        shiftType: ShiftType? = nil,
        date: Date? = nil
    ) -> ScheduledShift {
        ScheduledShift(
            id: UUID(),
            eventIdentifier: eventIdentifier,
            shiftType: shiftType ?? makeShiftType(),
            date: date ?? Calendar.current.startOfDay(for: Date())
        )
    }

    // MARK: - Location & Shift Type Integration

    @Test("Locations from LocationsFeature used in ShiftTypesFeature")
    func testLocationCreationAppearInShiftTypeForm() async {
        let location = makeLocation(name: "Downtown Office", address: "456 Oak St")

        // Step 1: Create location in LocationsFeature
        var locationsState = LocationsFeature.State()
        locationsState.locations.append(location)

        #expect(locationsState.locations.count == 1)
        #expect(locationsState.locations.first?.name == "Downtown Office")

        // Step 2: Create shift type using that location
        let newShiftType = makeShiftType(
            symbol: "O",
            title: "Downtown Shift",
            location: location
        )

        // Step 3: Add to ShiftTypesFeature
        var shiftTypesState = ShiftTypesFeature.State()
        shiftTypesState.shiftTypes[id: newShiftType.id] = newShiftType

        // Verify the shift type contains the location
        #expect(shiftTypesState.shiftTypes[id: newShiftType.id]?.location.name == "Downtown Office")
    }

    // MARK: - Schedule Search & Filter

    @Test("ScheduleFeature search filters shifts by shift type title")
    func testScheduleSearchFiltersByTitle() async {
        let location = makeLocation()

        let morningShift = makeShiftType(
            symbol: "M",
            title: "Morning Shift",
            location: location
        )
        let afternoonShift = makeShiftType(
            symbol: "A",
            title: "Afternoon Shift",
            location: location
        )

        let today = Calendar.current.startOfDay(for: Date())

        let shifts = [
            makeScheduledShift(
                eventIdentifier: "m-1",
                shiftType: morningShift,
                date: today
            ),
            makeScheduledShift(
                eventIdentifier: "a-1",
                shiftType: afternoonShift,
                date: today
            ),
            makeScheduledShift(
                eventIdentifier: "m-2",
                shiftType: morningShift,
                date: today
            )
        ]

        var scheduleState = ScheduleFeature.State(
            scheduledShifts: shifts,
            selectedDate: today,
            searchText: ""
        )

        // Search for "Morning"
        scheduleState.searchText = "Morning"

        // Verify filtered results contain only morning shifts
        #expect(scheduleState.filteredShifts.count == 2)
        #expect(scheduleState.filteredShifts.allSatisfy { shift in
            shift.shiftType?.title.contains("Morning") ?? false
        })

        // Search for "Afternoon"
        scheduleState.searchText = "Afternoon"

        #expect(scheduleState.filteredShifts.count == 1)
        #expect(scheduleState.filteredShifts.first?.shiftType?.title.contains("Afternoon") ?? false)

        // Clear search
        scheduleState.searchText = ""

        #expect(scheduleState.filteredShifts.count == 3)
    }

    @Test("ShiftTypesFeature search filters by title, symbol, and location")
    func testShiftTypeSearchFilters() async {
        let officeLocation = makeLocation(name: "Office")
        let remoteLocation = makeLocation(name: "Remote")
        let hybridLocation = makeLocation(name: "Hybrid - Office/Remote")

        let shifts = [
            makeShiftType(
                symbol: "☀️",
                title: "Morning Shift",
                location: officeLocation
            ),
            makeShiftType(
                symbol: "🌤",
                title: "Afternoon Shift",
                location: remoteLocation
            ),
            makeShiftType(
                symbol: "🌙",
                title: "Evening Shift",
                location: officeLocation
            ),
            makeShiftType(
                symbol: "⭐",
                title: "Office Evening",
                location: officeLocation
            )
        ]

        var shiftTypesState = ShiftTypesFeature.State(
            shiftTypes: IdentifiedArray(uniqueElements: shifts),
            searchText: ""
        )

        // Search by title
        shiftTypesState.searchText = "Morning"

        #expect(shiftTypesState.filteredShiftTypes.count == 1)
        #expect(shiftTypesState.filteredShiftTypes.first?.title == "Morning Shift")

        // Search by symbol
        shiftTypesState.searchText = "🌤"

        #expect(shiftTypesState.filteredShiftTypes.count == 1)
        #expect(shiftTypesState.filteredShiftTypes.first?.symbol == "🌤")

        // Search by location
        shiftTypesState.searchText = "Remote"

        #expect(shiftTypesState.filteredShiftTypes.count == 1)
        #expect(shiftTypesState.filteredShiftTypes.first?.location.name == "Remote")

        // Search for Office should return 3 results
        shiftTypesState.searchText = "Office"

        #expect(shiftTypesState.filteredShiftTypes.count == 3)
    }

    // MARK: - Date Selection

    @Test("ScheduleFeature filters shifts for selected date")
    func testDateSelectionLoadsShiftsForDate() async {
        let location = makeLocation()
        let shiftType = makeShiftType(location: location)

        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let nextDay = Calendar.current.date(byAdding: .day, value: 2, to: today)!

        let shifts = [
            makeScheduledShift(
                eventIdentifier: "today-1",
                shiftType: shiftType,
                date: today
            ),
            makeScheduledShift(
                eventIdentifier: "today-2",
                shiftType: shiftType,
                date: today
            ),
            makeScheduledShift(
                eventIdentifier: "tomorrow-1",
                shiftType: shiftType,
                date: tomorrow
            ),
            makeScheduledShift(
                eventIdentifier: "nextday-1",
                shiftType: shiftType,
                date: nextDay
            )
        ]

        var scheduleState = ScheduleFeature.State(
            scheduledShifts: shifts,
            selectedDate: today
        )

        // Verify today's shifts are shown
        #expect(scheduleState.shiftsForSelectedDate.count == 2)

        // Change date to tomorrow
        scheduleState.selectedDate = tomorrow

        // Verify tomorrow's shifts are shown
        #expect(scheduleState.shiftsForSelectedDate.count == 1)
        #expect(scheduleState.shiftsForSelectedDate.first?.eventIdentifier == "tomorrow-1")

        // Change to next day
        scheduleState.selectedDate = nextDay

        #expect(scheduleState.shiftsForSelectedDate.count == 1)
        #expect(scheduleState.shiftsForSelectedDate.first?.eventIdentifier == "nextday-1")
    }

    // MARK: - Shift State Management

    @Test("ScheduleFeature manages undo/redo state")
    func testScheduleShiftHistory() async {
        let oldType = makeShiftType(symbol: "M", title: "Morning")
        let newType = makeShiftType(symbol: "A", title: "Afternoon")
        let today = Calendar.current.startOfDay(for: Date())

        let shift = makeScheduledShift(
            eventIdentifier: "switch-test",
            shiftType: oldType,
            date: today
        )

        let operation = ShiftSwitchOperation(
            eventIdentifier: shift.eventIdentifier,
            scheduledDate: today,
            oldShiftType: oldType,
            newShiftType: newType,
            changeLogEntryId: UUID(),
            reason: "Requested via schedule"
        )

        var scheduleState = ScheduleFeature.State(
            scheduledShifts: [shift],
            selectedDate: today,
            undoStack: [operation],
            redoStack: []
        )

        // Verify undo/redo availability
        #expect(scheduleState.canUndo == true)
        #expect(scheduleState.canRedo == false)

        // Simulate undo
        scheduleState.undoStack.removeAll()
        scheduleState.redoStack.append(operation)

        #expect(scheduleState.canUndo == false)
        #expect(scheduleState.canRedo == true)
    }

    // MARK: - Multiple Locations

    @Test("Multiple locations are preserved in shift types")
    func testMultipleLocationsInShiftTypes() async {
        let officeLocation = makeLocation(name: "Downtown Office")
        let remoteLocation = makeLocation(name: "Remote Home")
        let hybridLocation = makeLocation(name: "Hybrid - Office/Remote")

        let shifts = [
            makeShiftType(symbol: "O", title: "Office Shift", location: officeLocation),
            makeShiftType(symbol: "R", title: "Remote Shift", location: remoteLocation),
            makeShiftType(symbol: "H", title: "Hybrid Shift", location: hybridLocation),
            makeShiftType(symbol: "O2", title: "Office Evening", location: officeLocation)
        ]

        var shiftTypesState = ShiftTypesFeature.State(
            shiftTypes: IdentifiedArray(uniqueElements: shifts)
        )

        // Verify all shift types are present
        #expect(shiftTypesState.shiftTypes.count == 4)

        // Verify locations are preserved
        let officeShifts = shiftTypesState.shiftTypes.filter { $0.location.name == "Downtown Office" }
        #expect(officeShifts.count == 2)

        let remoteShifts = shiftTypesState.shiftTypes.filter { $0.location.name == "Remote Home" }
        #expect(remoteShifts.count == 1)
    }

    // MARK: - Combined Feature Integration

    @Test("Search and date navigation work together")
    func testSearchAndDateNavigationIntegration() async {
        let location = makeLocation()

        let morningType = makeShiftType(
            symbol: "☀️",
            title: "Morning Shift",
            location: location
        )
        let afternoonType = makeShiftType(
            symbol: "🌤",
            title: "Afternoon Shift",
            location: location
        )

        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        let shifts = [
            makeScheduledShift(eventIdentifier: "today-m", shiftType: morningType, date: today),
            makeScheduledShift(eventIdentifier: "today-a", shiftType: afternoonType, date: today),
            makeScheduledShift(eventIdentifier: "tomorrow-m", shiftType: morningType, date: tomorrow)
        ]

        var scheduleState = ScheduleFeature.State(
            scheduledShifts: shifts,
            selectedDate: today,
            searchText: ""
        )

        // Start with all today's shifts visible
        #expect(scheduleState.shiftsForSelectedDate.count == 2)
        #expect(scheduleState.filteredShifts.count == 2)

        // Search for "Morning"
        scheduleState.searchText = "Morning"

        #expect(scheduleState.filteredShifts.count == 1)
        #expect(scheduleState.filteredShifts.first?.eventIdentifier == "today-m")

        // Switch to tomorrow
        scheduleState.selectedDate = tomorrow

        // Should still have the search active and show tomorrow's morning shift
        #expect(scheduleState.shiftsForSelectedDate.count == 1)
        #expect(scheduleState.filteredShifts.count == 1)
        #expect(scheduleState.filteredShifts.first?.eventIdentifier == "tomorrow-m")

        // Clear search
        scheduleState.searchText = ""

        // Back to showing all of tomorrow's shifts
        #expect(scheduleState.filteredShifts.count == 1)
    }
}
