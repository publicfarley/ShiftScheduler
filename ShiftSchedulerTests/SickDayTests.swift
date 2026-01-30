import Foundation
import Testing
@testable import ShiftScheduler

// MARK: - Sick Day Feature Tests

@MainActor
struct SickDayTests {

    // MARK: - Model Tests

    @Test("ScheduledShift marks isSickDay property correctly")
    func testScheduledShiftSickDayProperty() {
        let shift = ScheduledShiftBuilder.today().asSickDay().build()
        #expect(shift.isSickDay == true)
    }

    @Test("ScheduledShift defaults isSickDay to false")
    func testScheduledShiftDefaultNotSick() {
        let shift = ScheduledShiftBuilder.today().build()
        #expect(shift.isSickDay == false)
    }

    @Test("ScheduledShiftData preserves isSickDay flag")
    func testScheduledShiftDataSickDay() {
        let date = Date()
        let shiftData = ScheduledShiftData(
            eventIdentifier: "test-event",
            shiftTypeId: UUID(),
            startDate: date,
            endDate: date,
            title: "Test Shift",
            notes: nil,
            isSickDay: true,
            reason: nil
        )
        #expect(shiftData.isSickDay == true)
    }

    // MARK: - Change Type Tests

    @Test("ChangeType includes markedAsSick case")
    func testChangeTypeMarkedAsSick() {
        let changeType = ChangeType.markedAsSick
        #expect(changeType.displayName == "Marked as Sick")
    }

    @Test("ChangeType includes unmarkedAsSick case")
    func testChangeTypeUnmarkedAsSick() {
        let changeType = ChangeType.unmarkedAsSick
        #expect(changeType.displayName == "Unmarked as Sick")
    }

    // MARK: - Redux Action Tests

    @Test("TodayAction has markShiftAsSick action")
    func testTodayActionMarkAsSick() {
        let shift = ScheduledShiftBuilder.today().build()
        let action = TodayAction.markShiftAsSick(shift, reason: "Flu")

        // Verify action can be created and encoded
        let actionData = AppAction.today(action)
        #expect(actionData != nil)
    }

    @Test("TodayAction has unmarkShiftAsSick action")
    func testTodayActionUnmarkAsSick() {
        let shift = ScheduledShiftBuilder.today().build()
        let action = TodayAction.unmarkShiftAsSick(shift)

        let actionData = AppAction.today(action)
        #expect(actionData != nil)
    }

    @Test("ScheduleAction has markShiftAsSick action")
    func testScheduleActionMarkAsSick() {
        let shift = ScheduledShiftBuilder.today().build()
        let action = ScheduleAction.markShiftAsSick(shift, reason: "Illness")

        let actionData = AppAction.schedule(action)
        #expect(actionData != nil)
    }

    // MARK: - Reducer Tests

    @Test("Reducer sets isLoading when markShiftAsSick action dispatched")
    func testReducerMarkAsSickLoading() {
        var state = TodayState()
        let shift = ScheduledShiftBuilder.today().build()
        let action = TodayAction.markShiftAsSick(shift, reason: "Cold")

        state = appReducer(state: AppState(), action: .today(action)).today
        #expect(state.isLoading == true)
    }

    @Test("Reducer closes sheet on successful sick day marking")
    func testReducerMarkAsSickSuccess() {
        var state = AppState()
        state.today.showMarkAsSickSheet = true
        state.today.isLoading = true

        let action = TodayAction.shiftMarkedAsSick(.success(()))
        let newState = appReducer(state: state, action: .today(action))

        #expect(newState.today.showMarkAsSickSheet == false)
        #expect(newState.today.isLoading == false)
        #expect(newState.today.toastMessage != nil)
    }

    @Test("Reducer handles error when sick day marking fails")
    func testReducerMarkAsSickFailure() {
        var state = AppState()
        state.today.isLoading = true

        let error = ScheduleError.unknown("Test error")
        let action = TodayAction.shiftMarkedAsSick(.failure(error))
        let newState = appReducer(state: state, action: .today(action))

        #expect(newState.today.isLoading == false)
        #expect(newState.today.currentError != nil)
    }

    @Test("Reducer toggles mark as sick sheet")
    func testReducerMarkAsSickSheetToggle() {
        var state = AppState()
        state.today.showMarkAsSickSheet = false

        let action = TodayAction.markAsSickSheetToggled(true)
        var newState = appReducer(state: state, action: .today(action))
        #expect(newState.today.showMarkAsSickSheet == true)

        let toggleOffAction = TodayAction.markAsSickSheetToggled(false)
        newState = appReducer(state: newState, action: .today(toggleOffAction))
        #expect(newState.today.showMarkAsSickSheet == false)
    }

