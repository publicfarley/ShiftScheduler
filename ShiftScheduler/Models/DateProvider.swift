import Foundation

/// Abstraction for date/time operations to enable unit testing with fixed dates
struct DateProvider: Sendable {
    let referenceDate: Date
    
    init(referenceDate: Date) {
        self.referenceDate = referenceDate
    }
    
    init?(
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


    var currentDay: Date {
        referenceDate
    }
    
    var previousDay: Date? {
        Calendar.current.date(byAdding: .day, value: -1, to: currentDay)
    }
    
    var nextDay: Date? {
        Calendar.current.date(byAdding: .day, value: 1, to: currentDay)
    }
}

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
}
