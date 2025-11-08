import Testing
import Foundation
@testable import ShiftScheduler

/// Tests for ShiftType update cascade functionality
/// Validates that updating a ShiftType cascades to all calendar events that were created from it
@Suite("ShiftType Update Cascade Tests")
@MainActor
struct ShiftTypeUpdateCascadeTests {

    // MARK: - Test Helpers

    /// Create a test service container with mocks
    static func createMockServiceContainer() -> ServiceContainer {
        ServiceContainer(
            calendarService: MockCalendarService(),
            persistenceService: MockPersistenceService(),
            currentDayService: CurrentDayService()
        )
    }
    
    // MARK: - ShiftType Cascade Tests

    @Test("saveShiftType cascades update to calendar events created from the ShiftType")
    func testSaveShiftTypeCascadesToCalendarEvents() async throws {
        // Given
        let mockServices = Self.createMockServiceContainer()
        let mockCalendar = try #require(mockServices.calendarService as? MockCalendarService)
        let mockPersistence = try #require(mockServices.persistenceService as? MockPersistenceService)

        let location = LocationBuilder(name: "Office", address: "123 Main St").build()
        let shiftType = ShiftTypeBuilder(title: "Day Shift", location: location).build()
        let updatedShiftType = ShiftType(
            id: shiftType.id,
            symbol: shiftType.symbol,
            duration: shiftType.duration,
            title: "Updated Day Shift",
            description: "New description",
            location: location
        )

        // Create calendar events that reference the shift type
        let shift1 = ScheduledShift(
            id: UUID(),
            eventIdentifier: "event1",
            shiftType: shiftType,
            date: Date()
        )
        let shift2 = ScheduledShift(
            id: UUID(),
            eventIdentifier: "event2",
            shiftType: shiftType,
            date: Date().addingTimeInterval(86400)
        )
        mockCalendar.mockShifts = [shift1, shift2]

        // Mock locations to pass validation
        mockPersistence.mockLocations = [location]

        var state = AppState()
        state.locations.locations = [location]
        state.shiftTypes.shiftTypes = [shiftType]

        var dispatchedActions: [AppAction] = []
        let dispatcher: Dispatcher<AppAction> = { action in
            dispatchedActions.append(action)
        }

        // When
        await shiftTypesMiddleware(
            state: state,
            action: .shiftTypes(.saveShiftType(updatedShiftType)),
            services: mockServices,
            dispatch: dispatcher
        )

        // Then
        // Verify saveShiftType was called
        #expect(mockPersistence.saveShiftTypeCallCount == 1)

        // Verify updateEventsWithShiftType was called
        #expect(mockCalendar.updateEventsWithShiftTypeCallCount == 1)

        // Verify correct actions were dispatched
        #expect(dispatchedActions.count >= 3)

        // Should dispatch schedule refresh
        let hasScheduleRefresh = dispatchedActions.contains { action in
            if case .schedule(.loadShifts) = action {
                return true
            }
            return false
        }
        #expect(hasScheduleRefresh, "Should dispatch schedule refresh when calendar events are updated")

        // Should dispatch shift type saved success
        let hasShiftTypeSaved = dispatchedActions.contains { action in
            if case .shiftTypes(.shiftTypeSaved(.success)) = action {
                return true
            }
            return false
        }
        #expect(hasShiftTypeSaved, "Should dispatch shift type saved success")

        // Should dispatch shift types refresh
        let hasShiftTypesRefresh = dispatchedActions.contains { action in
            if case .shiftTypes(.refreshShiftTypes) = action {
                return true
            }
            return false
        }
        #expect(hasShiftTypesRefresh, "Should dispatch shift types refresh")

        // Verify calendar events were updated
        #expect(mockCalendar.mockShifts.count == 2)
        #expect(mockCalendar.mockShifts[0].shiftType?.title == "Updated Day Shift")
        #expect(mockCalendar.mockShifts[1].shiftType?.title == "Updated Day Shift")
    }

