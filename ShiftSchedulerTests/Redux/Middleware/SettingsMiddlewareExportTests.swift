import Testing
import Foundation
@testable import ShiftScheduler

/// Tests for SettingsMiddleware shift export feature
/// Validates that the export feature correctly formats shifts with tildes for unscheduled dates
@Suite("SettingsMiddleware Export Tests")
@MainActor
struct SettingsMiddlewareExportTests {

    // MARK: - Test Helpers

    /// Create a test service container with mocks
    static func createMockServiceContainer() -> ServiceContainer {
        ServiceContainer(
            calendarService: MockCalendarService(),
            persistenceService: MockPersistenceService(),
            currentDayService: CurrentDayService(),
            timeChangeService: MockTimeChangeService()
        )
    }

    /// Create test shifts for specific dates
    static func createTestShifts(
        from startDate: Date,
        symbolMap: [Date: String]
    ) -> [ScheduledShift] {
        symbolMap.map { date, symbol in
            let shiftType = ShiftTypeBuilder(symbol: symbol, title: symbol, description: "Test shift").build()
            return ScheduledShift(
                id: UUID(),
                eventIdentifier: "test-\(UUID())",
                shiftType: shiftType,
                date: date
            )
        }
    }

    // MARK: - Export Format Tests

    @Test("Export with all dates scheduled produces no tildes")
    func testExportWithAllDatesScheduled() async throws {
        // Given
        let mockServices = Self.createMockServiceContainer()
        let mockCalendar = try #require(mockServices.calendarService as? MockCalendarService)

        // Create three consecutive days, all with shifts
        let startDate = try #require(Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 3)))
        let date1 = startDate
        let date2 = try #require(Calendar.current.date(byAdding: .day, value: 1, to: date1))
        let date3 = try #require(Calendar.current.date(byAdding: .day, value: 2, to: date1))
        let endDate = date3

        // Map dates to symbols (all scheduled)
        let shifts = Self.createTestShifts(
            from: startDate,
            symbolMap: [
                date1: "D",
                date2: "N",
                date3: "X"
            ]
        )
        mockCalendar.mockShifts = shifts

        var exportedSymbols: String?

        func mockTrackingMiddleware(
            state: AppState,
            action: AppAction,
            services: ServiceContainer,
            dispatch: @escaping Dispatcher<AppAction>
        ) async {
            if case .settings(.exportGenerated(let symbols)) = action {
                exportedSymbols = symbols
            }
        }

        var state = AppState()
        state.settings.exportStartDate = startDate
        state.settings.exportEndDate = endDate

        let store = Store(
            state: state,
            reducer: appReducer,
            services: mockServices,
            middlewares: [settingsMiddleware, mockTrackingMiddleware]
        )

        // When
        await store.dispatch(action: .settings(.generateExport))

        // Then
        #expect(exportedSymbols == "D N X", "Expected all scheduled dates without tildes, got: \(exportedSymbols ?? "nil")")
    }

    @Test("Export with single unscheduled date in middle produces tilde")
    func testExportWithSingleUnscheduledDate() async throws {
        // Given
        let mockServices = Self.createMockServiceContainer()
        let mockCalendar = try #require(mockServices.calendarService as? MockCalendarService)

        // Create three consecutive days, middle day unscheduled
        let startDate = try #require(Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 3)))
        let date1 = startDate
        let date3 = try #require(Calendar.current.date(byAdding: .day, value: 2, to: date1))
        let endDate = date3

        // Map dates to symbols (day 2 unscheduled)
        let shifts = Self.createTestShifts(
            from: startDate,
            symbolMap: [
                date1: "D",
                date3: "X"
            ]
        )
        mockCalendar.mockShifts = shifts

        var exportedSymbols: String?

        func mockTrackingMiddleware(
            state: AppState,
            action: AppAction,
            services: ServiceContainer,
            dispatch: @escaping Dispatcher<AppAction>
        ) async {
            if case .settings(.exportGenerated(let symbols)) = action {
                exportedSymbols = symbols
            }
        }

        var state = AppState()
        state.settings.exportStartDate = startDate
        state.settings.exportEndDate = endDate

        let store = Store(
            state: state,
            reducer: appReducer,
            services: mockServices,
            middlewares: [settingsMiddleware, mockTrackingMiddleware]
        )

        // When
        await store.dispatch(action: .settings(.generateExport))

        // Then
        #expect(exportedSymbols == "D ~ X", "Expected tilde for unscheduled middle day, got: \(exportedSymbols ?? "nil")")
    }

    @Test("Export with multiple unscheduled dates produces multiple tildes")
    func testExportWithMultipleUnscheduledDates() async throws {
        // Given
        let mockServices = Self.createMockServiceContainer()
        let mockCalendar = try #require(mockServices.calendarService as? MockCalendarService)

        // Create five consecutive days, days 2 and 4 unscheduled
        let startDate = try #require(Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 3)))
        let date1 = startDate
        let date3 = try #require(Calendar.current.date(byAdding: .day, value: 2, to: date1))
        let date5 = try #require(Calendar.current.date(byAdding: .day, value: 4, to: date1))
        let endDate = date5

        // Map dates to symbols (days 2 and 4 unscheduled)
        let shifts = Self.createTestShifts(
            from: startDate,
            symbolMap: [
                date1: "A",
                date3: "C",
                date5: "E"
            ]
        )
        mockCalendar.mockShifts = shifts

        var exportedSymbols: String?

        func mockTrackingMiddleware(
            state: AppState,
            action: AppAction,
            services: ServiceContainer,
            dispatch: @escaping Dispatcher<AppAction>
        ) async {
            if case .settings(.exportGenerated(let symbols)) = action {
                exportedSymbols = symbols
            }
        }

        var state = AppState()
        state.settings.exportStartDate = startDate
        state.settings.exportEndDate = endDate

        let store = Store(
            state: state,
            reducer: appReducer,
            services: mockServices,
            middlewares: [settingsMiddleware, mockTrackingMiddleware]
        )

        // When
        await store.dispatch(action: .settings(.generateExport))

        // Then
        #expect(exportedSymbols == "A ~ C ~ E", "Expected tildes for days 2 and 4, got: \(exportedSymbols ?? "nil")")
    }

