import Testing
import Foundation
@testable import ShiftScheduler

/// Tests for ChangeLogPurgeService
/// DISABLED: This test references ChangeLogPurgeService and ChangeLogRetentionPolicyManager classes which no longer exist in the codebase
/// The change log purging functionality is now handled by Redux middleware instead
@Suite("ChangeLogPurgeService Tests - DISABLED")
struct ChangeLogPurgeServiceTests {
    @Test("Placeholder - change log purge tests disabled")
    func testDisabled() {
        // Change log purging tests are now part of middleware integration tests
        // See ShiftSchedulerTests/Redux/MiddlewareIntegrationTests.swift
    }
}
