import Foundation
@testable import ShiftScheduler

/// Test Data Builders for creating domain objects in tests
/// These builders provide convenient factory methods with sensible defaults

// MARK: - Location Builder

@MainActor
struct LocationBuilder: Sendable {
    let id: UUID
    let name: String
    let address: String

    init(
        id: UUID = UUID(),
        name: String = "Test Location",
        address: String = "123 Test St"
    ) {
        self.id = id
        self.name = name
        self.address = address
    }

    func build() -> Location {
        Location(id: id, name: name, address: address)
    }

    static func `default`() -> Location {
        LocationBuilder().build()
    }

    static func headquarters() -> Location {
        LocationBuilder(name: "Headquarters", address: "123 Main St").build()
    }

    static func branch() -> Location {
        LocationBuilder(name: "Branch Office", address: "456 Oak Ave").build()
    }

    static func remote() -> Location {
        LocationBuilder(name: "Remote", address: "Home").build()
    }
}

// MARK: - ShiftType Builder
@MainActor
let defaultDuration = ShiftDuration.scheduled(
    from: HourMinuteTime(hour: 9, minute: 0),
    to: HourMinuteTime(hour: 17, minute: 0)
)

@MainActor
struct ShiftTypeBuilder {
    let id: UUID
    let symbol: String
    let duration: ShiftDuration
    let title: String
    let description: String
    let location: Location
    
    enum DurationChoice {
        case `default`
        case specified(ShiftDuration)
    }
    
    init(
        id: UUID = UUID(),
        symbol: String = "sun.fill",
        duration: DurationChoice = .default,
        title: String = "Day Shift",
        description: String = "Standard day shift",
        location: Location? = nil
    ) {
        self.id = id
        self.symbol = symbol

        self.duration = switch duration {
        case .default:
            ShiftDuration.scheduled(
                from: HourMinuteTime(hour: 9, minute: 0),
                to: HourMinuteTime(hour: 17, minute: 0)
            )

        case .specified(let duration):
            duration
        }
        
        self.title = title
        self.description = description
        self.location = location ?? LocationBuilder().build()
    }

    func build() -> ShiftType {
        ShiftType(
            id: id,
            symbol: symbol,
            duration: duration,
            title: title,
            description: description,
            location: location
        )
    }

    static func `default`() -> ShiftType {
        ShiftTypeBuilder().build()
    }

    static func morningShift(location: Location? = nil) -> ShiftType {
        ShiftTypeBuilder(
            symbol: "sun.fill",
            duration: .specified(.scheduled(
                from: HourMinuteTime(hour: 6, minute: 0),
                to: HourMinuteTime(hour: 14, minute: 0))
            ),
            title: "Morning",
            description: "Morning shift",
            location: location
        ).build()
    }

    static func afternoonShift(location: Location? = nil) -> ShiftType {
        ShiftTypeBuilder(
            symbol: "sun.max.fill",
            duration: .specified(.scheduled(
                from: HourMinuteTime(hour: 14, minute: 0),
                to: HourMinuteTime(hour: 22, minute: 0))
            ),
            title: "Afternoon",
            description: "Afternoon shift",
            location: location
        ).build()
    }

    static func nightShift(location: Location? = nil) -> ShiftType {
        ShiftTypeBuilder(
            symbol: "moon.fill",
            duration: .specified(.scheduled(
                from: HourMinuteTime(hour: 22, minute: 0),
                to: HourMinuteTime(hour: 6, minute: 0))
            ),
            title: "Night",
            description: "Night shift",
            location: location
        ).build()
    }
}

// MARK: - ScheduledShift Builder
@MainActor
struct ScheduledShiftBuilder {
    let id: UUID
    let date: Date
    let shiftType: ShiftType
    let notes: String?

    init(
        id: UUID = UUID(),
        date: Date = try Date.fixedTestDate_Nov11_2025(),
        shiftType: ShiftType? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.date = date
        self.shiftType = shiftType ?? ShiftTypeBuilder().build()
        self.notes = notes
    }

    func build() -> ScheduledShift {
        ScheduledShift(
            id: id,
            eventIdentifier: "Dummy",
            shiftType: shiftType,
            date: date,
            notes: notes
        )
    }

    static func `default`() -> ScheduledShift {
        ScheduledShiftBuilder().build()
    }

