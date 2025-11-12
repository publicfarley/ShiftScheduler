import Testing
import Foundation
import SwiftUI
@testable import ShiftScheduler

/// Tests for Change Log View
/// Verifies UI logic, relative time formatting, and view state
@Suite("Change Log View Tests")
@MainActor
struct ChangeLogViewTests {

    // MARK: - Relative Time String Tests

    @Test("Relative time string formats 'Just now' for recent times")
    func testRelativeTimeString_justNow() throws {
        let currentDate = try #require(Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 30, hour: 12, minute: 0)))
        let thirtySecondsAgo = currentDate.addingTimeInterval(-30)

        let entry = ChangeLogEntryBuilder(timestamp: thirtySecondsAgo).build()
        let card = EnhancedChangeLogCard(entry: entry, currentDate: currentDate)

        // Verify the relative time calculation
        let relativeTime = card.relativeTimeString(from: thirtySecondsAgo)
        #expect(relativeTime == "Just now")
    }

    @Test("Relative time string formats minutes ago correctly")
    func testRelativeTimeString_minutesAgo() throws {
        let currentDate = try #require(Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 30, hour: 12, minute: 0)))
        let fiveMinutesAgo = currentDate.addingTimeInterval(-300) // 5 minutes

        let entry = ChangeLogEntryBuilder(timestamp: fiveMinutesAgo).build()
        let card = EnhancedChangeLogCard(entry: entry, currentDate: currentDate)

        let relativeTime = card.relativeTimeString(from: fiveMinutesAgo)
        #expect(relativeTime == "5m ago")
    }

    @Test("Relative time string formats hours ago correctly")
    func testRelativeTimeString_hoursAgo() throws {
        let currentDate = try #require(Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 30, hour: 12, minute: 0)))
        let twoHoursAgo = currentDate.addingTimeInterval(-7200) // 2 hours

        let entry = ChangeLogEntryBuilder(timestamp: twoHoursAgo).build()
        let card = EnhancedChangeLogCard(entry: entry, currentDate: currentDate)

        let relativeTime = card.relativeTimeString(from: twoHoursAgo)
        #expect(relativeTime == "2h ago")
    }

    @Test("Relative time string formats days ago correctly")
    func testRelativeTimeString_daysAgo() throws {
        let currentDate = try #require(Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 30, hour: 12, minute: 0)))
        let threeDaysAgo = currentDate.addingTimeInterval(-259200) // 3 days

        let entry = ChangeLogEntryBuilder(timestamp: threeDaysAgo).build()
        let card = EnhancedChangeLogCard(entry: entry, currentDate: currentDate)

        let relativeTime = card.relativeTimeString(from: threeDaysAgo)
        #expect(relativeTime == "3d ago")
    }

    @Test("Relative time string formats weeks ago correctly")
    func testRelativeTimeString_weeksAgo() throws {
        let currentDate = try #require(Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 30, hour: 12, minute: 0)))
        let twoWeeksAgo = currentDate.addingTimeInterval(-1209600) // 2 weeks

        let entry = ChangeLogEntryBuilder(timestamp: twoWeeksAgo).build()
        let card = EnhancedChangeLogCard(entry: entry, currentDate: currentDate)

        let relativeTime = card.relativeTimeString(from: twoWeeksAgo)
        #expect(relativeTime == "2w ago")
    }

    // MARK: - Change Type Color Tests

    @Test("Change type color returns correct color for switched")
    func testChangeTypeColor_switched() {
        let entry = ChangeLogEntryBuilder(changeType: .switched).build()
        let card = EnhancedChangeLogCard(entry: entry, currentDate: try Date.fixedTestDate_Nov11_2025())

        #expect(card.changeTypeColor == .blue)
    }

    @Test("Change type color returns correct color for deleted")
    func testChangeTypeColor_deleted() {
        let entry = ChangeLogEntryBuilder(changeType: .deleted).build()
        let card = EnhancedChangeLogCard(entry: entry, currentDate: try Date.fixedTestDate_Nov11_2025())

        #expect(card.changeTypeColor == .red)
    }

    @Test("Change type color returns correct color for created")
    func testChangeTypeColor_created() {
        let entry = ChangeLogEntryBuilder(changeType: .created).build()
        let card = EnhancedChangeLogCard(entry: entry, currentDate: try Date.fixedTestDate_Nov11_2025())

        #expect(card.changeTypeColor == .green)
    }

    @Test("Change type color returns correct color for undo")
    func testChangeTypeColor_undo() {
        let entry = ChangeLogEntryBuilder(changeType: .undo).build()
        let card = EnhancedChangeLogCard(entry: entry, currentDate: try Date.fixedTestDate_Nov11_2025())

        #expect(card.changeTypeColor == .orange)
    }

    @Test("Change type color returns correct color for redo")
    func testChangeTypeColor_redo() {
        let entry = ChangeLogEntryBuilder(changeType: .redo).build()
        let card = EnhancedChangeLogCard(entry: entry, currentDate: try Date.fixedTestDate_Nov11_2025())

        #expect(card.changeTypeColor == .purple)
    }

