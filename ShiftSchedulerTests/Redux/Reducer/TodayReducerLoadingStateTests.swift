import Testing
import Foundation
@testable import ShiftScheduler

/// Unit tests for Today reducer loading state management
/// Demonstrates testing intermediate states (like isLoading) by testing the reducer directly
/// This is faster and more reliable than testing through the full Store+Middleware stack
@Suite("Today Reducer - Loading State Management")
@MainActor
struct TodayReducerLoadingStateTests {

    // MARK: - Loading State Tests

    @Test("loadShifts action sets isLoading to true")
    func testLoadShiftsStartsLoading() {
        // Given - Initial state with loading = false
        var state = TodayState()
        state.isLoading = false

        // When - Reducer handles loadShifts action
        let newState = todayReducer(state: state, action: .loadShifts)

        // Then - Loading state is set to true
        #expect(newState.isLoading == true)
    }

    @Test("loadShifts preserves other state while setting loading")
    func testLoadShiftsPreservesOtherState() {
        // Given - State with existing data
        var state = TodayState()
        state.isLoading = false
        state.scheduledShifts = [
            ScheduledShift(
                eventIdentifier: UUID().uuidString,
                shiftType: Self.createTestShiftType(),
                date: try Date.fixedTestDate_Nov11_2025(),
                notes: nil
            )
        ]
        state.errorMessage = "Previous error"

        // When
        let newState = todayReducer(state: state, action: .loadShifts)

        // Then - Loading set but other state preserved
        #expect(newState.isLoading == true)
        #expect(newState.scheduledShifts.count == 1)
        #expect(newState.errorMessage == "Previous error")
    }

    @Test("shiftsLoaded success clears loading and sets shifts")
    func testShiftsLoadedSuccessClearsLoading() {
        // Given - Loading state
        var state = TodayState()
        state.isLoading = true

        let testShifts = [
            ScheduledShift(
                eventIdentifier: UUID().uuidString,
                shiftType: Self.createTestShiftType(),
                date: try Date.fixedTestDate_Nov11_2025(),
                notes: nil
            )
        ]

        // When
        let newState = todayReducer(
            state: state,
            action: .shiftsLoaded(.success(testShifts))
        )

        // Then
        #expect(newState.isLoading == false)
        #expect(newState.scheduledShifts.count == 1)
        #expect(newState.errorMessage == nil)
    }

    @Test("shiftsLoaded failure clears loading and sets error")
    func testShiftsLoadedFailureClearsLoading() {
        // Given - Loading state
        var state = TodayState()
        state.isLoading = true

        let error = NSError(
            domain: "test",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Test error"]
        )

        // When
        let newState = todayReducer(
            state: state,
            action: .shiftsLoaded(.failure(error))
        )

        // Then
        #expect(newState.isLoading == false)
        #expect(newState.errorMessage == "Failed to load shifts: Test error")
    }

    @Test("performSwitchShift sets isLoading to true")
    func testPerformSwitchShiftStartsLoading() {
        // Given
        var state = TodayState()
        state.isLoading = false
        
        let morningShiftType = ShiftTypeBuilder.morningShift()
        let afternoonShiftType = ShiftTypeBuilder.afternoonShift()
        
        let scheduledMorningShift = ScheduledShiftBuilder(shiftType: morningShiftType).build()

        // When
        let newState = todayReducer(
            state: state,
            action: .performSwitchShift(
                scheduledMorningShift,
                afternoonShiftType,
                "Required switch"
            )
        )

        // Then
        #expect(newState.isLoading == true)
    }

    @Test("shiftSwitched success clears loading and closes sheet")
    func testShiftSwitchedSuccessClearsLoading() {
        // Given - Loading state with sheet open
        var state = TodayState()
        state.isLoading = true
        state.showSwitchShiftSheet = true
        state.selectedShift = ScheduledShift(
            eventIdentifier: UUID().uuidString,
            shiftType: Self.createTestShiftType(),
            date: try Date.fixedTestDate_Nov11_2025(),
            notes: nil
        )

        // When
        let newState = todayReducer(state: state, action: .shiftSwitched(.success(())))

        // Then
        #expect(newState.isLoading == false)
        #expect(newState.showSwitchShiftSheet == false)
        #expect(newState.selectedShift == nil)
        #expect(newState.toastMessage != nil)
    }

    @Test("shiftSwitched failure clears loading but keeps sheet open")
    func testShiftSwitchedFailureClearsLoadingButKeepsSheet() {
        // Given
        var state = TodayState()
        state.isLoading = true
        state.showSwitchShiftSheet = true

        let error = NSError(
            domain: "test",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Switch failed"]
        )

        // When
        let newState = todayReducer(
            state: state,
            action: .shiftSwitched(.failure(error))
        )

        // Then
        #expect(newState.isLoading == false)
        #expect(newState.showSwitchShiftSheet == true)  // Still open for retry
        #expect(newState.toastMessage != nil)
    }

    // MARK: - Loading State Transitions

    @Test("Complete loading cycle: start -> success")
    func testCompleteLoadingCycleSuccess() {
        // Given - Initial state
        var state = TodayState()
        state.isLoading = false
        state.scheduledShifts = []

        // When - Start loading
        state = todayReducer(state: state, action: .loadShifts)
        #expect(state.isLoading == true)

        // When - Complete loading
        let testShift = ScheduledShift(
            eventIdentifier: UUID().uuidString,
            shiftType: Self.createTestShiftType(),
            date: try Date.fixedTestDate_Nov11_2025(),
            notes: nil
        )
        state = todayReducer(
            state: state,
            action: .shiftsLoaded(.success([testShift]))
        )

        // Then - Loading complete
        #expect(state.isLoading == false)
        #expect(state.scheduledShifts.count == 1)
    }

    @Test("Complete loading cycle: start -> failure")
    func testCompleteLoadingCycleFailure() {
        // Given - Initial state
        var state = TodayState()
        state.isLoading = false

        // When - Start loading
        state = todayReducer(state: state, action: .loadShifts)
        #expect(state.isLoading == true)

        // When - Loading fails
        let error = NSError(domain: "test", code: 1)
        state = todayReducer(
            state: state,
            action: .shiftsLoaded(.failure(error))
        )

        // Then - Loading complete with error
        #expect(state.isLoading == false)
        #expect(state.errorMessage != nil)
    }

    @Test("Multiple loading cycles don't interfere")
    func testMultipleLoadingCycles() {
        var state = TodayState()

        // First load
        state = todayReducer(state: state, action: .loadShifts)
        #expect(state.isLoading == true)
        state = todayReducer(state: state, action: .shiftsLoaded(.success([])))
        #expect(state.isLoading == false)

        // Second load
        state = todayReducer(state: state, action: .loadShifts)
        #expect(state.isLoading == true)
        state = todayReducer(state: state, action: .shiftsLoaded(.success([])))
        #expect(state.isLoading == false)
    }

    // MARK: - Test Helpers

    static func createTestShiftType() -> ShiftType {
        let location = Location(
            id: UUID(),
            name: "Test Office",
            address: "123 Test St"
        )

        return ShiftType(
            id: UUID(),
            symbol: "☀️",
            duration: .scheduled(
                from: HourMinuteTime(hour: 9, minute: 0),
                to: HourMinuteTime(hour: 17, minute: 0)
            ),
            title: "Day Shift",
            description: "Test shift",
            location: location
        )
    }
}
