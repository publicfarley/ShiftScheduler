import Testing
import Foundation
@testable import ShiftScheduler

/// Tests for UndoRedoPersistence
/// These tests verify that the persistence layer handles the disabled state correctly
@Suite("UndoRedoPersistence Tests")
struct UndoRedoPersistenceTests {
    let suiteName = "com.functioncraft.shiftscheduler.tests.undoredo"

    @Test("Persistence is disabled - loadUndoStack returns empty")
    func testLoadUndoStackReturnsEmpty() async throws {
        // Given
        let userDefaults = UserDefaults(suiteName: suiteName)!
        defer { userDefaults.removePersistentDomain(forName: suiteName) }

        let persistence = UndoRedoPersistence(userDefaults: userDefaults)

        // When
        let loadedOperations = await persistence.loadUndoStack()

        // Then - persistence is disabled, so nothing is loaded
        #expect(loadedOperations.isEmpty)
    }

    @Test("Persistence is disabled - loadRedoStack returns empty")
    func testLoadRedoStackReturnsEmpty() async throws {
        // Given
        let userDefaults = UserDefaults(suiteName: suiteName)!
        defer { userDefaults.removePersistentDomain(forName: suiteName) }

        let persistence = UndoRedoPersistence(userDefaults: userDefaults)

        // When
        let loadedOperations = await persistence.loadRedoStack()

        // Then - persistence is disabled, so nothing is loaded
        #expect(loadedOperations.isEmpty)
    }

    @Test("Persistence is disabled - loadBothStacks returns empty")
    func testLoadBothStacksReturnsEmpty() async throws {
        // Given
        let userDefaults = UserDefaults(suiteName: suiteName)!
        defer { userDefaults.removePersistentDomain(forName: suiteName) }

        let persistence = UndoRedoPersistence(userDefaults: userDefaults)

        // When
        let (undoOps, redoOps) = await persistence.loadBothStacks()

        // Then - persistence is disabled, so nothing is loaded
        #expect(undoOps.isEmpty)
        #expect(redoOps.isEmpty)
    }

    @Test("Persistence is disabled - saveUndoStack does not throw")
    func testSaveUndoStackDoesNotThrow() async throws {
        // Given
        let userDefaults = UserDefaults(suiteName: suiteName)!
        defer { userDefaults.removePersistentDomain(forName: suiteName) }

        let persistence = UndoRedoPersistence(userDefaults: userDefaults)

        // When/Then - should not throw even though persistence is disabled
        await persistence.saveUndoStack([])
    }

    @Test("Persistence is disabled - clearBothStacks does not throw")
    func testClearBothStacksDoesNotThrow() async throws {
        // Given
        let userDefaults = UserDefaults(suiteName: suiteName)!
        defer { userDefaults.removePersistentDomain(forName: suiteName) }

        let persistence = UndoRedoPersistence(userDefaults: userDefaults)

        // When/Then - should not throw even though persistence is disabled
        await persistence.clearBothStacks()
    }
}
