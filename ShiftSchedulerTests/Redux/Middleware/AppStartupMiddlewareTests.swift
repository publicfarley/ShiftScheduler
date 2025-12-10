import Testing
import Foundation
@testable import ShiftScheduler

/// Tests for the AppStartupMiddleware calendar authorization verification
@Suite("AppStartupMiddleware Tests")
@MainActor
struct AppStartupMiddlewareTests {

    // MARK: - App Startup Authorization Flow

    @Test("When app appears with no authorization verification, should dispatch verification action")
    func testAppAppearsDispatchesVerification() async {
        // Create initial state where authorization hasn't been verified
        var state = AppState()
        state.isCalendarAuthorizationVerified = false
        state.isCalendarAuthorized = false

        var dispatchedActions: [AppAction] = []
        let mockDispatch: @MainActor (AppAction) async -> Void = { action in
            dispatchedActions.append(action)
        }

        let mockServices = ServiceContainer(
            calendarService: MockCalendarService(),
            persistenceService: MockPersistenceService(),
            currentDayService: MockCurrentDayService(),
            conflictResolutionService: ConflictResolutionService(),
            syncService: MockSyncService()
        )

        // Dispatch onAppear action
        await appStartupMiddleware(state, .appLifecycle(.onAppAppear), mockServices, mockDispatch)

        // Middleware should dispatch: userProfileUpdated, profileLoaded, and verifyCalendarAccessOnStartup
        #expect(!dispatchedActions.isEmpty)
        #expect(dispatchedActions.count >= 3)

        // Verify verification action was dispatched
        let hasVerificationAction = dispatchedActions.contains { action in
            if case .appLifecycle(.verifyCalendarAccessOnStartup) = action {
                return true
            }
            return false
        }
        #expect(hasVerificationAction, "Expected verifyCalendarAccessOnStartup action to be dispatched")
    }

    @Test("When app appears with already verified authorization, should load profile but skip verification")
    func testAppAppearsWithVerifiedAuthorizationDoesNothing() async {
        // Create initial state where authorization has already been verified
        var state = AppState()
        state.isCalendarAuthorizationVerified = true
        state.isCalendarAuthorized = true

        var dispatchedActions: [AppAction] = []
        let mockDispatch: @MainActor (AppAction) async -> Void = { action in
            dispatchedActions.append(action)
        }

        let mockServices = ServiceContainer(
            calendarService: MockCalendarService(),
            persistenceService: MockPersistenceService(),
            currentDayService: MockCurrentDayService(),
            conflictResolutionService: ConflictResolutionService(),
            syncService: MockSyncService()
        )

        // Dispatch onAppear action
        await appStartupMiddleware(state, .appLifecycle(.onAppAppear), mockServices, mockDispatch)

        // Middleware should dispatch: userProfileUpdated and profileLoaded (but NOT verifyCalendarAccessOnStartup)
        #expect(!dispatchedActions.isEmpty)

        // Should NOT dispatch verification action since already verified
        let hasVerificationAction = dispatchedActions.contains { action in
            if case .appLifecycle(.verifyCalendarAccessOnStartup) = action {
                return true
            }
            return false
        }
        #expect(!hasVerificationAction, "Should not dispatch verifyCalendarAccessOnStartup when already verified")

        // Should dispatch profileLoaded
        let hasProfileLoaded = dispatchedActions.contains { action in
            if case .appLifecycle(.profileLoaded) = action {
                return true
            }
            return false
        }
        #expect(hasProfileLoaded, "Expected profileLoaded action to be dispatched")
    }

    @Test("When verifying calendar access with granted permission, should dispatch calendarAccessVerified(true)")
    func testVerifyCalendarAccessWithGrantedPermission() async {
        let state = AppState()

        var dispatchedActions: [AppAction] = []
        let mockDispatch: @MainActor (AppAction) async -> Void = { action in
            dispatchedActions.append(action)
        }

        // Mock service with authorized calendar
        let mockCalendarService = MockCalendarService()
        mockCalendarService.mockIsAuthorized = true

        let mockServices = ServiceContainer(
            calendarService: mockCalendarService,
            persistenceService: MockPersistenceService(),
            currentDayService: MockCurrentDayService(),
            conflictResolutionService: ConflictResolutionService(),
            syncService: MockSyncService()
        )

        // Dispatch verification action
        await appStartupMiddleware(state, .appLifecycle(.verifyCalendarAccessOnStartup), mockServices, mockDispatch)

        // Should dispatch calendarAccessVerified(true)
        #expect(dispatchedActions.count == 1)

        if case .appLifecycle(.calendarAccessVerified(let isAuthorized)) = dispatchedActions[0] {
            #expect(isAuthorized == true)
        } else {
            #expect(Bool(false), "Expected calendarAccessVerified(true) action")
        }
    }

