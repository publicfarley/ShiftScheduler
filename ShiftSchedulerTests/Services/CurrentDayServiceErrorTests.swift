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
    func testGetTomorrowDateReturnsStartOfTomorrow() throws {
        let service = CurrentDayService()
        let tomorrow = service.getTomorrowDate()
        let expectedTomorrow = try #require(Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date())))

        let daysDifference = Calendar.current.dateComponents([.day], from: tomorrow, to: expectedTomorrow).day ?? 0
        #expect(daysDifference == 0)
    }

    @Test("getYesterdayDate returns start of yesterday")
    func testGetYesterdayDateReturnsStartOfYesterday() throws {
        let service = CurrentDayService()
        let yesterday = service.getYesterdayDate()
        let expectedYesterday = try #require(Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: Date())))

        let daysDifference = Calendar.current.dateComponents([.day], from: yesterday, to: expectedYesterday).day ?? 0
        #expect(daysDifference == 0)
    }

    // MARK: - Leap Year Edge Cases

    @Test("Calculates days correctly across leap year February 29th")
    func testHandlesLeapYearFebruary29() throws {
        let service = CurrentDayService()
        let leapYearFeb28 = try #require(Calendar.current.date(from: DateComponents(year: 2024, month: 2, day: 28)))
        let leapYearFeb29 = try #require(Calendar.current.date(from: DateComponents(year: 2024, month: 2, day: 29)))
        let leapYearMar1 = try #require(Calendar.current.date(from: DateComponents(year: 2024, month: 3, day: 1)))

        // Service correctly calculates day differences across leap day
        #expect(service.daysBetween(leapYearFeb28, leapYearFeb29) == 1)
        #expect(service.daysBetween(leapYearFeb29, leapYearMar1) == 1)
        #expect(service.daysBetween(leapYearFeb28, leapYearMar1) == 2)
    }

    @Test("Calculates month end correctly for non-leap year February")
    func testHandlesNonLeapYearFebruary28() throws {
        let service = CurrentDayService()
        let nonLeapYearFeb = try #require(Calendar.current.date(from: DateComponents(year: 2025, month: 2, day: 28)))
        let mar1 = try #require(Calendar.current.date(from: DateComponents(year: 2025, month: 3, day: 1)))

        // Service correctly identifies end of February in non-leap year
        let endOfFeb = service.getEndOfMonth(for: nonLeapYearFeb)
        #expect(service.daysBetween(endOfFeb, mar1) == 1)
    }

    // MARK: - Month Boundary Edge Cases

    @Test("Service calculates day differences correctly across month transitions")
    func testHandlesMonthTransitions() throws {
        let service = CurrentDayService()
        let lastDayOfMonth = try #require(Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 31)))
        let firstDayOfNextMonth = try #require(Calendar.current.date(from: DateComponents(year: 2025, month: 2, day: 1)))

        // Service correctly handles month boundary
        #expect(service.daysBetween(lastDayOfMonth, firstDayOfNextMonth) == 1)
    }

    @Test("Service calculates day differences correctly across year transitions")
    func testHandlesYearTransitions() throws {
        let service = CurrentDayService()
        let lastDayOfYear = try #require(Calendar.current.date(from: DateComponents(year: 2024, month: 12, day: 31)))
        let firstDayOfNextYear = try #require(Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 1)))

        // Service correctly handles year boundary
        #expect(service.daysBetween(lastDayOfYear, firstDayOfNextYear) == 1)
    }

    @Test("Handles negative day calculations")
    func testHandlesNegativeDayCalculations() throws {
        let service = CurrentDayService()
        let baseDate = try #require(Calendar.current.date(from: DateComponents(year: 2025, month: 6, day: 15)))
        let earlierDate = try #require(Calendar.current.date(from: DateComponents(year: 2025, month: 5, day: 26)))

        // Service correctly calculates negative differences (past dates)
        let daysDifference = service.daysBetween(baseDate, earlierDate)
        #expect(daysDifference == -20)
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
    func testIsTodayForOtherDates() throws {
        let service = CurrentDayService()
        let otherDate = try #require(Calendar.current.date(byAdding: .day, value: 5, to: Date()))

        let result = service.isToday(otherDate)
        #expect(result == false)
    }

    @Test("isTomorrow returns correct result for actual tomorrow")
    func testIsTomorrowForActualTomorrow() throws {
        let service = CurrentDayService()
        let tomorrow = try #require(Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date())))

        let result = service.isTomorrow(tomorrow)
        #expect(result == true)
    }

    @Test("isTomorrow returns false for other dates")
    func testIsTomorrowForOtherDates() throws {
        let service = CurrentDayService()
        let otherDate = try #require(Calendar.current.date(byAdding: .day, value: 5, to: Date()))

        let result = service.isTomorrow(otherDate)
        #expect(result == false)
    }

    @Test("isYesterday returns correct result for actual yesterday")
    func testIsYesterdayForActualYesterday() throws {
        let service = CurrentDayService()
        let yesterday = try #require(Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: Date())))

        let result = service.isYesterday(yesterday)
        #expect(result == true)
    }

    @Test("isYesterday returns false for other dates")
    func testIsYesterdayForOtherDates() throws {
        let service = CurrentDayService()
        let otherDate = try #require(Calendar.current.date(byAdding: .day, value: 5, to: Date()))

        let result = service.isYesterday(otherDate)
        #expect(result == false)
    }

    // MARK: - Day Difference Calculation Tests

    @Test("daysBetween returns zero for same date")
    func testDaysBetweenSameDate() throws {
        let service = CurrentDayService()
        let date = try #require(Calendar.current.date(from: DateComponents(year: 2025, month: 6, day: 15)))

        let difference = service.daysBetween(date, date)
        #expect(difference == 0)
    }

    @Test("daysBetween returns positive for future date")
    func testDaysBetweenFutureDate() throws {
        let service = CurrentDayService()
        let startDate = try #require(Calendar.current.date(from: DateComponents(year: 2025, month: 6, day: 15)))
        let endDate = try #require(Calendar.current.date(from: DateComponents(year: 2025, month: 6, day: 20)))

        let difference = service.daysBetween(startDate, endDate)
        #expect(difference == 5)
    }

    @Test("daysBetween returns negative for past date")
    func testDaysBetweenPastDate() throws {
        let service = CurrentDayService()
        let startDate = try #require(Calendar.current.date(from: DateComponents(year: 2025, month: 6, day: 20)))
        let endDate = try #require(Calendar.current.date(from: DateComponents(year: 2025, month: 6, day: 15)))

        let difference = service.daysBetween(startDate, endDate)
        #expect(difference == -5)
    }

    @Test("daysBetween handles month boundary")
    func testDaysBetweenMonthBoundary() throws {
        let service = CurrentDayService()
        let startDate = try #require(Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 30)))
        let endDate = try #require(Calendar.current.date(from: DateComponents(year: 2025, month: 2, day: 2)))

        let difference = service.daysBetween(startDate, endDate)
        #expect(difference == 3)
    }

    @Test("daysBetween handles year boundary")
    func testDaysBetweenYearBoundary() throws {
        let service = CurrentDayService()
        let startDate = try #require(Calendar.current.date(from: DateComponents(year: 2024, month: 12, day: 30)))
        let endDate = try #require(Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 2)))

        let difference = service.daysBetween(startDate, endDate)
        #expect(difference == 3)
    }

    // MARK: - Time Component Handling

    @Test("Date comparisons ignore time components")
    func testDateComparisonsIgnoreTimeComponents() throws {
        let service = CurrentDayService()

        var components = DateComponents(year: 2025, month: 6, day: 15, hour: 10, minute: 30, second: 45)
        let date1 = try #require(Calendar.current.date(from: components))

        components = DateComponents(year: 2025, month: 6, day: 15, hour: 20, minute: 45, second: 30)
        let date2 = try #require(Calendar.current.date(from: components))

        // Same day despite different times
        let difference = service.daysBetween(date1, date2)
        #expect(difference == 0)
    }

    // MARK: - Large Date Range Tests

    @Test("Handles large positive date offsets")
    func testHandlesLargeDateOffsets() throws {
        let service = CurrentDayService()
        let baseDate = try #require(Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 1)))
        let futureDate = try #require(Calendar.current.date(byAdding: .day, value: 365, to: baseDate))

        let difference = service.daysBetween(baseDate, futureDate)
        #expect(difference == 365)
    }

    @Test("Handles large negative date offsets")
    func testHandlesLargeNegativeDateOffsets() throws {
        let service = CurrentDayService()
        let baseDate = try #require(Calendar.current.date(from: DateComponents(year: 2025, month: 12, day: 31)))
        let pastDate = try #require(Calendar.current.date(byAdding: .day, value: -365, to: baseDate))

        let difference = service.daysBetween(baseDate, pastDate)
        #expect(difference == -365)
    }

    // MARK: - DST Edge Cases (if applicable)

    @Test("Handles daylight saving time transitions")
    func testHandlesDaylightSavingTime() throws {
        let service = CurrentDayService()

        // Spring forward (example: US 2025 - March 9)
        let beforeDST = try #require(Calendar.current.date(from: DateComponents(year: 2025, month: 3, day: 8)))
        let afterDST = try #require(Calendar.current.date(from: DateComponents(year: 2025, month: 3, day: 10)))

        let difference = service.daysBetween(beforeDST, afterDST)
        #expect(difference == 2)  // Still 2 days apart despite hour changes
    }

    // MARK: - Error and Exception Handling Tests

    @Test("Service calculates dates correctly for distant past dates")
    func testGetYesterdayDateHandlesDistantPast() throws {
        let service = CurrentDayService(calendar: Calendar.current)
        let veryOldDate = try #require(Calendar.current.date(from: DateComponents(year: 1900, month: 1, day: 1)))
        let refDate = try #require(Calendar.current.date(from: DateComponents(year: 1900, month: 1, day: 2)))

        // Service can calculate day differences across distant past dates
        let daysDifference = service.daysBetween(veryOldDate, refDate)
        #expect(daysDifference == 1)
    }

    @Test("Service calculates dates correctly for distant future dates")
    func testGetTomorrowDateHandlesDistantFuture() throws {
        let service = CurrentDayService(calendar: Calendar.current)
        let veryFutureDate = try #require(Calendar.current.date(from: DateComponents(year: 2099, month: 12, day: 31)))
        let refDate = try #require(Calendar.current.date(from: DateComponents(year: 2100, month: 1, day: 1)))

        // Service can calculate day differences across distant future dates
        let daysDifference = service.daysBetween(veryFutureDate, refDate)
        #expect(daysDifference == 1)
    }

    @Test("daysBetween handles extreme date ranges without overflow")
    func testDaysBetweenHandlesExtremeRanges() throws {
        let service = CurrentDayService()
        let startDate = try #require(Calendar.current.date(from: DateComponents(year: 1970, month: 1, day: 1)))
        let endDate = try #require(Calendar.current.date(from: DateComponents(year: 2070, month: 12, day: 31)))

        let difference = service.daysBetween(startDate, endDate)
        #expect(difference > 0)
        #expect(difference > 36000) // Should be ~36,869 days
    }

    @Test("isToday returns false for historical dates")
    func testIsTodayFalseForHistoricalDates() throws {
        let service = CurrentDayService()
        let historicalDate = try #require(Calendar.current.date(from: DateComponents(year: 1950, month: 6, day: 15)))

        let result = service.isToday(historicalDate)
        #expect(result == false)
    }

    @Test("isTomorrow returns false for random future dates")
    func testIsTomorrowFalseForRandomFutureDates() throws {
        let service = CurrentDayService()
        let futureDate = try #require(Calendar.current.date(byAdding: .day, value: 10, to: Date()))

        let result = service.isTomorrow(futureDate)
        #expect(result == false)
    }

    @Test("isYesterday returns false for random past dates")
    func testIsYesterdayFalseForRandomPastDates() throws {
        let service = CurrentDayService()
        let pastDate = try #require(Calendar.current.date(byAdding: .day, value: -10, to: Date()))

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

    @Test("Service correctly identifies date ranges")
    func testExtractsDateComponentsSafely() throws {
        let service = CurrentDayService()
        let june15 = try #require(Calendar.current.date(from: DateComponents(year: 2025, month: 6, day: 15)))
        let june20 = try #require(Calendar.current.date(from: DateComponents(year: 2025, month: 6, day: 20)))

        // Service can work with dates from the same month
        let monthDifference = service.daysBetween(june15, june20)
        #expect(monthDifference == 5)
    }

    @Test("Service formats dates correctly")
    func testFormattesDateCorrectly() throws {
        let service = CurrentDayService()
        let date = try #require(Calendar.current.date(from: DateComponents(year: 2025, month: 6, day: 15)))

        // Service's formatDate method produces non-empty output
        let formatted = service.formatDate(date, style: .medium)
        #expect(!formatted.isEmpty)
        #expect(formatted.contains("6") || formatted.contains("15") || formatted.contains("Jun") || formatted.contains("2025"))
    }
}