    @Test("saveShiftType does not dispatch schedule refresh when no events reference the ShiftType")
    func testSaveShiftTypeWithNoAffectedEvents() async throws {
        // Given
        let mockServices = Self.createMockServiceContainer()
        let mockCalendar = try #require(mockServices.calendarService as? MockCalendarService)
        let mockPersistence = try #require(mockServices.persistenceService as? MockPersistenceService)

        let location = LocationBuilder(name: "Office", address: "123 Main St").build()
        let shiftType = ShiftTypeBuilder(title: "Day Shift", location: location).build()
        let otherShiftType = ShiftTypeBuilder(title: "Night Shift", location: location).build()

        // Create calendar event that references a different shift type
        let shift = ScheduledShift(
            id: UUID(),
            eventIdentifier: "event1",
            shiftType: otherShiftType,
            date: Date()
        )
        mockCalendar.mockShifts = [shift]

        // Mock locations to pass validation
        mockPersistence.mockLocations = [location]

        var state = AppState()
        state.locations.locations = [location]
        state.shiftTypes.shiftTypes = [shiftType, otherShiftType]

        func mockTrackingMiddleware(
            state: AppState,
            action: AppAction,
            services: ServiceContainer,
            dispatch: @escaping Dispatcher<AppAction>
        ) async {
            switch action {
            case .shiftTypes(.shiftTypeSaved(.success)), .shiftTypes(.refreshShiftTypes):
                // Should still dispatch success and refresh
                print("As expected")
                
            case .schedule(.loadShifts):
                Issue.record("Should not dispatch schedule refresh when no events are affected")
            default:
                break
            }
        }

        let store = Store(
            state: state,
            reducer: appReducer,
            services: mockServices,
            middlewares: [shiftTypesMiddleware, scheduleMiddleware, mockTrackingMiddleware]
        )
        
        // When
        await store.dispatch(action: .shiftTypes(.saveShiftType(shiftType)))

        // Then
        #expect(mockPersistence.saveShiftTypeCallCount == 1)
        #expect(mockCalendar.updateEventsWithShiftTypeCallCount == 1)
    }

    @Test("saveShiftType handles calendar service error gracefully")
    func testSaveShiftTypeCalendarError() async throws {
        // Given
        let mockServices = Self.createMockServiceContainer()
        let mockCalendar = try #require(mockServices.calendarService as? MockCalendarService)
        let mockPersistence = try #require(mockServices.persistenceService as? MockPersistenceService)

        let location = LocationBuilder(name: "Office", address: "123 Main St").build()
        let shiftType = ShiftTypeBuilder(title: "Day Shift", location: location).build()

        // Configure calendar to throw error
        mockCalendar.shouldThrowError = true
        mockCalendar.throwError = NSError(domain: "TestError", code: 1, userInfo: nil)

        // Mock locations to pass validation
        mockPersistence.mockLocations = [location]

        var state = AppState()
        state.locations.locations = [location]
        state.shiftTypes.shiftTypes = [shiftType]

        var dispatchedActions: [AppAction] = []
        let dispatcher: Dispatcher<AppAction> = { action in
            dispatchedActions.append(action)
        }

        // When
        await shiftTypesMiddleware(
            state: state,
            action: .shiftTypes(.saveShiftType(shiftType)),
            services: mockServices,
            dispatch: dispatcher
        )

        // Then
        #expect(mockPersistence.saveShiftTypeCallCount == 1)

        // Should dispatch failure action
        let hasShiftTypeSavedFailure = dispatchedActions.contains { action in
            if case .shiftTypes(.shiftTypeSaved(.failure)) = action {
                return true
            }
            return false
        }
        #expect(hasShiftTypeSavedFailure, "Should dispatch shift type saved failure on calendar error")

        // Should not dispatch refresh actions on error
        let hasScheduleRefresh = dispatchedActions.contains { action in
            if case .schedule(.loadShifts) = action {
                return true
            }
            return false
        }
        #expect(!hasScheduleRefresh, "Should not dispatch schedule refresh on error")

        let hasShiftTypesRefresh = dispatchedActions.contains { action in
            if case .shiftTypes(.refreshShiftTypes) = action {
                return true
            }
            return false
        }
        #expect(!hasShiftTypesRefresh, "Should not dispatch shift types refresh on error")
    }

