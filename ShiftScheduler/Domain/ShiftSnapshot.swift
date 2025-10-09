import Foundation

/// Immutable snapshot of a ShiftType at a point in time
/// Used for audit trail in change log to preserve historical data
struct ShiftSnapshot: Codable, Equatable, Sendable {
    let shiftTypeId: UUID
    let symbol: String
    let title: String
    let shiftDescription: String
    let duration: ShiftDuration
    let locationName: String?
    let locationAddress: String?

    init(from shiftType: ShiftType) {
        self.shiftTypeId = shiftType.id
        self.symbol = shiftType.symbol
        self.title = shiftType.title
        self.shiftDescription = shiftType.shiftDescription
        self.duration = shiftType.duration
        self.locationName = shiftType.location?.name
        self.locationAddress = shiftType.location?.address
    }

    init(
        shiftTypeId: UUID,
        symbol: String,
        title: String,
        shiftDescription: String,
        duration: ShiftDuration,
        locationName: String?,
        locationAddress: String?
    ) {
        self.shiftTypeId = shiftTypeId
        self.symbol = symbol
        self.title = title
        self.shiftDescription = shiftDescription
        self.duration = duration
        self.locationName = locationName
        self.locationAddress = locationAddress
    }
}
