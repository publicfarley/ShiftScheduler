import Testing
import Foundation
@testable import ShiftScheduler

/// Tests for Location update cascade functionality
/// Validates that updating a Location cascades to all ShiftTypes that reference it
@Suite("Location Update Cascade Tests")
@MainActor
struct LocationUpdateCascadeTests {

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

    // MARK: - Location Cascade Tests

    @Test("saveLocation cascades update to ShiftTypes that reference the Location")
    func testSaveLocationCascadesToShiftTypes() async throws {
        // Given
        let mockServices = Self.createMockServiceContainer()
        let mockPersistence = try #require(mockServices.persistenceService as? MockPersistenceService)

        let location = LocationBuilder(name: "Office", address: "123 Main St").build()
        let updatedLocation = Location(id: location.id, name: "Office", address: "456 New St")

        // Create shift types that reference the location
        let shiftType1 = ShiftTypeBuilder(title: "Day Shift", location: location).build()
        let shiftType2 = ShiftTypeBuilder(title: "Night Shift", location: location).build()

        // Pre-populate mock with shift types
        mockPersistence.mockShiftTypes = [shiftType1, shiftType2]

        var isLocationSaved = false
        var isShiftTypesRefreshed = false
        var isLocationsRefreshed = false

        func mockTrackingMiddleware(
            state: AppState,
            action: AppAction,
            services: ServiceContainer,
            dispatch: @escaping Dispatcher<AppAction>
        ) async {
            switch action {
            case .locations(.locationSaved(.success)):
                isLocationSaved = true
            case .locations(.locationSaved(.failure)):
                Issue.record("Should not get failure when saving location")
            case .shiftTypes(.refreshShiftTypes):
                isShiftTypesRefreshed = true
            case .locations(.refreshLocations):
                isLocationsRefreshed = true
            default:
                break
            }
        }

        var state = AppState()
        state.locations.locations = [location]

        let store = Store(
            state: state,
            reducer: appReducer,
            services: mockServices,
            middlewares: [locationsMiddleware, mockTrackingMiddleware]
        )

        // When
        await store.dispatch(action: .locations(.saveLocation(updatedLocation)))

        // Then
        // Verify saveLocation was called
        #expect(mockPersistence.saveLocationCallCount == 1)

        // Verify updateShiftTypesWithLocation was called
        #expect(mockPersistence.updateShiftTypesWithLocationCallCount == 1)

        // Verify correct actions were dispatched
        #expect(isLocationSaved, "Should dispatch location saved success")
        #expect(isShiftTypesRefreshed, "Should dispatch shiftTypes refresh when ShiftTypes are updated")
        #expect(isLocationsRefreshed, "Should dispatch locations refresh")

        // Verify ShiftTypes were updated with new location data
        #expect(mockPersistence.mockShiftTypes.count == 2)
        #expect(mockPersistence.mockShiftTypes[0].location.address == "456 New St")
        #expect(mockPersistence.mockShiftTypes[1].location.address == "456 New St")
    }

    @Test("saveLocation does not dispatch shiftTypes refresh when no ShiftTypes reference the Location")
    func testSaveLocationWithNoAffectedShiftTypes() async throws {
        // Given
        let mockServices = Self.createMockServiceContainer()
        let mockPersistence = try #require(mockServices.persistenceService as? MockPersistenceService)

        let location = LocationBuilder(name: "Office", address: "123 Main St").build()
        let otherLocation = LocationBuilder(name: "Home", address: "789 Home Ave").build()

        // Create shift type that references a different location
        let shiftType = ShiftTypeBuilder(title: "Day Shift", location: otherLocation).build()
        mockPersistence.mockShiftTypes = [shiftType]

        var isLocationSaved = false
        var isLocationsRefreshed = false
        var isShiftTypesRefreshed = false

        func mockTrackingMiddleware(
            state: AppState,
            action: AppAction,
            services: ServiceContainer,
            dispatch: @escaping Dispatcher<AppAction>
        ) async {
            switch action {
            case .locations(.locationSaved(.success)):
                isLocationSaved = true
            case .locations(.locationSaved(.failure)):
                Issue.record("Should not get failure when saving location")
            case .locations(.refreshLocations):
                isLocationsRefreshed = true
            case .shiftTypes(.refreshShiftTypes):
                isShiftTypesRefreshed = true
            default:
                break
            }
        }

        var state = AppState()
        state.locations.locations = [location]
        state.shiftTypes.shiftTypes = [shiftType]

        let store = Store(
            state: state,
            reducer: appReducer,
            services: mockServices,
            middlewares: [locationsMiddleware, mockTrackingMiddleware]
        )

        // When
        await store.dispatch(action: .locations(.saveLocation(location)))

        // Then
        #expect(mockPersistence.saveLocationCallCount == 1)
        #expect(mockPersistence.updateShiftTypesWithLocationCallCount == 1)

        // Should NOT dispatch shiftTypes refresh since no ShiftTypes were affected
        #expect(!isShiftTypesRefreshed, "Should not dispatch shiftTypes refresh when no ShiftTypes are affected")

        // Should still dispatch success and refresh
        #expect(isLocationSaved)
        #expect(isLocationsRefreshed)
    }

