import Foundation
import Testing
import ComposableArchitecture
@testable import ShiftScheduler

@MainActor
@Suite("TodayFeature Tests")
struct TodayFeatureTests {
    // MARK: - Test Helpers

    func makeShiftType(symbol: String = "☀️", duration: ShiftDuration = .allDay) -> ShiftType {
        let location = Location(name: "Office", address: "123 Main St")
        return ShiftType(
            symbol: symbol,
            duration: duration,
            title: "Test Shift",
            description: "Test description",
            location: location
        )
    }

    // MARK: - Initial Load Tests

    @Test("loadShifts successfully fetches shifts from calendar")
    func testLoadShiftsSuccess() async {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let shiftType = makeShiftType()

        let shiftsData = [
            ScheduledShiftData(eventIdentifier: "event-001", shiftTypeId: shiftType.id, date: today, title: shiftType.title, location: shiftType.location.name),
            ScheduledShiftData(eventIdentifier: "event-002", shiftTypeId: shiftType.id, date: tomorrow, title: shiftType.title, location: shiftType.location.name)
        ]

        let mockCalendarClient = CalendarClient.testValue
        let mockShiftSwitchClient = ShiftSwitchClient.testValue

        let store = TestStore(
            initialState: TodayFeature.State()
        ) {
            TodayFeature()
        } withDependencies: {
            $0.calendarClient = mockCalendarClient
            $0.shiftSwitchClient = mockShiftSwitchClient
        }

        await store.send(.loadShifts) { state in
            state.isLoading = true
        }

        let expectedShifts = shiftsData.map { data in
            ScheduledShift(
                id: UUID(),
                eventIdentifier: data.eventIdentifier,
                shiftType: nil,
                date: data.date
            )
        }

        await store.receive(.shiftsLoaded(.success(expectedShifts))) { state in
            state.isLoading = false
            state.errorMessage == nil
        }

        await store.receive(.updateCachedShifts)
    }

    @Test("loadShifts handles errors gracefully")
    func testLoadShiftsFailure() async {
        enum MockError: Error {
            case fetchFailed
        }

        let store = TestStore(
            initialState: TodayFeature.State()
        ) {
            TodayFeature()
        } withDependencies: {
            // Use test value for calendar client
            $0.calendarClient.fetchShiftsInRange = { _, _ in
                throw MockError.fetchFailed
            }
        }

        await store.send(.task) { state in
            state.isLoading = true
        }

        // The reducer will attempt to load shifts and encounter the error
        // which will be caught and stored in errorMessage
    }

    // MARK: - Shift Switch Tests

    @Test("switchShiftTapped opens the sheet for selection")
    func testSwitchShiftTapped() async {
        let today = Calendar.current.startOfDay(for: Date())
        let shiftType = makeShiftType()
        let shift = ScheduledShift(
            id: UUID(),
            eventIdentifier: "event-001",
            shiftType: shiftType,
            date: today
        )

        let mockCalendarClient = CalendarClient.testValue
        let mockShiftSwitchClient = ShiftSwitchClient.testValue

        let store = TestStore(
            initialState: TodayFeature.State(
                scheduledShifts: [shift]
            )
        ) {
            TodayFeature()
        } withDependencies: {
            $0.calendarClient = mockCalendarClient
            $0.shiftSwitchClient = mockShiftSwitchClient
        }

        await store.send(.switchShiftTapped(shift)) { state in
            state.selectedShift = shift
            state.showSwitchShiftSheet = true
        }
    }

    @Test("performSwitchShift successfully switches shift")
    func testSwitchShiftSuccess() async {
        let oldShiftType = makeShiftType(symbol: "M1", duration: .scheduled(
            from: HourMinuteTime(hour: 9, minute: 0),
            to: HourMinuteTime(hour: 17, minute: 0)
        ))

        let newShiftType = makeShiftType(symbol: "A1", duration: .scheduled(
            from: HourMinuteTime(hour: 13, minute: 0),
            to: HourMinuteTime(hour: 21, minute: 0)
        ))

        let today = Calendar.current.startOfDay(for: Date())
        let shift = ScheduledShift(
            id: UUID(),
            eventIdentifier: "event-001",
            shiftType: oldShiftType,
            date: today
        )

        let mockCalendarClient = CalendarClient.testValue
        let mockShiftSwitchClient = ShiftSwitchClient.testValue

        let store = TestStore(
            initialState: TodayFeature.State(
                scheduledShifts: [shift]
            )
        ) {
            TodayFeature()
        } withDependencies: {
            $0.calendarClient = mockCalendarClient
            $0.shiftSwitchClient = mockShiftSwitchClient
        }

        await store.send(.performSwitchShift(shift, newShiftType, "Requested switch")) { state in
            state.isLoading = true
        }

        await store.receive(.shiftSwitched(.success(()))) { state in
            state.isLoading = false
            state.showSwitchShiftSheet = false
            state.selectedShift == nil
            state.toastMessage != nil
        }

        await store.receive(.loadShifts)
        await store.receive(.updateUndoRedoStates)
    }

