import Foundation
import Testing

@testable import ShiftScheduler

// MARK: - ScheduleState Multi-Select Tests

@MainActor
@Suite("ScheduleState Multi-Select Properties")
struct ScheduleStateMultiSelectTests {
    // MARK: - Initialization Tests

    @Test("Initial state has empty selection")
    func initialStateHasEmptySelection() {
        let state = ScheduleState()

        #expect(state.selectedShiftIds.isEmpty)
        #expect(state.isInSelectionMode == false)
        #expect(state.selectionMode == nil)
        #expect(state.showBulkDeleteConfirmation == false)
    }

    // MARK: - Selected Shift IDs Tests

    @Test("Can add shift ID to selection")
    func canAddShiftIdToSelection() {
        var state = ScheduleState()
        let shiftId = UUID()

        state.selectedShiftIds.insert(shiftId)

        #expect(state.selectedShiftIds.contains(shiftId))
        #expect(state.selectedShiftIds.count == 1)
    }

    @Test("Can remove shift ID from selection")
    func canRemoveShiftIdFromSelection() {
        var state = ScheduleState()
        let shiftId = UUID()

        state.selectedShiftIds.insert(shiftId)
        #expect(state.selectedShiftIds.contains(shiftId))

        state.selectedShiftIds.remove(shiftId)

        #expect(!state.selectedShiftIds.contains(shiftId))
        #expect(state.selectedShiftIds.isEmpty)
    }

    @Test("Can add multiple shift IDs to selection")
    func canAddMultipleShiftIds() {
        var state = ScheduleState()
        let ids = (0..<5).map { _ in UUID() }

        ids.forEach { state.selectedShiftIds.insert($0) }

        #expect(state.selectedShiftIds.count == 5)
        ids.forEach { id in
            #expect(state.selectedShiftIds.contains(id))
        }
    }

    // MARK: - Selection Mode Tests

    @Test("Can enter delete selection mode")
    func canEnterDeleteSelectionMode() {
        var state = ScheduleState()
        let shiftId = UUID()

        state.isInSelectionMode = true
        state.selectionMode = .delete
        state.selectedShiftIds.insert(shiftId)

        #expect(state.isInSelectionMode == true)
        #expect(state.selectionMode == .delete)
        #expect(state.selectedShiftIds.contains(shiftId))
    }

    @Test("Can enter add selection mode")
    func canEnterAddSelectionMode() {
        var state = ScheduleState()
        let shiftId = UUID()

        state.isInSelectionMode = true
        state.selectionMode = .add
        state.selectedShiftIds.insert(shiftId)

        #expect(state.isInSelectionMode == true)
        #expect(state.selectionMode == .add)
        #expect(state.selectedShiftIds.contains(shiftId))
    }

    @Test("Can exit selection mode and clear selection")
    func canExitSelectionModeAndClear() {
        var state = ScheduleState()
        let shiftId = UUID()

        // Enter selection mode
        state.isInSelectionMode = true
        state.selectionMode = .delete
        state.selectedShiftIds.insert(shiftId)

        // Exit selection mode
        state.isInSelectionMode = false
        state.selectionMode = nil
        state.selectedShiftIds.removeAll()

        #expect(state.isInSelectionMode == false)
        #expect(state.selectionMode == nil)
        #expect(state.selectedShiftIds.isEmpty)
    }

    // MARK: - Bulk Delete Confirmation Tests

    @Test("Can show bulk delete confirmation")
    func canShowBulkDeleteConfirmation() {
        var state = ScheduleState()

        state.showBulkDeleteConfirmation = true

        #expect(state.showBulkDeleteConfirmation == true)
    }

    @Test("Can hide bulk delete confirmation")
    func canHideBulkDeleteConfirmation() {
        var state = ScheduleState()

        state.showBulkDeleteConfirmation = true
        state.showBulkDeleteConfirmation = false

        #expect(state.showBulkDeleteConfirmation == false)
    }

    // MARK: - Computed Properties Tests

