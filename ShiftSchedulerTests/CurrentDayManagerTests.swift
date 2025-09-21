import Testing
import Foundation
@testable import ShiftScheduler

struct CurrentDayManagerTests {

    @Test("CurrentDayManager provides correct today date")
    func testTodayDate() async throws {
        let manager = CurrentDayManager.shared
        let expectedToday = Calendar.current.startOfDay(for: Date())

        #expect(Calendar.current.isDate(manager.today, inSameDayAs: expectedToday))
    }

    @Test("CurrentDayManager provides correct tomorrow date")
    func testTomorrowDate() async throws {
        let manager = CurrentDayManager.shared
        let expectedTomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))!

        #expect(Calendar.current.isDate(manager.tomorrow, inSameDayAs: expectedTomorrow))
    }

    @Test("CurrentDayManager provides correct yesterday date")
    func testYesterdayDate() async throws {
        let manager = CurrentDayManager.shared
        let expectedYesterday = Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: Date()))!

        #expect(Calendar.current.isDate(manager.yesterday, inSameDayAs: expectedYesterday))
    }

    @Test("isToday correctly identifies today's date")
    func testIsToday() async throws {
        let manager = CurrentDayManager.shared
        let now = Date()
        let todayEarlier = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: now)!
        let todayLater = Calendar.current.date(bySettingHour: 15, minute: 30, second: 0, of: now)!

        #expect(manager.isToday(now))
        #expect(manager.isToday(todayEarlier))
        #expect(manager.isToday(todayLater))
    }

    @Test("isTomorrow correctly identifies tomorrow's date")
    func testIsTomorrow() async throws {
        let manager = CurrentDayManager.shared
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let tomorrowMorning = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: tomorrow)!
        let tomorrowEvening = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: tomorrow)!

        #expect(manager.isTomorrow(tomorrow))
        #expect(manager.isTomorrow(tomorrowMorning))
        #expect(manager.isTomorrow(tomorrowEvening))
    }

    @Test("isYesterday correctly identifies yesterday's date")
    func testIsYesterday() async throws {
        let manager = CurrentDayManager.shared
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let yesterdayMorning = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: yesterday)!
        let yesterdayEvening = Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: yesterday)!

        #expect(manager.isYesterday(yesterday))
        #expect(manager.isYesterday(yesterdayMorning))
        #expect(manager.isYesterday(yesterdayEvening))
    }

    @Test("daysBetween calculates correct difference")
    func testDaysBetween() async throws {
        let manager = CurrentDayManager.shared
        let today = Date()
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: today)!
        let fiveDaysFromNow = Calendar.current.date(byAdding: .day, value: 5, to: today)!

        #expect(manager.daysBetween(from: threeDaysAgo, to: today) == 3)
        #expect(manager.daysBetween(from: today, to: fiveDaysFromNow) == 5)
        #expect(manager.daysBetween(from: fiveDaysFromNow, to: threeDaysAgo) == -8)
    }

    #if DEBUG
    @Test("setTestDate updates current date in debug mode")
    func testSetTestDate() async throws {
        let manager = CurrentDayManager.shared
        let testDate = Calendar.current.date(from: DateComponents(year: 2024, month: 6, day: 15))!

        manager.setTestDate(testDate)

        #expect(Calendar.current.isDate(manager.today, inSameDayAs: testDate))

        let expectedTomorrow = Calendar.current.date(byAdding: .day, value: 1, to: testDate)!
        #expect(Calendar.current.isDate(manager.tomorrow, inSameDayAs: expectedTomorrow))

        let expectedYesterday = Calendar.current.date(byAdding: .day, value: -1, to: testDate)!
        #expect(Calendar.current.isDate(manager.yesterday, inSameDayAs: expectedYesterday))
    }

    @Test("day change notification is posted when date changes")
    func testDayChangeNotification() async throws {
        let manager = CurrentDayManager.shared
        let originalDate = manager.today

        var notificationReceived = false
        var receivedPreviousDate: Date?
        var receivedCurrentDate: Date?

        let expectation = expectation(description: "Day change notification")

        let observer = NotificationCenter.default.addObserver(
            forName: .currentDayChanged,
            object: nil,
            queue: .main
        ) { notification in
            notificationReceived = true
            receivedPreviousDate = notification.userInfo?["previousDate"] as? Date
            receivedCurrentDate = notification.userInfo?["currentDate"] as? Date
            expectation.fulfill()
        }

        defer {
            NotificationCenter.default.removeObserver(observer)
        }

        // Set a different test date to trigger the notification
        let newTestDate = Calendar.current.date(byAdding: .day, value: 1, to: originalDate)!
        manager.setTestDate(newTestDate)

        await fulfillment(of: [expectation], timeout: 1.0)

        #expect(notificationReceived)
        #expect(receivedPreviousDate != nil)
        #expect(receivedCurrentDate != nil)
        #expect(Calendar.current.isDate(receivedCurrentDate!, inSameDayAs: newTestDate))
    }
    #endif
}

// MARK: - Helper Extensions for Testing
private extension XCTestExpectation {
    static func expectation(description: String) -> XCTestExpectation {
        return XCTestExpectation(description: description)
    }
}

private func expectation(description: String) -> XCTestExpectation {
    return XCTestExpectation(description: description)
}

private func fulfillment(of expectations: [XCTestExpectation], timeout: TimeInterval) async {
    await withCheckedContinuation { continuation in
        let waiter = XCTWaiter()
        waiter.wait(for: expectations, timeout: timeout)
        continuation.resume()
    }
}

// Import XCTest for expectation support
import XCTest