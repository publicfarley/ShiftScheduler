import Testing
import Foundation
@testable import ShiftScheduler

/// Tests for the calendar-events recovery path in AppStartupMiddleware.loadInitialData
/// (Part B): when the local cache has no shift types, rebuild them from the calendar.
@Suite("AppStartupMiddleware Recovery Tests")
@MainActor
struct AppStartupRecoveryTests {

    private func makeShiftType(title: String) -> ShiftType {
        ShiftType(
            id: UUID(),
            symbol: "☀️",
            duration: .allDay,
            title: title,
            description: "",
            location: Location(id: UUID(), name: "Work", address: "1 Main St")
        )
    }

    @Test("Empty shift-type cache triggers recovery and persists reconstructed data")
    func recoversWhenCacheEmpty() async throws {
        let calendar = MockCalendarService()
        let recovered = makeShiftType(title: "Day Shift")
        calendar.mockRecoveryResult = .init(shiftTypes: [recovered], locations: [recovered.location])

        let persistence = MockPersistenceService()
        persistence.mockShiftTypes = []
        persistence.mockLocations = []

        let services = ServiceContainer(
            calendarService: calendar,
            persistenceService: persistence,
            currentDayService: MockCurrentDayService(),
            timeChangeService: MockTimeChangeService()
        )

        var dispatched: [AppAction] = []
        let dispatch: @MainActor (AppAction) async -> Void = { dispatched.append($0) }

        await appStartupMiddleware(AppState(), .appLifecycle(.loadInitialData), services, dispatch)

        #expect(calendar.recoverShiftTypeDataCallCount == 1)
        #expect(persistence.mockShiftTypes.contains { $0.id == recovered.id })
        #expect(persistence.mockLocations.contains { $0.id == recovered.location.id })

        // The shiftTypesLoaded dispatch should carry the recovered type.
        let loadedTypes: [ShiftType]? = dispatched.compactMap {
            if case .shiftTypes(.shiftTypesLoaded(.success(let types))) = $0 { return types }
            return nil
        }.first
        #expect(loadedTypes?.contains { $0.id == recovered.id } == true)
    }

    @Test("Non-empty shift-type cache skips recovery entirely")
    func skipsRecoveryWhenCachePopulated() async throws {
        let calendar = MockCalendarService()
        let persistence = MockPersistenceService()
        persistence.mockShiftTypes = [makeShiftType(title: "Existing")]

        let services = ServiceContainer(
            calendarService: calendar,
            persistenceService: persistence,
            currentDayService: MockCurrentDayService(),
            timeChangeService: MockTimeChangeService()
        )

        await appStartupMiddleware(AppState(), .appLifecycle(.loadInitialData), services) { _ in }

        #expect(calendar.recoverShiftTypeDataCallCount == 0)
    }

    @Test("Recovery yielding nothing still completes initialization without crashing")
    func recoveryEmptyStillCompletes() async throws {
        let calendar = MockCalendarService()
        calendar.mockRecoveryResult = .init(shiftTypes: [], locations: [])

        let persistence = MockPersistenceService()
        persistence.mockShiftTypes = []

        let services = ServiceContainer(
            calendarService: calendar,
            persistenceService: persistence,
            currentDayService: MockCurrentDayService(),
            timeChangeService: MockTimeChangeService()
        )

        var dispatched: [AppAction] = []
        let mockDispatch: @MainActor (AppAction) async -> Void = { action in
            dispatched.append(action)
        }
        await appStartupMiddleware(AppState(), .appLifecycle(.loadInitialData), services, mockDispatch)

        let completed = dispatched.contains {
            if case .appLifecycle(.initializationComplete(.success)) = $0 { return true }
            return false
        }
        #expect(completed)
    }

    // MARK: - Recovery after calendar access is granted

    private func makeServices(
        calendar: MockCalendarService,
        persistence: MockPersistenceService
    ) -> ServiceContainer {
        ServiceContainer(
            calendarService: calendar,
            persistenceService: persistence,
            currentDayService: MockCurrentDayService(),
            timeChangeService: MockTimeChangeService()
        )
    }

