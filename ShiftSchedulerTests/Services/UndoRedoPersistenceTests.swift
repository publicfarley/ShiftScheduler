import Testing
import Foundation
@testable import ShiftScheduler

/// Tests for UndoRedoPersistence
/// DISABLED: This test references UndoRedoPersistence class which no longer exists in the codebase
/// The undo/redo functionality is now handled by Redux middleware instead
@Suite("UndoRedoPersistence Tests - DISABLED")
struct UndoRedoPersistenceTests {
    @Test("Placeholder - undo/redo tests disabled")
    func testDisabled() {
        // Undo/redo functionality tests are now part of middleware integration tests
        // See ShiftSchedulerTests/Redux/MiddlewareIntegrationTests.swift
    }
}
