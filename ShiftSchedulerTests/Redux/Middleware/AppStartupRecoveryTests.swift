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
        await appStartupMiddleware(AppState(), .appLifecycle(.loadInitialData), services) { dispatched.append($0) }

        let completed = dispatched.contains {
            if case .appLifecycle(.initializationComplete(.success)) = $0 { return true }
            return false
        }
        #expect(completed)
    }
}
