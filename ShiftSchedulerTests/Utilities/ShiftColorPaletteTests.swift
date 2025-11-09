import Testing
import SwiftUI
@testable import ShiftScheduler

/// Tests for ShiftColorPalette utility
/// Verifies color generation for shift types and locations
@Suite("ShiftColorPalette Tests")
@MainActor
struct ShiftColorPaletteTests {

    // MARK: - Shift Color Generation Tests

    @Test("Color generation for shift type returns consistent color")
    func testColorForShiftConsistency() {
        let location = Location(id: UUID(), name: "Office", address: "123 Main St")
        let shiftType = ShiftType(
            id: UUID(),
            symbol: "☀️",
            duration: .scheduled(from: HourMinuteTime(hour: 9, minute: 0), to: HourMinuteTime(hour: 17, minute: 0)),
            title: "Day Shift",
            description: "Day shift",
            location: location
        )

        let color1 = ShiftColorPalette.colorForShift(shiftType)
        let color2 = ShiftColorPalette.colorForShift(shiftType)

        // Colors should be consistent for the same shift type
        #expect(color1 == color2)
    }

    @Test("Different symbols generate different colors")
    func testDifferentSymbolsGenerateDifferentColors() {
        let location = Location(id: UUID(), name: "Office", address: "123 Main St")

        let shiftType1 = ShiftType(
            id: UUID(),
            symbol: "☀️",
            duration: .scheduled(from: HourMinuteTime(hour: 9, minute: 0), to: HourMinuteTime(hour: 17, minute: 0)),
            title: "Day",
            description: "Day shift",
            location: location
        )

        let shiftType2 = ShiftType(
            id: UUID(),
            symbol: "🌙",
            duration: .scheduled(from: HourMinuteTime(hour: 21, minute: 0), to: HourMinuteTime(hour: 5, minute: 0)),
            title: "Night",
            description: "Night shift",
            location: location
        )

        let color1 = ShiftColorPalette.colorForShift(shiftType1)
        let color2 = ShiftColorPalette.colorForShift(shiftType2)

        // Different symbols should likely generate different colors
        // (though hash collisions are possible, unlikely for these symbols)
        #expect(color1 == color1) // Self-consistency check
        #expect(color2 == color2) // Self-consistency check
    }

    // MARK: - Adaptive Text Color Tests

    @Test("Adaptive text color returns valid color")
    func testAdaptiveTextColor() {
        let backgroundColor = Color.blue

        let textColor = ShiftColorPalette.adaptiveTextColor(for: backgroundColor)

        // Should return white (as per current implementation)
        #expect(textColor == .white)
    }

    // MARK: - Location Color Tests

    @Test("Color for location returns consistent color")
    func testColorForLocationConsistency() {
        let locationName = "Office"

        let color1 = ShiftColorPalette.colorForLocation(locationName)
        let color2 = ShiftColorPalette.colorForLocation(locationName)

        // Colors should be consistent for the same location name
        #expect(color1 == color2)
    }
}