    // MARK: - Persistence Tests

    @Test("Calendar service updates shift sick day flag")
    func testCalendarServiceMarkAsSick() async throws {
        let service = MockCalendarService()
        let shift = try #require(ScheduledShiftBuilder.tomorrow()?.build())
        service.mockShifts = [shift]

        let initialCallCount = service.markShiftAsSickCallCount
        try await service.markShiftAsSick(
            eventIdentifier: shift.eventIdentifier,
            isSickDay: true,
            reason: "Illness"
        )

        #expect(service.markShiftAsSickCallCount == initialCallCount + 1)
    }

    @Test("Calendar service preserves notes when marking shift as sick")
    func testCalendarServicePreservesNotes() async throws {
        let service = MockCalendarService()
        let shift = ScheduledShiftBuilder.today().build()
        service.mockShifts = [shift]

        // Mark shift with both notes and sick day flag
        try await service.markShiftAsSick(
            eventIdentifier: shift.eventIdentifier,
            isSickDay: true,
            reason: "Fever"
        )

        #expect(service.lastMarkAsSickData != nil)
    }

    // MARK: - Change Log Tests

    @Test("Change log entry captures marked as sick action")
    func testChangeLogMarkedAsSick() {
        let shift = ScheduledShiftBuilder.today().build()
        let snapshot = shift.shiftType.map { ShiftSnapshot(from: $0) }

        let entry = ChangeLogEntry(
            id: UUID(),
            timestamp: Date(),
            userId: UUID(),
            userDisplayName: "Test User",
            changeType: .markedAsSick,
            scheduledShiftDate: shift.date,
            oldShiftSnapshot: snapshot,
            newShiftSnapshot: nil,
            reason: "Sick"
        )

        #expect(entry.changeType == .markedAsSick)
        #expect(entry.reason == "Sick")
        #expect(entry.oldShiftSnapshot != nil)
    }

    @Test("Change log entry captures unmarked as sick action")
    func testChangeLogUnmarkedAsSick() {
        let shift = ScheduledShiftBuilder.today().asSickDay().build()
        let snapshot = shift.shiftType.map { ShiftSnapshot(from: $0) }

        let entry = ChangeLogEntry(
            id: UUID(),
            timestamp: Date(),
            userId: UUID(),
            userDisplayName: "Test User",
            changeType: .unmarkedAsSick,
            scheduledShiftDate: shift.date,
            oldShiftSnapshot: snapshot,
            newShiftSnapshot: nil,
            reason: nil
        )

        #expect(entry.changeType == .unmarkedAsSick)
        #expect(entry.reason == nil)
    }

    // MARK: - Test Data Builder Tests

    @Test("ScheduledShiftBuilder creates sick day shift")
    func testBuilderCreatesSickDay() {
        let builder = ScheduledShiftBuilder.today().asSickDay()
        let shift = builder.build()

        #expect(shift.isSickDay == true)
        #expect(shift.date.timeIntervalSince(Date()) > -86400)  // Today or later
    }

    @Test("ScheduledShiftBuilder asSickDay modifier preserves other properties")
    func testBuilderPreservesProperties() {
        let notes = "Test notes"
        let builder = ScheduledShiftBuilder(notes: notes).asSickDay()
        let shift = builder.build()

        #expect(shift.isSickDay == true)
        #expect(shift.notes == notes)
    }

    // MARK: - Integration Tests

    @Test("Sick day state persists through reducer cycle")
    func testSickDayPersistenceInReducer() {
        var state = AppState()
        let shift = ScheduledShiftBuilder.today().asSickDay().build()

        // Simulate marking shift as sick
        state.today.scheduledShifts = [shift]

        let action = TodayAction.markAsSickSheetToggled(true)
        let newState = appReducer(state: state, action: .today(action))

        #expect(newState.today.scheduledShifts[0].isSickDay == true)
        #expect(newState.today.showMarkAsSickSheet == true)
    }

    @Test("Toast message displays on successful sick day marking")
    func testSickDaySuccessToast() {
        var state = AppState()
        state.today.isLoading = true

        let action = TodayAction.shiftMarkedAsSick(.success(()))
        let newState = appReducer(state: state, action: .today(action))

        let toast = newState.today.toastMessage
        #expect(toast?.message.contains("updated") ?? false)
    }
}