    @Test("Granting calendar access with an empty cache triggers recovery and publishes the result")
    func grantingAccessWithEmptyCacheRecovers() async throws {
        // Given: first launch, no local shift types, calendar holds recoverable events
        let calendar = MockCalendarService()
        let recovered = makeShiftType(title: "Day Shift")
        calendar.mockRecoveryResult = .init(shiftTypes: [recovered], locations: [recovered.location])
        let persistence = MockPersistenceService()
        let services = makeServices(calendar: calendar, persistence: persistence)

        var dispatched: [AppAction] = []
        let dispatch: @MainActor (AppAction) async -> Void = { dispatched.append($0) }

        // When: the user taps Allow on the permission prompt
        await appStartupMiddleware(
            AppState(), .appLifecycle(.calendarAccessRequested(.success(true))), services, dispatch
        )

        // Then
        #expect(calendar.recoverShiftTypeDataCallCount == 1)
        #expect(persistence.mockShiftTypes.contains { $0.id == recovered.id })
        #expect(persistence.mockLocations.contains { $0.id == recovered.location.id })

        let loadedTypes: [ShiftType]? = dispatched.compactMap {
            if case .shiftTypes(.shiftTypesLoaded(.success(let types))) = $0 { return types }
            return nil
        }.first
        #expect(loadedTypes?.contains { $0.id == recovered.id } == true)

        let loadedLocations: [Location]? = dispatched.compactMap {
            if case .locations(.locationsLoaded(.success(let locations))) = $0 { return locations }
            return nil
        }.first
        #expect(loadedLocations?.contains { $0.id == recovered.location.id } == true)
    }

    @Test("Denied calendar access does not attempt recovery")
    func deniedAccessSkipsRecovery() async throws {
        // Given
        let calendar = MockCalendarService()
        let persistence = MockPersistenceService()
        let services = makeServices(calendar: calendar, persistence: persistence)

        var dispatched: [AppAction] = []
        let dispatch: @MainActor (AppAction) async -> Void = { dispatched.append($0) }

        // When
        await appStartupMiddleware(
            AppState(), .appLifecycle(.calendarAccessRequested(.success(false))), services, dispatch
        )

        // Then
        #expect(calendar.recoverShiftTypeDataCallCount == 0)
        #expect(dispatched.isEmpty)
    }

    @Test("Granting calendar access with a populated cache skips recovery")
    func grantingAccessWithPopulatedCacheSkipsRecovery() async throws {
        // Given
        let calendar = MockCalendarService()
        let existing = makeShiftType(title: "Existing")
        let persistence = MockPersistenceService()
        persistence.mockShiftTypes = [existing]
        let services = makeServices(calendar: calendar, persistence: persistence)

        var dispatched: [AppAction] = []
        let dispatch: @MainActor (AppAction) async -> Void = { dispatched.append($0) }

        // When
        await appStartupMiddleware(
            AppState(), .appLifecycle(.calendarAccessRequested(.success(true))), services, dispatch
        )

        // Then
        #expect(calendar.recoverShiftTypeDataCallCount == 0)
        #expect(persistence.mockShiftTypes.map(\.id) == [existing.id])
    }

    @Test("Recovery that finds nothing after access is granted does not publish empty data")
    func emptyRecoveryAfterGrantPublishesNothing() async throws {
        // Given: calendar has no shift events to rebuild from
        let calendar = MockCalendarService()
        calendar.mockRecoveryResult = .init(shiftTypes: [], locations: [])
        let persistence = MockPersistenceService()
        let services = makeServices(calendar: calendar, persistence: persistence)

        var dispatched: [AppAction] = []
        let dispatch: @MainActor (AppAction) async -> Void = { dispatched.append($0) }

        // When
        await appStartupMiddleware(
            AppState(), .appLifecycle(.calendarAccessRequested(.success(true))), services, dispatch
        )

        // Then: recovery was attempted, but nothing was saved or published
        #expect(calendar.recoverShiftTypeDataCallCount == 1)
        #expect(persistence.mockShiftTypes.isEmpty)
        #expect(persistence.mockLocations.isEmpty)
        #expect(dispatched.isEmpty)
    }
}
