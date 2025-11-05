import Testing
import Foundation
@testable import ShiftScheduler

/// Tests for CurrentDayService
/// Validates date utilities, date arithmetic, and time formatting
@Suite("CurrentDayService Tests")
@MainActor
struct CurrentDayServiceTests {
    // MARK: - Setup Helpers

    /// Create a calendar with fixed date for testing
    static func createTestCalendar(withDate testDate: Date) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(abbreviation: "UTC") ?? .current
        return calendar
    }

    /// Date for testing: October 23, 2025 (Wednesday)
    static let testDate = DateComponents(
        calendar: Calendar(identifier: .gregorian),
        year: 2025,
        month: 10,
        day: 23,
        hour: 10,
        minute: 30
    ).date

    // MARK: - Tests: Basic Date Methods

    @Test("getCurrentDate returns start of day")
    func testGetCurrentDateReturnsStartOfDay() {
        // Given
        let calendar = Calendar.current
        let service = CurrentDayService(calendar: calendar)

        // When
        let result = service.getCurrentDate()

        // Then
        let components = calendar.dateComponents([.hour, .minute, .second], from: result)
        #expect(components.hour == 0)
        #expect(components.minute == 0)
        #expect(components.second == 0)
    }

    @Test("getCurrentDate returns today's date at start of day")
    func testGetCurrentDateReturnsStartOfToday() {
        // Given
        let calendar = Calendar.current
        let service = CurrentDayService(calendar: calendar)
        let startOfToday = calendar.startOfDay(for: Date())

        // When
        let result = service.getCurrentDate()

        // Then
        #expect(result == startOfToday)
    }

    // MARK: - Tests: Date Comparison Methods

    @Test("isToday correctly identifies today")
    func testIsTodayIdentifiesToday() {
        // Given
        let service = CurrentDayService()
        let today = Date()

        // When
        let result = service.isToday(today)

        // Then
        #expect(result == true)
    }

    @Test("isToday returns false for yesterday")
    func testIsTodayReturnsFalseForYesterday() throws {
        // Given
        let service = CurrentDayService()
        let yesterday = try #require(Calendar.current.date(byAdding: .day, value: -1, to: Date()))

        // When
        let result = service.isToday(yesterday)

        // Then
        #expect(result == false)
    }

    @Test("isToday returns false for tomorrow")
    func testIsTodayReturnsFalseForTomorrow() throws {
        // Given
        let service = CurrentDayService()
        let tomorrow = try #require(Calendar.current.date(byAdding: .day, value: 1, to: Date()))

        // When
        let result = service.isToday(tomorrow)

        // Then
        #expect(result == false)
    }

    @Test("isTomorrow correctly identifies tomorrow")
    func testIsTomorrowIdentifiesTomorrow() throws {
        // Given
        let service = CurrentDayService()
        let tomorrow = try #require(Calendar.current.date(byAdding: .day, value: 1, to: Date()))

        // When
        let result = service.isTomorrow(tomorrow)

        // Then
        #expect(result == true)
    }

    @Test("isTomorrow returns false for today")
    func testIsTomorrowReturnsFalseForToday() {
        // Given
        let service = CurrentDayService()

        // When
        let result = service.isTomorrow(Date())

        // Then
        #expect(result == false)
    }

    @Test("isYesterday correctly identifies yesterday")
    func testIsYesterdayIdentifiesYesterday() throws {
        // Given
        let service = CurrentDayService()
        let yesterday = try #require(Calendar.current.date(byAdding: .day, value: -1, to: Date()))

        // When
        let result = service.isYesterday(yesterday)

        // Then
        #expect(result == true)
    }

    @Test("isYesterday returns false for today")
    func testIsYesterdayReturnsFalseForToday() {
        // Given
        let service = CurrentDayService()

        // When
        let result = service.isYesterday(Date())

        // Then
        #expect(result == false)
    }

    // MARK: - Tests: Week/Month Calculations

    @Test("getStartOfWeek returns start of week")
    func testGetStartOfWeekReturnsWeekStart() throws {
        // Given
        let service = CurrentDayService()
        let calendar = Calendar.current
        // Use fixed testDate (October 23, 2025 - Wednesday)
        let testDate = Self.testDate

        // When
        let startOfWeek = service.getStartOfWeek(for: try #require(testDate))

        // Then
        let components = calendar.dateComponents([.weekday], from: startOfWeek)
        // Sunday = 1 in Gregorian calendar
        #expect(components.weekday == 1)
    }

    @Test("getEndOfWeek returns 6 days after week start")
    func testGetEndOfWeekReturns6DaysAfterStart() throws {
        // Given
        let service = CurrentDayService()
        let calendar = Calendar.current
        // Use fixed testDate (October 23, 2025 - Wednesday)
        let testDate = try #require(Self.testDate)

        // When
        let startOfWeek = service.getStartOfWeek(for: testDate)
        let endOfWeek = service.getEndOfWeek(for: testDate)

        // Then
        let daysBetween = calendar.dateComponents([.day], from: startOfWeek, to: endOfWeek).day ?? 0
        #expect(daysBetween == 6)
    }

    @Test("getStartOfMonth returns first day of month")
    func testGetStartOfMonthReturnsFirstDay() throws {
        // Given
        let service = CurrentDayService()
        let calendar = Calendar.current
        // Use fixed testDate (October 23, 2025 - Wednesday)
        let testDate = try #require(Self.testDate)

        // When
        let startOfMonth = service.getStartOfMonth(for: testDate)

        // Then
        let components = calendar.dateComponents([.day], from: startOfMonth)
        #expect(components.day == 1)
    }

    @Test("getEndOfMonth returns last day of month")
    func testGetEndOfMonthReturnsLastDay() throws {
        // Given
        let service = CurrentDayService()
        let calendar = Calendar.current
        // Use fixed testDate (October 23, 2025 - Wednesday)
        let testDate = try #require(Self.testDate)

        // When
        let endOfMonth = service.getEndOfMonth(for: testDate)

        // Then
        // End of month + 1 day should be first day of next month
        let nextMonthStart = try #require(calendar.date(byAdding: .day, value: 1, to: endOfMonth))
        let components = calendar.dateComponents([.day], from: nextMonthStart)
        #expect(components.day == 1)
    }

    // MARK: - Tests: Day Calculations

    @Test("daysBetween calculates correct days between dates")
    func testDaysBetweenCalculatesCorrectly() throws {
        // Given
        let service = CurrentDayService()
        let date1 = try #require(Self.testDate)
        let date2 = try #require(Calendar.current.date(byAdding: .day, value: 7, to: date1))

        // When
        let days = service.daysBetween(date1, date2)

        // Then
        #expect(days == 7)
    }

    @Test("daysBetween handles negative differences")
    func testDaysBetweenHandlesNegativeDifference() throws {
        // Given
        let service = CurrentDayService()
        let date1 = try #require(Self.testDate)
        let date2 = try #require(Calendar.current.date(byAdding: .day, value: -5, to: date1))

        // When
        let days = service.daysBetween(date1, date2)

        // Then
        #expect(days == -5)
    }

    @Test("daysBetween returns zero for same day")
    func testDaysBetweenReturnZeroForSameDay() throws {
        // Given
        let service = CurrentDayService()
        let date = try #require(Self.testDate)

        // When
        let days = service.daysBetween(date, date)

        // Then
        #expect(days == 0)
    }

    @Test("daysBetween handles multiple weeks")
    func testDaysBetweenHandlesMultipleWeeks() throws {
        // Given
        let service = CurrentDayService()
        let date1 = try #require(Self.testDate)
        let date2 = try #require(Calendar.current.date(byAdding: .day, value: 30, to: date1))

        // When
        let days = service.daysBetween(date1, date2)

        // Then
        #expect(days == 30)
    }

    @Test("daysBetween ignores time component")
    func testDaysBetweenIgnoresTimeComponent() throws {
        // Given
        let service = CurrentDayService()
        let calendar = Calendar.current

        var components1 = calendar.dateComponents([.year, .month, .day], from: try #require(Self.testDate))
        components1.hour = 8
        components1.minute = 30
        let date1 = try #require(calendar.date(from: components1))

        var components2 = calendar.dateComponents([.year, .month, .day], from: try #require(Self.testDate))
        if let day = components2.day {
            components2.day = day + 5
        }
        components2.hour = 20
        components2.minute = 45
        let date2 = try #require(calendar.date(from: components2))

        // When
        let days = service.daysBetween(date1, date2)

        // Then
        #expect(days == 5)
    }

    // MARK: - Tests: Time Utilities

    @Test("getCurrentTime returns valid HourMinuteTime")
    func testGetCurrentTimeReturnsValidTime() {
        // Given
        let service = CurrentDayService()

        // When
        let time = service.getCurrentTime()

        // Then
        #expect(time.hour >= 0 && time.hour < 24)
        #expect(time.minute >= 0 && time.minute < 60)
    }

    @Test("getCurrentTime hour is within valid range")
    func testGetCurrentTimeHourIsValid() {
        // Given
        let service = CurrentDayService()

        // When
        let time = service.getCurrentTime()

        // Then
        #expect(time.hour >= 0)
        #expect(time.hour <= 23)
    }

    @Test("getCurrentTime minute is within valid range")
    func testGetCurrentTimeMinuteIsValid() {
        // Given
        let service = CurrentDayService()

        // When
        let time = service.getCurrentTime()

        // Then
        #expect(time.minute >= 0)
        #expect(time.minute <= 59)
    }

    // MARK: - Tests: Month Boundaries

    @Test("getEndOfMonth handles leap years correctly")
    func testGetEndOfMonthHandlesLeapYears() throws {
        // Given
        let service = CurrentDayService()
        let calendar = Calendar.current

        // February in leap year (2025 is not a leap year, use 2024)
        let leapYearFeb = try #require(calendar.date(from: DateComponents(year: 2024, month: 2, day: 15)))

        // When
        let endOfMonth = service.getEndOfMonth(for: leapYearFeb)

        // Then
        let components = calendar.dateComponents([.day], from: endOfMonth)
        #expect(components.day == 29)
    }

    @Test("getEndOfMonth handles 31-day months")
    func testGetEndOfMonthHandles31DayMonths() throws {
        // Given
        let service = CurrentDayService()
        let calendar = Calendar.current

        let january = try #require(calendar.date(from: DateComponents(year: 2025, month: 1, day: 15)))

        // When
        let endOfMonth = service.getEndOfMonth(for: january)

        // Then
        let components = calendar.dateComponents([.day], from: endOfMonth)
        #expect(components.day == 31)
    }

    @Test("getEndOfMonth handles 30-day months")
    func testGetEndOfMonthHandles30DayMonths() throws {
        // Given
        let service = CurrentDayService()
        let calendar = Calendar.current

        let april = try #require(calendar.date(from: DateComponents(year: 2025, month: 4, day: 15)))

        // When
        let endOfMonth = service.getEndOfMonth(for: april)

        // Then
        let components = calendar.dateComponents([.day], from: endOfMonth)
        #expect(components.day == 30)
    }

    @Test("getTomorrowDate returns date one day after today")
    func testGetTomorrowDateReturnsNextDay() {
        // Given
        let service = CurrentDayService()
        let today = service.getTodayDate()

        // When
        let tomorrow = service.getTomorrowDate()

        // Then
        let components = Calendar.current.dateComponents([.day], from: today, to: tomorrow)
        #expect(components.day == 1)
    }

    @Test("getYesterdayDate returns date one day before today")
    func testGetYesterdayDateReturnsPreviousDay() {
        // Given
        let service = CurrentDayService()
        let today = service.getTodayDate()

        // When
        let yesterday = service.getYesterdayDate()

        // Then
        let components = Calendar.current.dateComponents([.day], from: yesterday, to: today)
        #expect(components.day == 1)
    }
}