    @Test("Export with all dates unscheduled produces all tildes")
    func testExportWithAllDatesUnscheduled() async throws {
        // Given
        let mockServices = Self.createMockServiceContainer()
        let mockCalendar = try #require(mockServices.calendarService as? MockCalendarService)

        // Create three consecutive days, all unscheduled
        let startDate = try #require(Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 3)))
        let endDate = try #require(Calendar.current.date(byAdding: .day, value: 2, to: startDate))

        // No shifts scheduled
        mockCalendar.mockShifts = []

        var exportedSymbols: String?

        func mockTrackingMiddleware(
            state: AppState,
            action: AppAction,
            services: ServiceContainer,
            dispatch: @escaping Dispatcher<AppAction>
        ) async {
            if case .settings(.exportGenerated(let symbols)) = action {
                exportedSymbols = symbols
            }
        }

        var state = AppState()
        state.settings.exportStartDate = startDate
        state.settings.exportEndDate = endDate

        let store = Store(
            state: state,
            reducer: appReducer,
            services: mockServices,
            middlewares: [settingsMiddleware, mockTrackingMiddleware]
        )

        // When
        await store.dispatch(action: .settings(.generateExport))

        // Then
        #expect(exportedSymbols == "~ ~ ~", "Expected all tildes for unscheduled dates, got: \(exportedSymbols ?? "nil")")
    }

    @Test("Export with unscheduled date at start produces tilde")
    func testExportWithUnscheduledAtStart() async throws {
        // Given
        let mockServices = Self.createMockServiceContainer()
        let mockCalendar = try #require(mockServices.calendarService as? MockCalendarService)

        // Create three consecutive days, first day unscheduled
        let startDate = try #require(Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 3)))
        let date1 = startDate
        let date2 = try #require(Calendar.current.date(byAdding: .day, value: 1, to: date1))
        let date3 = try #require(Calendar.current.date(byAdding: .day, value: 2, to: date1))
        let endDate = date3

        // Map dates to symbols (day 1 unscheduled)
        let shifts = Self.createTestShifts(
            from: startDate,
            symbolMap: [
                date2: "B",
                date3: "C"
            ]
        )
        mockCalendar.mockShifts = shifts

        var exportedSymbols: String?

        func mockTrackingMiddleware(
            state: AppState,
            action: AppAction,
            services: ServiceContainer,
            dispatch: @escaping Dispatcher<AppAction>
        ) async {
            if case .settings(.exportGenerated(let symbols)) = action {
                exportedSymbols = symbols
            }
        }

        var state = AppState()
        state.settings.exportStartDate = startDate
        state.settings.exportEndDate = endDate

        let store = Store(
            state: state,
            reducer: appReducer,
            services: mockServices,
            middlewares: [settingsMiddleware, mockTrackingMiddleware]
        )

        // When
        await store.dispatch(action: .settings(.generateExport))

        // Then
        #expect(exportedSymbols == "~ B C", "Expected tilde for unscheduled first day, got: \(exportedSymbols ?? "nil")")
    }

    @Test("Export with unscheduled date at end produces tilde")
    func testExportWithUnscheduledAtEnd() async throws {
        // Given
        let mockServices = Self.createMockServiceContainer()
        let mockCalendar = try #require(mockServices.calendarService as? MockCalendarService)

        // Create three consecutive days, last day unscheduled
        let startDate = try #require(Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 3)))
        let date1 = startDate
        let date2 = try #require(Calendar.current.date(byAdding: .day, value: 1, to: date1))
        let date3 = try #require(Calendar.current.date(byAdding: .day, value: 2, to: date1))
        let endDate = date3

        // Map dates to symbols (day 3 unscheduled)
        let shifts = Self.createTestShifts(
            from: startDate,
            symbolMap: [
                date1: "A",
                date2: "B"
            ]
        )
        mockCalendar.mockShifts = shifts

        var exportedSymbols: String?

        func mockTrackingMiddleware(
            state: AppState,
            action: AppAction,
            services: ServiceContainer,
            dispatch: @escaping Dispatcher<AppAction>
        ) async {
            if case .settings(.exportGenerated(let symbols)) = action {
                exportedSymbols = symbols
            }
        }

        var state = AppState()
        state.settings.exportStartDate = startDate
        state.settings.exportEndDate = endDate

        let store = Store(
            state: state,
            reducer: appReducer,
            services: mockServices,
            middlewares: [settingsMiddleware, mockTrackingMiddleware]
        )

        // When
        await store.dispatch(action: .settings(.generateExport))

        // Then
        #expect(exportedSymbols == "A B ~", "Expected tilde for unscheduled last day, got: \(exportedSymbols ?? "nil")")
    }
}