    // MARK: - Change Type Icon Tests

    @Test("Change type icon returns correct icon for switched")
    func testChangeTypeIcon_switched() {
        let entry = ChangeLogEntryBuilder(changeType: .switched).build()
        let card = EnhancedChangeLogCard(entry: entry, currentDate: try Date.fixedTestDate_Nov11_2025())

        #expect(card.changeTypeIcon == "arrow.triangle.2.circlepath")
    }

    @Test("Change type icon returns correct icon for deleted")
    func testChangeTypeIcon_deleted() {
        let entry = ChangeLogEntryBuilder(changeType: .deleted).build()
        let card = EnhancedChangeLogCard(entry: entry, currentDate: try Date.fixedTestDate_Nov11_2025())

        #expect(card.changeTypeIcon == "trash.fill")
    }

    @Test("Change type icon returns correct icon for created")
    func testChangeTypeIcon_created() {
        let entry = ChangeLogEntryBuilder(changeType: .created).build()
        let card = EnhancedChangeLogCard(entry: entry, currentDate: try Date.fixedTestDate_Nov11_2025())

        #expect(card.changeTypeIcon == "plus.circle.fill")
    }

    @Test("Change type icon returns correct icon for undo")
    func testChangeTypeIcon_undo() {
        let entry = ChangeLogEntryBuilder(changeType: .undo).build()
        let card = EnhancedChangeLogCard(entry: entry, currentDate: try Date.fixedTestDate_Nov11_2025())

        #expect(card.changeTypeIcon == "arrow.uturn.backward.circle.fill")
    }

    @Test("Change type icon returns correct icon for redo")
    func testChangeTypeIcon_redo() {
        let entry = ChangeLogEntryBuilder(changeType: .redo).build()
        let card = EnhancedChangeLogCard(entry: entry, currentDate: try Date.fixedTestDate_Nov11_2025())

        #expect(card.changeTypeIcon == "arrow.uturn.forward.circle.fill")
    }

    // MARK: - Deterministic Date Tests

    @Test("EnhancedChangeLogCard uses passed current date not try Date.fixedTestDate_Nov11_2025()")
    func testDeterministicCurrenttry Date.fixedTestDate_Nov11_2025() throws {
        // Fixed dates for deterministic testing
        let fixedCurrentDate = try #require(Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 30, hour: 15, minute: 0)))
        let fixedTimestamp = try #require(Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 30, hour: 13, minute: 0)))

        let entry = ChangeLogEntryBuilder(timestamp: fixedTimestamp).build()
        let card = EnhancedChangeLogCard(entry: entry, currentDate: fixedCurrentDate)

        // Should be 2 hours ago
        let relativeTime = card.relativeTimeString(from: fixedTimestamp)
        #expect(relativeTime == "2h ago")

        // Verify it's deterministic by creating another card with same dates
        let card2 = EnhancedChangeLogCard(entry: entry, currentDate: fixedCurrentDate)
        let relativeTime2 = card2.relativeTimeString(from: fixedTimestamp)
        #expect(relativeTime2 == relativeTime)
    }

    // MARK: - Edge Case Tests

    @Test("Relative time handles exact boundaries correctly")
    func testRelativeTimeBoundaries() throws {
        let currentDate = try #require(Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 30, hour: 12, minute: 0)))

        // Exactly 60 seconds (should be 1m ago, not "Just now")
        let sixtySecondsAgo = currentDate.addingTimeInterval(-60)
        let entry1 = ChangeLogEntryBuilder(timestamp: sixtySecondsAgo).build()
        let card1 = EnhancedChangeLogCard(entry: entry1, currentDate: currentDate)
        #expect(card1.relativeTimeString(from: sixtySecondsAgo) == "1m ago")

        // Exactly 3600 seconds (should be 1h ago, not minutes)
        let oneHourAgo = currentDate.addingTimeInterval(-3600)
        let entry2 = ChangeLogEntryBuilder(timestamp: oneHourAgo).build()
        let card2 = EnhancedChangeLogCard(entry: entry2, currentDate: currentDate)
        #expect(card2.relativeTimeString(from: oneHourAgo) == "1h ago")

        // Exactly 86400 seconds (should be 1d ago, not hours)
        let oneDayAgo = currentDate.addingTimeInterval(-86400)
        let entry3 = ChangeLogEntryBuilder(timestamp: oneDayAgo).build()
        let card3 = EnhancedChangeLogCard(entry: entry3, currentDate: currentDate)
        #expect(card3.relativeTimeString(from: oneDayAgo) == "1d ago")

        // Exactly 604800 seconds (should be 1w ago, not days)
        let oneWeekAgo = currentDate.addingTimeInterval(-604800)
        let entry4 = ChangeLogEntryBuilder(timestamp: oneWeekAgo).build()
        let card4 = EnhancedChangeLogCard(entry: entry4, currentDate: currentDate)
        #expect(card4.relativeTimeString(from: oneWeekAgo) == "1w ago")
    }
}
