import Foundation

/// Thin orchestration layer over the app's services for CLI operations.
/// Not Redux: commands are one-shot, so state lives in persistence and the calendar.
final class CLIController {
    let persistence: PersistenceServiceProtocol
    let calendar: CalendarServiceProtocol
    let currentDay: CurrentDayServiceProtocol

    init(dataDirectory: URL? = nil) {
        let cloudKit = CloudKitManager()
        let shiftTypeRepository = ShiftTypeRepository(directoryURL: dataDirectory, cloudKitManager: cloudKit)
        persistence = PersistenceService(
            shiftTypeRepository: shiftTypeRepository,
            locationRepository: LocationRepository(directoryURL: dataDirectory, cloudKitManager: cloudKit),
            changeLogRepository: ChangeLogRepository(directoryURL: dataDirectory),
            userProfileRepository: UserProfileRepository(directoryURL: dataDirectory)
        )
        calendar = CalendarService(shiftTypeRepository: shiftTypeRepository)
        currentDay = CurrentDayService()
    }

    // MARK: - Authorization

    func requireCalendarAuthorization() async throws {
        guard try await calendar.isCalendarAuthorized() else {
            throw CLIError.calendarNotAuthorized
        }
    }

    // MARK: - Reference resolution
    //
    // Commands accept UUIDs (unambiguous, agent-friendly) or human-readable
    // names/titles/symbols (unique match required).

    func resolveShiftType(_ reference: String) async throws -> ShiftType {
        let types = try await persistence.loadShiftTypes()
        if let id = UUID(uuidString: reference), let match = types.first(where: { $0.id == id }) {
            return match
        }
        let titleMatches = types.filter { $0.title.caseInsensitiveCompare(reference) == .orderedSame }
        if titleMatches.count == 1 { return titleMatches[0] }
        if titleMatches.count > 1 {
            throw CLIError.ambiguous(
                kind: "shift type",
                reference: reference,
                candidates: titleMatches.map { "\($0.id.uuidString)  \($0.title)" }
            )
        }
        let symbolMatches = types.filter { $0.symbol == reference }
        if symbolMatches.count == 1 { return symbolMatches[0] }
        if symbolMatches.count > 1 {
            throw CLIError.ambiguous(
                kind: "shift type",
                reference: reference,
                candidates: symbolMatches.map { "\($0.id.uuidString)  \($0.title)" }
            )
        }
        throw CLIError.shiftTypeNotFound(reference)
    }

    func resolveLocation(_ reference: String) async throws -> Location {
        let locations = try await persistence.loadLocations()
        if let id = UUID(uuidString: reference), let match = locations.first(where: { $0.id == id }) {
            return match
        }
        let nameMatches = locations.filter { $0.name.caseInsensitiveCompare(reference) == .orderedSame }
        if nameMatches.count == 1 { return nameMatches[0] }
        if nameMatches.count > 1 {
            throw CLIError.ambiguous(
                kind: "location",
                reference: reference,
                candidates: nameMatches.map { "\($0.id.uuidString)  \($0.name)" }
            )
        }
        throw CLIError.locationNotFound(reference)
    }

    func findShift(eventIdentifier: String) async throws -> ScheduledShift {
        try await requireCalendarAuthorization()
        let shifts = try await calendar.loadShiftsForExtendedRange()
        guard let match = shifts.first(where: { $0.eventIdentifier == eventIdentifier }) else {
            throw CLIError.shiftNotFound(eventIdentifier)
        }
        return match
    }

    // MARK: - Schedule operations (with audit trail + undo stack)

    func addShift(date: Date, typeReference: String, notes: String?) async throws -> ScheduledShift {
        try await requireCalendarAuthorization()
        let type = try await resolveShiftType(typeReference)
        let shift = try await calendar.createShiftEvent(date: date, shiftType: type, notes: notes)
        let entry = try await makeEntry(type: .created, date: date, old: nil, new: snapshot(type), reason: notes)
        try await record(entry)
        return shift
    }

    func deleteShift(eventIdentifier: String, reason: String?) async throws -> ScheduledShift {
        let shift = try await findShift(eventIdentifier: eventIdentifier)
        try await calendar.deleteShiftEvent(eventIdentifier: eventIdentifier)
        let entry = try await makeEntry(
            type: .deleted,
            date: shift.date,
            old: shift.shiftType.map(snapshot),
            new: nil,
            reason: reason
        )
        try await record(entry)
        return shift
    }