    @Test("When verifying calendar access without permission, should dispatch requestCalendarAccess")
    func testVerifyCalendarAccessWithoutPermission() async {
        let state = AppState()

        var dispatchedActions: [AppAction] = []
        let mockDispatch: @MainActor (AppAction) async -> Void = { action in
            dispatchedActions.append(action)
        }

        // Mock service with unauthorized calendar
        let mockCalendarService = MockCalendarService()
        mockCalendarService.mockIsAuthorized = false

        let mockServices = ServiceContainer(
            calendarService: mockCalendarService,
            persistenceService: MockPersistenceService(),
            currentDayService: MockCurrentDayService(),
            conflictResolutionService: ConflictResolutionService(),
            syncService: MockSyncService()
        )

        // Dispatch verification action
        await appStartupMiddleware(state, .appLifecycle(.verifyCalendarAccessOnStartup), mockServices, mockDispatch)

        // Should dispatch requestCalendarAccess
        #expect(dispatchedActions.count == 1)

        if case .appLifecycle(.requestCalendarAccess) = dispatchedActions[0] {
            // Test passes
        } else {
            #expect(Bool(false), "Expected requestCalendarAccess action")
        }
    }

    @Test("When requesting calendar access and user grants it, should dispatch calendarAccessRequested(success)")
    func testRequestCalendarAccessGranted() async {
        let state = AppState()

        var dispatchedActions: [AppAction] = []
        let mockDispatch: @MainActor (AppAction) async -> Void = { action in
            dispatchedActions.append(action)
        }

        // Mock service that grants access
        let mockCalendarService = MockCalendarService()
        mockCalendarService.mockRequestAccessResult = true

        let mockServices = ServiceContainer(
            calendarService: mockCalendarService,
            persistenceService: MockPersistenceService(),
            currentDayService: MockCurrentDayService(),
            conflictResolutionService: ConflictResolutionService(),
            syncService: MockSyncService()
        )

        // Dispatch request action
        await appStartupMiddleware(state, .appLifecycle(.requestCalendarAccess), mockServices, mockDispatch)

        // Should dispatch calendarAccessRequested with success
        #expect(dispatchedActions.count == 1)

        if case .appLifecycle(.calendarAccessRequested(.success(let hasAccess))) = dispatchedActions[0] {
            #expect(hasAccess == true)
        } else {
            #expect(Bool(false), "Expected calendarAccessRequested(.success(true)) action")
        }
    }

    @Test("When requesting calendar access and user denies it, should dispatch calendarAccessRequested(success) with false")
    func testRequestCalendarAccessDenied() async {
        let state = AppState()

        var dispatchedActions: [AppAction] = []
        let mockDispatch: @MainActor (AppAction) async -> Void = { action in
            dispatchedActions.append(action)
        }

        // Mock service that denies access
        let mockCalendarService = MockCalendarService()
        mockCalendarService.mockRequestAccessResult = false

        let mockServices = ServiceContainer(
            calendarService: mockCalendarService,
            persistenceService: MockPersistenceService(),
            currentDayService: MockCurrentDayService(),
            conflictResolutionService: ConflictResolutionService(),
            syncService: MockSyncService()
        )

        // Dispatch request action
        await appStartupMiddleware(state, .appLifecycle(.requestCalendarAccess), mockServices, mockDispatch)

        // Should dispatch calendarAccessRequested with failure
        #expect(dispatchedActions.count == 1)

        if case .appLifecycle(.calendarAccessRequested(.success(let hasAccess))) = dispatchedActions[0] {
            #expect(hasAccess == false)
        } else {
            #expect(Bool(false), "Expected calendarAccessRequested(.success(false)) action")
        }
    }
}

