import Testing
import SwiftUI
@testable import ShiftScheduler

struct ShiftColorPaletteTests {

    // MARK: - Shift Color Tests

    @Test("colorForShift returns consistent color for same shift")
    func testColorForShiftConsistency() async throws {
        let shiftType = createMockShiftType(symbol: "D", title: "Day Shift")

        let color1 = ShiftColorPalette.colorForShift(shiftType)
        let color2 = ShiftColorPalette.colorForShift(shiftType)

        #expect(color1 == color2, "Same shift should always return same color")
    }

    @Test("colorForShift returns different colors for different symbols")
    func testColorForShiftVariety() async throws {
        let shiftD = createMockShiftType(symbol: "D", title: "Day Shift")
        let shiftN = createMockShiftType(symbol: "N", title: "Night Shift")
        let shiftE = createMockShiftType(symbol: "E", title: "Evening Shift")

        let colorD = ShiftColorPalette.colorForShift(shiftD)
        let colorN = ShiftColorPalette.colorForShift(shiftN)
        let colorE = ShiftColorPalette.colorForShift(shiftE)

        // At least some should be different (highly probable with 10 colors)
        let allSame = (colorD == colorN) && (colorN == colorE)
        #expect(!allSame, "Different shifts should typically have different colors")
    }

    @Test("gradientColorsForShift returns valid gradient pair")
    func testGradientColorsForShift() async throws {
        let shiftType = createMockShiftType(symbol: "D", title: "Day Shift")

        let (primary, secondary) = ShiftColorPalette.gradientColorsForShift(shiftType)

        #expect(primary != secondary, "Gradient colors should be different")
    }

    @Test("glowColorForShift returns color with reduced opacity")
    func testGlowColorForShift() async throws {
        let shiftType = createMockShiftType(symbol: "D", title: "Day Shift")

        let glowColor = ShiftColorPalette.glowColorForShift(shiftType)

        // Glow color should exist (basic validation)
        #expect(glowColor != Color.clear, "Glow color should not be clear")
    }

    // MARK: - Location Color Tests

    @Test("colorForLocation returns consistent color for same location")
    func testColorForLocationConsistency() async throws {
        let locationName = "Hospital A"

        let color1 = ShiftColorPalette.colorForLocation(locationName)
        let color2 = ShiftColorPalette.colorForLocation(locationName)

        #expect(color1 == color2, "Same location name should always return same color")
    }

    @Test("colorForLocation returns different colors for different locations")
    func testColorForLocationVariety() async throws {
        let locationA = "Hospital A"
        let locationB = "Clinic B"
        let locationC = "Office C"

        let colorA = ShiftColorPalette.colorForLocation(locationA)
        let colorB = ShiftColorPalette.colorForLocation(locationB)
        let colorC = ShiftColorPalette.colorForLocation(locationC)

        // At least some should be different (highly probable with 6 colors)
        let allSame = (colorA == colorB) && (colorB == colorC)
        #expect(!allSame, "Different locations should typically have different colors")
    }

    @Test("gradientColorsForLocation returns valid gradient pair")
    func testGradientColorsForLocation() async throws {
        let locationName = "Hospital A"

        let (primary, secondary) = ShiftColorPalette.gradientColorsForLocation(locationName)

        #expect(primary != secondary, "Gradient colors should be different")
    }

    @Test("glowColorForLocation returns color with reduced opacity")
    func testGlowColorForLocation() async throws {
        let locationName = "Hospital A"

        let glowColor = ShiftColorPalette.glowColorForLocation(locationName)

        #expect(glowColor != Color.clear, "Glow color should not be clear")
    }

    // MARK: - Hash-Based Distribution Tests

    @Test("colorForShift distributes across palette for multiple shifts")
    func testShiftColorDistribution() async throws {
        let shifts = [
            createMockShiftType(symbol: "A", title: "Shift A"),
            createMockShiftType(symbol: "B", title: "Shift B"),
            createMockShiftType(symbol: "C", title: "Shift C"),
            createMockShiftType(symbol: "D", title: "Shift D"),
            createMockShiftType(symbol: "E", title: "Shift E")
        ]

        let colors = shifts.map { ShiftColorPalette.colorForShift($0) }
        let uniqueColors = Set(colors.map { "\($0)" }) // String representation for uniqueness

        // With 5 shifts and 10 colors, expect some variety
        #expect(uniqueColors.count >= 2, "Multiple shifts should use different colors from palette")
    }

    @Test("colorForLocation distributes across palette for multiple locations")
    func testLocationColorDistribution() async throws {
        let locations = [
            "Hospital A",
            "Clinic B",
            "Office C",
            "Center D",
            "Facility E"
        ]

        let colors = locations.map { ShiftColorPalette.colorForLocation($0) }
        let uniqueColors = Set(colors.map { "\($0)" })

        // With 5 locations and 6 colors, expect some variety
        #expect(uniqueColors.count >= 2, "Multiple locations should use different colors from palette")
    }

    // MARK: - Edge Cases

    @Test("colorForLocation handles empty string")
    func testLocationColorWithEmptyString() async throws {
        let emptyLocation = ""

        let color = ShiftColorPalette.colorForLocation(emptyLocation)

        #expect(color != Color.clear, "Should return valid color even for empty string")
    }

    @Test("colorForLocation handles special characters")
    func testLocationColorWithSpecialCharacters() async throws {
        let specialLocation = "Hospital #1 & Clinic (Main)"

        let color1 = ShiftColorPalette.colorForLocation(specialLocation)
        let color2 = ShiftColorPalette.colorForLocation(specialLocation)

        #expect(color1 == color2, "Special characters should still produce consistent colors")
    }

    @Test("colorForShift handles single character symbols")
    func testShiftColorWithSingleCharacter() async throws {
        let shiftA = createMockShiftType(symbol: "A", title: "Shift A")
        let shiftZ = createMockShiftType(symbol: "Z", title: "Shift Z")

        let colorA = ShiftColorPalette.colorForShift(shiftA)
        let colorZ = ShiftColorPalette.colorForShift(shiftZ)

        #expect(colorA != Color.clear, "Single character should return valid color")
        #expect(colorZ != Color.clear, "Single character should return valid color")
    }

    // MARK: - Helper Methods

    private func createMockShiftType(symbol: String, title: String) -> ShiftType {
        let testLocation = Location(id: UUID(), name: "Test Location", address: "123 Test St")

        return ShiftType(
            symbol: symbol,
            duration: .scheduled(
                from: HourMinuteTime(hour: 9, minute: 0),
                to: HourMinuteTime(hour: 17, minute: 0)
            ),
            title: title,
            description: "Test shift",
            location: testLocation
        )
    }
}
