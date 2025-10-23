import Foundation
import ComposableArchitecture

/// TCA Dependency Client for shift switching operations
/// Provides stateless operations for switching shifts and recording changes
/// State management is handled by the TCA reducer, not this client
@DependencyClient
struct ShiftSwitchClient: Sendable {
    /// Switches a shift to a new shift type and logs the change
    /// Returns the change log entry ID for tracking
    var switchShift: @Sendable (
        String,      // eventIdentifier
        Date,        // scheduledDate
        ShiftType,   // oldShiftType
        ShiftType,   // newShiftType
        String?      // reason
    ) async throws -> UUID = { _, _, _, _, _ in UUID() }
}

extension ShiftSwitchClient: DependencyKey {
    /// Live implementation
    nonisolated static let liveValue: ShiftSwitchClient = .testValue

    /// Test value with unimplemented methods
    nonisolated static let testValue = ShiftSwitchClient()

    /// Preview value with mock data
    nonisolated static let previewValue = ShiftSwitchClient(
        switchShift: { _, _, _, _, _ in UUID() }
    )
}

extension DependencyValues {
    var shiftSwitchClient: ShiftSwitchClient {
        get { self[ShiftSwitchClient.self] }
        set { self[ShiftSwitchClient.self] = newValue }
    }
}
