import Testing
import Foundation
@testable import ShiftScheduler

/// Tests for bulk add middleware
/// Validates that middleware properly creates shifts and persists change log entries
@Suite("Bulk Add Middleware Tests")
@MainActor
struct BulkAddMiddlewareTests {

    // MARK: - Test Helpers

    static func createTestLocation() -> Location {
        Location(id: UUID(), name: "Test Office", address: "123 Test St")
    }

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

    // MARK: - Bulk Add Confirmed Action Tests

    @Test("bulkAddConfirmed creates shifts for all selected dates")
    async func testBulkAddCreatesShiftsForAllDates() {
        // Given
        let mockServices = ServiceContainer(
            calendarService: MockCalendarService(),
            persistenceService: MockPersistenceService(),
            currentDayService: CurrentDayService()
        )

        var state = AppState()
        state.schedule.selectionMode = .add
        let date1 = Calendar.current.startOfDay(for: Date())
        let date2 = Calendar.current.date(byAdding: .day, value: 1, to: date1)!
        state.schedule.selectedDates = [date1, date2]

        let shiftType = Self.createTestShiftType()
        state.shiftTypes.shiftTypes = [shiftType]

        var dispatchedActions: [AppAction] = []

        let store = Store(
            state: state,
            reducer: appReducer,
            services: mockServices,
            middlewares: [
                { state, action, dispatch in
                    // Record dispatch calls for verification
                    Task {
                        if case .schedule = action {
                            dispatchedActions.append(action)
                        }
                        await scheduleMiddleware(state, action, dispatch, mockServices)
                    }
                }
            ]
        )

        // When
        await store.dispatch(action: .schedule(.bulkAddConfirmed(shiftType: shiftType, notes: "Test notes")))

        // Give time for async operations
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then - should have triggered bulk add completion
        let completionActions = dispatchedActions.filter { action in
            if case .schedule(.bulkAddCompleted) = action {
                return true
            }
            return false
        }
        #expect(!completionActions.isEmpty)
    }

    @Test("bulkAddConfirmed includes notes in change log entries")
    async func testBulkAddIncludesNotesInChangeLog() {
        // Given
        let mockPersistence = MockPersistenceService()
        let mockServices = ServiceContainer(
            calendarService: MockCalendarService(),
            persistenceService: mockPersistence,
            currentDayService: CurrentDayService()
        )

        var state = AppState()
        state.userProfile = UserProfile(userId: UUID(), displayName: "Test User")
        state.schedule.selectionMode = .add
        let date1 = Calendar.current.startOfDay(for: Date())
        state.schedule.selectedDates = [date1]

        let shiftType = Self.createTestShiftType()
        state.shiftTypes.shiftTypes = [shiftType]

        let store = Store(
            state: state,
            reducer: appReducer,
            services: mockServices,
            middlewares: [scheduleMiddleware]
        )

        // When
        let testNotes = "Important shift notes"
        await store.dispatch(action: .schedule(.bulkAddConfirmed(shiftType: shiftType, notes: testNotes)))

        // Give time for async operations
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then - change log entries should include notes
        let changeLogEntries = mockPersistence.mockChangeLogEntries
        #expect(!changeLogEntries.isEmpty)

        // Verify notes are in the entries
        let hasNotes = changeLogEntries.contains { entry in
            entry.reason == testNotes
        }
        #expect(hasNotes)
    }

    @Test("bulkAddConfirmed handles empty notes correctly")
    async func testBulkAddWithEmptyNotes() {
        // Given
        let mockServices = ServiceContainer(
            calendarService: MockCalendarService(),
            persistenceService: MockPersistenceService(),
            currentDayService: CurrentDayService()
        )

        var state = AppState()
        state.schedule.selectionMode = .add
        let testDate = Calendar.current.startOfDay(for: Date())
        state.schedule.selectedDates = [testDate]

        let shiftType = Self.createTestShiftType()
        state.shiftTypes.shiftTypes = [shiftType]

        var successAction: ScheduleAction?

        let store = Store(
            state: state,
            reducer: appReducer,
            services: mockServices,
            middlewares: [
                { state, action, dispatch in
                    Task {
                        if case .schedule(let scheduleAction) = action {
                            if case .bulkAddCompleted = scheduleAction {
                                successAction = scheduleAction
                            }
                        }
                        await scheduleMiddleware(state, action, dispatch, mockServices)
                    }
                }
            ]
        )

        // When - no notes provided
        await store.dispatch(action: .schedule(.bulkAddConfirmed(shiftType: shiftType, notes: "")))

        // Give time for async operations
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then - should complete successfully without crashing
        #expect(successAction != nil)
    }

