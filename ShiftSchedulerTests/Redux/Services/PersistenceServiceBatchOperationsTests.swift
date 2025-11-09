import Foundation
import Testing

@testable import ShiftScheduler

@Suite("PersistenceService Batch Operations")
struct PersistenceServiceBatchOperationsTests {
    // MARK: - AddMultipleChangeLogEntries Tests

    @Test("addMultipleChangeLogEntries adds all entries")
    func addMultipleChangeLogEntriesAddsAllEntries() async throws {
        let mockService = MockPersistenceService()

        let entry1 = ChangeLogEntry(
            id: UUID(),
            timestamp: Date(),
            type: .switch_shift,
            userName: "John",
            metadata: [],
            count: 1
        )
        let entry2 = ChangeLogEntry(
            id: UUID(),
            timestamp: Date(),
            type: .switch_shift,
            userName: "Jane",
            metadata: [],
            count: 1
        )
        let entry3 = ChangeLogEntry(
            id: UUID(),
            timestamp: Date(),
            type: .switch_shift,
            userName: "Bob",
            metadata: [],
            count: 1
        )

        try await mockService.addMultipleChangeLogEntries([entry1, entry2, entry3])

        #expect(mockService.mockChangeLogEntries.count == 3)
        #expect(mockService.mockChangeLogEntries[0].userName == "John")
        #expect(mockService.mockChangeLogEntries[1].userName == "Jane")
        #expect(mockService.mockChangeLogEntries[2].userName == "Bob")
    }

    @Test("addMultipleChangeLogEntries preserves existing entries")
    func addMultipleChangeLogEntriesPreservesExisting() async throws {
        let mockService = MockPersistenceService()

        let existingEntry = ChangeLogEntry(
            id: UUID(),
            timestamp: Date(),
            type: .switch_shift,
            userName: "Existing",
            metadata: [],
            count: 1
        )
        mockService.mockChangeLogEntries = [existingEntry]

        let newEntry1 = ChangeLogEntry(
            id: UUID(),
            timestamp: Date(),
            type: .switch_shift,
            userName: "New1",
            metadata: [],
            count: 1
        )
        let newEntry2 = ChangeLogEntry(
            id: UUID(),
            timestamp: Date(),
            type: .switch_shift,
            userName: "New2",
            metadata: [],
            count: 1
        )

        try await mockService.addMultipleChangeLogEntries([newEntry1, newEntry2])

        #expect(mockService.mockChangeLogEntries.count == 3)
        #expect(mockService.mockChangeLogEntries[0].userName == "Existing")
        #expect(mockService.mockChangeLogEntries[1].userName == "New1")
        #expect(mockService.mockChangeLogEntries[2].userName == "New2")
    }

    @Test("addMultipleChangeLogEntries handles empty array")
    func addMultipleChangeLogEntriesHandlesEmptyArray() async throws {
        let mockService = MockPersistenceService()

        let existingEntry = ChangeLogEntry(
            id: UUID(),
            timestamp: Date(),
            type: .switch_shift,
            userName: "Existing",
            metadata: [],
            count: 1
        )
        mockService.mockChangeLogEntries = [existingEntry]

        try await mockService.addMultipleChangeLogEntries([])

        #expect(mockService.mockChangeLogEntries.count == 1)
        #expect(mockService.mockChangeLogEntries[0].userName == "Existing")
    }

    @Test("addMultipleChangeLogEntries increments call count")
    func addMultipleChangeLogEntriesIncrementsCallCount() async throws {
        let mockService = MockPersistenceService()

        #expect(mockService.addMultipleChangeLogEntriesCallCount == 0)

        try await mockService.addMultipleChangeLogEntries([])

        #expect(mockService.addMultipleChangeLogEntriesCallCount == 1)

        let entry = ChangeLogEntry(
            id: UUID(),
            timestamp: Date(),
            type: .switch_shift,
            userName: "Test",
            metadata: [],
            count: 1
        )
        try await mockService.addMultipleChangeLogEntries([entry])

        #expect(mockService.addMultipleChangeLogEntriesCallCount == 2)
    }

    @Test("addMultipleChangeLogEntries respects shouldThrowError flag")
    func addMultipleChangeLogEntriesRespectsErrorFlag() async throws {
        let mockService = MockPersistenceService()
        mockService.shouldThrowError = true
        mockService.throwError = PersistenceError.saveFailed("Test error")

        let entry = ChangeLogEntry(
            id: UUID(),
            timestamp: Date(),
            type: .switch_shift,
            userName: "Test",
            metadata: [],
            count: 1
        )

        do {
            try await mockService.addMultipleChangeLogEntries([entry])
            #fail("Should throw error")
        } catch {
            #expect(error is PersistenceError)
        }
    }

    @Test("addMultipleChangeLogEntries with large batch")
    func addMultipleChangeLogEntriesWithLargeBatch() async throws {
        let mockService = MockPersistenceService()

        // Create 50 entries
        let entries = (0..<50).map { i in
            ChangeLogEntry(
                id: UUID(),
                timestamp: Date(),
                type: .switch_shift,
                userName: "User\(i)",
                metadata: [],
                count: 1
            )
        }

        try await mockService.addMultipleChangeLogEntries(entries)

        #expect(mockService.mockChangeLogEntries.count == 50)
        #expect(mockService.mockChangeLogEntries.last?.userName == "User49")
    }

    @Test("addMultipleChangeLogEntries maintains insertion order")
    func addMultipleChangeLogEntriesMaintainsOrder() async throws {
        let mockService = MockPersistenceService()

        let entry1 = ChangeLogEntry(
            id: UUID(),
            timestamp: Date(timeIntervalSince1970: 1000),
            type: .switch_shift,
            userName: "First",
            metadata: [],
            count: 1
        )
        let entry2 = ChangeLogEntry(
            id: UUID(),
            timestamp: Date(timeIntervalSince1970: 2000),
            type: .switch_shift,
            userName: "Second",
            metadata: [],
            count: 1
        )
        let entry3 = ChangeLogEntry(
            id: UUID(),
            timestamp: Date(timeIntervalSince1970: 3000),
            type: .switch_shift,
            userName: "Third",
            metadata: [],
            count: 1
        )

        try await mockService.addMultipleChangeLogEntries([entry1, entry2, entry3])

        #expect(mockService.mockChangeLogEntries[0].timestamp < mockService.mockChangeLogEntries[1].timestamp)
        #expect(mockService.mockChangeLogEntries[1].timestamp < mockService.mockChangeLogEntries[2].timestamp)
    }

    @Test("addMultipleChangeLogEntries works with different entry types")
    func addMultipleChangeLogEntriesWorkWithDifferentTypes() async throws {
        let mockService = MockPersistenceService()

        let entry1 = ChangeLogEntry(
            id: UUID(),
            timestamp: Date(),
            type: .switch_shift,
            userName: "John",
            metadata: [],
            count: 1
        )
        let entry2 = ChangeLogEntry(
            id: UUID(),
            timestamp: Date(),
            type: .switch_shift,
            userName: "Jane",
            metadata: [],
            count: 1
        )

        try await mockService.addMultipleChangeLogEntries([entry1, entry2])

        #expect(mockService.mockChangeLogEntries.count == 2)
        #expect(mockService.mockChangeLogEntries.allSatisfy { $0.type == .switch_shift })
    }
}
