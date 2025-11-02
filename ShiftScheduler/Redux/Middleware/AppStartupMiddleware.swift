import Foundation
import OSLog

private nonisolated let logger = Logger(subsystem: "com.shiftscheduler.redux.middleware", category: "AppStartupMiddleware")

/// Middleware for handling app startup and calendar authorization verification
/// Ensures the user has granted calendar access before the app proceeds
let appStartupMiddleware: Middleware<AppState, AppAction> = { state, action, services, dispatch in
    // Only handle app lifecycle actions
    guard case .appLifecycle(let lifecycleAction) = action else {
        return
    }

    switch lifecycleAction {
    case .onAppear:
        // When app appears, verify calendar access if not already verified
        if !state.isCalendarAuthorizationVerified {
            await dispatch(.appLifecycle(.verifyCalendarAccessOnStartup))
        }

    case .verifyCalendarAccessOnStartup:
        // Check current authorization status
        do {
            let isAuthorized = try await services.calendarService.isCalendarAuthorized()
            logger.debug("Calendar authorization status: \(isAuthorized)")

            if isAuthorized {
                // User has already granted access
                await dispatch(.appLifecycle(.calendarAccessVerified(true)))
            } else {
                // User hasn't granted access, request it
                await dispatch(.appLifecycle(.requestCalendarAccess))
            }
        } catch {
            logger.error("Failed to check calendar authorization: \(error.localizedDescription)")
            // If we can't check status, assume not authorized and request access
            await dispatch(.appLifecycle(.requestCalendarAccess))
        }

    case .requestCalendarAccess:
        // Request calendar access from the user
        do {
            let hasAccess = try await services.calendarService.requestCalendarAccess()
            logger.debug("Calendar access request result: \(hasAccess)")
            await dispatch(.appLifecycle(.calendarAccessRequested(.success(hasAccess))))
        } catch {
            logger.error("Failed to request calendar access: \(error.localizedDescription)")
            await dispatch(.appLifecycle(.calendarAccessRequested(.failure(error))))
        }

    case .calendarAccessVerified, .calendarAccessRequested:
        // State updates handled by reducer, no middleware action needed
        break

    case .loadInitialData:
        // Load locations and shift types from persistent storage
        do {
            // Load locations
            let locations = try await services.persistenceService.loadLocations()
            logger.debug("Loaded \(locations.count) locations")
            await dispatch(.locations(.locationsLoaded(.success(locations))))

            // Load shift types
            let shiftTypes = try await services.persistenceService.loadShiftTypes()
            logger.debug("Loaded \(shiftTypes.count) shift types")
            await dispatch(.shiftTypes(.shiftTypesLoaded(.success(shiftTypes))))

            // Mark initialization as complete
            await dispatch(.appLifecycle(.initializationComplete(.success(()))))
        } catch {
            logger.error("Failed to load initial data: \(error.localizedDescription)")
            // Still mark as complete so app shows content (empty state is ok)
            await dispatch(.appLifecycle(.initializationComplete(.failure(error))))
        }

    case .initializationComplete:
        // State updates handled by reducer, no middleware action needed
        break

    case .tabSelected, .userProfileUpdated:
        // Not handled by this middleware
        break
    }
}