    @Test("selectedShifts returns correct subset from scheduledShifts")
    func selectedShiftsReturnsCorrectSubset() {
        var state = ScheduleState()

        // Create test shifts
        let shiftType = ShiftTypeBuilder.nightShift()

        let shift1 = ScheduledShift(
            id: UUID(),
            eventIdentifier: "event1",
            shiftType: shiftType,
            date: try Date.fixedTestDate_Nov11_2025(),
            notes: nil
        )
        let shift2 = ScheduledShift(
            id: UUID(),
            eventIdentifier: "event2",
            shiftType: shiftType,
            date: try Date.fixedTestDate_Nov11_2025(),
            notes: nil
        )
        let shift3 = ScheduledShift(
            id: UUID(),
            eventIdentifier: "event3",
            shiftType: shiftType,
            date: try Date.fixedTestDate_Nov11_2025(),
            notes: nil
        )

        state.scheduledShifts = [shift1, shift2, shift3]
        state.selectedShiftIds = [shift1.id, shift3.id]

        let selectedShifts = state.selectedShifts

        #expect(selectedShifts.count == 2)
        #expect(selectedShifts.contains { $0.id == shift1.id })
        #expect(selectedShifts.contains { $0.id == shift3.id })
        #expect(!selectedShifts.contains { $0.id == shift2.id })
    }

    @Test("selectedShifts returns empty array when no selection")
    func selectedShiftsReturnsEmptyWhenNoSelection() {
        var state = ScheduleState()

        let shiftType = ShiftTypeBuilder.nightShift()

        state.scheduledShifts = [
            ScheduledShift(
                id: UUID(),
                eventIdentifier: "event1",
                shiftType: shiftType,
                date: try Date.fixedTestDate_Nov11_2025(),
                notes: nil
            )
        ]
        state.selectedShiftIds = []

        let selectedShifts = state.selectedShifts

        #expect(selectedShifts.isEmpty)
    }

    @Test("selectedShifts returns empty array when selected IDs don't exist")
    func selectedShiftsReturnsEmptyWhenIdsNotFound() {
        var state = ScheduleState()

        state.scheduledShifts = []
        state.selectedShiftIds = [UUID()]

        let selectedShifts = state.selectedShifts

        #expect(selectedShifts.isEmpty)
    }

    @Test("selectionCount returns correct count for delete mode")
    func selectionCountReturnsCorrectCount() {
        var state = ScheduleState()

        // Set selection mode to .delete to test selectedShiftIds.count
        state.selectionMode = .delete
        state.isInSelectionMode = true
        state.selectedShiftIds = [UUID(), UUID(), UUID()]

        #expect(state.selectionCount == 3)
    }

    @Test("selectionCount returns correct count for add mode")
    func selectionCountReturnsCorrectCountForAddMode() throws {
        var state = ScheduleState()

        state.selectionMode = .add
        state.isInSelectionMode = true
        let date = try Calendar.current.startOfDay(for: Date.fixedTestDate_Nov11_2025())
        state.selectedDates = [date, try #require(Calendar.current.date(byAdding: .day, value: 1, to: date))]

        #expect(state.selectionCount == 2)
    }
    @Test("selectionCount returns zero when no selection")
    func selectionCountReturnsZeroWhenEmpty() {
        let state = ScheduleState()

        #expect(state.selectionCount == 0)
    }

    @Test("canDeleteSelectedShifts is true only in delete mode with selection")
    func canDeleteSelectedShiftsRequiresDeleteModeAndSelection() {
        var state = ScheduleState()

        // No selection, no mode
        #expect(state.canDeleteSelectedShifts == false)

        // Has selection but not in delete mode
        state.selectedShiftIds.insert(UUID())
        state.selectionMode = .add
        #expect(state.canDeleteSelectedShifts == false)

        // In delete mode but no selection
        state.selectedShiftIds.removeAll()
        state.selectionMode = .delete
        #expect(state.canDeleteSelectedShifts == false)

        // In delete mode with selection
        state.selectedShiftIds.insert(UUID())
        state.selectionMode = .delete
        #expect(state.canDeleteSelectedShifts == true)
    }

    @Test("canAddToSelectedDates is true only in add mode with selection")
    func canAddToSelectedDatesRequiresAddModeAndSelection() {
        var state = ScheduleState()

        // No selection, no mode
        #expect(state.canAddToSelectedDates == false)

        // Has selection but not in add mode
        state.selectedDates.insert(try Date.fixedTestDate_Nov11_2025())
        state.selectionMode = .delete
        #expect(state.canAddToSelectedDates == false)

        // In add mode but no selection
        state.selectedDates.removeAll()
        state.selectionMode = .add
        #expect(state.canAddToSelectedDates == false)

        // In add mode with selection
        state.selectedDates.insert(try Date.fixedTestDate_Nov11_2025())
        state.selectionMode = .add
        #expect(state.canAddToSelectedDates == true)
    }
}
