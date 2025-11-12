import Testing
import Foundation
@testable import ShiftScheduler

@MainActor
struct ChangeLogRetentionPolicyTests {

    // MARK: - Test Helpers

    /// Fixed reference date for deterministic testing
    /// Using a known date ensures tests are reproducible regardless of when they run
    private static func referencetry Date.fixedTestDate_Nov11_2025() throws -> Date {
        try #require(Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 30)))
    }
    
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
        #expect(policy.cutoffDate(from: try Self.referencetry Date.fixedTestDate_Nov11_2025()) == nil)
    }

    @Test("30 days policy calculates correct cutoff date")
    func testDays30Cutofftry Date.fixedTestDate_Nov11_2025() async throws {
        let policy = ChangeLogRetentionPolicy.days30
        let cutoff = try #require(policy.cutoffDate(from: Self.referencetry Date.fixedTestDate_Nov11_2025()))

        // Calculate expected cutoff from fixed reference date
        let expectedCutoff = try #require(Calendar.current.date(byAdding: .day, value: -30, to: Self.referencetry Date.fixedTestDate_Nov11_2025()))

        // Should match exactly since we're using the same reference date
        #expect(Calendar.current.dateComponents([.day, .month, .year], from: cutoff) == Calendar.current.dateComponents([.day, .month, .year], from: expectedCutoff))
    }

    @Test("90 days policy calculates correct cutoff date")
    func testDays90Cutofftry Date.fixedTestDate_Nov11_2025() async throws {
        let policy = ChangeLogRetentionPolicy.days90
        let cutoff = try #require(policy.cutoffDate(from: Self.referencetry Date.fixedTestDate_Nov11_2025()))

        // Calculate expected cutoff from fixed reference date
        let expectedCutoff = try #require(Calendar.current.date(byAdding: .day, value: -90, to: Self.referencetry Date.fixedTestDate_Nov11_2025()))

        #expect(Calendar.current.dateComponents([.day, .month, .year], from: cutoff) == Calendar.current.dateComponents([.day, .month, .year], from: expectedCutoff))
    }

    @Test("6 months policy calculates correct cutoff date")
    func testMonths6Cutofftry Date.fixedTestDate_Nov11_2025() async throws {
        let policy = ChangeLogRetentionPolicy.months6
        let cutoff = try #require(policy.cutoffDate(from: Self.referencetry Date.fixedTestDate_Nov11_2025()))

        // Calculate expected cutoff from fixed reference date
        let expectedCutoff = try #require(Calendar.current.date(byAdding: .month, value: -6, to: Self.referencetry Date.fixedTestDate_Nov11_2025()))

        #expect(Calendar.current.dateComponents([.day, .month, .year], from: cutoff) == Calendar.current.dateComponents([.day, .month, .year], from: expectedCutoff))
    }

    @Test("1 year policy calculates correct cutoff date")
    func testYear1Cutofftry Date.fixedTestDate_Nov11_2025() async throws {
        let policy = ChangeLogRetentionPolicy.year1
        let cutoff = try #require(policy.cutoffDate(from: Self.referencetry Date.fixedTestDate_Nov11_2025()))

        // Calculate expected cutoff from fixed reference date
        let expectedCutoff = try #require(Calendar.current.date(byAdding: .year, value: -1, to: Self.referencetry Date.fixedTestDate_Nov11_2025()))

        #expect(Calendar.current.dateComponents([.day, .month, .year], from: cutoff) == Calendar.current.dateComponents([.day, .month, .year], from: expectedCutoff))
    }

    @Test("2 years policy calculates correct cutoff date")
    func testYears2Cutofftry Date.fixedTestDate_Nov11_2025() async throws {
        let policy = ChangeLogRetentionPolicy.years2
        let cutoff = try #require(policy.cutoffDate(from: Self.referencetry Date.fixedTestDate_Nov11_2025()))

        // Calculate expected cutoff from fixed reference date
        let expectedCutoff = try #require(Calendar.current.date(byAdding: .year, value: -2, to: Self.referencetry Date.fixedTestDate_Nov11_2025()))

        #expect(Calendar.current.dateComponents([.day, .month, .year], from: cutoff) == Calendar.current.dateComponents([.day, .month, .year], from: expectedCutoff))
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
        let referenceDate = try Self.referencetry Date.fixedTestDate_Nov11_2025()

        for policy in ChangeLogRetentionPolicy.allCases where policy != .forever {
            let cutoff = try #require(policy.cutoffDate(from: referenceDate))
            // Cutoff should be before the reference date
            let daysDifference = Calendar.current.dateComponents([.day], from: cutoff, to: referenceDate).day ?? 0
            #expect(daysDifference > 0, "Cutoff date for \(policy.displayName) should be in the past relative to reference date")
        }
    }

    @Test("Longer retention policies have earlier cutoff dates")
    func testRetentionPolicyOrdering() async throws {
        let days30Cutoff = try #require(ChangeLogRetentionPolicy.days30.cutoffDate(from: Self.referencetry Date.fixedTestDate_Nov11_2025()))
        let days90Cutoff = try #require(ChangeLogRetentionPolicy.days90.cutoffDate(from: Self.referencetry Date.fixedTestDate_Nov11_2025()))
        let months6Cutoff = try #require(ChangeLogRetentionPolicy.months6.cutoffDate(from: Self.referencetry Date.fixedTestDate_Nov11_2025()))
        let year1Cutoff = try #require(ChangeLogRetentionPolicy.year1.cutoffDate(from: Self.referencetry Date.fixedTestDate_Nov11_2025()))
        let years2Cutoff = try #require(ChangeLogRetentionPolicy.years2.cutoffDate(from: Self.referencetry Date.fixedTestDate_Nov11_2025()))

        // Earlier cutoff dates mean longer retention
        #expect(days30Cutoff > days90Cutoff)
        #expect(days90Cutoff > months6Cutoff)
        #expect(months6Cutoff > year1Cutoff)
        #expect(year1Cutoff > years2Cutoff)
    }
}
