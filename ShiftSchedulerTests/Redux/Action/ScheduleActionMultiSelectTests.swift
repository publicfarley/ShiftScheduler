import Foundation
import Testing

@testable import ShiftScheduler

// MARK: - ScheduleAction Multi-Select Tests
@MainActor
@Suite("ScheduleAction Multi-Select Cases")
struct ScheduleActionMultiSelectTests {
    // MARK: - Action Creation Tests

    @Test("Can create enterSelectionMode action with delete mode")
    func canCreateEnterSelectionModeDeleteAction() {
        let shiftId = UUID()
        let action = ScheduleAction.enterSelectionMode(mode: .delete, firstId: shiftId)

        if case .enterSelectionMode(let mode, let firstId) = action {
            #expect(mode == .delete)
            #expect(firstId == shiftId)
        } else {
            Issue.record("Action should be enterSelectionMode")
        }
    }

    @Test("Can create enterSelectionMode action with add mode")
    func canCreateEnterSelectionModeAddAction() {
        let dateId = UUID()
        let action = ScheduleAction.enterSelectionMode(mode: .add, firstId: dateId)

        if case .enterSelectionMode(let mode, let firstId) = action {
            #expect(mode == .add)
            #expect(firstId == dateId)
        } else {
            Issue.record("Action should be enterSelectionMode")
        }
    }

    @Test("Can create exitSelectionMode action")
    func canCreateExitSelectionModeAction() {
        let action = ScheduleAction.exitSelectionMode

        if case .exitSelectionMode = action {
            // Successfully pattern matched
        } else {
            Issue.record("Action should be exitSelectionMode")
        }
    }

    @Test("Can create toggleShiftSelection action")
    func canCreateToggleShiftSelectionAction() {
        let shiftId = UUID()
        let action = ScheduleAction.toggleShiftSelection(shiftId)

        if case .toggleShiftSelection(let id) = action {
            #expect(id == shiftId)
        } else {
            Issue.record("Action should be toggleShiftSelection")
        }
    }

    @Test("Can create selectAllVisible action")
    func canCreateSelectAllVisibleAction() {
        let action = ScheduleAction.selectAllVisible

        if case .selectAllVisible = action {
            // Successfully pattern matched
        } else {
            Issue.record("Action should be selectAllVisible")
        }
    }

    @Test("Can create clearSelection action")
    func canCreateClearSelectionAction() {
        let action = ScheduleAction.clearSelection

        if case .clearSelection = action {
            // Successfully pattern matched
        } else {
            Issue.record("Action should be clearSelection")
        }
    }

    @Test("Can create bulkDeleteRequested action")
    func canCreateBulkDeleteRequestedAction() {
        let action = ScheduleAction.bulkDeleteRequested

        if case .bulkDeleteRequested = action {
            // Successfully pattern matched
        } else {
            Issue.record("Action should be bulkDeleteRequested")
        }
    }

    @Test("Can create bulkDeleteConfirmed action with shift IDs")
    func canCreateBulkDeleteConfirmedAction() {
        let shiftIds = [UUID(), UUID(), UUID()]
        let action = ScheduleAction.bulkDeleteConfirmed(shiftIds)

        if case .bulkDeleteConfirmed(let ids) = action {
            #expect(ids.count == 3)
            #expect(ids == shiftIds)
        } else {
            Issue.record("Action should be bulkDeleteConfirmed")
        }
    }

    @Test("Can create bulkDeleteCompleted action with success")
    func canCreateBulkDeleteCompletedSuccess() {
        let action = ScheduleAction.bulkDeleteCompleted(.success(5))

        if case .bulkDeleteCompleted(.success(let count)) = action {
            #expect(count == 5)
        } else {
            Issue.record("Action should be bulkDeleteCompleted with success")
        }
    }

    @Test("Can create bulkDeleteCompleted action with failure")
    func canCreateBulkDeleteCompletedFailure() {
        let error = ScheduleError.calendarEventDeletionFailed("Test error")
        let action = ScheduleAction.bulkDeleteCompleted(.failure(error))

        if case .bulkDeleteCompleted(.failure) = action {
            // Successfully pattern matched
        } else {
            Issue.record("Action should be bulkDeleteCompleted with failure")
        }
    }

    // MARK: - Action Equality Tests