    @Test("saveLocation handles persistence error gracefully")
    func testSaveLocationPersistenceError() async throws {
        // Given
        let mockServices = Self.createMockServiceContainer()
        let mockPersistence = try #require(mockServices.persistenceService as? MockPersistenceService)

        let location = LocationBuilder(name: "Office", address: "123 Main St").build()

        mockPersistence.shouldThrowError = true
        mockPersistence.throwError = NSError(domain: "TestError", code: 1, userInfo: nil)

        var isLocationSavedFailure = false
        var isShiftTypesRefreshed = false
        var isLocationsRefreshed = false

        func mockTrackingMiddleware(
            state: AppState,
            action: AppAction,
            services: ServiceContainer,
            dispatch: @escaping Dispatcher<AppAction>
        ) async {
            switch action {
            case .locations(.locationSaved(.failure)):
                isLocationSavedFailure = true
            case .locations(.locationSaved(.success)):
                Issue.record("Should not succeed when persistence error occurs")
            case .shiftTypes(.refreshShiftTypes):
                isShiftTypesRefreshed = true
            case .locations(.refreshLocations):
                isLocationsRefreshed = true
            default:
                break
            }
        }

        var state = AppState()
        state.locations.locations = [location]

        let store = Store(
            state: state,
            reducer: appReducer,
            services: mockServices,
            middlewares: [locationsMiddleware, mockTrackingMiddleware]
        )

        // When
        await store.dispatch(action: .locations(.saveLocation(location)))

        // Then
        #expect(mockPersistence.saveLocationCallCount == 1)

        // Should dispatch failure action
        #expect(isLocationSavedFailure, "Should dispatch location saved failure on error")

        // Should not dispatch refresh actions on error
        #expect(!isShiftTypesRefreshed, "Should not dispatch shiftTypes refresh on error")
        #expect(!isLocationsRefreshed, "Should not dispatch locations refresh on error")
    }

    @Test("saveLocation updates multiple ShiftTypes with same Location")
    func testSaveLocationUpdatesMultipleShiftTypes() async throws {
        // Given
        let mockServices = Self.createMockServiceContainer()
        let mockPersistence = try #require(mockServices.persistenceService as? MockPersistenceService)

        let location = LocationBuilder(name: "Hospital", address: "100 Health Blvd").build()
        let updatedLocation = Location(id: location.id, name: "Hospital", address: "200 New Health Ave")

        // Create 5 shift types that all reference the same location
        let shiftTypes = (1...5).map { index in
            ShiftTypeBuilder(title: "Shift \(index)", location: location).build()
        }
        mockPersistence.mockShiftTypes = shiftTypes

        var isLocationSaved = false
        var isShiftTypesRefreshed = false

        func mockTrackingMiddleware(
            state: AppState,
            action: AppAction,
            services: ServiceContainer,
            dispatch: @escaping Dispatcher<AppAction>
        ) async {
            switch action {
            case .locations(.locationSaved(.success)):
                isLocationSaved = true
            case .shiftTypes(.refreshShiftTypes):
                isShiftTypesRefreshed = true
            default:
                break
            }
        }

        var state = AppState()
        state.locations.locations = [location]

        let store = Store(
            state: state,
            reducer: appReducer,
            services: mockServices,
            middlewares: [locationsMiddleware, mockTrackingMiddleware]
        )

        // When
        await store.dispatch(action: .locations(.saveLocation(updatedLocation)))

        // Then
        #expect(mockPersistence.saveLocationCallCount == 1)
        #expect(mockPersistence.updateShiftTypesWithLocationCallCount == 1)

        // Verify all 5 ShiftTypes were updated
        #expect(mockPersistence.mockShiftTypes.count == 5)
        for shiftType in mockPersistence.mockShiftTypes {
            #expect(shiftType.location.address == "200 New Health Ave")
        }

        // Should dispatch shiftTypes refresh
        #expect(isLocationSaved)
        #expect(isShiftTypesRefreshed)
    }
}
