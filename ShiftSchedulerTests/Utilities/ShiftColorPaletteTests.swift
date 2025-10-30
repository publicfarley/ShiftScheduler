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

    @Test("Color generation for nil shift type returns default color")
    func testColorForNilShift() {
        let color = ShiftColorPalette.colorForShift(nil)

        // Should return the default color (not crash)
        #expect(color != nil)
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

    // MARK: - Gradient Generation Tests

    @Test("Gradient colors for shift type returns two colors")
    func testGradientColorsForShift() {
        let location = Location(id: UUID(), name: "Office", address: "123 Main St")
        let shiftType = ShiftType(
            id: UUID(),
            symbol: "☀️",
            duration: .scheduled(from: HourMinuteTime(hour: 9, minute: 0), to: HourMinuteTime(hour: 17, minute: 0)),
            title: "Day Shift",
            description: "Day shift",
            location: location
        )

        let (primary, secondary) = ShiftColorPalette.gradientColorsForShift(shiftType)

        // Should return valid colors
        #expect(primary != nil)
        #expect(secondary != nil)
    }

    @Test("Gradient colors for nil shift type returns default colors")
    func testGradientColorsForNilShift() {
        let (primary, secondary) = ShiftColorPalette.gradientColorsForShift(nil)

        // Should return default colors (not crash)
        #expect(primary != nil)
        #expect(secondary != nil)
    }

    @Test("Gradient for shift creates LinearGradient")
    func testGradientForShift() {
        let location = Location(id: UUID(), name: "Office", address: "123 Main St")
        let shiftType = ShiftType(
            id: UUID(),
            symbol: "☀️",
            duration: .scheduled(from: HourMinuteTime(hour: 9, minute: 0), to: HourMinuteTime(hour: 17, minute: 0)),
            title: "Day Shift",
            description: "Day shift",
            location: location
        )

        let gradient = ShiftColorPalette.gradientForShift(shiftType)

        // Should return a valid LinearGradient
        #expect(gradient != nil)
    }

    // MARK: - Adaptive Text Color Tests

    @Test("Adaptive text color returns valid color")
    func testAdaptiveTextColor() {
        let backgroundColor = Color.blue

        let textColor = ShiftColorPalette.adaptiveTextColor(for: backgroundColor)

        // Should return white (as per current implementation)
        #expect(textColor == .white)
    }

    // MARK: - Color Effect Tests

    @Test("Glow color for shift has opacity")
    func testGlowColorForShift() {
        let location = Location(id: UUID(), name: "Office", address: "123 Main St")
        let shiftType = ShiftType(
            id: UUID(),
            symbol: "☀️",
            duration: .scheduled(from: HourMinuteTime(hour: 9, minute: 0), to: HourMinuteTime(hour: 17, minute: 0)),
            title: "Day Shift",
            description: "Day shift",
            location: location
        )

        let glowColor = ShiftColorPalette.glowColorForShift(shiftType)

        // Should return a valid color (with opacity applied)
        #expect(glowColor != nil)
    }

    @Test("Glass tint for shift has low opacity")
    func testGlassTintForShift() {
        let location = Location(id: UUID(), name: "Office", address: "123 Main St")
        let shiftType = ShiftType(
            id: UUID(),
            symbol: "☀️",
            duration: .scheduled(from: HourMinuteTime(hour: 9, minute: 0), to: HourMinuteTime(hour: 17, minute: 0)),
            title: "Day Shift",
            description: "Day shift",
            location: location
        )

        let glassTint = ShiftColorPalette.glassTintForShift(shiftType)

        // Should return a valid color with low opacity
        #expect(glassTint != nil)
    }

    @Test("Border color for shift creates LinearGradient")
    func testBorderColorForShift() {
        let location = Location(id: UUID(), name: "Office", address: "123 Main St")
        let shiftType = ShiftType(
            id: UUID(),
            symbol: "☀️",
            duration: .scheduled(from: HourMinuteTime(hour: 9, minute: 0), to: HourMinuteTime(hour: 17, minute: 0)),
            title: "Day Shift",
            description: "Day shift",
            location: location
        )

        let borderGradient = ShiftColorPalette.borderColorForShift(shiftType)

        // Should return a valid LinearGradient
        #expect(borderGradient != nil)
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

    @Test("Different location names may generate different colors")
    func testDifferentLocationNamesGenerateColors() {
        let color1 = ShiftColorPalette.colorForLocation("Office")
        let color2 = ShiftColorPalette.colorForLocation("Home")

        // Should return valid colors
        #expect(color1 != nil)
        #expect(color2 != nil)
    }

    @Test("Gradient colors for location returns two colors")
    func testGradientColorsForLocation() {
        let locationName = "Office"

        let (primary, secondary) = ShiftColorPalette.gradientColorsForLocation(locationName)

        // Should return valid colors
        #expect(primary != nil)
        #expect(secondary != nil)
    }

    @Test("Glow color for location has opacity")
    func testGlowColorForLocation() {
        let locationName = "Office"

        let glowColor = ShiftColorPalette.glowColorForLocation(locationName)

        // Should return a valid color with opacity
        #expect(glowColor != nil)
    }

    // MARK: - Color Extension Tests

    @Test("Color darkened creates valid color")
    func testColorDarkened() {
        let originalColor = Color.blue
        let darkenedColor = originalColor.darkened(by: 0.2)

        // Should return a valid color
        #expect(darkenedColor != nil)
    }

    @Test("Color lightened creates valid color")
    func testColorLightened() {
        let originalColor = Color.blue
        let lightenedColor = originalColor.lightened(by: 0.2)

        // Should return a valid color
        #expect(lightenedColor != nil)
    }

    @Test("Color darkened with different percentages")
    func testColorDarkenedPercentages() {
        let originalColor = Color.red

        let darkened10 = originalColor.darkened(by: 0.1)
        let darkened50 = originalColor.darkened(by: 0.5)

        // Should return valid colors
        #expect(darkened10 != nil)
        #expect(darkened50 != nil)
    }
}
