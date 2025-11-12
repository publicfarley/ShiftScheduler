import Foundation
@testable import ShiftScheduler

/// Mock implementation of DateProviderProtocol for unit testing with fixed dates
struct MockDateProvider: DateProviderProtocol {
    var fixedNow: Date
    var fixedToday: Date
    var fixedTomorrow: Date

    init(fixedNow: Date = Date()) {
        self.fixedNow = fixedNow
        self.fixedToday = Calendar.current.startOfDay(for: fixedNow)
        self.fixedTomorrow = Calendar.current.date(byAdding: .day, value: 1, to: fixedToday) ?? fixedToday
    }

    func now() -> Date {
        fixedNow
    }

    func today() -> Date {
        fixedToday
    }

    func tomorrow() -> Date {
        fixedTomorrow
    }
}