    func switchShift(
        eventIdentifier: String,
        toTypeReference: String,
        reason: String?
    ) async throws -> (shift: ScheduledShift, newType: ShiftType) {
        let shift = try await findShift(eventIdentifier: eventIdentifier)
        let newType = try await resolveShiftType(toTypeReference)
        if shift.shiftType?.id == newType.id {
            throw CLIError.invalidOperation("Shift is already of type '\(newType.title)'")
        }
        try await calendar.updateShiftEvent(eventIdentifier: eventIdentifier, newShiftType: newType, date: shift.date)
        let entry = try await makeEntry(
            type: .switched,
            date: shift.date,
            old: shift.shiftType.map(snapshot),
            new: snapshot(newType),
            reason: reason
        )
        try await record(entry)
        return (shift, newType)
    }

    func updateShiftNotes(eventIdentifier: String, notes: String) async throws {
        _ = try await findShift(eventIdentifier: eventIdentifier)
        try await calendar.updateShiftNotes(eventIdentifier: eventIdentifier, notes: notes)
    }

    // MARK: - Undo / Redo
    //
    // Implemented against change-log snapshots. The affected calendar event is
    // located by date + shift type (event identifiers are not stored in
    // ChangeLogEntry).

    func undo() async throws -> ChangeLogEntry {
        var (undoStack, redoStack) = try await persistence.loadUndoRedoStacks()
        guard let entry = undoStack.last else { throw CLIError.nothingToUndo }
        try await requireCalendarAuthorization()
        try await revert(entry)
        undoStack.removeLast()
        redoStack.append(entry)
        try await persistence.saveUndoRedoStacks(undo: undoStack, redo: redoStack)
        return entry
    }

    func redo() async throws -> ChangeLogEntry {
        var (undoStack, redoStack) = try await persistence.loadUndoRedoStacks()
        guard let entry = redoStack.last else { throw CLIError.nothingToRedo }
        try await requireCalendarAuthorization()
        try await apply(entry)
        redoStack.removeLast()
        undoStack.append(entry)
        try await persistence.saveUndoRedoStacks(undo: undoStack, redo: redoStack)
        return entry
    }

    /// Reverses the effect of a change log entry (undo).
    private func revert(_ entry: ChangeLogEntry) async throws {
        switch entry.changeType {
        case .switched:
            guard let old = entry.oldShiftSnapshot, let new = entry.newShiftSnapshot else {
                throw CLIError.cannotRevert("Change entry is missing shift snapshots")
            }
            let shift = try await findShift(on: entry.scheduledShiftDate, typeId: new.shiftTypeId)
            let oldType = try await shiftType(from: old)
            try await calendar.updateShiftEvent(eventIdentifier: shift.eventIdentifier, newShiftType: oldType, date: shift.date)
        case .created:
            guard let new = entry.newShiftSnapshot else {
                throw CLIError.cannotRevert("Change entry is missing shift snapshot")
            }
            let shift = try await findShift(on: entry.scheduledShiftDate, typeId: new.shiftTypeId)
            try await calendar.deleteShiftEvent(eventIdentifier: shift.eventIdentifier)
        case .deleted:
            guard let old = entry.oldShiftSnapshot else {
                throw CLIError.cannotRevert("Change entry is missing shift snapshot")
            }
            let type = try await shiftType(from: old)
            _ = try await calendar.createShiftEvent(date: entry.scheduledShiftDate, shiftType: type, notes: nil)
        default:
            throw CLIError.cannotRevert("Cannot undo a '\(entry.changeType.rawValue)' operation")
        }
    }

    /// Re-applies the effect of a change log entry (redo).
    private func apply(_ entry: ChangeLogEntry) async throws {
        switch entry.changeType {
        case .switched:
            guard let old = entry.oldShiftSnapshot, let new = entry.newShiftSnapshot else {
                throw CLIError.cannotRevert("Change entry is missing shift snapshots")
            }
            let shift = try await findShift(on: entry.scheduledShiftDate, typeId: old.shiftTypeId)
            let newType = try await shiftType(from: new)
            try await calendar.updateShiftEvent(eventIdentifier: shift.eventIdentifier, newShiftType: newType, date: shift.date)
        case .created:
            guard let new = entry.newShiftSnapshot else {
                throw CLIError.cannotRevert("Change entry is missing shift snapshot")
            }
            let type = try await shiftType(from: new)
            _ = try await calendar.createShiftEvent(date: entry.scheduledShiftDate, shiftType: type, notes: nil)
        case .deleted:
            guard let old = entry.oldShiftSnapshot else {
                throw CLIError.cannotRevert("Change entry is missing shift snapshot")
            }
            let shift = try await findShift(on: entry.scheduledShiftDate, typeId: old.shiftTypeId)
            try await calendar.deleteShiftEvent(eventIdentifier: shift.eventIdentifier)
        default:
            throw CLIError.cannotRevert("Cannot redo a '\(entry.changeType.rawValue)' operation")
        }
    }