    static func today() -> ScheduledShift {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: try Date.fixedTestDate_Nov11_2025())
        return ScheduledShiftBuilder(date: today).build()
    }

    static func tomorrow() -> ScheduledShift? {
        let calendar = Calendar.current
        
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: try Date.fixedTestDate_Nov11_2025())) else {
            return nil
        }
        
        return ScheduledShiftBuilder(date: tomorrow).build()
    }
}

// MARK: - ChangeLogEntry Builder
@MainActor
struct ChangeLogEntryBuilder {
    let id: UUID
    let timestamp: Date
    let userId: UUID
    let userDisplayName: String
    let changeType: ChangeType
    let scheduledShiftDate: Date
    let oldShiftSnapshot: ShiftSnapshot?
    let newShiftSnapshot: ShiftSnapshot?
    let reason: String

    init(
        id: UUID = UUID(),
        timestamp: Date = try Date.fixedTestDate_Nov11_2025(),
        userId: UUID = UUID(),
        userDisplayName: String = "Test User",
        changeType: ChangeType = .created,
        scheduledShiftDate: Date = try Date.fixedTestDate_Nov11_2025(),
        oldShiftSnapshot: ShiftSnapshot? = nil,
        newShiftSnapshot: ShiftSnapshot? = nil,
        reason: String = ""
    ) {
        self.id = id
        self.timestamp = timestamp
        self.userId = userId
        self.userDisplayName = userDisplayName
        self.changeType = changeType
        self.scheduledShiftDate = scheduledShiftDate
        self.oldShiftSnapshot = oldShiftSnapshot
        self.newShiftSnapshot = newShiftSnapshot
        self.reason = reason
    }

    func build() -> ChangeLogEntry {
        ChangeLogEntry(
            id: id,
            timestamp: timestamp,
            userId: userId,
            userDisplayName: userDisplayName,
            changeType: changeType,
            scheduledShiftDate: scheduledShiftDate,
            oldShiftSnapshot: oldShiftSnapshot,
            newShiftSnapshot: newShiftSnapshot,
            reason: reason
        )
    }

    static func `default`() -> ChangeLogEntry {
        ChangeLogEntryBuilder().build()
    }

    static func switchedShift() -> ChangeLogEntry {
        let oldShift = ShiftTypeBuilder.morningShift()
        let newShift = ShiftTypeBuilder.afternoonShift()

        return ChangeLogEntryBuilder(
            changeType: .switched,
            oldShiftSnapshot: ShiftSnapshot(from: oldShift),
            newShiftSnapshot: ShiftSnapshot(from: newShift),
            reason: "Requested shift change"
        ).build()
    }
}

// MARK: - ShiftSnapshot Builder
@MainActor
struct ShiftSnapshotBuilder {
    let shiftType: ShiftType

    init(shiftType: ShiftType? = nil) {
        self.shiftType = shiftType ?? ShiftTypeBuilder().build()
    }

    func build() -> ShiftSnapshot {
        ShiftSnapshot(from: shiftType)
    }

    static func `default`() -> ShiftSnapshot {
        ShiftSnapshotBuilder().build()
    }
}

// MARK: - Test Data Collections
@MainActor
struct TestDataCollections {
    /// Create a standard set of locations for testing
    static func standardLocations() -> [Location] {
        [
            LocationBuilder.headquarters(),
            LocationBuilder.branch(),
            LocationBuilder.remote(),
        ]
    }

    /// Create a standard set of shift types for testing
    static func standardShiftTypes() -> [ShiftType] {
        let location = standardLocations()[0]
        return [
            ShiftTypeBuilder.morningShift(location: location),
            ShiftTypeBuilder.afternoonShift(location: location),
            ShiftTypeBuilder.nightShift(location: location),
        ]
    }

    /// Create a standard week of scheduled shifts
    static func weekOfShifts() -> [ScheduledShift] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: try Date.fixedTestDate_Nov11_2025())
        let shiftTypes = standardShiftTypes()

        return (0..<7).compactMap { dayOffset in
            guard let shiftDate = calendar.date(byAdding: .day, value: dayOffset, to: today) else { return nil }
            let shiftType = shiftTypes[dayOffset % shiftTypes.count]
            return ScheduledShiftBuilder(date: shiftDate, shiftType: shiftType).build()
        }
    }
}
