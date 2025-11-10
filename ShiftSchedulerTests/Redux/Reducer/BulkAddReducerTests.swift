import Testing
import Foundation
@testable import ShiftScheduler

/// Tests for bulk add reducer logic
/// Validates state mutations for date selection, mode management, and bulk add operations
@Suite("Bulk Add Reducer Tests")
@MainActor
struct BulkAddReducerTests {

    // MARK: - Test Helpers

    /// Create test location
    static func createTestLocation() -> Location {
        Location(id: UUID(), name: "Test Office", address: "123 Test St")
    }

    /// Create test shift type
    static func createTestShiftType() -> ShiftType {
        ShiftType(
            id: UUID(),
            symbol: "☀️",
            duration: .allDay,
            title: "Test Shift",
            description: "Test shift",
            location: createTestLocation()
        )
    }

    // MARK: - Toggle Date Selection Tests

    @Test("toggleDateSelection adds date when not selected")
    func testToggleDateSelectionAddsDate() {
        // Given
        var state = AppState()
        state.schedule.selectedDates = []
        let testDate = Date()

        // When
        appReducer(&state, .schedule(.toggleDateSelection(testDate)))

        // Then
        let isSelected = state.schedule.selectedDates.contains { selectedDate in
            Calendar.current.isDate(testDate, inSameDayAs: selectedDate)
        }
        #expect(isSelected)
        #expect(state.schedule.selectedDates.count == 1)
    }

    @Test("toggleDateSelection removes date when already selected")
    func testToggleDateSelectionRemovesDate() {
        // Given
        var state = AppState()
        let testDate = Date()
        state.schedule.selectedDates = [testDate]
        #expect(state.schedule.selectedDates.count == 1)

        // When
        appReducer(&state, .schedule(.toggleDateSelection(testDate)))

        // Then
        let isSelected = state.schedule.selectedDates.contains { selectedDate in
            Calendar.current.isDate(testDate, inSameDayAs: selectedDate)
        }
        #expect(!isSelected)
        #expect(state.schedule.selectedDates.isEmpty)
    }

    @Test("toggleDateSelection handles multiple dates correctly")
    func testToggleDateSelectionMultipleDates() {
        // Given
        var state = AppState()
        let date1 = Calendar.current.startOfDay(for: Date())
        let date2 = Calendar.current.date(byAdding: .day, value: 1, to: date1)!
        let date3 = Calendar.current.date(byAdding: .day, value: 2, to: date1)!

        // When - add three dates
        appReducer(&state, .schedule(.toggleDateSelection(date1)))
        appReducer(&state, .schedule(.toggleDateSelection(date2)))
        appReducer(&state, .schedule(.toggleDateSelection(date3)))

        // Then - all three should be selected
        #expect(state.schedule.selectedDates.count == 3)

        // When - remove middle date
        appReducer(&state, .schedule(.toggleDateSelection(date2)))

        // Then - date2 should be removed, others remain
        #expect(state.schedule.selectedDates.count == 2)
        let date2Selected = state.schedule.selectedDates.contains { selectedDate in
            Calendar.current.isDate(date2, inSameDayAs: selectedDate)
        }
        #expect(!date2Selected)
    }

    @Test("toggleDateSelection ignores time component (date-only comparison)")
    func testToggleDateSelectionIgnoresTimeComponent() {
        // Given
        var state = AppState()
        let baseDate = Calendar.current.startOfDay(for: Date())
        let sameDay9AM = Calendar.current.date(byAdding: .hour, value: 9, to: baseDate)!
        let sameDay5PM = Calendar.current.date(byAdding: .hour, value: 17, to: baseDate)!

        // When - add base date
        appReducer(&state, .schedule(.toggleDateSelection(baseDate)))
        #expect(state.schedule.selectedDates.count == 1)

        // When - try to toggle same day at different time (should remove)
        appReducer(&state, .schedule(.toggleDateSelection(sameDay9AM)))

        // Then - should be removed (same day, time component ignored)
        #expect(state.schedule.selectedDates.isEmpty)
    }

    // MARK: - Clear Selected Dates Tests

    @Test("clearSelectedDates removes all selected dates")
    func testClearSelectedDatesRemovesAll() {
        // Given
        var state = AppState()
        let date1 = Calendar.current.startOfDay(for: Date())
        let date2 = Calendar.current.date(byAdding: .day, value: 1, to: date1)!
        let date3 = Calendar.current.date(byAdding: .day, value: 2, to: date1)!
        state.schedule.selectedDates = [date1, date2, date3]
        #expect(state.schedule.selectedDates.count == 3)

        // When
        appReducer(&state, .schedule(.clearSelectedDates))

        // Then
        #expect(state.schedule.selectedDates.isEmpty)
        #expect(state.schedule.selectedDates.count == 0)
    }

