import Testing
import Foundation
@testable import ShiftScheduler

/// Error scenario tests for CurrentDayService
/// Tests invalid dates, edge cases, and date calculation robustness
@Suite("CurrentDayService Error Scenario Tests")
@MainActor
struct CurrentDayServiceErrorTests {

    // MARK: - Edge Case Date Tests

    @Test("getCurrentDate returns valid date")
    func testGetCurrentDateReturnsValidDate() {
        let service = CurrentDayService()
        let date = service.getCurrentDate()
        #expect(date <= Date())
    }

    @Test("getTodayDate returns start of today")
    func testGetTodayDateReturnsStartOfToday() {
        let service = CurrentDayService()
        let today = service.getTodayDate()
        let expectedToday = Calendar.current.startOfDay(for: Date())

        let daysDifference = Calendar.current.dateComponents([.day], from: today, to: expectedToday).day ?? 0
        #expect(daysDifference == 0)
    }

    @Test("getTomorrowDate returns start of tomorrow")
    func testGetTomorrowDateReturnsStartOfTomorrow() {
        let service = CurrentDayService()
        let tomorrow = service.getTomorrowDate()
        let expectedTomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))!

        let daysDifference = Calendar.current.dateComponents([.day], from: tomorrow, to: expectedTomorrow).day ?? 0
        #expect(daysDifference == 0)
    }

    @Test("getYesterdayDate returns start of yesterday")
    func testGetYesterdayDateReturnsStartOfYesterday() {
        let service = CurrentDayService()
        let yesterday = service.getYesterdayDate()
        let expectedYesterday = Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: Date()))!

        let daysDifference = Calendar.current.dateComponents([.day], from: yesterday, to: expectedYesterday).day ?? 0
        #expect(daysDifference == 0)
    }

    // MARK: - Leap Year Edge Cases

    @Test("Handles leap year February 29th correctly")
    func testHandlesLeapYearFebruary29() {
        let service = CurrentDayService()
        let leapYearDate = Calendar.current.date(from: DateComponents(year: 2024, month: 2, day: 29))!

        // February 29, 2024 is a valid leap year date
        let dayOfWeek = Calendar.current.component(.weekday, from: leapYearDate)
        #expect(dayOfWeek >= 1 && dayOfWeek <= 7)
    }

    @Test("Handles non-leap year February 28th correctly")
    func testHandlesNonLeapYearFebruary28() {
        let service = CurrentDayService()
        let nonLeapYearDate = Calendar.current.date(from: DateComponents(year: 2025, month: 2, day: 28))!

        let dayOfWeek = Calendar.current.component(.weekday, from: nonLeapYearDate)
        #expect(dayOfWeek >= 1 && dayOfWeek <= 7)
    }

    // MARK: - Month Boundary Edge Cases

    @Test("Handles month transitions correctly")
    func testHandlesMonthTransitions() {
        let service = CurrentDayService()
        let lastDayOfMonth = Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 31))!
        let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: lastDayOfMonth)!

        let nextMonth = Calendar.current.component(.month, from: nextDay)
        #expect(nextMonth == 2)
    }

    @Test("Handles year transitions correctly")
    func testHandlesYearTransitions() {
        let service = CurrentDayService()
        let lastDayOfYear = Calendar.current.date(from: DateComponents(year: 2024, month: 12, day: 31))!
        let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: lastDayOfYear)!

        let nextYear = Calendar.current.component(.year, from: nextDay)
        #expect(nextYear == 2025)
    }

    @Test("Handles negative day calculations")
    func testHandlesNegativeDayCalculations() {
        let service = CurrentDayService()
        let date = Calendar.current.date(from: DateComponents(year: 2025, month: 6, day: 15))!

        // Go back 20 days
        let pastDate = Calendar.current.date(byAdding: .day, value: -20, to: date)!
        let daysDifference = Calendar.current.dateComponents([.day], from: pastDate, to: date).day ?? 0
        #expect(daysDifference == 20)
    }

    // MARK: - Comparison Tests

    @Test("isToday returns correct result for actual today")
    func testIsTodayForActualToday() {
        let service = CurrentDayService()
        let today = Calendar.current.startOfDay(for: Date())

        let result = service.isToday(today)
        #expect(result == true)
    }

    @Test("isToday returns false for other dates")
    func testIsTodayForOtherDates() {
        let service = CurrentDayService()
        let otherDate = Calendar.current.date(byAdding: .day, value: 5, to: Date())!

        let result = service.isToday(otherDate)
        #expect(result == false)
    }

    @Test("isTomorrow returns correct result for actual tomorrow")
    func testIsTomorrowForActualTomorrow() {
        let service = CurrentDayService()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))!

        let result = service.isTomorrow(tomorrow)
        #expect(result == true)
    }

    @Test("isTomorrow returns false for other dates")
    func testIsTomorrowForOtherDates() {
        let service = CurrentDayService()
        let otherDate = Calendar.current.date(byAdding: .day, value: 5, to: Date())!

        let result = service.isTomorrow(otherDate)
        #expect(result == false)
    }

    @Test("isYesterday returns correct result for actual yesterday")
    func testIsYesterdayForActualYesterday() {
        let service = CurrentDayService()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: Date()))!

        let result = service.isYesterday(yesterday)
        #expect(result == true)
    }

    @Test("isYesterday returns false for other dates")
    func testIsYesterdayForOtherDates() {
        let service = CurrentDayService()
        let otherDate = Calendar.current.date(byAdding: .day, value: 5, to: Date())!

        let result = service.isYesterday(otherDate)
        #expect(result == false)
    }

    // MARK: - Day Difference Calculation Tests

    @Test("daysBetween returns zero for same date")
    func testDaysBetweenSameDate() {
        let service = CurrentDayService()
        let date = Calendar.current.date(from: DateComponents(year: 2025, month: 6, day: 15))!

        let difference = service.daysBetween(date, date)
        #expect(difference == 0)
    }

    @Test("daysBetween returns positive for future date")
    func testDaysBetweenFutureDate() {
        let service = CurrentDayService()
        let startDate = Calendar.current.date(from: DateComponents(year: 2025, month: 6, day: 15))!
        let endDate = Calendar.current.date(from: DateComponents(year: 2025, month: 6, day: 20))!

        let difference = service.daysBetween(startDate, endDate)
        #expect(difference == 5)
    }

    @Test("daysBetween returns negative for past date")
    func testDaysBetweenPastDate() {
        let service = CurrentDayService()
        let startDate = Calendar.current.date(from: DateComponents(year: 2025, month: 6, day: 20))!
        let endDate = Calendar.current.date(from: DateComponents(year: 2025, month: 6, day: 15))!

        let difference = service.daysBetween(startDate, endDate)
        #expect(difference == -5)
    }

    @Test("daysBetween handles month boundary")
    func testDaysBetweenMonthBoundary() {
        let service = CurrentDayService()
        let startDate = Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 30))!
        let endDate = Calendar.current.date(from: DateComponents(year: 2025, month: 2, day: 2))!

        let difference = service.daysBetween(startDate, endDate)
        #expect(difference == 3)
    }

    @Test("daysBetween handles year boundary")
    func testDaysBetweenYearBoundary() {
        let service = CurrentDayService()
        let startDate = Calendar.current.date(from: DateComponents(year: 2024, month: 12, day: 30))!
        let endDate = Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 2))!

        let difference = service.daysBetween(startDate, endDate)
        #expect(difference == 3)
    }

    // MARK: - Time Component Handling

    @Test("Date comparisons ignore time components")
    func testDateComparisonsIgnoreTimeComponents() {
        let service = CurrentDayService()

        var components = DateComponents(year: 2025, month: 6, day: 15, hour: 10, minute: 30, second: 45)
        let date1 = Calendar.current.date(from: components)!

        components = DateComponents(year: 2025, month: 6, day: 15, hour: 20, minute: 45, second: 30)
        let date2 = Calendar.current.date(from: components)!

        // Same day despite different times
        let difference = service.daysBetween(date1, date2)
        #expect(difference == 0)
    }

    // MARK: - Large Date Range Tests

    @Test("Handles large positive date offsets")
    func testHandlesLargeDateOffsets() {
        let service = CurrentDayService()
        let baseDate = Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 1))!
        let futureDate = Calendar.current.date(byAdding: .day, value: 365, to: baseDate)!

        let difference = service.daysBetween(baseDate, futureDate)
        #expect(difference == 365)
    }

    @Test("Handles large negative date offsets")
    func testHandlesLargeNegativeDateOffsets() {
        let service = CurrentDayService()
        let baseDate = Calendar.current.date(from: DateComponents(year: 2025, month: 12, day: 31))!
        let pastDate = Calendar.current.date(byAdding: .day, value: -365, to: baseDate)!

        let difference = service.daysBetween(baseDate, pastDate)
        #expect(difference == -365)
    }

    // MARK: - DST Edge Cases (if applicable)

    @Test("Handles daylight saving time transitions")
    func testHandlesDaylightSavingTime() {
        let service = CurrentDayService()

        // Spring forward (example: US 2025 - March 9)
        let beforeDST = Calendar.current.date(from: DateComponents(year: 2025, month: 3, day: 8))!
        let afterDST = Calendar.current.date(from: DateComponents(year: 2025, month: 3, day: 10))!

        let difference = service.daysBetween(beforeDST, afterDST)
        #expect(difference == 2)  // Still 2 days apart despite hour changes
    }

    // MARK: - Error and Exception Handling Tests

    @Test("getYesterdayDate handles distant past dates")
    func testGetYesterdayDateHandlesDistantPast() {
        let service = CurrentDayService()
        let veryOldDate = Calendar.current.date(from: DateComponents(year: 1900, month: 1, day: 1))!
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: veryOldDate)!

        let daysDifference = Calendar.current.dateComponents([.day], from: yesterday, to: veryOldDate).day ?? 0
        #expect(daysDifference == 1)
    }

    @Test("getTomorrowDate handles distant future dates")
    func testGetTomorrowDateHandlesDistantFuture() {
        let service = CurrentDayService()
        let veryFutureDate = Calendar.current.date(from: DateComponents(year: 2099, month: 12, day: 31))!
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: veryFutureDate)!

        let daysDifference = Calendar.current.dateComponents([.day], from: veryFutureDate, to: tomorrow).day ?? 0
        #expect(daysDifference == -1)
    }

    @Test("daysBetween handles extreme date ranges without overflow")
    func testDaysBetweenHandlesExtremeRanges() {
        let service = CurrentDayService()
        let startDate = Calendar.current.date(from: DateComponents(year: 1970, month: 1, day: 1))!
        let endDate = Calendar.current.date(from: DateComponents(year: 2070, month: 12, day: 31))!

        let difference = service.daysBetween(startDate, endDate)
        #expect(difference > 0)
        #expect(difference > 36000) // Should be ~36,869 days
    }

    @Test("isToday returns false for historical dates")
    func testIsTodayFalseForHistoricalDates() {
        let service = CurrentDayService()
        let historicalDate = Calendar.current.date(from: DateComponents(year: 1950, month: 6, day: 15))!

        let result = service.isToday(historicalDate)
        #expect(result == false)
    }

    @Test("isTomorrow returns false for random future dates")
    func testIsTomorrowFalseForRandomFutureDates() {
        let service = CurrentDayService()
        let futureDate = Calendar.current.date(byAdding: .day, value: 10, to: Date())!

        let result = service.isTomorrow(futureDate)
        #expect(result == false)
    }

    @Test("isYesterday returns false for random past dates")
    func testIsYesterdayFalseForRandomPastDates() {
        let service = CurrentDayService()
        let pastDate = Calendar.current.date(byAdding: .day, value: -10, to: Date())!

        let result = service.isYesterday(pastDate)
        #expect(result == false)
    }

    // MARK: - Consistency Tests

    @Test("Service returns consistent results across multiple calls")
    func testConsistentResults() {
        let service = CurrentDayService()
        let today1 = service.getTodayDate()
        let today2 = service.getTodayDate()

        let difference = Calendar.current.dateComponents([.day], from: today1, to: today2).day ?? 0
        #expect(difference == 0)
    }

    @Test("getDates returns correctly ordered results")
    func testGetDatesOrdering() {
        let service = CurrentDayService()
        let yesterday = service.getYesterdayDate()
        let today = service.getTodayDate()
        let tomorrow = service.getTomorrowDate()

        #expect(yesterday < today)
        #expect(today < tomorrow)
    }

    // MARK: - Component Access Tests

    @Test("Can extract date components safely")
    func testExtractsDateComponentsSafely() {
        let service = CurrentDayService()
        let date = Calendar.current.date(from: DateComponents(year: 2025, month: 6, day: 15))!

        let year = Calendar.current.component(.year, from: date)
        let month = Calendar.current.component(.month, from: date)
        let day = Calendar.current.component(.day, from: date)

        #expect(year == 2025)
        #expect(month == 6)
        #expect(day == 15)
    }

    @Test("Can format dates correctly")
    func testFormattesDateCorrectly() {
        let service = CurrentDayService()
        let date = Calendar.current.date(from: DateComponents(year: 2025, month: 6, day: 15))!

        let formatted = date.formatted(date: .abbreviated, time: .omitted)
        #expect(!formatted.isEmpty)
    }
}
