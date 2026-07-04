import Foundation
import OSLog
import UIKit

private nonisolated let logger = Logger(subsystem: "com.shiftscheduler.redux", category: "SettingsMiddleware")

/// Middleware for Settings feature side effects
/// Handles loading and saving user settings
func settingsMiddleware(
    state: AppState,
    action: AppAction,
    services: ServiceContainer,
    dispatch: Dispatcher<AppAction>,
) async {
    guard case .settings(let settingsAction) = action else { return }
    
    switch settingsAction {
    case .loadSettings:
        // User profile is already loaded in AppState by AppStartupMiddleware
        // Sync the relevant settings from UserProfile to SettingsState
        await dispatch(.settings(.retentionPolicyChanged(state.userProfile.retentionPolicy)))
        await dispatch(.settings(.autoPurgeToggled(state.userProfile.autoPurgeEnabled)))
        if let lastPurgeDate = state.userProfile.lastPurgeDate {
            await dispatch(.settings(.lastPurgeDateUpdated(lastPurgeDate)))
        }
        // Note: Purge statistics are loaded explicitly by SettingsView when needed

    case .saveSettings:
        logger.debug("Saving settings")

        do {
            let profile = UserProfile(
                userId: state.userProfile.userId,
                displayName: state.userProfile.displayName,
                retentionPolicy: state.settings.retentionPolicy,
                autoPurgeEnabled: state.settings.autoPurgeEnabled,
                lastPurgeDate: state.settings.lastPurgeDate
            )

            try await services.persistenceService.saveUserProfile(profile)
            await dispatch(.settings(.settingsSaved(.success(()))))

            // Update app-level user profile
            await dispatch(.appLifecycle(.userProfileUpdated(profile)))
        } catch {
            logger.error("Failed to save settings: \(error.localizedDescription)")
            await dispatch(.settings(.settingsSaved(.failure(error))))
        }

    // MARK: - Purge Statistics Actions

    case .loadPurgeStatistics:
        logger.debug("Loading purge statistics")
        do {
            // Get metadata without loading full entries (optimized)
            let metadata = try await services.persistenceService.getChangeLogMetadata()
            let total = metadata.count
            let oldestDate = metadata.oldestDate

            // For toBePurged count, we still need to load entries when there's a cutoff date
            var toBePurged = 0
            if let cutoffDate = state.settings.retentionPolicy.cutoffDate {
                let entries = try await services.persistenceService.loadChangeLogEntries()
                toBePurged = entries.filter { $0.timestamp < cutoffDate }.count
            }

            await dispatch(.settings(.purgeStatisticsLoaded(total: total, toBePurged: toBePurged, oldestDate: oldestDate)))
        } catch {
            logger.error("Failed to load purge statistics: \(error.localizedDescription)")
        }

    case .manualPurgeTriggered:
        logger.debug("Manual purge triggered from Settings")
        // Dispatch purge action to ChangeLogMiddleware
        // Completion will be handled when ChangeLogMiddleware dispatches purgeCompleted
        await dispatch(.changeLog(.purgeOldEntries))

    case .autoPurgeToggled(let enabled):
        logger.debug("Auto-purge toggled: \(enabled)")
        // Update will be saved when user saves settings
        // For now, just update reducer state - no direct UserDefaults access

    case .manualPurgeCompleted(.success(let deletedCount)):
        logger.debug("Manual purge completed: deleted \(deletedCount) entries")
        // Update last purge date in user profile
        let now = Date()
        do {
            var profile = try await services.persistenceService.loadUserProfile()
            profile.lastPurgeDate = now
            try await services.persistenceService.saveUserProfile(profile)
            await dispatch(.settings(.lastPurgeDateUpdated(now)))
        } catch {
            logger.error("Failed to save last purge date: \(error.localizedDescription)")
        }

        // Reload statistics after purge
        await dispatch(.settings(.loadPurgeStatistics))

    case .manualPurgeCompleted(.failure(let error)):
        logger.error("Manual purge failed: \(error.localizedDescription)")
        // Error already handled and logged by ChangeLogMiddleware

    case .resyncCalendarEventsRequested:
        logger.debug("Calendar event resync requested")
        do {
            let result = try await services.calendarService.resyncAllCalendarEvents()
            await dispatch(.settings(.resyncCalendarEventsCompleted(.success(result))))

            // Refresh schedule to reflect resynced calendar events
            if result.updated > 0 {
                await dispatch(.schedule(.loadShifts))
            }
        } catch {
            logger.error("Calendar resync failed: \(error.localizedDescription)")
            await dispatch(.settings(.resyncCalendarEventsCompleted(.failure(error))))
        }

    // MARK: - Shift Export Actions

    case .generateExport:
        logger.debug("Generating shift export")
        guard let startDate = state.settings.exportStartDate,
              let endDate = state.settings.exportEndDate else {
            await dispatch(.settings(.exportFailed("Please select both start and end dates")))
            return
        }

        // Validate date range
        guard startDate <= endDate else {
            await dispatch(.settings(.exportFailed("Start date must be before or equal to end date")))
            return
        }

        do {
            // Load shifts for the date range
            let shifts = try await services.calendarService.loadShifts(from: startDate, to: endDate)

            // Group shifts by date and extract symbols
            var dateToSymbols: [(Date, String)] = []

            // Get all dates in the range
            var currentDate = Calendar.current.startOfDay(for: startDate)
            let endOfDayEnd = Calendar.current.startOfDay(for: endDate)

            while currentDate <= endOfDayEnd {
                // Find shifts on this date
                let shiftsOnDate = shifts.filter { shift in
                    shift.occursOn(date: currentDate)
                }.sorted { $0.date < $1.date }

                // Extract symbol (use first shift if multiple, or tilde if none)
                let symbol = shiftsOnDate.first?.shiftType?.symbol ?? "~"
                dateToSymbols.append((currentDate, symbol))

                // Move to next day
                currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }

            // Format as space-separated symbols
            let symbolsString = dateToSymbols.map { $0.1 }.joined(separator: " ")

            logger.debug("Export generated: \(symbolsString)")
            await dispatch(.settings(.exportGenerated(symbolsString)))
        } catch {
            logger.error("Failed to generate export: \(error.localizedDescription)")
            await dispatch(.settings(.exportFailed("Failed to load shifts: \(error.localizedDescription)")))
        }

    case .copyToClipboard:
        logger.debug("Copying export to clipboard")
        guard let symbols = state.settings.exportedSymbols else {
            logger.warning("No exported symbols to copy")
            return
        }

        // Copy to clipboard using UIPasteboard
        await MainActor.run {
            UIPasteboard.general.string = symbols
        }

    // MARK: - Shift Import Actions

    case .pasteImportFromClipboard:
        logger.debug("Pasting import text from clipboard")
        let text = await MainActor.run { UIPasteboard.general.string }
        await dispatch(.settings(.importTextChanged(text ?? "")))
        await dispatch(.settings(.validateImport))

    case .validateImport:
        logger.debug("Validating shift import text")
        do {
            let entries = try ShiftImportParser.parse(state.settings.importText)

            guard let firstDate = entries.first?.date, let lastDate = entries.last?.date else {
                await dispatch(.settings(.importFailed("No shifts found to import")))
                return
            }

            let existingShifts = try await services.calendarService.loadShifts(from: firstDate, to: lastDate)
            let preview = ShiftImportPreview.build(
                entries: entries,
                shiftTypes: state.shiftTypes.shiftTypes,
                existingShifts: existingShifts
            )
            await dispatch(.settings(.importPreviewGenerated(preview)))
        } catch let error as ShiftImportParser.ParseError {
            await dispatch(.settings(.importFailed(importParseErrorMessage(error))))
        } catch {
            await dispatch(.settings(.importFailed("Failed to validate import: \(error.localizedDescription)")))
        }

    case .confirmImport:
        logger.debug("Confirming shift import")
        guard let preview = state.settings.importPreview, !preview.hasBlockingErrors else {
            await dispatch(.settings(.importFailed("Cannot import: resolve unknown symbols first")))
            return
        }

        if state.settings.importConflictPolicy == .abortOnConflict && preview.conflictCount > 0 {
            await dispatch(.settings(.importFailed("Import aborted: \(preview.conflictCount) day(s) already have a scheduled shift")))
            return
        }

        let userId = state.userProfile.userId
        let userDisplayName = state.userProfile.displayName
        let calendarService = services.calendarService
        let persistenceService = services.persistenceService

        let daysToImport = preview.days.compactMap { day -> (Date, ShiftType)? in
            if case .willImport(let shiftType) = day.status {
                return (day.date, shiftType)
            }
            return nil
        }

        var createdCount = 0
        for (date, shiftType) in daysToImport.sorted(by: { $0.0 < $1.0 }) {
            do {
                _ = try await calendarService.createShiftEvent(date: date, shiftType: shiftType, notes: "Imported")
                createdCount += 1

                let entry = ChangeLogEntry(
                    id: UUID(),
                    timestamp: Date(),
                    userId: userId,
                    userDisplayName: userDisplayName,
                    changeType: .created,
                    scheduledShiftDate: date,
                    oldShiftSnapshot: nil,
                    newShiftSnapshot: ShiftSnapshot(from: shiftType),
                    reason: "Imported from text"
                )
                try await persistenceService.addChangeLogEntry(entry)
            } catch {
                logger.error("Failed to import shift on \(date): \(error.localizedDescription)")
                let failureError = ScheduleError.calendarEventCreationFailed(
                    "Failed to import shift on \(date). \(createdCount) shift(s) were imported before this error."
                )
                await dispatch(.settings(.importCompleted(.failure(failureError))))
                await dispatch(.schedule(.loadShifts))
                return
            }
        }

        await dispatch(.settings(.importCompleted(.success(createdCount))))
        await dispatch(.schedule(.loadShifts))

    case .settingsLoaded, .settingsSaved, .clearUnsavedChanges, .displayNameChanged, .retentionPolicyChanged,
         .purgeStatisticsLoaded, .lastPurgeDateUpdated, .resyncCalendarEventsCompleted, .toastMessageCleared,
         .exportSheetToggled, .exportStartDateChanged, .exportEndDateChanged, .exportGenerated, .exportFailed, .resetExport,
         .importSheetToggled, .importTextChanged, .importFileLoaded, .importPreviewGenerated, .importConflictPolicyChanged,
         .importCompleted, .importFailed, .resetImport:
        // Handled by reducer only
        break
    }
}

private func importParseErrorMessage(_ error: ShiftImportParser.ParseError) -> String {
    switch error {
    case .emptyInput:
        return "Import text is empty"
    case .invalidDate(let line, let token):
        return "Line \(line): expected a date in yyyy-MM-dd format, got \"\(token)\""
    case .noSymbols(let line):
        return "Line \(line): date has no shift symbols"
    case .overlappingRanges(let date):
        let dateStr = date.formatted(date: .abbreviated, time: .omitted)
        return "\(dateStr) is assigned more than once"
    }
}
