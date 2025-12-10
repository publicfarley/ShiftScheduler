import Foundation

/// Central service container providing all Redux middleware dependencies
/// Implements factory pattern for service creation and management
/// NO SINGLETONS - All services are injected via this container
public final class ServiceContainer {
    // MARK: - Stored Properties (Lazy Initialized Services)

    private var _calendarService: CalendarServiceProtocol
    private var _persistenceService: PersistenceServiceProtocol
    private var _currentDayService: CurrentDayServiceProtocol
    private var _conflictResolutionService: ConflictResolutionServiceProtocol
    private var _syncService: SyncServiceProtocol

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

    /// Get the conflict resolution service instance
    var conflictResolutionService: ConflictResolutionServiceProtocol {
        _conflictResolutionService
    }

    /// Get the sync service instance
    var syncService: SyncServiceProtocol {
        _syncService
    }


    // MARK: - Initialization

    /// Create a new service container with production services
    init() {
        self._calendarService = CalendarService()
        self._persistenceService = PersistenceService()
        self._currentDayService = CurrentDayService()
        self._conflictResolutionService = ConflictResolutionService()
        self._syncService = CloudKitSyncService(
            persistenceService: self._persistenceService,
            conflictResolutionService: self._conflictResolutionService
        )
    }

    /// Create a service container with custom services (for testing)
    init(
        calendarService: CalendarServiceProtocol,
        persistenceService: PersistenceServiceProtocol,
        currentDayService: CurrentDayServiceProtocol,
        conflictResolutionService: ConflictResolutionServiceProtocol,
        syncService: SyncServiceProtocol
    ) {
        self._calendarService = calendarService
        self._persistenceService = persistenceService
        self._currentDayService = currentDayService
        self._conflictResolutionService = conflictResolutionService
        self._syncService = syncService
    }

    // MARK: - Test Helpers

    /// Create a test service container with mock services
    static func createTestContainer() -> ServiceContainer {
        let calendarService = MockCalendarService()
        let persistenceService = MockPersistenceService()
        let currentDayService = MockCurrentDayService()
        let conflictResolutionService = ConflictResolutionService()
        let syncService = MockSyncService()

        return ServiceContainer(
            calendarService: calendarService,
            persistenceService: persistenceService,
            currentDayService: currentDayService,
            conflictResolutionService: conflictResolutionService,
            syncService: syncService
        )
    }

    /// Create a service container with partially mocked services
    /// Used for integration testing where some services should be real
    static func createPartialMockContainer(
        mockCalendar: Bool = false,
        mockPersistence: Bool = false,
        mockCurrentDay: Bool = false,
        mockShiftSwitch: Bool = false,
        mockSync: Bool = false
    ) -> ServiceContainer {
        let calendarService: CalendarServiceProtocol = mockCalendar ? MockCalendarService() : CalendarService()
        let persistenceService: PersistenceServiceProtocol = mockPersistence ? MockPersistenceService() : PersistenceService()
        let currentDayService: CurrentDayServiceProtocol = mockCurrentDay ? MockCurrentDayService() : CurrentDayService()
        let conflictResolutionService: ConflictResolutionServiceProtocol = ConflictResolutionService()
        let syncService: SyncServiceProtocol = mockSync ? MockSyncService() : CloudKitSyncService(
            persistenceService: persistenceService,
            conflictResolutionService: conflictResolutionService
        )

        return ServiceContainer(
            calendarService: calendarService,
            persistenceService: persistenceService,
            currentDayService: currentDayService,
            conflictResolutionService: conflictResolutionService,
            syncService: syncService
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