    @Test("performSwitchShift handles errors when old shift type is missing")
    func testSwitchShiftWithoutOldType() async {
        let newShiftType = makeShiftType()
        let today = Calendar.current.startOfDay(for: Date())
        let shift = ScheduledShift(
            id: UUID(),
            eventIdentifier: "event-001",
            shiftType: nil,
            date: today
        )

        let mockCalendarClient = CalendarClient.testValue
        let mockShiftSwitchClient = ShiftSwitchClient.testValue

        let store = TestStore(
            initialState: TodayFeature.State(
                scheduledShifts: [shift]
            )
        ) {
            TodayFeature()
        } withDependencies: {
            $0.calendarClient = mockCalendarClient
            $0.shiftSwitchClient = mockShiftSwitchClient
        }

        await store.send(.performSwitchShift(shift, newShiftType, nil)) { state in
            state.toastMessage != nil
            state.isLoading == false
        }
    }

    // MARK: - Undo/Redo Tests

    @Test("undo operation moves item from undo stack to redo stack")
    func testUndoOperation() async {
        let shiftType = makeShiftType()
        let operation = ShiftSwitchOperation(
            eventIdentifier: "event-001",
            scheduledDate: Date(),
            oldShiftType: shiftType,
            newShiftType: shiftType,
            changeLogEntryId: UUID(),
            reason: "Test undo"
        )

        let mockCalendarClient = CalendarClient.testValue
        let mockShiftSwitchClient = ShiftSwitchClient.testValue

        let store = TestStore(
            initialState: TodayFeature.State(
                undoStack: [operation],
                redoStack: []
            )
        ) {
            TodayFeature()
        } withDependencies: {
            $0.calendarClient = mockCalendarClient
            $0.shiftSwitchClient = mockShiftSwitchClient
        }

        await store.send(.undo) { state in
            state.isLoading = true
        }

        await store.receive(.undoCompleted(.success(()))) { state in
            state.isLoading = false
            state.undoStack.count == 0
            state.redoStack.count == 1
            state.toastMessage != nil
        }

        await store.receive(.loadShifts)
        await store.receive(.updateUndoRedoStates)
    }

    @Test("undo fails gracefully when stack is empty")
    func testUndoWithEmptyStack() async {
        let mockCalendarClient = CalendarClient.testValue
        let mockShiftSwitchClient = ShiftSwitchClient.testValue

        let store = TestStore(
            initialState: TodayFeature.State(
                undoStack: [],
                redoStack: []
            )
        ) {
            TodayFeature()
        } withDependencies: {
            $0.calendarClient = mockCalendarClient
            $0.shiftSwitchClient = mockShiftSwitchClient
        }

        await store.send(.undo) { state in
            state.toastMessage != nil
            state.isLoading == false
        }
    }

    @Test("redo operation moves item from redo stack to undo stack")
    func testRedoOperation() async {
        let shiftType = makeShiftType()
        let operation = ShiftSwitchOperation(
            eventIdentifier: "event-001",
            scheduledDate: Date(),
            oldShiftType: shiftType,
            newShiftType: shiftType,
            changeLogEntryId: UUID(),
            reason: "Test redo"
        )

        let mockCalendarClient = CalendarClient.testValue
        let mockShiftSwitchClient = ShiftSwitchClient.testValue

        let store = TestStore(
            initialState: TodayFeature.State(
                undoStack: [],
                redoStack: [operation]
            )
        ) {
            TodayFeature()
        } withDependencies: {
            $0.calendarClient = mockCalendarClient
            $0.shiftSwitchClient = mockShiftSwitchClient
        }

        await store.send(.redo) { state in
            state.isLoading = true
        }

        await store.receive(.redoCompleted(.success(()))) { state in
            state.isLoading = false
            state.redoStack.count == 0
            state.undoStack.count == 1
            state.toastMessage != nil
        }

        await store.receive(.loadShifts)
        await store.receive(.updateUndoRedoStates)
    }

    @Test("redo fails gracefully when stack is empty")
    func testRedoWithEmptyStack() async {
        let mockCalendarClient = CalendarClient.testValue
        let mockShiftSwitchClient = ShiftSwitchClient.testValue

        let store = TestStore(
            initialState: TodayFeature.State(
                undoStack: [],
                redoStack: []
            )
        ) {
            TodayFeature()
        } withDependencies: {
            $0.calendarClient = mockCalendarClient
            $0.shiftSwitchClient = mockShiftSwitchClient
        }

        await store.send(.redo) { state in
            state.toastMessage != nil
            state.isLoading == false
        }
    }

