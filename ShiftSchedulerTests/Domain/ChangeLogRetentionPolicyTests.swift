import Testing
import Foundation
@testable import ShiftScheduler

@MainActor
struct ChangeLogRetentionPolicyTests {

    // MARK: - Test Helpers

    /// Fixed reference date for deterministic testing
    /// Using a known date ensures tests are reproducible regardless of when they run
    static let referenceDate = Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 30))!

    @Test("All retention policies have correct display names")
    func testDisplayNames() async throws {
        #expect(ChangeLogRetentionPolicy.days30.displayName == "30 Days")
        #expect(ChangeLogRetentionPolicy.days90.displayName == "90 Days")
        #expect(ChangeLogRetentionPolicy.months6.displayName == "6 Months")
        #expect(ChangeLogRetentionPolicy.year1.displayName == "1 Year")
        #expect(ChangeLogRetentionPolicy.years2.displayName == "2 Years")
        #expect(ChangeLogRetentionPolicy.forever.displayName == "Forever")
    }

    @Test("Forever policy has no cutoff date")
    func testForeverPolicyNoCutoff() async throws {
        let policy = ChangeLogRetentionPolicy.forever
        #expect(policy.cutoffDate == nil)
    }

    @Test("30 days policy calculates correct cutoff date")
    func testDays30CutoffDate() async throws {
        let policy = ChangeLogRetentionPolicy.days30
        let cutoff = try #require(policy.cutoffDate)

        // Calculate expected cutoff from fixed reference date
        let expectedCutoff = Calendar.current.date(byAdding: .day, value: -30, to: Self.referenceDate)!
        let daysDifference = Calendar.current.dateComponents([.day], from: cutoff, to: expectedCutoff).day ?? 0

        // Cutoff should be approximately correct (allow small variance due to time passing during test)
        #expect(abs(daysDifference) <= 1)
    }

    @Test("90 days policy calculates correct cutoff date")
    func testDays90CutoffDate() async throws {
        let policy = ChangeLogRetentionPolicy.days90
        let cutoff = try #require(policy.cutoffDate)

        // Calculate expected cutoff from fixed reference date
        let expectedCutoff = Calendar.current.date(byAdding: .day, value: -90, to: Self.referenceDate)!
        let daysDifference = Calendar.current.dateComponents([.day], from: cutoff, to: expectedCutoff).day ?? 0

        #expect(abs(daysDifference) <= 1)
    }

    @Test("6 months policy calculates correct cutoff date")
    func testMonths6CutoffDate() async throws {
        let policy = ChangeLogRetentionPolicy.months6
        let cutoff = try #require(policy.cutoffDate)

        // Calculate expected cutoff from fixed reference date
        let expectedCutoff = Calendar.current.date(byAdding: .month, value: -6, to: Self.referenceDate)!
        let daysDifference = Calendar.current.dateComponents([.day], from: cutoff, to: expectedCutoff).day ?? 0

        #expect(abs(daysDifference) <= 1)
    }

    @Test("1 year policy calculates correct cutoff date")
    func testYear1CutoffDate() async throws {
        let policy = ChangeLogRetentionPolicy.year1
        let cutoff = try #require(policy.cutoffDate)

        // Calculate expected cutoff from fixed reference date
        let expectedCutoff = Calendar.current.date(byAdding: .year, value: -1, to: Self.referenceDate)!
        let daysDifference = Calendar.current.dateComponents([.day], from: cutoff, to: expectedCutoff).day ?? 0

        #expect(abs(daysDifference) <= 1)
    }

    @Test("2 years policy calculates correct cutoff date")
    func testYears2CutoffDate() async throws {
        let policy = ChangeLogRetentionPolicy.years2
        let cutoff = try #require(policy.cutoffDate)

        // Calculate expected cutoff from fixed reference date
        let expectedCutoff = Calendar.current.date(byAdding: .year, value: -2, to: Self.referenceDate)!
        let daysDifference = Calendar.current.dateComponents([.day], from: cutoff, to: expectedCutoff).day ?? 0

        #expect(abs(daysDifference) <= 1)
    }

    @Test("All policies are codable")
    func testCodable() async throws {
        for policy in ChangeLogRetentionPolicy.allCases {
            let encoder = JSONEncoder()
            let decoder = JSONDecoder()

            let encoded = try encoder.encode(policy)
            let decoded = try decoder.decode(ChangeLogRetentionPolicy.self, from: encoded)

            #expect(decoded == policy)
        }
    }

    @Test("Policy enum has all expected cases")
    func testAllCases() async throws {
        let allCases = ChangeLogRetentionPolicy.allCases

        #expect(allCases.count == 6)
        #expect(allCases.contains(.days30))
        #expect(allCases.contains(.days90))
        #expect(allCases.contains(.months6))
        #expect(allCases.contains(.year1))
        #expect(allCases.contains(.years2))
        #expect(allCases.contains(.forever))
    }

    @Test("Cutoff dates are in the past")
    func testCutoffDatesInPast() async throws {
        let referenceDate = Self.referenceDate

        for policy in ChangeLogRetentionPolicy.allCases where policy != .forever {
            let cutoff = try #require(policy.cutoffDate)
            // Cutoff should be before the reference date (allow 1 day variance)
            let daysDifference = Calendar.current.dateComponents([.day], from: cutoff, to: referenceDate).day ?? 0
            #expect(daysDifference > 0, "Cutoff date for \(policy.displayName) should be in the past relative to reference date")
        }
    }

    @Test("Longer retention policies have earlier cutoff dates")
    func testRetentionPolicyOrdering() async throws {
        let days30Cutoff = try #require(ChangeLogRetentionPolicy.days30.cutoffDate)
        let days90Cutoff = try #require(ChangeLogRetentionPolicy.days90.cutoffDate)
        let months6Cutoff = try #require(ChangeLogRetentionPolicy.months6.cutoffDate)
        let year1Cutoff = try #require(ChangeLogRetentionPolicy.year1.cutoffDate)
        let years2Cutoff = try #require(ChangeLogRetentionPolicy.years2.cutoffDate)

        // Earlier cutoff dates mean longer retention
        #expect(days30Cutoff > days90Cutoff)
        #expect(days90Cutoff > months6Cutoff)
        #expect(months6Cutoff > year1Cutoff)
        #expect(year1Cutoff > years2Cutoff)
    }
}