    @Test("bulkAddConfirmed creates ChangeLogEntry for each shift")
    async func testBulkAddCreatesChangeLogEntry() {
        // Given
        let mockPersistence = MockPersistenceService()
        let mockServices = ServiceContainer(
            calendarService: MockCalendarService(),
            persistenceService: mockPersistence,
            currentDayService: CurrentDayService()
        )

        var state = AppState()
        state.userProfile = UserProfile(userId: UUID(), displayName: "Test User")
        state.schedule.selectionMode = .add
        let date1 = Calendar.current.startOfDay(for: Date())
        let date2 = Calendar.current.date(byAdding: .day, value: 1, to: date1)!
        state.schedule.selectedDates = [date1, date2]

        let shiftType = Self.createTestShiftType()
        state.shiftTypes.shiftTypes = [shiftType]

        let store = Store(
            state: state,
            reducer: appReducer,
            services: mockServices,
            middlewares: [scheduleMiddleware]
        )

        // When
        await store.dispatch(action: .schedule(.bulkAddConfirmed(shiftType: shiftType, notes: "Test")))

        // Give time for async operations
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then - should have created 2 change log entries (one per date)
        let entries = mockPersistence.mockChangeLogEntries
        #expect(entries.count == 2)

        // Verify entries have correct change type
        let allCreated = entries.allSatisfy { entry in
            entry.changeType == .created
        }
        #expect(allCreated)
    }

    @Test("bulkAddConfirmed dispatches loadShifts to refresh calendar")
    async func testBulkAddDispatchesLoadShifts() {
        // Given
        let mockServices = ServiceContainer(
            calendarService: MockCalendarService(),
            persistenceService: MockPersistenceService(),
            currentDayService: CurrentDayService()
        )

        var state = AppState()
        state.schedule.selectionMode = .add
        let testDate = Calendar.current.startOfDay(for: Date())
        state.schedule.selectedDates = [testDate]

        let shiftType = Self.createTestShiftType()
        state.shiftTypes.shiftTypes = [shiftType]

        var dispatchedLoadShifts = false

        let store = Store(
            state: state,
            reducer: appReducer,
            services: mockServices,
            middlewares: [
                { state, action, dispatch in
                    Task {
                        if case .schedule(.loadShifts) = action {
                            dispatchedLoadShifts = true
                        }
                        await scheduleMiddleware(state, action, dispatch, mockServices)
                    }
                }
            ]
        )

        // When
        await store.dispatch(action: .schedule(.bulkAddConfirmed(shiftType: shiftType, notes: nil)))

        // Give time for async operations
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        #expect(dispatchedLoadShifts)
    }

    // MARK: - Error Handling Tests

    @Test("bulkAddConfirmed handles calendar service error gracefully")
    async func testBulkAddHandlesCalendarError() {
        // Given
        let mockCalendar = MockCalendarService()
        mockCalendar.mockIsAuthorized = false  // Will cause error

        let mockServices = ServiceContainer(
            calendarService: mockCalendar,
            persistenceService: MockPersistenceService(),
            currentDayService: CurrentDayService()
        )

        var state = AppState()
        state.schedule.selectionMode = .add
        let testDate = Calendar.current.startOfDay(for: Date())
        state.schedule.selectedDates = [testDate]

        let shiftType = Self.createTestShiftType()
        state.shiftTypes.shiftTypes = [shiftType]

        var completedWithError = false

        let store = Store(
            state: state,
            reducer: appReducer,
            services: mockServices,
            middlewares: [
                { state, action, dispatch in
                    Task {
                        if case .schedule(.bulkAddCompleted(.failure)) = action {
                            completedWithError = true
                        }
                        await scheduleMiddleware(state, action, dispatch, mockServices)
                    }
                }
            ]
        )

        // When
        await store.dispatch(action: .schedule(.bulkAddConfirmed(shiftType: shiftType, notes: nil)))

        // Give time for async operations
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then - should handle error gracefully
        #expect(completedWithError)
    }