    // MARK: - Locations

    func deleteLocation(_ reference: String) async throws -> Location {
        let location = try await resolveLocation(reference)
        let types = try await persistence.loadShiftTypes()
        let dependents = types.filter { $0.location.id == location.id }
        guard dependents.isEmpty else {
            throw CLIError.locationInUse(name: location.name, usedBy: dependents.map(\.title))
        }
        try await persistence.deleteLocation(id: location.id)
        return location
    }

    /// Saves an edited location and cascades the change to shift types and,
    /// when the calendar is available, existing calendar events.
    func editLocation(_ reference: String, name: String?, address: String?) async throws -> (location: Location, cascadedTypes: Int, cascadedEvents: Int) {
        var location = try await resolveLocation(reference)
        if let name { location.name = name }
        if let address { location.address = address }
        try await persistence.saveLocation(location)
        let updatedTypes = try await persistence.updateShiftTypesWithLocation(location)
        let cascadedEvents = await cascadeToCalendar(updatedTypes)
        return (location, updatedTypes.count, cascadedEvents)
    }

    // MARK: - Shift types

    /// Saves an edited shift type and cascades the change to existing calendar
    /// events when the calendar is available.
    func saveShiftTypeCascading(_ type: ShiftType) async throws -> Int {
        try await persistence.saveShiftType(type)
        return await cascadeToCalendar([type])
    }

    /// Best-effort calendar cascade: skipped silently when the calendar is not
    /// authorized (persistence remains the source of truth for the edit itself).
    private func cascadeToCalendar(_ types: [ShiftType]) async -> Int {
        guard (try? await calendar.isCalendarAuthorized()) == true else { return 0 }
        var count = 0
        for type in types {
            count += (try? await calendar.updateEventsWithShiftType(type)) ?? 0
        }
        return count
    }

    // MARK: - Private helpers

    private func snapshot(_ type: ShiftType) -> ShiftSnapshot {
        ShiftSnapshot(
            shiftTypeId: type.id,
            symbol: type.symbol,
            title: type.title,
            shiftDescription: type.shiftDescription,
            duration: type.duration,
            locationName: type.location.name,
            locationAddress: type.location.address
        )
    }

    private func makeEntry(
        type: ChangeType,
        date: Date,
        old: ShiftSnapshot?,
        new: ShiftSnapshot?,
        reason: String?
    ) async throws -> ChangeLogEntry {
        let profile = try await persistence.loadUserProfile()
        let name = profile.displayName.isEmpty ? "CLI" : profile.displayName
        return ChangeLogEntry(
            timestamp: Date(),
            userId: profile.userId,
            userDisplayName: name,
            changeType: type,
            scheduledShiftDate: date,
            oldShiftSnapshot: old,
            newShiftSnapshot: new,
            reason: reason
        )
    }

    /// Persists a change log entry and pushes it onto the undo stack
    /// (clearing the redo stack, as any new operation invalidates redo history).
    private func record(_ entry: ChangeLogEntry) async throws {
        try await persistence.addChangeLogEntry(entry)
        var (undoStack, _) = try await persistence.loadUndoRedoStacks()
        undoStack.append(entry)
        try await persistence.saveUndoRedoStacks(undo: undoStack, redo: [])
    }

    /// Resolves the current ShiftType for a snapshot, falling back to
    /// reconstructing it from the snapshot when the type no longer exists.
    private func shiftType(from snapshot: ShiftSnapshot) async throws -> ShiftType {
        let types = try await persistence.loadShiftTypes()
        if let match = types.first(where: { $0.id == snapshot.shiftTypeId }) {
            return match
        }
        return ShiftType(
            id: snapshot.shiftTypeId,
            symbol: snapshot.symbol,
            duration: snapshot.duration,
            title: snapshot.title,
            description: snapshot.shiftDescription,
            location: Location(
                name: snapshot.locationName ?? "Unknown Location",
                address: snapshot.locationAddress ?? ""
            )
        )
    }

    private func findShift(on date: Date, typeId: UUID) async throws -> ScheduledShift {
        let cal = Calendar.current
        let start = cal.date(byAdding: .day, value: -1, to: date) ?? date
        let end = cal.date(byAdding: .day, value: 2, to: date) ?? date
        let shifts = try await calendar.loadShifts(from: start, to: end)
        guard let match = shifts.first(where: { cal.isDate($0.date, inSameDayAs: date) && $0.shiftType?.id == typeId }) else {
            throw CLIError.cannotRevert("No shift of the expected type found on \(OutputFormatter.dayString(date))")
        }
        return match
    }
}
