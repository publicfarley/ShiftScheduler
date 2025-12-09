import SwiftUI

/// Color palette for Schedule view calendar dates
/// Based on warm earth-toned palette for natural, inviting aesthetic
struct ScheduleViewColorPalette {

    // MARK: - Core Palette Colors

    /// Forest Green - Deep, rich green for scheduled shifts
    /// HEX: #17421A | RGB: 23, 66, 26
    static let forestGreen = Color(UIColor.systemGreen) //Color(red: 23/255, green: 66/255, blue: 26/255)

    /// Lime Green
    /// RGB: 50, 205, 50
    static let limeGreen = Color(red: 50/255, green: 205/255, blue: 50/255)
    
    /// Golden Harvest - Warm golden brown for today highlights
    /// HEX: #B67B13 | RGB: 182, 123, 19
    static let goldenHarvest = Color(red: 182/255, green: 123/255, blue: 19/255)

    /// Warm Sand - Light peachy beige for subtle backgrounds
    /// HEX: #F0BE6D | RGB: 240, 190, 109
    static let warmSand = Color(red: 240/255, green: 190/255, blue: 109/255)

    /// Terracotta - Rich burnt orange/red for emphasis and borders
    /// HEX: #AA2704 | RGB: 170, 39, 4
    static let terracotta = Color(red: 170/255, green: 39/255, blue: 4/255)

    /// Cyan Blue - Fresh, complementary to green palette for today highlights
    /// RGB: 0, 180, 220
    static let cyanBlue = Color(red: 0/255, green: 180/255, blue: 220/255)

    // MARK: - Adaptive Colors for Light/Dark Mode

    /// Adaptive text color - primary text that adapts to color scheme
    static let cellTextPrimary = Color.primary

    /// Adaptive text color for secondary text (out-of-month dates)
    static let cellTextSecondary = Color.secondary

    /// Adaptive border color using opaque separator for more prominent borders
    static let cellBorder = Color(UIColor.opaqueSeparator)

    /// Adaptive empty cell background
    static let emptyCellBackground = Color(UIColor.systemBackground)

    /// Adaptive red border for today's date - vibrant in both light and dark modes
    static let todayBorder = Color(UIColor(cyanBlue))

    // MARK: - Semantic Color Usage

    /// Background color for today's date (no shift scheduled)
    /// Cyan/teal color that complements the green palette
    /// Lighter in light mode, more visible in dark mode
    static var todayBackground: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(cyanBlue.opacity(0.4))
                : UIColor(cyanBlue.opacity(0.25))
        })
    }

    /// Background color for dates with scheduled shifts
    /// Full color in light mode, adjusted opacity in dark mode
    static var scheduledShiftBackground: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(forestGreen.opacity(0.6))
                : UIColor(forestGreen)
        })
    }

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
    /// Black in light mode, white in dark mode
    static var selectedDateBorder: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor.white
                : UIColor.black
        })
    }

    /// Accent color overlay for selected dates
    static let selectedDateOverlay = terracotta.opacity(0.12)
}
