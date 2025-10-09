import Foundation

/// Protocol abstraction for date/time operations to enable unit testing with fixed dates
protocol DateProviderProtocol: Sendable {
    func now() -> Date
    func today() -> Date
    func tomorrow() -> Date
}

/// Production implementation using system date/time
struct SystemDateProvider: DateProviderProtocol {
    func now() -> Date {
        Date()
    }

    func today() -> Date {
        Calendar.current.startOfDay(for: Date())
    }

    func tomorrow() -> Date {
        Calendar.current.date(byAdding: .day, value: 1, to: today()) ?? today()
    }
}