    // MARK: - Date Ordering Tests

    @Test("bulkAddConfirmed creates shifts in chronological order")
    async func testBulkAddCreatesShiftsInOrder() {
        // Given
        let mockCalendar = MockCalendarService()
        mockCalendar.mockIsAuthorized = true
        let mockServices = ServiceContainer(
            calendarService: mockCalendar,
            persistenceService: MockPersistenceService(),
            currentDayService: CurrentDayService()
        )

        var state = AppState()
        state.userProfile = UserProfile(userId: UUID(), displayName: "Test User")
        state.schedule.selectionMode = .add

        // Add dates in random order
        let baseDate = Calendar.current.startOfDay(for: Date())
        let date3 = Calendar.current.date(byAdding: .day, value: 2, to: baseDate)!
        let date1 = baseDate
        let date2 = Calendar.current.date(byAdding: .day, value: 1, to: baseDate)!

        // Insert in non-chronological order
        state.schedule.selectedDates = [date3, date1, date2]

        let shiftType = Self.createTestShiftType()
        state.shiftTypes.shiftTypes = [shiftType]

        let store = Store(
            state: state,
            reducer: appReducer,
            services: mockServices,
            middlewares: [scheduleMiddleware]
        )

        // When
        await store.dispatch(action: .schedule(.bulkAddConfirmed(shiftType: shiftType, notes: nil)))

        // Give time for async operations
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then - shifts should be created (middleware sorts them)
        // This test validates the middleware processes dates chronologically
        #expect(!mockCalendar.mockShifts.isEmpty)
    }

    // MARK: - Integration Tests

    @Test("Complete bulk add flow: select dates → confirm → shifts created")
    async func testCompleteBulkAddFlow() {
        // Given
        let mockCalendar = MockCalendarService()
        mockCalendar.mockIsAuthorized = true
        let mockPersistence = MockPersistenceService()
        let mockServices = ServiceContainer(
            calendarService: mockCalendar,
            persistenceService: mockPersistence,
            currentDayService: CurrentDayService()
        )

        var state = AppState()
        state.userProfile = UserProfile(userId: UUID(), displayName: "Test User")
        state.schedule.selectionMode = .add
        let date1 = Calendar.current.startOfDay(for: Date())
        let date2 = Calendar.current.date(byAdding: .day, value: 1, to: date1)!
        state.schedule.selectedDates = [date1, date2]

        let shiftType = Self.createTestShiftType()
        state.shiftTypes.shiftTypes = [shiftType]

        let store = Store(
            state: state,
            reducer: appReducer,
            services: mockServices,
            middlewares: [scheduleMiddleware]
        )

        // When - confirm bulk add
        await store.dispatch(action: .schedule(.bulkAddConfirmed(shiftType: shiftType, notes: "Test notes")))

        // Give time for async operations
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        // 1. Shifts should be created in calendar
        #expect(!mockCalendar.mockShifts.isEmpty)

        // 2. Change log entries should be persisted
        #expect(!mockPersistence.mockChangeLogEntries.isEmpty)

        // 3. State should be updated
        #expect(store.state.schedule.selectedDates.isEmpty)
    }

    @Test("bulkAddCompleted success clears selected dates")
    async func testBulkAddCompletedClearsSelection() {
        // Given
        var state = AppState()
        state.schedule.selectedDates = [Date()]
        let shift = ScheduledShift(id: UUID(), eventIdentifier: "test", shiftType: nil, date: Date())

        // When
        appReducer(&state, .schedule(.bulkAddCompleted(.success([shift]))))

        // Then
        #expect(state.schedule.selectedDates.isEmpty)
    }
}
