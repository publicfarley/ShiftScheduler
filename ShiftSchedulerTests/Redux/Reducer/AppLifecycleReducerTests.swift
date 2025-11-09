import Testing
import Foundation
@testable import ShiftScheduler

/// Tests for the AppLifecycleReducer authorization state handling
@Suite("AppLifecycleReducer Authorization Tests")
@MainActor
struct AppLifecycleReducerTests {

    // MARK: - Calendar Authorization State Updates

    @Test("calendarAccessVerified(true) sets authorization state to true and marks as verified")
    func testCalendarAccessVerifiedTrue() {
        var state = AppState()
        state.isCalendarAuthorized = false
        state.isCalendarAuthorizationVerified = false

        let newState = appLifecycleReducer(state: state, action: .calendarAccessVerified(true))

        #expect(newState.isCalendarAuthorized == true)
        #expect(newState.isCalendarAuthorizationVerified == true)
    }

    @Test("calendarAccessVerified(false) sets authorization state to false and marks as verified")
    func testCalendarAccessVerifiedFalse() {
        var state = AppState()
        state.isCalendarAuthorized = true
        state.isCalendarAuthorizationVerified = false

        let newState = appLifecycleReducer(state: state, action: .calendarAccessVerified(false))

        #expect(newState.isCalendarAuthorized == false)
        #expect(newState.isCalendarAuthorizationVerified == true)
    }

    @Test("calendarAccessRequested(.success(true)) sets authorization to true and marks as verified")
    func testCalendarAccessRequestedSuccess() {
        var state = AppState()
        state.isCalendarAuthorized = false
        state.isCalendarAuthorizationVerified = false

        let newState = appLifecycleReducer(
            state: state,
            action: .calendarAccessRequested(.success(true))
        )

        #expect(newState.isCalendarAuthorized == true)
        #expect(newState.isCalendarAuthorizationVerified == true)
    }

    @Test("calendarAccessRequested(.success(false)) sets authorization to false and marks as verified")
    func testCalendarAccessRequestedFailure() {
        var state = AppState()
        state.isCalendarAuthorized = true
        state.isCalendarAuthorizationVerified = false

        let newState = appLifecycleReducer(
            state: state,
            action: .calendarAccessRequested(.success(false))
        )

        #expect(newState.isCalendarAuthorized == false)
        #expect(newState.isCalendarAuthorizationVerified == true)
    }

    @Test("calendarAccessRequested(.failure) marks as verified but keeps previous authorization state")
    func testCalendarAccessRequestedError() {
        var state = AppState()
        state.isCalendarAuthorized = true  // Previously had access
        state.isCalendarAuthorizationVerified = false

        let error = NSError(domain: "TestError", code: -1)
        let newState = appLifecycleReducer(
            state: state,
            action: .calendarAccessRequested(.failure(error))
        )

        // Should keep previous authorization state but mark as verified
        #expect(newState.isCalendarAuthorized == true)
        #expect(newState.isCalendarAuthorizationVerified == true)
    }

    // MARK: - Other Lifecycle Actions

    @Test("onAppear action does not change state")
    func testOnAppearDoesNotChangeState() {
        let state = AppState()

        let newState = appLifecycleReducer(state: state, action: .onAppAppear)

        #expect(newState == state)
    }

    @Test("verifyCalendarAccessOnStartup action does not change state")
    func testVerifyCalendarAccessOnStartupDoesNotChangeState() {
        let state = AppState()

        let newState = appLifecycleReducer(state: state, action: .verifyCalendarAccessOnStartup)

        #expect(newState == state)
    }

    @Test("requestCalendarAccess action does not change state")
    func testRequestCalendarAccessDoesNotChangeState() {
        let state = AppState()

        let newState = appLifecycleReducer(state: state, action: .requestCalendarAccess)

        #expect(newState == state)
    }

    @Test("tabSelected action updates selected tab")
    func testTabSelectedUpdatesTab() {
        var state = AppState()
        state.selectedTab = .today

        let newState = appLifecycleReducer(state: state, action: .tabSelected(.settings))

        #expect(newState.selectedTab == .settings)
    }

    @Test("userProfileUpdated action updates user profile")
    func testUserProfileUpdatedChangesProfile() {
        let state = AppState()
        let newProfile = UserProfile(userId: UUID(), displayName: "John Doe")

        let newState = appLifecycleReducer(state: state, action: .userProfileUpdated(newProfile))

        #expect(newState.userProfile.displayName == "John Doe")
        #expect(newState.userProfile.userId == newProfile.userId)
    }
}
