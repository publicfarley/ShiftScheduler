import Foundation

/// Pure rules for deciding which calendar events point at shift types that the
/// local catalog does not hold. No I/O.
nonisolated enum ShiftTypeResolution {
    /// Shift type ids that events reference but the catalog does not contain.
    static func unresolvedShiftTypeIds(in events: [ScheduledShiftData], knownIds: Set<UUID>) -> Set<UUID> {
        Set(events.map(\.shiftTypeId)).subtracting(knownIds)
    }

    /// Number of events that cannot show as shifts because their type is unknown.
    static func skippedEventCount(in events: [ScheduledShiftData], knownIds: Set<UUID>) -> Int {
        events.filter { !knownIds.contains($0.shiftTypeId) }.count
    }

    /// Recovered values that the local files do not hold yet, by id.
    /// Existing local values always win, so a rebuild never overwrites real data.
    static func missingOnly<T, ID: Hashable>(recovered: [T], existingIds: Set<ID>, id: (T) -> ID) -> [T] {
        recovered.filter { !existingIds.contains(id($0)) }
    }
}
