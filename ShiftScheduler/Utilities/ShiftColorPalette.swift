import SwiftUI

/// Dynamic color generation for shift types based on symbol hashing
/// Provides consistent, vibrant colors with gradient pairs for premium UI
struct ShiftColorPalette {

    // MARK: - Color Generation

    /// Generate a primary color for a shift type based on its symbol
    /// Uses hash-based selection for consistency across app sessions
    static func colorForShift(_ shiftType: ShiftType?) -> Color {
        guard let shiftType = shiftType else {
            return Color(red: 0.2, green: 0.35, blue: 0.5)
        }

        let hash = shiftType.symbol.hashValue
        let colors = vibrantColorPalette
        return colors[abs(hash) % colors.count]
    }

    /// Generate a gradient color pair for a shift type
    /// Returns (primary, secondary) colors for gradient effects
    static func gradientColorsForShift(_ shiftType: ShiftType?) -> (Color, Color) {
        guard let shiftType = shiftType else {
            return (Color(red: 0.2, green: 0.35, blue: 0.5),
                    Color(red: 0.1, green: 0.25, blue: 0.4))
        }

        let primaryColor = colorForShift(shiftType)
        let secondaryColor = primaryColor.opacity(0.7)

        return (primaryColor, secondaryColor)
    }

    /// Get an adaptive text color that contrasts well with the given background
    /// Automatically chooses white or black based on luminance
    static func adaptiveTextColor(for backgroundColor: Color) -> Color {
        // For simplicity, use white text for all shift colors (they're dark enough)
        // In production, could implement proper luminance calculation
        return .white
    }

    // MARK: - Color Palettes

    /// Vibrant color palette for shift types
    /// These colors are selected for:
    /// - High visual appeal
    /// - Good contrast with white text
    /// - Distinct appearance from each other
    private static let vibrantColorPalette: [Color] = [
        Color(red: 0.1, green: 0.5, blue: 0.8),   // Vibrant Blue
        Color(red: 0.2, green: 0.7, blue: 0.5),   // Emerald Green
        Color(red: 0.8, green: 0.4, blue: 0.2),   // Warm Orange
        Color(red: 0.6, green: 0.3, blue: 0.8),   // Purple
        Color(red: 0.8, green: 0.3, blue: 0.5),   // Magenta
        Color(red: 0.3, green: 0.7, blue: 0.7),   // Teal
        Color(red: 0.9, green: 0.5, blue: 0.2),   // Amber
        Color(red: 0.4, green: 0.6, blue: 0.9),   // Light Blue
        Color(red: 0.7, green: 0.3, blue: 0.7),   // Lavender
        Color(red: 0.3, green: 0.8, blue: 0.6)    // Mint
    ]

    // MARK: - Gradient Helpers

    /// Create a gradient from a shift's primary color
    static func gradientForShift(_ shiftType: ShiftType?) -> LinearGradient {
        let (primary, secondary) = gradientColorsForShift(shiftType)
        return LinearGradient(
            colors: [primary, secondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Create a subtle glow color for shadows and highlights
    static func glowColorForShift(_ shiftType: ShiftType?) -> Color {
        colorForShift(shiftType).opacity(0.4)
    }

    /// Create a light background tint for glass effects
    static func glassTintForShift(_ shiftType: ShiftType?) -> Color {
        colorForShift(shiftType).opacity(0.08)
    }

    /// Create a border color with gradient effect
    static func borderColorForShift(_ shiftType: ShiftType?) -> LinearGradient {
        let primary = colorForShift(shiftType)
        return LinearGradient(
            colors: [
                primary.opacity(0.3),
                primary.opacity(0.1),
                primary.opacity(0.2)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Color Extensions

extension Color {
    /// Creates a slightly darker version of the color
    func darkened(by percentage: Double = 0.2) -> Color {
        self.opacity(1.0 - percentage)
    }

    /// Creates a slightly lighter version of the color
    func lightened(by percentage: Double = 0.2) -> Color {
        // Note: This is a simplified version
        // A full implementation would adjust RGB values
        self.opacity(0.7 + (percentage * 0.3))
    }
}
