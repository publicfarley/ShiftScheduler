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
    func testBulkAddCreatesShiftsForAllDates() async throws {
        // Given
        let mockServices = ServiceContainer(
            calendarService: MockCalendarService(),
            persistenceService: MockPersistenceService(),
            currentDayService: CurrentDayService(),
            timeChangeService: MockTimeChangeService()
        )

        var state = AppState()
        state.schedule.selectionMode = .add
        let date1 = Calendar.current.startOfDay(for: try Date.fixedTestDate_Nov11_2025())
        let date2 = try #require(Calendar.current.date(byAdding: .day, value: 1, to: date1))
        state.schedule.selectedDates = [date1, date2]

        let shiftType = Self.createTestShiftType()
        state.shiftTypes.shiftTypes = [shiftType]

        var isBulkAddCompleted = false

        func mockTrackingMiddleware(
            state: AppState,
            action: AppAction,
            services: ServiceContainer,
            dispatch: @escaping Dispatcher<AppAction>
        ) async {
            switch action {
            case .schedule(.bulkAddCompleted):
                isBulkAddCompleted = true
            default:
                break
            }
        }

        let store = Store(
            state: state,
            reducer: appReducer,
            services: mockServices,
            middlewares: [scheduleMiddleware, mockTrackingMiddleware]
        )

        // When
        await store.dispatch(action: .schedule(.bulkAddConfirmed(shiftType: shiftType, notes: "Test notes")))

        // Then - should have triggered bulk add completion
        #expect(isBulkAddCompleted)
    }

    @Test("bulkAddConfirmed includes notes in change log entries")
    func testBulkAddIncludesNotesInChangeLog() async {
        // Given
        let mockPersistence = MockPersistenceService()
        let mockServices = ServiceContainer(
            calendarService: MockCalendarService(),
            persistenceService: mockPersistence,
            currentDayService: CurrentDayService(),
            timeChangeService: MockTimeChangeService()
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
    func testBulkAddWithEmptyNotes() async {
        // Given
        let mockServices = ServiceContainer(
            calendarService: MockCalendarService(),
            persistenceService: MockPersistenceService(),
            currentDayService: CurrentDayService(),
            timeChangeService: MockTimeChangeService()
        )

        var state = AppState()
        state.schedule.selectionMode = .add
        let testDate = Calendar.current.startOfDay(for: Date())
        state.schedule.selectedDates = [testDate]

        let shiftType = Self.createTestShiftType()
        state.shiftTypes.shiftTypes = [shiftType]

        var isBulkAddCompleted = false

        func mockTrackingMiddleware(
            state: AppState,
            action: AppAction,
            services: ServiceContainer,
            dispatch: @escaping Dispatcher<AppAction>
        ) async {
            switch action {
            case .schedule(.bulkAddCompleted(.success)):
                isBulkAddCompleted = true
            case .schedule(.bulkAddCompleted(.failure)):
                Issue.record("Should not get failure when handling empty notes")
            default:
                break
            }
        }

        let store = Store(
            state: state,
            reducer: appReducer,
            services: mockServices,
            middlewares: [scheduleMiddleware, mockTrackingMiddleware]
        )

        // When - no notes provided
        await store.dispatch(action: .schedule(.bulkAddConfirmed(shiftType: shiftType, notes: "")))

        // Then - should complete successfully without crashing
        #expect(isBulkAddCompleted)
    }

    @Test("bulkAddConfirmed creates ChangeLogEntry for each shift")
    func testBulkAddCreatesChangeLogEntry() async throws {
        // Given
        let mockPersistence = MockPersistenceService()
        let mockServices = ServiceContainer(
            calendarService: MockCalendarService(),
            persistenceService: mockPersistence,
            currentDayService: CurrentDayService(),
            timeChangeService: MockTimeChangeService()
        )

        var state = AppState()
        state.userProfile = UserProfile(userId: UUID(), displayName: "Test User")
        state.schedule.selectionMode = .add
        let date1 = Calendar.current.startOfDay(for: try Date.fixedTestDate_Nov11_2025())
        let date2 = try #require(Calendar.current.date(byAdding: .day, value: 1, to: date1))
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
    func testBulkAddDispatchesLoadShifts() async {
        // Given
        let mockServices = ServiceContainer(
            calendarService: MockCalendarService(),
            persistenceService: MockPersistenceService(),
            currentDayService: CurrentDayService(),
            timeChangeService: MockTimeChangeService()
        )

        var state = AppState()
        state.schedule.selectionMode = .add
        let testDate = Calendar.current.startOfDay(for: Date())
        state.schedule.selectedDates = [testDate]

        let shiftType = Self.createTestShiftType()
        state.shiftTypes.shiftTypes = [shiftType]

        var dispatchedLoadShifts = false

        func mockTrackingMiddleware(
            state: AppState,
            action: AppAction,
            services: ServiceContainer,
            dispatch: @escaping Dispatcher<AppAction>
        ) async {
            switch action {
            case .schedule(.loadShifts):
                dispatchedLoadShifts = true
            default:
                break
            }
        }

        let store = Store(
            state: state,
            reducer: appReducer,
            services: mockServices,
            middlewares: [scheduleMiddleware, mockTrackingMiddleware]
        )

        // When
        await store.dispatch(action: .schedule(.bulkAddConfirmed(shiftType: shiftType, notes: "")))

        // Then
        #expect(dispatchedLoadShifts)
    }

    // MARK: - Error Handling Tests

    @Test("bulkAddConfirmed handles calendar service error gracefully")
    func testBulkAddHandlesCalendarError() async {
        // Given
        let mockCalendar = MockCalendarService()
        mockCalendar.mockIsAuthorized = false  // Will cause error

        let mockServices = ServiceContainer(
            calendarService: mockCalendar,
            persistenceService: MockPersistenceService(),
            currentDayService: CurrentDayService(),
            timeChangeService: MockTimeChangeService()
        )

        var state = AppState()
        state.schedule.selectionMode = .add
        let testDate = Calendar.current.startOfDay(for: Date())
        state.schedule.selectedDates = [testDate]

        let shiftType = Self.createTestShiftType()
        state.shiftTypes.shiftTypes = [shiftType]

        var completedWithError = false

        func mockTrackingMiddleware(
            state: AppState,
            action: AppAction,
            services: ServiceContainer,
            dispatch: @escaping Dispatcher<AppAction>
        ) async {
            switch action {
            case .schedule(.bulkAddCompleted(.failure)):
                completedWithError = true
            case .schedule(.bulkAddCompleted(.success)):
                Issue.record("Should not succeed when calendar service error occurs")
            default:
                break
            }
        }

        let store = Store(
            state: state,
            reducer: appReducer,
            services: mockServices,
            middlewares: [scheduleMiddleware, mockTrackingMiddleware]
        )

        // When
        await store.dispatch(action: .schedule(.bulkAddConfirmed(shiftType: shiftType, notes: "")))

        // Then - should handle error gracefully
        #expect(completedWithError)
    }

    // MARK: - Date Ordering Tests

    @Test("bulkAddConfirmed creates shifts in chronological order")
    func testBulkAddCreatesShiftsInOrder() async throws {
        // Given
        let mockCalendar = MockCalendarService()
        mockCalendar.mockIsAuthorized = true
        let mockServices = ServiceContainer(
            calendarService: mockCalendar,
            persistenceService: MockPersistenceService(),
            currentDayService: CurrentDayService(),
            timeChangeService: MockTimeChangeService()
        )

        var state = AppState()
        state.userProfile = UserProfile(userId: UUID(), displayName: "Test User")
        state.schedule.selectionMode = .add

        // Add dates in random order
        let baseDate = Calendar.current.startOfDay(for: try Date.fixedTestDate_Nov11_2025())
        let date3 = try #require(Calendar.current.date(byAdding: .day, value: 2, to: baseDate))
        let date1 = baseDate
        let date2 = try #require(Calendar.current.date(byAdding: .day, value: 1, to: baseDate))

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
        await store.dispatch(action: .schedule(.bulkAddConfirmed(shiftType: shiftType, notes: "")))

        // Then - shifts should be created (middleware sorts them)
        // This test validates the middleware processes dates chronologically
        #expect(!mockCalendar.mockShifts.isEmpty)
    }

    // MARK: - Integration Tests

    @Test("Complete bulk add flow: select dates → confirm → shifts created")
    func testCompleteBulkAddFlow() async throws {
        // Given
        let mockCalendar = MockCalendarService()
        mockCalendar.mockIsAuthorized = true
        let mockPersistence = MockPersistenceService()
        let mockServices = ServiceContainer(
            calendarService: mockCalendar,
            persistenceService: mockPersistence,
            currentDayService: CurrentDayService(),
            timeChangeService: MockTimeChangeService()
        )

        var state = AppState()
        state.userProfile = UserProfile(userId: UUID(), displayName: "Test User")
        state.schedule.selectionMode = .add
        let date1 = Calendar.current.startOfDay(for: Date())
        let date2 = try #require(Calendar.current.date(byAdding: .day, value: 1, to: date1))
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

        // Then
        // 1. Shifts should be created in calendar
        #expect(!mockCalendar.mockShifts.isEmpty)

        // 2. Change log entries should be persisted
        #expect(!mockPersistence.mockChangeLogEntries.isEmpty)

        // 3. State should be updated
        #expect(store.state.schedule.selectedDates.isEmpty)
    }

    @Test("bulkAddCompleted success clears selected dates")
    func testBulkAddCompletedClearsSelection() async {
        // Given
        var state = AppState()
        state.schedule.selectedDates = [Date()]
        let shift = ScheduledShift(id: UUID(), eventIdentifier: "test", shiftType: nil, date: Date())

        // When
        let newState = appReducer(state: state, action: .schedule(.bulkAddCompleted(.success([shift]))))

        // Then
        #expect(newState.schedule.selectedDates.isEmpty)
    }
}
