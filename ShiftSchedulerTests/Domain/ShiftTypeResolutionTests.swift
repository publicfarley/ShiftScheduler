import Testing
import Foundation
@testable import ShiftScheduler

@Suite("ShiftTypeResolution")
@MainActor
struct ShiftTypeResolutionTests {

    private static let start = Date(timeIntervalSinceReferenceDate: 800_000_000)

    private static func event(_ typeId: UUID, id: String = UUID().uuidString) -> ScheduledShiftData {
        ScheduledShiftData(
            eventIdentifier: id,
            shiftTypeId: typeId,
            startDate: start,
            endDate: start,
            title: "D: Day"
        )
    }

    @Test("Ids that the catalog holds are not unresolved")
    func knownIdsResolve() {
        let known = UUID()
        let unresolved = ShiftTypeResolution.unresolvedShiftTypeIds(in: [Self.event(known)], knownIds: [known])
        #expect(unresolved.isEmpty)
    }

    @Test("Ids that the catalog lacks are unresolved, once each")
    func unknownIdsListedOnce() {
        let missing = UUID()
        let events = [Self.event(missing), Self.event(missing), Self.event(UUID())]
        let unresolved = ShiftTypeResolution.unresolvedShiftTypeIds(in: events, knownIds: [])
        #expect(unresolved.count == 2)
        #expect(unresolved.contains(missing))
    }

    @Test("An empty catalog skips every event")
    func emptyCatalogSkipsAll() {
        let events = [Self.event(UUID()), Self.event(UUID()), Self.event(UUID())]
        #expect(ShiftTypeResolution.skippedEventCount(in: events, knownIds: []) == 3)
    }

    @Test("Only events with an unknown type count as skipped")
    func partialSkip() {
        let known = UUID()
        let events = [Self.event(known), Self.event(known), Self.event(UUID())]
        #expect(ShiftTypeResolution.skippedEventCount(in: events, knownIds: [known]) == 1)
    }

    @Test("No events means nothing unresolved and nothing skipped")
    func noEvents() {
        #expect(ShiftTypeResolution.unresolvedShiftTypeIds(in: [], knownIds: []).isEmpty)
        #expect(ShiftTypeResolution.skippedEventCount(in: [], knownIds: []) == 0)
    }

    @Test("Recovered records that exist locally are dropped, so local data wins")
    func missingOnlyKeepsLocal() {
        let kept = Location(name: "Kept", address: "1 Main St")
        let fresh = Location(name: "Fresh", address: "2 Main St")
        let result = ShiftTypeResolution.missingOnly(recovered: [kept, fresh], existingIds: [kept.id], id: \.id)
        #expect(result == [fresh])
    }
}