    @Test("saveShiftType updates multiple calendar events with same ShiftType")
    func testSaveShiftTypeUpdatesMultipleEvents() async throws {
        // Given
        let mockServices = Self.createMockServiceContainer()
        let mockCalendar = try #require(mockServices.calendarService as? MockCalendarService)
        let mockPersistence = try #require(mockServices.persistenceService as? MockPersistenceService)

        let location = LocationBuilder(name: "Office", address: "123 Main St").build()
        let shiftType = ShiftTypeBuilder(title: "Day Shift", location: location).build()
        let updatedShiftType = ShiftType(
            id: shiftType.id,
            symbol: shiftType.symbol,
            duration: shiftType.duration,
            title: "Updated Day Shift",
            description: shiftType.shiftDescription,
            location: location
        )

        // Create 5 calendar events that all reference the same shift type
        let shifts = (1...5).map { index in
            ScheduledShift(
                id: UUID(),
                eventIdentifier: "event\(index)",
                shiftType: shiftType,
                date: Date().addingTimeInterval(Double(index) * 86400)
            )
        }
        mockCalendar.mockShifts = shifts

        // Mock locations to pass validation
        mockPersistence.mockLocations = [location]

        var state = AppState()
        state.locations.locations = [location]
        state.shiftTypes.shiftTypes = [shiftType]

        var dispatchedActions: [AppAction] = []
        let dispatcher: Dispatcher<AppAction> = { action in
            dispatchedActions.append(action)
        }

        // When
        await shiftTypesMiddleware(
            state: state,
            action: .shiftTypes(.saveShiftType(updatedShiftType)),
            services: mockServices,
            dispatch: dispatcher
        )

        // Then
        #expect(mockPersistence.saveShiftTypeCallCount == 1)
        #expect(mockCalendar.updateEventsWithShiftTypeCallCount == 1)

        // Verify all 5 events were updated
        #expect(mockCalendar.mockShifts.count == 5)
        for shift in mockCalendar.mockShifts {
            #expect(shift.shiftType?.title == "Updated Day Shift")
        }

        // Should dispatch schedule refresh
        let hasScheduleRefresh = dispatchedActions.contains { action in
            if case .schedule(.loadShifts) = action {
                return true
            }
            return false
        }
        #expect(hasScheduleRefresh)
    }

    @Test("saveShiftType preserves validation checks before cascading")
    func testSaveShiftTypeValidationBeforeCascade() async throws {
        // Given
        let mockServices = Self.createMockServiceContainer()
        let mockCalendar = try #require(mockServices.calendarService as? MockCalendarService)
        let mockPersistence = try #require(mockServices.persistenceService as? MockPersistenceService)

        let location = LocationBuilder(name: "Office", address: "123 Main St").build()
        let shiftType = ShiftTypeBuilder(symbol: "D", title: "Day Shift", location: location).build()
        let duplicateSymbolShiftType = ShiftType(
            id: UUID(), // Different ID
            symbol: "D", // Same symbol
            duration: shiftType.duration,
            title: "Another Shift",
            description: "",
            location: location
        )

        // Mock locations to pass location validation
        mockPersistence.mockLocations = [location]

        var state = AppState()
        state.locations.locations = [location]
        state.shiftTypes.shiftTypes = [shiftType] // Existing shift type with same symbol

        var dispatchedActions: [AppAction] = []
        let dispatcher: Dispatcher<AppAction> = { action in
            dispatchedActions.append(action)
        }

        // When
        await shiftTypesMiddleware(
            state: state,
            action: .shiftTypes(.saveShiftType(duplicateSymbolShiftType)),
            services: mockServices,
            dispatch: dispatcher
        )

        // Then
        // Should fail validation and not reach cascade logic
        #expect(mockPersistence.saveShiftTypeCallCount == 0, "Should not save when validation fails")
        #expect(mockCalendar.updateEventsWithShiftTypeCallCount == 0, "Should not cascade when validation fails")

        // Should dispatch failure action
        let hasShiftTypeSavedFailure = dispatchedActions.contains { action in
            if case .shiftTypes(.shiftTypeSaved(.failure)) = action {
                return true
            }
            return false
        }
        #expect(hasShiftTypeSavedFailure, "Should dispatch failure when duplicate symbol detected")
    }
}
