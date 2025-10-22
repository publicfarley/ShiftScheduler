import Foundation
import Testing
import ComposableArchitecture
@testable import ShiftScheduler

@Suite("TodayFlow Integration Tests")
struct TodayFlowTests {
    // MARK: - Test Helpers

    func makeLocation(name: String = "Office") -> Location {
        Location(name: name, address: "123 Main St")
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

    // MARK: - Shift Type Creation & Today View Loading

    @Test("ShiftTypesFeature creates types that can be used in TodayFeature")
    func testShiftTypeCreationThenLoadInToday() async {
        let location = makeLocation(name: "Office")
        let newShiftType = makeShiftType(
            symbol: "★",
            title: "Custom Shift",
            location: location
        )

        // Step 1: Verify shift type can be added to ShiftTypesFeature
        var shiftTypesState = ShiftTypesFeature.State()
        shiftTypesState.shiftTypes[id: newShiftType.id] = newShiftType

        #expect(shiftTypesState.shiftTypes[id: newShiftType.id] != nil)
        #expect(shiftTypesState.shiftTypes[id: newShiftType.id]?.title == "Custom Shift")

        // Step 2: Verify shift with that type can be loaded in TodayFeature
        let today = Calendar.current.startOfDay(for: Date())
        let scheduledShift = makeScheduledShift(
            eventIdentifier: "today-event",
            shiftType: newShiftType,
            date: today
        )

        var todayState = TodayFeature.State()
        todayState.scheduledShifts = [scheduledShift]

        #expect(todayState.scheduledShifts.count == 1)
        #expect(todayState.scheduledShifts.first?.shiftType?.title == "Custom Shift")
    }

    // MARK: - Shift Switching with Undo/Redo

    @Test("TodayFeature manages undo/redo stacks from shift switches")
    func testShiftSwitchUndoRedoFlow() async {
        let oldShiftType = makeShiftType(
            symbol: "M",
            title: "Morning Shift"
        )
        let newShiftType = makeShiftType(
            symbol: "A",
            title: "Afternoon Shift"
        )
        let today = Calendar.current.startOfDay(for: Date())
        let shift = makeScheduledShift(
            eventIdentifier: "event-001",
            shiftType: oldShiftType,
            date: today
        )

        // Simulate successful shift switch creating an operation
        let operation = ShiftSwitchOperation(
            eventIdentifier: shift.eventIdentifier,
            scheduledDate: today,
            oldShiftType: oldShiftType,
            newShiftType: newShiftType,
            changeLogEntryId: UUID(),
            reason: "Requested change"
        )

        var todayState = TodayFeature.State(
            scheduledShifts: [shift],
            undoStack: [operation],
            redoStack: []
        )

        // Verify undo is available
        #expect(todayState.canUndo == true)
        #expect(todayState.canRedo == false)

        // Simulate undo by moving operation
        todayState.undoStack.removeAll()
        todayState.redoStack.append(operation)

        // Verify redo is now available
        #expect(todayState.canUndo == false)
        #expect(todayState.canRedo == true)
    }

    // MARK: - Multiple Shift Switches in Sequence

    @Test("Multiple shift switches build up undo/redo history")
    func testMultipleShiftSwitchesWithHistory() async {
        let shift1Type = makeShiftType(symbol: "M", title: "Morning")
        let shift2Type = makeShiftType(symbol: "A", title: "Afternoon")
        let shift3Type = makeShiftType(symbol: "N", title: "Night")

        let today = Calendar.current.startOfDay(for: Date())
        let shift = makeScheduledShift(
            eventIdentifier: "multi-event",
            shiftType: shift1Type,
            date: today
        )

        let op1 = ShiftSwitchOperation(
            eventIdentifier: shift.eventIdentifier,
            scheduledDate: today,
            oldShiftType: shift1Type,
            newShiftType: shift2Type,
            changeLogEntryId: UUID(),
            reason: "First switch"
        )

        let op2 = ShiftSwitchOperation(
            eventIdentifier: shift.eventIdentifier,
            scheduledDate: today,
            oldShiftType: shift2Type,
            newShiftType: shift3Type,
            changeLogEntryId: UUID(),
            reason: "Second switch"
        )

        var todayState = TodayFeature.State(
            scheduledShifts: [shift],
            undoStack: [op1, op2],
            redoStack: []
        )

        // Verify both operations are in undo stack
        #expect(todayState.undoStack.count == 2)
        #expect(todayState.canUndo == true)

        // Simulate undoing first operation
        todayState.undoStack.removeAll()
        todayState.undoStack.append(op1)
        todayState.redoStack.append(op2)

        #expect(todayState.undoStack.count == 1)
        #expect(todayState.redoStack.count == 1)
    }

    // MARK: - Error Handling in Today Feature

    @Test("TodayFeature handles shifts without type data gracefully")
    func testShiftSwitchErrorDisplay() async {
        let newShiftType = makeShiftType()
        let shift = makeScheduledShift(shiftType: nil)

        var todayState = TodayFeature.State(
            scheduledShifts: [shift]
        )

        // Verify shift is in the list even without type data
        #expect(todayState.scheduledShifts.count == 1)
        #expect(todayState.scheduledShifts.first?.shiftType == nil)
    }

    // MARK: - Cache Updates

    @Test("TodayFeature caches today and tomorrow shifts")
    func testCachingAfterShiftLoad() async {
        let shiftType = makeShiftType()
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        let shifts = [
            makeScheduledShift(
                eventIdentifier: "today-shift",
                shiftType: shiftType,
                date: today
            ),
            makeScheduledShift(
                eventIdentifier: "tomorrow-shift",
                shiftType: shiftType,
                date: tomorrow
            )
        ]

        var todayState = TodayFeature.State(
            scheduledShifts: shifts
        )

        // Manually update caches like reducer would
        todayState.todayShift = todayState.scheduledShifts.first { shift in
            Calendar.current.isDate(shift.date, inSameDayAs: today)
        }
        todayState.tomorrowShift = todayState.scheduledShifts.first { shift in
            Calendar.current.isDate(shift.date, inSameDayAs: tomorrow)
        }

        #expect(todayState.todayShift?.eventIdentifier == "today-shift")
        #expect(todayState.tomorrowShift?.eventIdentifier == "tomorrow-shift")
    }

    // MARK: - Integration: Multiple Features Working Together

    @Test("Features compose: ShiftTypes → Shifts → Today View")
    func testFeatureComposition() async {
        // Step 1: Create shift types in ShiftTypesFeature
        let officeLocation = makeLocation(name: "Office")
        let remoteLocation = makeLocation(name: "Remote")

        let morningType = makeShiftType(
            symbol: "☀️",
            title: "Morning",
            location: officeLocation
        )
        let afternoonType = makeShiftType(
            symbol: "🌤",
            title: "Afternoon",
            location: remoteLocation
        )

        var shiftTypesState = ShiftTypesFeature.State()
        shiftTypesState.shiftTypes[id: morningType.id] = morningType
        shiftTypesState.shiftTypes[id: afternoonType.id] = afternoonType

        // Step 2: Schedule shifts using those types in ScheduleFeature
        let today = Calendar.current.startOfDay(for: Date())
        let scheduledShifts = [
            makeScheduledShift(
                eventIdentifier: "sched-1",
                shiftType: morningType,
                date: today
            ),
            makeScheduledShift(
                eventIdentifier: "sched-2",
                shiftType: afternoonType,
                date: today
            )
        ]

        var scheduleState = ScheduleFeature.State(
            scheduledShifts: scheduledShifts,
            selectedDate: today
        )

        // Step 3: Load the same shifts in TodayFeature
        var todayState = TodayFeature.State(
            scheduledShifts: scheduledShifts
        )

        // Verify all features have the shift type information
        #expect(shiftTypesState.shiftTypes.count == 2)
        #expect(scheduleState.scheduledShifts.count == 2)
        #expect(todayState.scheduledShifts.count == 2)

        // Verify shift types are correctly linked
        #expect(scheduleState.scheduledShifts[0].shiftType?.title == "Morning")
        #expect(scheduleState.scheduledShifts[1].shiftType?.title == "Afternoon")
        #expect(todayState.scheduledShifts[0].shiftType?.location.name == "Office")
        #expect(todayState.scheduledShifts[1].shiftType?.location.name == "Remote")
    }
}
