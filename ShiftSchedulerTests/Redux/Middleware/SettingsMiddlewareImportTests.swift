import Testing
import Foundation
@testable import ShiftScheduler

/// Tests for SettingsMiddleware shift import feature
/// Validates parsing/validation, conflict handling, and shift creation via .confirmImport
@Suite("SettingsMiddleware Import Tests")
@MainActor
struct SettingsMiddlewareImportTests {

    // MARK: - Test Helpers

    static func createMockServiceContainer() -> ServiceContainer {
        ServiceContainer(
            calendarService: MockCalendarService(),
            persistenceService: MockPersistenceService(),
            currentDayService: CurrentDayService(),
            timeChangeService: MockTimeChangeService()
        )
    }

    static func date(_ year: Int, _ month: Int, _ day: Int) throws -> Date {
        try #require(Calendar.current.date(from: DateComponents(year: year, month: month, day: day)))
    }

    // MARK: - Validate Tests

    @Test("Validate generates a preview resolving known symbols against the catalog")
    func testValidateResolvesKnownSymbols() async throws {
        let mockServices = Self.createMockServiceContainer()
        let dayShift = ShiftTypeBuilder(symbol: "d", title: "Day").build()

        var state = AppState()
        state.shiftTypes.shiftTypes = [dayShift]
        state.settings.importText = "2026-01-01 d x"

        var preview: ShiftImportPreview?

        func mockTrackingMiddleware(
            state: AppState,
            action: AppAction,
            services: ServiceContainer,
            dispatch: @escaping Dispatcher<AppAction>
        ) async {
            if case .settings(.importPreviewGenerated(let generated)) = action {
                preview = generated
            }
        }

        let store = Store(
            state: state,
            reducer: appReducer,
            services: mockServices,
            middlewares: [settingsMiddleware, mockTrackingMiddleware]
        )

        await store.dispatch(action: .settings(.validateImport))

        let resolved = try #require(preview)
        #expect(resolved.days.count == 2)
        #expect(resolved.importableCount == 1)
        if case .willImport(let shiftType) = resolved.days[0].status {
            #expect(shiftType.symbol == "d")
        } else {
            Issue.record("Expected first day to resolve to the day shift")
        }
        #expect(resolved.days[1].status == .skipped)
    }

    @Test("Validate flags unknown symbols as blocking errors")
    func testValidateFlagsUnknownSymbol() async throws {
        let mockServices = Self.createMockServiceContainer()

        var state = AppState()
        state.shiftTypes.shiftTypes = []
        state.settings.importText = "2026-01-01 zz"

        var preview: ShiftImportPreview?

        func mockTrackingMiddleware(
            state: AppState,
            action: AppAction,
            services: ServiceContainer,
            dispatch: @escaping Dispatcher<AppAction>
        ) async {
            if case .settings(.importPreviewGenerated(let generated)) = action {
                preview = generated
            }
        }

        let store = Store(
            state: state,
            reducer: appReducer,
            services: mockServices,
            middlewares: [settingsMiddleware, mockTrackingMiddleware]
        )

        await store.dispatch(action: .settings(.validateImport))

        let resolved = try #require(preview)
        #expect(resolved.hasBlockingErrors)
        #expect(resolved.days[0].status == .unknownSymbol("zz"))
    }

    @Test("Validate detects a conflict with an already-scheduled shift")
    func testValidateDetectsConflict() async throws {
        let mockServices = Self.createMockServiceContainer()
        let mockCalendar = try #require(mockServices.calendarService as? MockCalendarService)

        let dayShift = ShiftTypeBuilder(symbol: "d", title: "Day").build()
        let targetDate = try Self.date(2026, 1, 1)
        let existing = ScheduledShift(
            eventIdentifier: "existing-1",
            shiftType: dayShift,
            date: targetDate
        )
        mockCalendar.mockShifts = [existing]

        var state = AppState()
        state.shiftTypes.shiftTypes = [dayShift]
        state.settings.importText = "2026-01-01 d"

        var preview: ShiftImportPreview?

        func mockTrackingMiddleware(
            state: AppState,
            action: AppAction,
            services: ServiceContainer,
            dispatch: @escaping Dispatcher<AppAction>
        ) async {
            if case .settings(.importPreviewGenerated(let generated)) = action {
                preview = generated
            }
        }

        let store = Store(
            state: state,
            reducer: appReducer,
            services: mockServices,
            middlewares: [settingsMiddleware, mockTrackingMiddleware]
        )

        await store.dispatch(action: .settings(.validateImport))

        let resolved = try #require(preview)
        #expect(resolved.conflictCount == 1)
        #expect(!resolved.hasBlockingErrors)
    }

    @Test("Validate reports a parse error for malformed input")
    func testValidateReportsParseError() async throws {
        let mockServices = Self.createMockServiceContainer()

        var state = AppState()
        state.settings.importText = "not-a-date d"

        var errorMessage: String?

        func mockTrackingMiddleware(
            state: AppState,
            action: AppAction,
            services: ServiceContainer,
            dispatch: @escaping Dispatcher<AppAction>
        ) async {
            if case .settings(.importFailed(let message)) = action {
                errorMessage = message
            }
        }

        let store = Store(
            state: state,
            reducer: appReducer,
            services: mockServices,
            middlewares: [settingsMiddleware, mockTrackingMiddleware]
        )

        await store.dispatch(action: .settings(.validateImport))

        #expect(errorMessage != nil)
    }

    // MARK: - Confirm Import Tests

