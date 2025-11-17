import SwiftUI

/// Color palette for Schedule view calendar dates
/// Based on warm earth-toned palette for natural, inviting aesthetic
struct ScheduleViewColorPalette {

    // MARK: - Core Palette Colors

    /// Forest Green - Deep, rich green for scheduled shifts
    /// HEX: #17421A | RGB: 23, 66, 26
    static let forestGreen = Color(red: 23/255, green: 66/255, blue: 26/255)

    /// Golden Harvest - Warm golden brown for today highlights
    /// HEX: #B67B13 | RGB: 182, 123, 19
    static let goldenHarvest = Color(red: 182/255, green: 123/255, blue: 19/255)

    /// Warm Sand - Light peachy beige for subtle backgrounds
    /// HEX: #F0BE6D | RGB: 240, 190, 109
    static let warmSand = Color(red: 240/255, green: 190/255, blue: 109/255)

    /// Terracotta - Rich burnt orange/red for emphasis and borders
    /// HEX: #AA2704 | RGB: 170, 39, 4
    static let terracotta = Color(red: 170/255, green: 39/255, blue: 4/255)

    // MARK: - Semantic Color Usage

    /// Background color for today's date (no shift scheduled)
    static let todayBackground = goldenHarvest.opacity(0.25)

    /// Background color for dates with scheduled shifts
    static let scheduledShiftBackground = forestGreen.opacity(0.12)

    /// Gradient background for today's date with a shift
    /// Uses stronger opacity and brighter golden harvest for clear distinction
    static let todayWithShiftGradient = LinearGradient(
        colors: [
            goldenHarvest.opacity(0.35),
            warmSand.opacity(0.25)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Background color for selected empty dates (bulk add mode)
    static let selectedEmptyDateBackground = warmSand.opacity(0.2)

    /// Border color for selected dates
    static let selectedDateBorder = terracotta

    /// Accent color overlay for selected dates
    static let selectedDateOverlay = terracotta.opacity(0.12)
}
