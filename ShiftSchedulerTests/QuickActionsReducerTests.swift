import Foundation
import Testing

@testable import ShiftScheduler

// MARK: - Quick Actions Reducer Tests

/// Tests for Quick Actions reducer state transitions
@MainActor
struct QuickActionsReducerTests {

    // MARK: - Edit Notes Sheet Tests

    @Test("Edit Notes: Opening sheet initializes state")
    func editNotesSheetOpening() {
        var state = TodayState()
        let action = TodayAction.editNotesSheetToggled(true)

        state = todayReducer(state: state, action: action)

        #expect(state.showEditNotesSheet == true)
    }

    @Test("Edit Notes: Notes text updates in state")
    func quickActionsNotesChanged() {
        var state = TodayState()
        let newNotes = "Updated notes for shift"

        let action = TodayAction.quickActionsNotesChanged(newNotes)
        state = todayReducer(state: state, action: action)

        #expect(state.quickActionsNotes == newNotes)
    }

    // MARK: - Delete Shift Tests

    @Test("Delete: Request sets confirmation shift")
    func deleteShiftRequested() {
        let testShift = makeTestShift()
        var state = TodayState()

        let action = TodayAction.deleteShiftRequested(testShift)
        state = todayReducer(state: state, action: action)

        #expect(state.deleteShiftConfirmationShift?.id == testShift.id)
    }

    @Test("Delete: Confirmation clears state (handled by middleware)")
    func deleteShiftConfirmed() {
        var state = TodayState()
        state.deleteShiftConfirmationShift = makeTestShift()

        let action = TodayAction.deleteShiftConfirmed
        state = todayReducer(state: state, action: action)

        // Reducer just breaks; middleware handles the actual deletion
        // State should remain unchanged until middleware dispatches shiftDeleted
        #expect(state.deleteShiftConfirmationShift != nil)
    }

    @Test("Delete: Cancellation clears confirmation shift")
    func deleteShiftCancelled() {
        var state = TodayState()
        state.deleteShiftConfirmationShift = makeTestShift()

        let action = TodayAction.deleteShiftCancelled
        state = todayReducer(state: state, action: action)

        #expect(state.deleteShiftConfirmationShift == nil)
    }

    @Test("Delete: Success clears confirmation shift")
    func shiftDeletedSuccess() {
        var state = TodayState()
        state.deleteShiftConfirmationShift = makeTestShift()

        let action = TodayAction.shiftDeleted(.success(()))
        state = todayReducer(state: state, action: action)

        #expect(state.deleteShiftConfirmationShift == nil)
    }

    @Test("Delete: Failure sets error message and clears confirmation")
    func shiftDeletedFailure() {
        var state = TodayState()
        state.deleteShiftConfirmationShift = makeTestShift()

        let testError = NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        let action = TodayAction.shiftDeleted(.failure(testError))
        state = todayReducer(state: state, action: action)

        #expect(state.deleteShiftConfirmationShift == nil)
        #expect(state.errorMessage?.contains("Failed to delete shift") ?? false)
    }

    // MARK: - Multiple Action Sequences


    @Test("Quick Actions: Complete delete flow with cancellation")
    func completeDeleteFlowWithCancellation() {
        let testShift = makeTestShift()
        var state = TodayState()

        // Request delete
        state = todayReducer(state: state, action: .deleteShiftRequested(testShift))
        #expect(state.deleteShiftConfirmationShift?.id == testShift.id)

        // Cancel delete
        state = todayReducer(state: state, action: .deleteShiftCancelled)
        #expect(state.deleteShiftConfirmationShift == nil)
    }

    @Test("Quick Actions: Rapid notes changes")
    func rapidNotesChanges() {
        var state = TodayState()
        let notes = ["A", "Ab", "Abc", "Abcd", "Abc", "Ab", "A", ""]

        for note in notes {
            state = todayReducer(state: state, action: .quickActionsNotesChanged(note))
            #expect(state.quickActionsNotes == note)
        }
    }
}

// MARK: - Helper Functions
@MainActor
private func makeTestShift() -> ScheduledShift {
    ScheduledShiftBuilder.today().build()
}