    @Test("Confirm import creates shifts and change log entries for importable days")
    func testConfirmImportCreatesShiftsAndChangeLogEntries() async throws {
        let mockServices = Self.createMockServiceContainer()
        let mockCalendar = try #require(mockServices.calendarService as? MockCalendarService)
        let mockPersistence = try #require(mockServices.persistenceService as? MockPersistenceService)

        let dayShift = ShiftTypeBuilder(symbol: "d", title: "Day").build()

        var state = AppState()
        state.shiftTypes.shiftTypes = [dayShift]
        state.settings.importPreview = ShiftImportPreview(days: [
            ShiftImportPreview.Day(date: try Self.date(2026, 1, 1), symbol: "d", status: .willImport(dayShift)),
            ShiftImportPreview.Day(date: try Self.date(2026, 1, 2), symbol: "x", status: .skipped)
        ])

        var completedCount: Int?
        var loadShiftsDispatched = false

        func mockTrackingMiddleware(
            state: AppState,
            action: AppAction,
            services: ServiceContainer,
            dispatch: @escaping Dispatcher<AppAction>
        ) async {
            if case .settings(.importCompleted(.success(let count))) = action {
                completedCount = count
            }
            if case .schedule(.loadShifts) = action {
                loadShiftsDispatched = true
            }
        }

        let store = Store(
            state: state,
            reducer: appReducer,
            services: mockServices,
            middlewares: [settingsMiddleware, mockTrackingMiddleware]
        )

        await store.dispatch(action: .settings(.confirmImport))

        #expect(completedCount == 1)
        #expect(mockCalendar.createShiftEventCallCount == 1)
        #expect(mockPersistence.addChangeLogEntryCallCount == 1)
        #expect(loadShiftsDispatched)
    }

    @Test("Confirm import is blocked when the preview has unknown symbols")
    func testConfirmImportBlockedByUnknownSymbol() async throws {
        let mockServices = Self.createMockServiceContainer()
        let mockCalendar = try #require(mockServices.calendarService as? MockCalendarService)

        var state = AppState()
        state.settings.importPreview = ShiftImportPreview(days: [
            ShiftImportPreview.Day(date: try Self.date(2026, 1, 1), symbol: "zz", status: .unknownSymbol("zz"))
        ])

        var errorMessage: String?

        func mockTrackingMiddleware(
            state: AppState,
            action: AppAction,
            services: ServiceContainer,
            dispatch: @escaping Dispatcher<AppAction>
        ) async {
            if case .settings(.importFailed(let message)) = action {
                errorMessage = message
            }
        }

        let store = Store(
            state: state,
            reducer: appReducer,
            services: mockServices,
            middlewares: [settingsMiddleware, mockTrackingMiddleware]
        )

        await store.dispatch(action: .settings(.confirmImport))

        #expect(errorMessage != nil)
        #expect(mockCalendar.createShiftEventCallCount == 0)
    }

    @Test("Confirm import aborts entirely when policy is abortOnConflict and conflicts exist")
    func testConfirmImportAbortsOnConflictPolicy() async throws {
        let mockServices = Self.createMockServiceContainer()
        let mockCalendar = try #require(mockServices.calendarService as? MockCalendarService)

        let dayShift = ShiftTypeBuilder(symbol: "d", title: "Day").build()

        var state = AppState()
        state.settings.importConflictPolicy = .abortOnConflict
        state.settings.importPreview = ShiftImportPreview(days: [
            ShiftImportPreview.Day(date: try Self.date(2026, 1, 1), symbol: "d", status: .willImport(dayShift)),
            ShiftImportPreview.Day(date: try Self.date(2026, 1, 2), symbol: "d", status: .conflict(dayShift, existingEventIdentifier: "existing"))
        ])

        var errorMessage: String?

        func mockTrackingMiddleware(
            state: AppState,
            action: AppAction,
            services: ServiceContainer,
            dispatch: @escaping Dispatcher<AppAction>
        ) async {
            if case .settings(.importFailed(let message)) = action {
                errorMessage = message
            }
        }

        let store = Store(
            state: state,
            reducer: appReducer,
            services: mockServices,
            middlewares: [settingsMiddleware, mockTrackingMiddleware]
        )

        await store.dispatch(action: .settings(.confirmImport))

        #expect(errorMessage != nil)
        #expect(mockCalendar.createShiftEventCallCount == 0)
    }

    @Test("Confirm import skips conflicting days under skipConflicts policy")
    func testConfirmImportSkipsConflictsUnderDefaultPolicy() async throws {
        let mockServices = Self.createMockServiceContainer()
        let mockCalendar = try #require(mockServices.calendarService as? MockCalendarService)

        let dayShift = ShiftTypeBuilder(symbol: "d", title: "Day").build()

        var state = AppState()
        state.settings.importConflictPolicy = .skipConflicts
        state.settings.importPreview = ShiftImportPreview(days: [
            ShiftImportPreview.Day(date: try Self.date(2026, 1, 1), symbol: "d", status: .willImport(dayShift)),
            ShiftImportPreview.Day(date: try Self.date(2026, 1, 2), symbol: "d", status: .conflict(dayShift, existingEventIdentifier: "existing"))
        ])

        var completedCount: Int?

        func mockTrackingMiddleware(
            state: AppState,
            action: AppAction,
            services: ServiceContainer,
            dispatch: @escaping Dispatcher<AppAction>
        ) async {
            if case .settings(.importCompleted(.success(let count))) = action {
                completedCount = count
            }
        }

        let store = Store(
            state: state,
            reducer: appReducer,
            services: mockServices,
            middlewares: [settingsMiddleware, mockTrackingMiddleware]
        )

        await store.dispatch(action: .settings(.confirmImport))

        #expect(completedCount == 1)
        #expect(mockCalendar.createShiftEventCallCount == 1)
    }
}
