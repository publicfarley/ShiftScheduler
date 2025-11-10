import Foundation
import Testing

@testable import ShiftScheduler

@MainActor
@Suite("PersistenceService Batch Operations")
struct PersistenceServiceBatchOperationsTests {
    // MARK: - AddMultipleChangeLogEntries Tests

    @Test("addMultipleChangeLogEntries adds all entries")
    func addMultipleChangeLogEntriesAddsAllEntries() async throws {
        let mockService = MockPersistenceService()

        let entry1 = ChangeLogEntryBuilder(userDisplayName: "John").build()
        let entry2 = ChangeLogEntryBuilder(userDisplayName: "Jane").build()
        let entry3 = ChangeLogEntryBuilder(userDisplayName: "Bob").build()

        try await mockService.addMultipleChangeLogEntries([entry1, entry2, entry3])

        #expect(mockService.mockChangeLogEntries.count == 3)
        #expect(mockService.mockChangeLogEntries[0].userDisplayName == "John")
        #expect(mockService.mockChangeLogEntries[1].userDisplayName == "Jane")
        #expect(mockService.mockChangeLogEntries[2].userDisplayName == "Bob")
    }

    @Test("addMultipleChangeLogEntries preserves existing entries")
    func addMultipleChangeLogEntriesPreservesExisting() async throws {
        let mockService = MockPersistenceService()

        let existingEntry = ChangeLogEntryBuilder(userDisplayName: "Existing").build()
        mockService.mockChangeLogEntries = [existingEntry]

        let newEntry1 = ChangeLogEntryBuilder(userDisplayName: "New1").build()
        let newEntry2 = ChangeLogEntryBuilder(userDisplayName: "New2").build()

        try await mockService.addMultipleChangeLogEntries([newEntry1, newEntry2])

        #expect(mockService.mockChangeLogEntries.count == 3)
        #expect(mockService.mockChangeLogEntries[0].userDisplayName == "Existing")
        #expect(mockService.mockChangeLogEntries[1].userDisplayName == "New1")
        #expect(mockService.mockChangeLogEntries[2].userDisplayName == "New2")
    }

    @Test("addMultipleChangeLogEntries handles empty array")
    func addMultipleChangeLogEntriesHandlesEmptyArray() async throws {
        let mockService = MockPersistenceService()

        let existingEntry = ChangeLogEntryBuilder(userDisplayName: "Existing").build()
        mockService.mockChangeLogEntries = [existingEntry]

        try await mockService.addMultipleChangeLogEntries([])

        #expect(mockService.mockChangeLogEntries.count == 1)
        #expect(mockService.mockChangeLogEntries[0].userDisplayName == "Existing")
    }

    @Test("addMultipleChangeLogEntries increments call count")
    func addMultipleChangeLogEntriesIncrementsCallCount() async throws {
        let mockService = MockPersistenceService()

        #expect(mockService.addMultipleChangeLogEntriesCallCount == 0)

        try await mockService.addMultipleChangeLogEntries([])

        #expect(mockService.addMultipleChangeLogEntriesCallCount == 1)

        let entry = ChangeLogEntryBuilder(userDisplayName: "Test").build()
        try await mockService.addMultipleChangeLogEntries([entry])

        #expect(mockService.addMultipleChangeLogEntriesCallCount == 2)
    }

    @Test("addMultipleChangeLogEntries respects shouldThrowError flag")
    func addMultipleChangeLogEntriesRespectsErrorFlag() async throws {
        let mockService = MockPersistenceService()
        mockService.shouldThrowError = true
        mockService.throwError = PersistenceError.saveFailed("Test error")

        let entry = ChangeLogEntryBuilder(userDisplayName: "Test").build()

        do {
            try await mockService.addMultipleChangeLogEntries([entry])
            Issue.record("Should have thrown a PersistenceError")
        } catch {
            #expect(error is PersistenceError)
        }
    }

    @Test("addMultipleChangeLogEntries with large batch")
    func addMultipleChangeLogEntriesWithLargeBatch() async throws {
        let mockService = MockPersistenceService()

        // Create 50 entries
        let entries = (0..<50).map { i in
            ChangeLogEntryBuilder(userDisplayName: "User\(i)").build()
        }

        try await mockService.addMultipleChangeLogEntries(entries)

        #expect(mockService.mockChangeLogEntries.count == 50)
        #expect(mockService.mockChangeLogEntries.last?.userDisplayName == "User49")
    }

    @Test("addMultipleChangeLogEntries maintains insertion order")
    func addMultipleChangeLogEntriesMaintainsOrder() async throws {
        let mockService = MockPersistenceService()

        let entry1 = ChangeLogEntryBuilder(
            timestamp: Date(timeIntervalSince1970: 1000),
            userDisplayName: "First"
        ).build()
        let entry2 = ChangeLogEntryBuilder(
            timestamp: Date(timeIntervalSince1970: 2000),
            userDisplayName: "Second"
        ).build()
        let entry3 = ChangeLogEntryBuilder(
            timestamp: Date(timeIntervalSince1970: 3000),
            userDisplayName: "Third"
        ).build()

        try await mockService.addMultipleChangeLogEntries([entry1, entry2, entry3])

        #expect(mockService.mockChangeLogEntries[0].timestamp < mockService.mockChangeLogEntries[1].timestamp)
        #expect(mockService.mockChangeLogEntries[1].timestamp < mockService.mockChangeLogEntries[2].timestamp)
    }

    @Test("addMultipleChangeLogEntries works with different entry types")
    func addMultipleChangeLogEntriesWorkWithDifferentTypes() async throws {
        let mockService = MockPersistenceService()

        let entry1 = ChangeLogEntryBuilder(userDisplayName: "John").build()
        let entry2 = ChangeLogEntryBuilder(userDisplayName: "Jane").build()

        try await mockService.addMultipleChangeLogEntries([entry1, entry2])

        #expect(mockService.mockChangeLogEntries.count == 2)
        #expect(mockService.mockChangeLogEntries.allSatisfy { $0.changeType == .created })
    }
}
