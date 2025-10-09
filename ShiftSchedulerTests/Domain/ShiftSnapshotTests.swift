import Foundation
import Testing
@testable import ShiftScheduler

struct ShiftSnapshotTests {
    @Test("ShiftSnapshot captures all shift type properties")
    func testShiftSnapshotCreation() {
        // Given
        let location = Location(name: "Office", address: "123 Main St")
        let duration = ShiftDuration.scheduled(
            from: HourMinuteTime(hour: 9, minute: 0),
            to: HourMinuteTime(hour: 17, minute: 0)
        )
        let shiftType = ShiftType(
            symbol: "🏢",
            duration: duration,
            title: "Day Shift",
            description: "Regular office hours",
            location: location
        )

        // When
        let snapshot = ShiftSnapshot(from: shiftType)

        // Then
        #expect(snapshot.shiftTypeId == shiftType.id)
        #expect(snapshot.symbol == "🏢")
        #expect(snapshot.title == "Day Shift")
        #expect(snapshot.shiftDescription == "Regular office hours")
        #expect(snapshot.duration == duration)
        #expect(snapshot.locationName == "Office")
        #expect(snapshot.locationAddress == "123 Main St")
    }

    @Test("ShiftSnapshot handles nil location")
    func testShiftSnapshotWithNilLocation() {
        // Given
        let shiftType = ShiftType(
            symbol: "🏡",
            duration: .allDay,
            title: "Remote",
            description: "Work from home",
            location: Location(name: "", address: "")
        )
        shiftType.location = nil

        // When
        let snapshot = ShiftSnapshot(from: shiftType)

        // Then
        #expect(snapshot.locationName == nil)
        #expect(snapshot.locationAddress == nil)
    }

    @Test("ShiftSnapshot is Equatable")
    func testShiftSnapshotEquality() {
        // Given
        let location = Location(name: "Office", address: "123 Main St")
        let shiftType1 = ShiftType(
            symbol: "🏢",
            duration: .allDay,
            title: "Day Shift",
            description: "Regular shift",
            location: location
        )
        let shiftType2 = ShiftType(
            id: shiftType1.id,
            symbol: "🏢",
            duration: .allDay,
            title: "Day Shift",
            description: "Regular shift",
            location: location
        )

        // When
        let snapshot1 = ShiftSnapshot(from: shiftType1)
        let snapshot2 = ShiftSnapshot(from: shiftType2)

        // Then
        #expect(snapshot1 == snapshot2)
    }

    @Test("ShiftSnapshot is Sendable")
    func testShiftSnapshotSendable() {
        // This test verifies that ShiftSnapshot conforms to Sendable at compile time
        func requiresSendable<T: Sendable>(_ value: T) {}

        let location = Location(name: "Office", address: "123 Main St")
        let shiftType = ShiftType(
            symbol: "🏢",
            duration: .allDay,
            title: "Day Shift",
            description: "Regular shift",
            location: location
        )
        let snapshot = ShiftSnapshot(from: shiftType)

        requiresSendable(snapshot)
    }
}
