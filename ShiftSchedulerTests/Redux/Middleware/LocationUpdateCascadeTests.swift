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
            currentDayService: CurrentDayService()
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

        var dispatchedActions: [AppAction] = []
        let dispatcher: Dispatcher<AppAction> = { action in
            dispatchedActions.append(action)
        }

        let state = AppState()

        // When
        await locationsMiddleware(
            state: state,
            action: .locations(.saveLocation(updatedLocation)),
            services: mockServices,
            dispatch: dispatcher
        )

        // Then
        // Verify saveLocation was called
        #expect(mockPersistence.saveLocationCallCount == 1)

        // Verify updateShiftTypesWithLocation was called
        #expect(mockPersistence.updateShiftTypesWithLocationCallCount == 1)

        // Verify correct actions were dispatched
        #expect(dispatchedActions.count >= 3)

        // Should dispatch shiftTypes refresh
        let hasShiftTypesRefresh = dispatchedActions.contains { action in
            if case .shiftTypes(.refreshShiftTypes) = action {
                return true
            }
            return false
        }
        #expect(hasShiftTypesRefresh, "Should dispatch shiftTypes refresh when ShiftTypes are updated")

        // Should dispatch location saved success
        let hasLocationSaved = dispatchedActions.contains { action in
            if case .locations(.locationSaved(.success)) = action {
                return true
            }
            return false
        }
        #expect(hasLocationSaved, "Should dispatch location saved success")

        // Should dispatch locations refresh
        let hasLocationsRefresh = dispatchedActions.contains { action in
            if case .locations(.refreshLocations) = action {
                return true
            }
            return false
        }
        #expect(hasLocationsRefresh, "Should dispatch locations refresh")

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

        var dispatchedActions: [AppAction] = []
        let dispatcher: Dispatcher<AppAction> = { action in
            dispatchedActions.append(action)
        }

        let state = AppState()

        // When
        await locationsMiddleware(
            state: state,
            action: .locations(.saveLocation(location)),
            services: mockServices,
            dispatch: dispatcher
        )

        // Then
        #expect(mockPersistence.saveLocationCallCount == 1)
        #expect(mockPersistence.updateShiftTypesWithLocationCallCount == 1)

        // Should NOT dispatch shiftTypes refresh since no ShiftTypes were affected
        let hasShiftTypesRefresh = dispatchedActions.contains { action in
            if case .shiftTypes(.refreshShiftTypes) = action {
                return true
            }
            return false
        }
        #expect(!hasShiftTypesRefresh, "Should not dispatch shiftTypes refresh when no ShiftTypes are affected")

        // Should still dispatch success and refresh
        let hasLocationSaved = dispatchedActions.contains { action in
            if case .locations(.locationSaved(.success)) = action {
                return true
            }
            return false
        }
        #expect(hasLocationSaved)

        let hasLocationsRefresh = dispatchedActions.contains { action in
            if case .locations(.refreshLocations) = action {
                return true
            }
            return false
        }
        #expect(hasLocationsRefresh)
    }

    @Test("saveLocation handles persistence error gracefully")
    func testSaveLocationPersistenceError() async throws {
        // Given
        let mockServices = Self.createMockServiceContainer()
        let mockPersistence = try #require(mockServices.persistenceService as? MockPersistenceService)

        let location = LocationBuilder(name: "Office", address: "123 Main St").build()

        mockPersistence.shouldThrowError = true
        mockPersistence.throwError = NSError(domain: "TestError", code: 1, userInfo: nil)

        var dispatchedActions: [AppAction] = []
        let dispatcher: Dispatcher<AppAction> = { action in
            dispatchedActions.append(action)
        }

        let state = AppState()

        // When
        await locationsMiddleware(
            state: state,
            action: .locations(.saveLocation(location)),
            services: mockServices,
            dispatch: dispatcher
        )

        // Then
        #expect(mockPersistence.saveLocationCallCount == 1)

        // Should dispatch failure action
        let hasLocationSavedFailure = dispatchedActions.contains { action in
            if case .locations(.locationSaved(.failure)) = action {
                return true
            }
            return false
        }
        #expect(hasLocationSavedFailure, "Should dispatch location saved failure on error")

        // Should not dispatch refresh actions on error
        let hasShiftTypesRefresh = dispatchedActions.contains { action in
            if case .shiftTypes(.refreshShiftTypes) = action {
                return true
            }
            return false
        }
        #expect(!hasShiftTypesRefresh, "Should not dispatch shiftTypes refresh on error")

        let hasLocationsRefresh = dispatchedActions.contains { action in
            if case .locations(.refreshLocations) = action {
                return true
            }
            return false
        }
        #expect(!hasLocationsRefresh, "Should not dispatch locations refresh on error")
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

        var dispatchedActions: [AppAction] = []
        let dispatcher: Dispatcher<AppAction> = { action in
            dispatchedActions.append(action)
        }

        let state = AppState()

        // When
        await locationsMiddleware(
            state: state,
            action: .locations(.saveLocation(updatedLocation)),
            services: mockServices,
            dispatch: dispatcher
        )

        // Then
        #expect(mockPersistence.saveLocationCallCount == 1)
        #expect(mockPersistence.updateShiftTypesWithLocationCallCount == 1)

        // Verify all 5 ShiftTypes were updated
        #expect(mockPersistence.mockShiftTypes.count == 5)
        for shiftType in mockPersistence.mockShiftTypes {
            #expect(shiftType.location.address == "200 New Health Ave")
        }

        // Should dispatch shiftTypes refresh
        let hasShiftTypesRefresh = dispatchedActions.contains { action in
            if case .shiftTypes(.refreshShiftTypes) = action {
                return true
            }
            return false
        }
        #expect(hasShiftTypesRefresh)
    }
}
