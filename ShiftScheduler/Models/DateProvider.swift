import Foundation

/// Abstraction for date/time operations to enable unit testing with fixed dates
public struct DateProvider: Sendable {
    public let referenceDate: Date
    
    public init(referenceDate: Date) {
        self.referenceDate = referenceDate
    }
    
    public init?(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 0,
        minute: Int = 0,
        second: Int = 0
    ) {
        let components = DateComponents(
            year: year, month: month, day: day, hour: hour, minute: minute, second: second
        )
        
        guard let date = Calendar.current.date(from: components) else {
            return nil
        }
        
        self.init(referenceDate: date)
    }


    public var currentDay: Date {
        referenceDate
    }
    
    public var previousDay: Date? {
        Calendar.current.date(byAdding: .day, value: -1, to: currentDay)
    }
    
    public var nextDay: Date? {
        Calendar.current.date(byAdding: .day, value: 1, to: currentDay)
    }
}

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
}
