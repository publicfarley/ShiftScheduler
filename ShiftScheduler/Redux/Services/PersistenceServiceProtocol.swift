import Foundation

/// Protocol for data persistence in Redux middleware
/// Handles all CRUD operations for shift types, locations, and change log
protocol PersistenceServiceProtocol: Sendable {
    // MARK: - Shift Types

    /// Load all shift types from persistence
    func loadShiftTypes() async throws -> [ShiftType]

    /// Save shift type (create or update)
    func saveShiftType(_ shiftType: ShiftType) async throws

    /// Delete shift type by ID
    func deleteShiftType(id: UUID) async throws

    // MARK: - Locations

    /// Load all locations from persistence
    func loadLocations() async throws -> [Location]

    /// Save location (create or update)
    func saveLocation(_ location: Location) async throws

    /// Delete location by ID
    func deleteLocation(id: UUID) async throws

    // MARK: - Change Log

    /// Load all change log entries
    func loadChangeLogEntries() async throws -> [ChangeLogEntry]

    /// Add entry to change log
    func addChangeLogEntry(_ entry: ChangeLogEntry) async throws

    /// Delete change log entry by ID
    func deleteChangeLogEntry(id: UUID) async throws

    /// Delete change log entries older than specified days
    func purgeOldChangeLogEntries(olderThanDays: Int) async throws -> Int

    // MARK: - Undo/Redo Stacks

    /// Load undo/redo stacks from persistence
    func loadUndoRedoStacks() async throws -> (undo: [ChangeLogEntry], redo: [ChangeLogEntry])

    /// Save undo/redo stacks to persistence
    func saveUndoRedoStacks(undo: [ChangeLogEntry], redo: [ChangeLogEntry]) async throws

    // MARK: - User Profile

    /// Load user profile from persistence
    func loadUserProfile() async throws -> UserProfile

    /// Save user profile to persistence
    func saveUserProfile(_ profile: UserProfile) async throws
}
