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

    /// Updates all ShiftTypes that contain the given Location with the updated Location data
    /// - Parameter location: The updated Location to cascade to ShiftTypes
    /// - Returns: The list of ShiftTypes that were updated
    func updateShiftTypesWithLocation(_ location: Location) async throws -> [ShiftType]

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

    /// Add multiple entries to change log in a batch
    /// - Parameter entries: Array of ChangeLogEntry objects to add
    /// - Throws: Error if batch addition fails
    func addMultipleChangeLogEntries(_ entries: [ChangeLogEntry]) async throws

    /// Delete change log entry by ID
    func deleteChangeLogEntry(id: UUID) async throws

    /// Delete change log entries older than specified cutoff date
    func purgeOldChangeLogEntries(olderThan cutoffDate: Date) async throws -> Int

    /// Get metadata about change log entries without loading full entries
    /// Optimized for calculating statistics without deserializing all entries
    /// - Returns: Tuple containing total count and oldest entry date (if any)
    func getChangeLogMetadata() async throws -> (count: Int, oldestDate: Date?)

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
