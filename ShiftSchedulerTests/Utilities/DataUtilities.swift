import Foundation
import Testing

extension Date {
    /// Get a deterministic test date (fixed for reproducibility)
    static func fixedTestDate_Nov11_2025() throws -> Date {
        // Use a fixed date: 2025-11-10 00:00:00 UTC
        var components = DateComponents()
        components.year = 2025
        components.month = 11
        components.day = 10
        components.hour = 0
        components.minute = 0
        components.second = 0
        
        return try #require(Calendar.current.date(from: components))
    }
}
