import SwiftUI

/// Color palette for Schedule view calendar dates
/// Based on AWSMCOLOR blue-themed palette for cohesive, modern aesthetic
struct ScheduleViewColorPalette {

    // MARK: - Core Palette Colors

    /// Continental Blue - Deep, rich blue for scheduled shifts
    /// HEX: #023E8A | RGB: 2, 62, 138 | CMYK: 100, 86, 21, 27
    static let continentalBlue = Color(red: 2/255, green: 62/255, blue: 138/255)

    /// Coastal Surge - Vibrant cyan/turquoise for today highlights
    /// HEX: #48CAE4 | RGB: 72, 202, 228 | CMYK: 62, 2, 13, 0
    static let coastalSurge = Color(red: 72/255, green: 202/255, blue: 228/255)

    /// Frostline Pale - Very light cyan for subtle backgrounds
    /// HEX: #CAF0F8 | RGB: 202, 240, 248 | CMYK: 20, 0, 4, 0
    static let frostlinePale = Color(red: 202/255, green: 240/255, blue: 248/255)

    /// Trench Blue - Navy/midnight blue for emphasis and borders
    /// HEX: #03045E | RGB: 3, 4, 94 | CMYK: 100, 98, 25, 37
    static let trenchBlue = Color(red: 3/255, green: 4/255, blue: 94/255)

    // MARK: - Semantic Color Usage

    /// Background color for today's date (no shift scheduled)
    static let todayBackground = coastalSurge.opacity(0.15)

    /// Background color for dates with scheduled shifts
    static let scheduledShiftBackground = continentalBlue.opacity(0.12)

    /// Gradient background for today's date with a shift
    static let todayWithShiftGradient = LinearGradient(
        colors: [
            coastalSurge.opacity(0.2),
            continentalBlue.opacity(0.15)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Background color for selected empty dates (bulk add mode)
    static let selectedEmptyDateBackground = frostlinePale.opacity(0.2)

    /// Border color for selected dates
    static let selectedDateBorder = trenchBlue

    /// Accent color overlay for selected dates
    static let selectedDateOverlay = trenchBlue.opacity(0.12)
}