    @Test("clearSelectedDates is idempotent (safe to call multiple times)")
    func testClearSelectedDatesIdempotent() {
        // Given
        var state = AppState()
        state.schedule.selectedDates = [Date()]

        // When - clear once
        appReducer(&state, .schedule(.clearSelectedDates))
        #expect(state.schedule.selectedDates.isEmpty)

        // When - clear again
        appReducer(&state, .schedule(.clearSelectedDates))

        // Then - still empty (no error)
        #expect(state.schedule.selectedDates.isEmpty)
    }

    // MARK: - Selection Mode Tests

    @Test("enterSelectionMode with .add sets selection mode")
    func testEnterSelectionModeAdd() {
        // Given
        var state = AppState()
        #expect(state.schedule.selectionMode == nil)

        // When
        let testId = UUID()
        appReducer(&state, .schedule(.enterSelectionMode(mode: .add, firstId: testId)))

        // Then
        #expect(state.schedule.selectionMode == .add)
        #expect(state.schedule.isInSelectionMode == true)
    }

    @Test("enterSelectionMode with .delete sets selection mode")
    func testEnterSelectionModeDelete() {
        // Given
        var state = AppState()
        #expect(state.schedule.selectionMode == nil)

        // When
        let testId = UUID()
        appReducer(&state, .schedule(.enterSelectionMode(mode: .delete, firstId: testId)))

        // Then
        #expect(state.schedule.selectionMode == .delete)
        #expect(state.schedule.isInSelectionMode == true)
    }

    @Test("exitSelectionMode clears selection mode and selected dates")
    func testExitSelectionMode() {
        // Given
        var state = AppState()
        state.schedule.selectionMode = .add
        state.schedule.isInSelectionMode = true
        let testDate = Date()
        state.schedule.selectedDates = [testDate]

        // When
        appReducer(&state, .schedule(.exitSelectionMode))

        // Then
        #expect(state.schedule.selectionMode == nil)
        #expect(state.schedule.isInSelectionMode == false)
        #expect(state.schedule.selectedDates.isEmpty)
    }

    // MARK: - Bulk Add Request/Confirmation Tests

    @Test("bulkAddRequested shows shift type selection sheet")
    func testBulkAddRequested() {
        // Given
        var state = AppState()
        #expect(!state.schedule.showBulkAddSheet)

        // When
        appReducer(&state, .schedule(.bulkAddRequested))

        // Then
        #expect(state.schedule.showBulkAddSheet)
    }

    @Test("bulkAddCompleted success clears selected dates and shows success toast")
    func testBulkAddCompletedSuccess() {
        // Given
        var state = AppState()
        state.schedule.selectedDates = [Date()]
        let testShift = ScheduledShift(
            id: UUID(),
            eventIdentifier: "test-event",
            shiftType: Self.createTestShiftType(),
            date: Date()
        )

        // When
        appReducer(&state, .schedule(.bulkAddCompleted(.success([testShift]))))

        // Then
        #expect(state.schedule.selectedDates.isEmpty)
        #expect(state.schedule.showSuccessToast == true)
        #expect(!state.schedule.successMessage?.isEmpty ?? false)
    }

    @Test("bulkAddCompleted failure sets error state")
    func testBulkAddCompletedFailure() {
        // Given
        var state = AppState()
        let testError = ScheduleError.calendarEventCreationFailed("Test error")

        // When
        appReducer(&state, .schedule(.bulkAddCompleted(.failure(testError))))

        // Then
        #expect(state.schedule.currentError == testError)
        #expect(state.schedule.showSuccessToast == false)
    }

    // MARK: - Integration Tests (Multiple Actions)

    @Test("Full bulk add flow: enter add mode → select dates → confirm → success")
    func testFullBulkAddFlow() {
        // Given
        var state = AppState()
        let date1 = Calendar.current.startOfDay(for: Date())
        let date2 = Calendar.current.date(byAdding: .day, value: 1, to: date1)!

        // When - enter add mode
        appReducer(&state, .schedule(.enterSelectionMode(mode: .add, firstId: UUID())))
        #expect(state.schedule.isInSelectionMode)
        #expect(state.schedule.selectionMode == .add)

        // When - select dates
        appReducer(&state, .schedule(.toggleDateSelection(date1)))
        appReducer(&state, .schedule(.toggleDateSelection(date2)))
        #expect(state.schedule.selectedDates.count == 2)

        // When - request bulk add
        appReducer(&state, .schedule(.bulkAddRequested))
        #expect(state.schedule.showBulkAddSheet)

        // When - confirm with success
        let testShift1 = ScheduledShift(
            id: UUID(),
            eventIdentifier: "event-1",
            shiftType: Self.createTestShiftType(),
            date: date1
        )
        let testShift2 = ScheduledShift(
            id: UUID(),
            eventIdentifier: "event-2",
            shiftType: Self.createTestShiftType(),
            date: date2
        )
        appReducer(&state, .schedule(.bulkAddCompleted(.success([testShift1, testShift2]))))

        // Then - state cleaned up, success shown
        #expect(state.schedule.selectedDates.isEmpty)
        #expect(state.schedule.showSuccessToast)
        #expect(!state.schedule.successMessage?.isEmpty ?? false)
    }