    // MARK: - Caching Tests

    @Test("updateCachedShifts correctly identifies today and tomorrow shifts")
    func testCachedShiftsUpdated() async {
        let shiftType = makeShiftType()
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: today)!

        let shifts = [
            ScheduledShift(id: UUID(), eventIdentifier: "event-001", shiftType: shiftType, date: today),
            ScheduledShift(id: UUID(), eventIdentifier: "event-002", shiftType: shiftType, date: tomorrow),
            ScheduledShift(id: UUID(), eventIdentifier: "event-003", shiftType: shiftType, date: nextWeek)
        ]

        let mockCalendarClient = CalendarClient.testValue
        let mockShiftSwitchClient = ShiftSwitchClient.testValue

        let store = TestStore(
            initialState: TodayFeature.State(
                scheduledShifts: shifts
            )
        ) {
            TodayFeature()
        } withDependencies: {
            $0.calendarClient = mockCalendarClient
            $0.shiftSwitchClient = mockShiftSwitchClient
        }

        await store.send(.updateCachedShifts) { state in
            state.todayShift != nil
            state.tomorrowShift != nil
            state.thisWeekShiftsCount == 2
            state.completedThisWeek == 0
        }
    }

    @Test("updateCachedShifts with empty shifts")
    func testCachedShiftsWithEmptyShifts() async {
        let mockCalendarClient = CalendarClient.testValue
        let mockShiftSwitchClient = ShiftSwitchClient.testValue

        let store = TestStore(
            initialState: TodayFeature.State(
                scheduledShifts: []
            )
        ) {
            TodayFeature()
        } withDependencies: {
            $0.calendarClient = mockCalendarClient
            $0.shiftSwitchClient = mockShiftSwitchClient
        }

        await store.send(.updateCachedShifts) { state in
            state.todayShift == nil
            state.tomorrowShift == nil
            state.thisWeekShiftsCount == 0
            state.completedThisWeek == 0
        }
    }

    // MARK: - UI State Tests

    @Test("toastMessageCleared clears toast notification")
    func testToastMessageCleared() async {
        let mockCalendarClient = CalendarClient.testValue
        let mockShiftSwitchClient = ShiftSwitchClient.testValue

        let store = TestStore(
            initialState: TodayFeature.State(
                toastMessage: .success("Test message")
            )
        ) {
            TodayFeature()
        } withDependencies: {
            $0.calendarClient = mockCalendarClient
            $0.shiftSwitchClient = mockShiftSwitchClient
        }

        await store.send(.toastMessageCleared) { state in
            state.toastMessage == nil
        }
    }

    @Test("switchShiftSheetDismissed clears selection and hides sheet")
    func testSwitchShiftSheetDismissed() async {
        let shiftType = makeShiftType()
        let shift = ScheduledShift(
            id: UUID(),
            eventIdentifier: "event-001",
            shiftType: shiftType,
            date: Date()
        )

        let mockCalendarClient = CalendarClient.testValue
        let mockShiftSwitchClient = ShiftSwitchClient.testValue

        let store = TestStore(
            initialState: TodayFeature.State(
                showSwitchShiftSheet: true,
                selectedShift: shift
            )
        ) {
            TodayFeature()
        } withDependencies: {
            $0.calendarClient = mockCalendarClient
            $0.shiftSwitchClient = mockShiftSwitchClient
        }

        await store.send(.switchShiftSheetDismissed) { state in
            state.showSwitchShiftSheet = false
            state.selectedShift == nil
        }
    }

    @Test("updateUndoRedoStates correctly reflects undo/redo availability")
    func testUpdateUndoRedoStates() async {
        let shiftType = makeShiftType()
        let operation = ShiftSwitchOperation(
            eventIdentifier: "event-001",
            scheduledDate: Date(),
            oldShiftType: shiftType,
            newShiftType: shiftType,
            changeLogEntryId: UUID(),
            reason: "Test"
        )

        let mockCalendarClient = CalendarClient.testValue
        let mockShiftSwitchClient = ShiftSwitchClient.testValue

        let store = TestStore(
            initialState: TodayFeature.State(
                undoStack: [operation],
                redoStack: [operation]
            )
        ) {
            TodayFeature()
        } withDependencies: {
            $0.calendarClient = mockCalendarClient
            $0.shiftSwitchClient = mockShiftSwitchClient
        }

        await store.send(.updateUndoRedoStates) { state in
            state.canUndo = true
            state.canRedo = true
        }
    }
}