    @Test("enterSelectionMode actions are equal when parameters match")
    func enterSelectionModeActionsEqualWhenParametersMatch() {
        let shiftId = UUID()
        let action1 = ScheduleAction.enterSelectionMode(mode: .delete, firstId: shiftId)
        let action2 = ScheduleAction.enterSelectionMode(mode: .delete, firstId: shiftId)

        #expect(action1 == action2)
    }

    @Test("enterSelectionMode actions are not equal when modes differ")
    func enterSelectionModeActionsNotEqualWhenModesDiffer() {
        let shiftId = UUID()
        let action1 = ScheduleAction.enterSelectionMode(mode: .delete, firstId: shiftId)
        let action2 = ScheduleAction.enterSelectionMode(mode: .add, firstId: shiftId)

        #expect(action1 != action2)
    }

    @Test("enterSelectionMode actions are not equal when IDs differ")
    func enterSelectionModeActionsNotEqualWhenIdsDiffer() {
        let action1 = ScheduleAction.enterSelectionMode(mode: .delete, firstId: UUID())
        let action2 = ScheduleAction.enterSelectionMode(mode: .delete, firstId: UUID())

        #expect(action1 != action2)
    }

    @Test("exitSelectionMode actions are equal")
    func exitSelectionModeActionsAreEqual() {
        let action1 = ScheduleAction.exitSelectionMode
        let action2 = ScheduleAction.exitSelectionMode

        #expect(action1 == action2)
    }

    @Test("toggleShiftSelection actions are equal when IDs match")
    func toggleShiftSelectionActionsEqualWhenIdsMatch() {
        let shiftId = UUID()
        let action1 = ScheduleAction.toggleShiftSelection(shiftId)
        let action2 = ScheduleAction.toggleShiftSelection(shiftId)

        #expect(action1 == action2)
    }

    @Test("toggleShiftSelection actions are not equal when IDs differ")
    func toggleShiftSelectionActionsNotEqualWhenIdsDiffer() {
        let action1 = ScheduleAction.toggleShiftSelection(UUID())
        let action2 = ScheduleAction.toggleShiftSelection(UUID())

        #expect(action1 != action2)
    }

    @Test("selectAllVisible actions are equal")
    func selectAllVisibleActionsAreEqual() {
        let action1 = ScheduleAction.selectAllVisible
        let action2 = ScheduleAction.selectAllVisible

        #expect(action1 == action2)
    }

    @Test("clearSelection actions are equal")
    func clearSelectionActionsAreEqual() {
        let action1 = ScheduleAction.clearSelection
        let action2 = ScheduleAction.clearSelection

        #expect(action1 == action2)
    }

    @Test("bulkDeleteRequested actions are equal")
    func bulkDeleteRequestedActionsAreEqual() {
        let action1 = ScheduleAction.bulkDeleteRequested
        let action2 = ScheduleAction.bulkDeleteRequested

        #expect(action1 == action2)
    }

    @Test("bulkDeleteConfirmed actions are equal when shift IDs match")
    func bulkDeleteConfirmedActionsEqualWhenIdsMatch() {
        let shiftIds = [UUID(), UUID()]
        let action1 = ScheduleAction.bulkDeleteConfirmed(shiftIds)
        let action2 = ScheduleAction.bulkDeleteConfirmed(shiftIds)

        #expect(action1 == action2)
    }

    @Test("bulkDeleteConfirmed actions are not equal when shift IDs differ")
    func bulkDeleteConfirmedActionsNotEqualWhenIdsDiffer() {
        let action1 = ScheduleAction.bulkDeleteConfirmed([UUID()])
        let action2 = ScheduleAction.bulkDeleteConfirmed([UUID()])

        #expect(action1 != action2)
    }

    @Test("bulkDeleteCompleted success actions are equal")
    func bulkDeleteCompletedSuccessActionsEqual() {
        let action1 = ScheduleAction.bulkDeleteCompleted(.success(5))
        let action2 = ScheduleAction.bulkDeleteCompleted(.success(5))

        #expect(action1 == action2)
    }

    @Test("bulkDeleteCompleted failure actions are equal")
    func bulkDeleteCompletedFailureActionsEqual() {
        let action1 = ScheduleAction.bulkDeleteCompleted(.failure(ScheduleError.calendarEventDeletionFailed("Error")))
        let action2 = ScheduleAction.bulkDeleteCompleted(.failure(ScheduleError.calendarEventDeletionFailed("Error")))

        #expect(action1 == action2)
    }
}