    @Test("Bulk add cancelled clears selection state")
    func testBulkAddCancelled() {
        // Given
        var state = AppState()
        state.schedule.selectionMode = .add
        state.schedule.isInSelectionMode = true
        state.schedule.selectedDates = [Date()]

        // When
        appReducer(&state, .schedule(.exitSelectionMode))

        // Then
        #expect(state.schedule.selectionMode == nil)
        #expect(!state.schedule.isInSelectionMode)
        #expect(state.schedule.selectedDates.isEmpty)
    }

    // MARK: - State Consistency Tests

    @Test("Selected dates count matches selectionCount computed property")
    func testSelectionCountConsistency() {
        // Given
        var state = AppState()
        let dates = [
            Calendar.current.startOfDay(for: Date()),
            Calendar.current.date(byAdding: .day, value: 1, to: Date())!,
            Calendar.current.date(byAdding: .day, value: 2, to: Date())!
        ]

        // When
        for date in dates {
            appReducer(&state, .schedule(.toggleDateSelection(date)))
        }

        // Then
        #expect(state.schedule.selectionCount == dates.count)
        #expect(state.schedule.selectionCount == state.schedule.selectedDates.count)
    }

    @Test("canAddToSelectedDates requires .add mode and selection")
    func testCanAddToSelectedDatesCheck() {
        // Given
        var state = AppState()

        // When - no mode set
        #expect(!state.schedule.canAddToSelectedDates)

        // When - add mode but no dates selected
        state.schedule.selectionMode = .add
        state.schedule.isInSelectionMode = true
        #expect(!state.schedule.canAddToSelectedDates)

        // When - add mode with dates selected
        appReducer(&state, .schedule(.toggleDateSelection(Date())))
        #expect(state.schedule.canAddToSelectedDates)

        // When - switch to delete mode
        appReducer(&state, .schedule(.exitSelectionMode))
        appReducer(&state, .schedule(.enterSelectionMode(mode: .delete, firstId: UUID())))
        #expect(!state.schedule.canAddToSelectedDates)
    }

    // MARK: - Edge Cases

    @Test("Bulk add with single date selected")
    func testBulkAddWithSingleDate() {
        // Given
        var state = AppState()
        let testDate = Calendar.current.startOfDay(for: Date())

        // When
        appReducer(&state, .schedule(.enterSelectionMode(mode: .add, firstId: UUID())))
        appReducer(&state, .schedule(.toggleDateSelection(testDate)))
        #expect(state.schedule.selectedDates.count == 1)

        // Then - should still work with one date
        #expect(state.schedule.canAddToSelectedDates)
    }

    @Test("Bulk add with many dates selected")
    func testBulkAddWithManyDates() {
        // Given
        var state = AppState()
        let baseDateDate = Calendar.current.startOfDay(for: Date())

        // When - select 30 dates
        for i in 0..<30 {
            if let date = Calendar.current.date(byAdding: .day, value: i, to: baseDateDate) {
                appReducer(&state, .schedule(.toggleDateSelection(date)))
            }
        }

        // Then
        #expect(state.schedule.selectedDates.count == 30)
        #expect(state.schedule.canAddToSelectedDates)
    }

    @Test("Success message includes count of created shifts")
    func testSuccessMessageIncludesCount() {
        // Given
        var state = AppState()
        let shifts = [
            ScheduledShift(id: UUID(), eventIdentifier: "1", shiftType: nil, date: Date()),
            ScheduledShift(id: UUID(), eventIdentifier: "2", shiftType: nil, date: Date()),
            ScheduledShift(id: UUID(), eventIdentifier: "3", shiftType: nil, date: Date())
        ]

        // When
        appReducer(&state, .schedule(.bulkAddCompleted(.success(shifts))))

        // Then
        #expect(state.schedule.successMessage?.contains("3") ?? false)
        #expect(state.schedule.showSuccessToast)
    }
}
