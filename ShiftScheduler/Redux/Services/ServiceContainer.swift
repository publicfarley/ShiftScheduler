import Foundation

/// Central service container providing all Redux middleware dependencies
/// Implements factory pattern for service creation and management
/// NO SINGLETONS - All services are injected via this container
public final class ServiceContainer {
    // MARK: - Stored Properties (Lazy Initialized Services)

    private lazy var _calendarService: CalendarServiceProtocol = CalendarService()
    private lazy var _persistenceService: PersistenceServiceProtocol = PersistenceService()
    private lazy var _currentDayService: CurrentDayServiceProtocol = CurrentDayService()
    private lazy var _timeChangeService: TimeChangeServiceProtocol = TimeChangeService()

    // MARK: - Public Service Accessors

    /// Get the calendar service instance
    var calendarService: CalendarServiceProtocol {
        _calendarService
    }

    /// Get the persistence service instance
    var persistenceService: PersistenceServiceProtocol {
        _persistenceService
    }

    /// Get the current day service instance
    var currentDayService: CurrentDayServiceProtocol {
        _currentDayService
    }

    /// Get the time change service instance
    var timeChangeService: TimeChangeServiceProtocol {
        _timeChangeService
    }

    // MARK: - Initialization

    /// Create a new service container with production services
    init() {}

    /// Create a service container with custom services (for testing)
    init(
        calendarService: CalendarServiceProtocol,
        persistenceService: PersistenceServiceProtocol,
        currentDayService: CurrentDayServiceProtocol,
        timeChangeService: TimeChangeServiceProtocol) {
        self._calendarService = calendarService
        self._persistenceService = persistenceService
        self._currentDayService = currentDayService
        self._timeChangeService = timeChangeService
    }

    // MARK: - Test Helpers

    /// Create a test service container with mock services
    static func createTestContainer() -> ServiceContainer {
        let calendarService = MockCalendarService()
        let persistenceService = MockPersistenceService()
        let currentDayService = MockCurrentDayService()
        let timeChangeService = MockTimeChangeService()

        return ServiceContainer(
            calendarService: calendarService,
            persistenceService: persistenceService,
            currentDayService: currentDayService,
            timeChangeService: timeChangeService
        )
    }

    /// Create a service container with partially mocked services
    /// Used for integration testing where some services should be real
    static func createPartialMockContainer(
        mockCalendar: Bool = false,
        mockPersistence: Bool = false,
        mockCurrentDay: Bool = false,
        mockShiftSwitch: Bool = false,
        mockTimeChange: Bool = false
    ) -> ServiceContainer {
        let calendarService: CalendarServiceProtocol = mockCalendar ? MockCalendarService() : CalendarService()
        let persistenceService: PersistenceServiceProtocol = mockPersistence ? MockPersistenceService() : PersistenceService()
        let currentDayService: CurrentDayServiceProtocol = mockCurrentDay ? MockCurrentDayService() : CurrentDayService()
        let timeChangeService: TimeChangeServiceProtocol = mockTimeChange ? MockTimeChangeService() : TimeChangeService()

        return ServiceContainer(
            calendarService: calendarService,
            persistenceService: persistenceService,
            currentDayService: currentDayService,
            timeChangeService: timeChangeService
        )
    }
}

// MARK: - Shared Instance (Optional - For Convenience)

/// Global shared service container instance
/// Usage in Redux middleware: let services = ServiceContainer.shared
/// For testing: Create a new container with mock services
extension ServiceContainer {
    private static var _shared: ServiceContainer?

    /// Get or create the shared service container instance
    static var shared: ServiceContainer {
        if let existing = _shared {
            return existing
        }
        let new = ServiceContainer()
        _shared = new
        return new
    }

    /// Reset the shared container (useful for testing)
    static func resetShared() {
        _shared = nil
    }

    /// Set a custom shared container (useful for testing)
    static func setSharedForTesting(_ container: ServiceContainer) {
        _shared = container
    }
}
