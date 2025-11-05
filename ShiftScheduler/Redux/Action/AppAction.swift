import Foundation

/// Root application action - Hierarchical action types
enum AppAction: Equatable {
    /// App lifecycle actions (initialization, tab selection)
    case appLifecycle(AppLifecycleAction)

    /// Today feature actions
    case today(TodayAction)

    /// Schedule feature actions
    case schedule(ScheduleAction)

    /// Shift types feature actions
    case shiftTypes(ShiftTypesAction)

    /// Locations feature actions
    case locations(LocationsAction)

    /// Change log feature actions
    case changeLog(ChangeLogAction)

    /// Settings feature actions
    case settings(SettingsAction)

    static func == (lhs: AppAction, rhs: AppAction) -> Bool {
        switch (lhs, rhs) {
        case (.appLifecycle(let a), .appLifecycle(let b)):
            return a == b
        case (.today(let a), .today(let b)):
            return a == b
        case (.schedule(let a), .schedule(let b)):
            return a == b
        case (.shiftTypes(let a), .shiftTypes(let b)):
            return a == b
        case (.locations(let a), .locations(let b)):
            return a == b
        case (.changeLog(let a), .changeLog(let b)):
            return a == b
        case (.settings(let a), .settings(let b)):
            return a == b
        default:
            return false
        }
    }
}

// MARK: - App Lifecycle Actions

/// Actions for app initialization and global navigation
enum AppLifecycleAction: Equatable {
    /// App launched and appeared
    case onAppear

    /// User selected a different tab
    case tabSelected(Tab)

    /// User profile was updated
    case userProfileUpdated(UserProfile)

    /// Verify calendar access on app startup
    case verifyCalendarAccessOnStartup

    /// Calendar access verification completed
    case calendarAccessVerified(Bool)

    /// Request calendar access from user
    case requestCalendarAccess

    /// Calendar access request completed
    case calendarAccessRequested(Result<Bool, Error>)

    /// Load initial data (locations and shift types) on app startup
    case loadInitialData

    /// Initial data loading completed
    case initializationComplete(Result<Void, Error>)

    static func == (lhs: AppLifecycleAction, rhs: AppLifecycleAction) -> Bool {
        switch (lhs, rhs) {
        case (.onAppear, .onAppear), (.verifyCalendarAccessOnStartup, .verifyCalendarAccessOnStartup),
             (.requestCalendarAccess, .requestCalendarAccess), (.loadInitialData, .loadInitialData):
            return true
        case let (.tabSelected(a), .tabSelected(b)):
            return a == b
        case let (.userProfileUpdated(a), .userProfileUpdated(b)):
            return a.userId == b.userId
        case let (.calendarAccessVerified(a), .calendarAccessVerified(b)):
            return a == b
        case (.calendarAccessRequested(.success), .calendarAccessRequested(.success)),
             (.calendarAccessRequested(.failure), .calendarAccessRequested(.failure)):
            return true
        case (.initializationComplete(.success), .initializationComplete(.success)),
             (.initializationComplete(.failure), .initializationComplete(.failure)):
            return true
        default:
            return false
        }
    }
}

// MARK: - Today Feature Actions

/// Actions for the Today feature
enum TodayAction: Equatable {
    /// View appeared, load initial data
    case task

    /// Load shifts from calendar for next 30 days
    case loadShifts

    /// Handle shifts loaded result
    case shiftsLoaded(Result<[ScheduledShift], Error>)

    /// User tapped to switch a shift
    case switchShiftTapped(ScheduledShift)

    /// Perform the actual shift switch
    case performSwitchShift(ScheduledShift, ShiftType, String?)

    /// Handle shift switch result
    case shiftSwitched(Result<Void, Error>)

    /// Clear the toast message
    case toastMessageCleared

    /// Sheet was dismissed
    case switchShiftSheetDismissed

    /// Update cached shift computations
    case updateCachedShifts

    /// Update undo/redo button states
    case updateUndoRedoStates

    // MARK: - Quick Actions

    /// Show/hide edit notes sheet
    case editNotesSheetToggled(Bool)

    /// Notes text changed in edit notes sheet
    case quickActionsNotesChanged(String)

    /// User requested to delete today's shift
    case deleteShiftRequested(ScheduledShift)

    /// User confirmed shift deletion
    case deleteShiftConfirmed

    /// User cancelled shift deletion
    case deleteShiftCancelled

    /// Shift deleted
    case shiftDeleted(Result<Void, Error>)

    static func == (lhs: TodayAction, rhs: TodayAction) -> Bool {
        switch (lhs, rhs) {
        case (.task, .task), (.loadShifts, .loadShifts),
             (.toastMessageCleared, .toastMessageCleared),
             (.switchShiftSheetDismissed, .switchShiftSheetDismissed),
             (.updateCachedShifts, .updateCachedShifts),
             (.updateUndoRedoStates, .updateUndoRedoStates),
             (.deleteShiftConfirmed, .deleteShiftConfirmed),
             (.deleteShiftCancelled, .deleteShiftCancelled):
            return true
        case let (.shiftsLoaded(a), .shiftsLoaded(b)):
            switch (a, b) {
            case (.success, .success), (.failure, .failure):
                return true
            default:
                return false
            }
        case let (.switchShiftTapped(a), .switchShiftTapped(b)):
            return a.id == b.id
        case let (.performSwitchShift(aShift, aType, aReason), .performSwitchShift(bShift, bType, bReason)):
            return aShift.id == bShift.id && aType.id == bType.id && aReason == bReason
        case (.shiftSwitched(.success), .shiftSwitched(.success)),
             (.shiftSwitched(.failure), .shiftSwitched(.failure)):
            return true
        case let (.editNotesSheetToggled(lhs), .editNotesSheetToggled(rhs)):
            return lhs == rhs
        case let (.quickActionsNotesChanged(lhs), .quickActionsNotesChanged(rhs)):
            return lhs == rhs
        case let (.deleteShiftRequested(lhs), .deleteShiftRequested(rhs)):
            return lhs.id == rhs.id
        case (.shiftDeleted(.success), .shiftDeleted(.success)),
             (.shiftDeleted(.failure), .shiftDeleted(.failure)):
            return true
        default:
            return false
        }
    }
}

// MARK: - Schedule Feature Actions

/// Actions for the Schedule feature
enum ScheduleAction: Equatable {
    /// View appeared, load initial data and restore undo/redo stacks
    case task

    /// Check calendar authorization status
    case checkAuthorization

    /// Authorization status checked
    case authorizationChecked(Bool)

    /// Load shifts from calendar for the current month
    case loadShifts

    /// Selected date changed
    case selectedDateChanged(Date)

    /// Search text changed
    case searchTextChanged(String)

    // MARK: - Detail View Actions

    /// User tapped a shift to view details
    case shiftTapped(ScheduledShift)

    /// Detail sheet was dismissed
    case shiftDetailDismissed

    // MARK: - Add Shift Actions

    /// Add shift sheet toggle
    case addShiftSheetToggled(Bool)

    /// Add shift button tapped
    case addShiftButtonTapped

    /// User requested to add a new shift
    case addShift(date: Date, shiftType: ShiftType, notes: String)

    /// Handle add shift result
    case addShiftResponse(Result<ScheduledShift, ScheduleError>)

    /// Add shift sheet was dismissed
    case addShiftSheetDismissed

    // MARK: - Delete Shift Actions

    /// User requested to delete a shift
    case deleteShiftRequested(ScheduledShift)

    /// User confirmed shift deletion
    case deleteShiftConfirmed

    /// User cancelled shift deletion
    case deleteShiftCancelled

    /// Shift deleted
    case deleteShift(ScheduledShift)

    /// Handle shift deleted result
    case shiftDeleted(Result<Void, ScheduleError>)

    // MARK: - Overlap Resolution Actions

    /// Overlapping shifts detected when loading from calendar
    case overlappingShiftsDetected(date: Date, shifts: [ScheduledShift])

    /// User selected which shift to keep from overlapping shifts
    case resolveOverlap(keepShift: ScheduledShift, deleteShifts: [ScheduledShift])

    /// Overlap resolution completed
    case overlapResolved(Result<Void, ScheduleError>)

    /// User dismissed overlap resolution dialog
    case overlapResolutionDismissed

    // MARK: - Switch Shift Actions

    /// Switch shift sheet toggle
    case switchShiftSheetToggled(Bool)

    /// User tapped to switch a shift
    case switchShiftTapped(ScheduledShift)

    /// Perform the actual shift switch
    case performSwitchShift(ScheduledShift, ShiftType, String?)

    /// Handle shift switch result
    case shiftSwitched(Result<ChangeLogEntry, ScheduleError>)

    // MARK: - Load Shifts

    /// Shifts loaded from calendar
    case shiftsLoaded(Result<[ScheduledShift], Error>)

    // MARK: - Stack Restoration

    /// Restore undo/redo stacks from persistence
    case restoreUndoRedoStacks

    /// Handle undo/redo stacks restored from persistence
    case stacksRestored(Result<(undo: [ChangeLogEntry], redo: [ChangeLogEntry]), Error>)

    /// Handle undo/redo stacks restoration failure
    case undoRedoStackRestoreFailed(ScheduleError)

    // MARK: - Undo/Redo Operations

    /// Undo operation
    case undo

    /// Redo operation
    case redo

    /// Handle undo result
    case undoCompleted(Result<Void, Error>)

    /// Handle redo result
    case redoCompleted(Result<Void, Error>)

    // MARK: - Feedback Actions

    /// Dismiss current error
    case dismissError

    /// Dismiss success toast
    case dismissSuccessToast

    // MARK: - Filter Actions

    /// Show/hide filter sheet
    case filterSheetToggled(Bool)

    /// Date range filter changed
    case filterDateRangeChanged(startDate: Date?, endDate: Date?)

    /// Location filter changed
    case filterLocationChanged(Location?)

    /// Shift type filter changed
    case filterShiftTypeChanged(ShiftType?)

    /// Clear all active filters
    case clearFilters

    // MARK: - Sliding Window Actions

    /// User navigated to a different month in the calendar view
    case displayedMonthChanged(Date)

    /// Load shifts centered around a specific month (for range fault handling)
    case loadShiftsAroundMonth(Date, monthOffset: Int)

    /// Handle shifts loaded around month result (includes range info)
    case shiftsLoadedAroundMonth(Result<(shifts: [ScheduledShift], rangeStart: Date, rangeEnd: Date), Error>)

    /// Jump to today's date in the calendar (animated)
    case jumpToToday

    static func == (lhs: ScheduleAction, rhs: ScheduleAction) -> Bool {
        switch (lhs, rhs) {
        case (.task, .task), (.checkAuthorization, .checkAuthorization),
             (.loadShifts, .loadShifts),
             (.shiftDetailDismissed, .shiftDetailDismissed),
             (.addShiftButtonTapped, .addShiftButtonTapped),
             (.deleteShiftCancelled, .deleteShiftCancelled),
             (.deleteShiftConfirmed, .deleteShiftConfirmed),
             (.undo, .undo), (.redo, .redo),
             (.dismissError, .dismissError),
             (.dismissSuccessToast, .dismissSuccessToast),
             (.clearFilters, .clearFilters),
             (.restoreUndoRedoStacks, .restoreUndoRedoStacks),
             (.jumpToToday, .jumpToToday):
            return true
        case let (.authorizationChecked(lhs), .authorizationChecked(rhs)):
            return lhs == rhs
        case let (.selectedDateChanged(lhs), .selectedDateChanged(rhs)):
            return lhs == rhs
        case let (.searchTextChanged(lhs), .searchTextChanged(rhs)):
            return lhs == rhs
        case let (.shiftTapped(lhs), .shiftTapped(rhs)):
            return lhs.id == rhs.id
        case let (.addShiftSheetToggled(lhs), .addShiftSheetToggled(rhs)):
            return lhs == rhs
        case let (.addShift(dateL, typeL, notesL), .addShift(dateR, typeR, notesR)):
            return dateL == dateR && typeL.id == typeR.id && notesL == notesR
        case let (.addShiftResponse(lhs), .addShiftResponse(rhs)):
            switch (lhs, rhs) {
            case (.success, .success), (.failure, .failure):
                return true
            default:
                return false
            }
        case let (.deleteShiftRequested(lhs), .deleteShiftRequested(rhs)):
            return lhs.id == rhs.id
        case let (.deleteShift(lhs), .deleteShift(rhs)):
            return lhs.eventIdentifier == rhs.eventIdentifier
        case let (.shiftDeleted(lhs), .shiftDeleted(rhs)):
            switch (lhs, rhs) {
            case (.success, .success), (.failure, .failure):
                return true
            default:
                return false
            }
        case let (.overlappingShiftsDetected(dateL, shiftsL), .overlappingShiftsDetected(dateR, shiftsR)):
            return dateL == dateR && shiftsL.map { $0.id } == shiftsR.map { $0.id }
        case let (.resolveOverlap(keepL, deleteL), .resolveOverlap(keepR, deleteR)):
            return keepL.id == keepR.id && deleteL.map { $0.id } == deleteR.map { $0.id }
        case let (.overlapResolved(lhs), .overlapResolved(rhs)):
            switch (lhs, rhs) {
            case (.success, .success), (.failure, .failure):
                return true
            default:
                return false
            }
        case (.overlapResolutionDismissed, .overlapResolutionDismissed):
            return true
        case let (.switchShiftSheetToggled(lhs), .switchShiftSheetToggled(rhs)):
            return lhs == rhs
        case let (.switchShiftTapped(lhs), .switchShiftTapped(rhs)):
            return lhs.eventIdentifier == rhs.eventIdentifier
        case let (.performSwitchShift(lhs, newLhs, reasonLhs), .performSwitchShift(rhs, newRhs, reasonRhs)):
            return lhs.eventIdentifier == rhs.eventIdentifier &&
                   newLhs.id == newRhs.id &&
                   reasonLhs == reasonRhs
        case let (.shiftSwitched(lhs), .shiftSwitched(rhs)):
            switch (lhs, rhs) {
            case (.success, .success), (.failure, .failure):
                return true
            default:
                return false
            }
        case let (.shiftsLoaded(lhs), .shiftsLoaded(rhs)):
            switch (lhs, rhs) {
            case (.success, .success), (.failure, .failure):
                return true
            default:
                return false
            }
        case let (.stacksRestored(lhs), .stacksRestored(rhs)):
            switch (lhs, rhs) {
            case let (.success(lhsStacks), .success(rhsStacks)):
                return lhsStacks.undo == rhsStacks.undo && lhsStacks.redo == rhsStacks.redo
            case (.failure, .failure):
                return true
            default:
                return false
            }
        case let (.undoRedoStackRestoreFailed(lhs), .undoRedoStackRestoreFailed(rhs)):
            return lhs == rhs
        case (.undoCompleted(.success), .undoCompleted(.success)),
             (.undoCompleted(.failure), .undoCompleted(.failure)):
            return true
        case (.redoCompleted(.success), .redoCompleted(.success)),
             (.redoCompleted(.failure), .redoCompleted(.failure)):
            return true
        case let (.filterSheetToggled(lhs), .filterSheetToggled(rhs)):
            return lhs == rhs
        case let (.filterDateRangeChanged(lhsStart, lhsEnd), .filterDateRangeChanged(rhsStart, rhsEnd)):
            return lhsStart == rhsStart && lhsEnd == rhsEnd
        case let (.filterLocationChanged(lhs), .filterLocationChanged(rhs)):
            return lhs?.id == rhs?.id
        case let (.filterShiftTypeChanged(lhs), .filterShiftTypeChanged(rhs)):
            return lhs?.id == rhs?.id
        case let (.displayedMonthChanged(lhs), .displayedMonthChanged(rhs)):
            return lhs == rhs
        case let (.loadShiftsAroundMonth(lhsDate, lhsOffset), .loadShiftsAroundMonth(rhsDate, rhsOffset)):
            return lhsDate == rhsDate && lhsOffset == rhsOffset
        case (.shiftsLoadedAroundMonth(.success), .shiftsLoadedAroundMonth(.success)),
             (.shiftsLoadedAroundMonth(.failure), .shiftsLoadedAroundMonth(.failure)):
            return true
        default:
            return false
        }
    }
}

// MARK: - Shift Types Feature Actions

/// Actions for the Shift Types feature
enum ShiftTypesAction: Equatable {
    /// View appeared, load initial data
    case task

    /// Search text changed
    case searchTextChanged(String)

    /// Add button tapped
    case addButtonTapped

    /// Edit button tapped for a shift type
    case editShiftType(ShiftType)

    /// Save shift type (add or edit)
    case saveShiftType(ShiftType)

    /// Shift type saved
    case shiftTypeSaved(Result<Void, Error>)

    /// Delete button tapped for a shift type
    case deleteShiftType(ShiftType)

    /// Shift type deleted
    case shiftTypeDeleted(Result<Void, Error>)

    /// Shift types loaded from database
    case shiftTypesLoaded(Result<[ShiftType], Error>)

    /// Sheet dismissed after save
    case addEditSheetDismissed

    /// Refresh shift types after add/edit
    case refreshShiftTypes

    static func == (lhs: ShiftTypesAction, rhs: ShiftTypesAction) -> Bool {
        switch (lhs, rhs) {
        case (.task, .task),
             (.addButtonTapped, .addButtonTapped),
             (.addEditSheetDismissed, .addEditSheetDismissed),
             (.refreshShiftTypes, .refreshShiftTypes):
            return true
        case let (.searchTextChanged(lhs), .searchTextChanged(rhs)):
            return lhs == rhs
        case let (.editShiftType(lhs), .editShiftType(rhs)):
            return lhs.id == rhs.id
        case let (.saveShiftType(lhs), .saveShiftType(rhs)):
            return lhs.id == rhs.id
        case let (.deleteShiftType(lhs), .deleteShiftType(rhs)):
            return lhs.id == rhs.id
        case let (.shiftTypesLoaded(lhs), .shiftTypesLoaded(rhs)):
            switch (lhs, rhs) {
            case (.success, .success), (.failure, .failure):
                return true
            default:
                return false
            }
        case (.shiftTypeSaved(.success), .shiftTypeSaved(.success)),
             (.shiftTypeSaved(.failure), .shiftTypeSaved(.failure)),
             (.shiftTypeDeleted(.success), .shiftTypeDeleted(.success)),
             (.shiftTypeDeleted(.failure), .shiftTypeDeleted(.failure)):
            return true
        default:
            return false
        }
    }
}

// MARK: - Locations Feature Actions

/// Actions for the Locations feature
enum LocationsAction: Equatable {
    /// View appeared, load initial data
    case task

    /// Search text changed
    case searchTextChanged(String)

    /// Add button tapped
    case addButtonTapped

    /// Edit button tapped for a location
    case editLocation(Location)

    /// Save location (add or edit)
    case saveLocation(Location)

    /// Location saved
    case locationSaved(Result<Void, Error>)

    /// Delete button tapped for a location
    case deleteLocation(Location)

    /// Location deleted
    case locationDeleted(Result<Void, Error>)

    /// Locations loaded from database
    case locationsLoaded(Result<[Location], Error>)

    /// Sheet dismissed
    case addEditSheetDismissed

    /// Refresh locations after add/edit
    case refreshLocations

    static func == (lhs: LocationsAction, rhs: LocationsAction) -> Bool {
        switch (lhs, rhs) {
        case (.task, .task),
             (.addButtonTapped, .addButtonTapped),
             (.addEditSheetDismissed, .addEditSheetDismissed),
             (.refreshLocations, .refreshLocations):
            return true
        case let (.searchTextChanged(lhs), .searchTextChanged(rhs)):
            return lhs == rhs
        case let (.editLocation(lhs), .editLocation(rhs)):
            return lhs.id == rhs.id
        case let (.saveLocation(lhs), .saveLocation(rhs)):
            return lhs.id == rhs.id
        case let (.deleteLocation(lhs), .deleteLocation(rhs)):
            return lhs.id == rhs.id
        case let (.locationsLoaded(lhs), .locationsLoaded(rhs)):
            switch (lhs, rhs) {
            case (.success, .success), (.failure, .failure):
                return true
            default:
                return false
            }
        case (.locationSaved(.success), .locationSaved(.success)),
             (.locationSaved(.failure), .locationSaved(.failure)),
             (.locationDeleted(.success), .locationDeleted(.success)),
             (.locationDeleted(.failure), .locationDeleted(.failure)):
            return true
        default:
            return false
        }
    }
}

// MARK: - Change Log Feature Actions

/// Actions for the Change Log feature
enum ChangeLogAction: Equatable {
    /// View appeared, load initial data
    case task

    /// Search text changed
    case searchTextChanged(String)

    /// Entries loaded from database
    case entriesLoaded(Result<[ChangeLogEntry], Error>)

    /// Delete entry
    case deleteEntry(ChangeLogEntry)

    /// Entry deleted
    case entryDeleted(Result<Void, Error>)

    /// Purge old entries
    case purgeOldEntries

    /// Purge completed with count of deleted entries
    case purgeCompleted(Result<Int, Error>)

    static func == (lhs: ChangeLogAction, rhs: ChangeLogAction) -> Bool {
        switch (lhs, rhs) {
        case (.task, .task),
             (.purgeOldEntries, .purgeOldEntries):
            return true
        case let (.searchTextChanged(lhs), .searchTextChanged(rhs)):
            return lhs == rhs
        case let (.entriesLoaded(lhs), .entriesLoaded(rhs)):
            switch (lhs, rhs) {
            case (.success, .success), (.failure, .failure):
                return true
            default:
                return false
            }
        case let (.deleteEntry(lhs), .deleteEntry(rhs)):
            return lhs.id == rhs.id
        case (.entryDeleted(.success), .entryDeleted(.success)),
             (.entryDeleted(.failure), .entryDeleted(.failure)),
             (.purgeCompleted(.success), .purgeCompleted(.success)),
             (.purgeCompleted(.failure), .purgeCompleted(.failure)):
            return true
        default:
            return false
        }
    }
}

// MARK: - Settings Feature Actions

/// Actions for the Settings feature
enum SettingsAction: Equatable {
    /// View appeared, load initial data
    case task

    /// User changed display name
    case displayNameChanged(String)

    /// User changed retention policy
    case retentionPolicyChanged(ChangeLogRetentionPolicy)

    /// Save settings
    case saveSettings

    /// Settings saved
    case settingsSaved(Result<Void, Error>)

    /// Settings loaded
    case settingsLoaded(Result<UserProfile, Error>)

    /// Clear unsaved changes flag
    case clearUnsavedChanges

    // MARK: - Purge Statistics Actions

    /// Load purge statistics (entry counts, oldest date, etc.)
    case loadPurgeStatistics

    /// Purge statistics loaded
    case purgeStatisticsLoaded(total: Int, toBePurged: Int, oldestDate: Date?)

    /// User manually triggered purge from Settings
    case manualPurgeTriggered

    /// Manual purge completed
    case manualPurgeCompleted(Result<Int, Error>)

    /// User toggled auto-purge on app launch
    case autoPurgeToggled(Bool)

    /// Last purge date updated
    case lastPurgeDateUpdated(Date?)

    static func == (lhs: SettingsAction, rhs: SettingsAction) -> Bool {
        switch (lhs, rhs) {
        case (.task, .task),
             (.saveSettings, .saveSettings),
             (.clearUnsavedChanges, .clearUnsavedChanges):
            return true
        case let (.displayNameChanged(lhs), .displayNameChanged(rhs)):
            return lhs == rhs
        case let (.retentionPolicyChanged(lhs), .retentionPolicyChanged(rhs)):
            return lhs == rhs
        case let (.settingsSaved(lhs), .settingsSaved(rhs)):
            switch (lhs, rhs) {
            case (.success, .success), (.failure, .failure):
                return true
            default:
                return false
            }
        case let (.settingsLoaded(lhs), .settingsLoaded(rhs)):
            switch (lhs, rhs) {
            case (.success, .success), (.failure, .failure):
                return true
            default:
                return false
            }
        case (.loadPurgeStatistics, .loadPurgeStatistics),
             (.manualPurgeTriggered, .manualPurgeTriggered):
            return true
        case let (.purgeStatisticsLoaded(lTotal, lToBePurged, lOldest), .purgeStatisticsLoaded(rTotal, rToBePurged, rOldest)):
            return lTotal == rTotal && lToBePurged == rToBePurged && lOldest == rOldest
        case let (.manualPurgeCompleted(lhs), .manualPurgeCompleted(rhs)):
            switch (lhs, rhs) {
            case (.success(let l), .success(let r)):
                return l == r
            case (.failure, .failure):
                return true
            default:
                return false
            }
        case let (.autoPurgeToggled(lhs), .autoPurgeToggled(rhs)):
            return lhs == rhs
        case let (.lastPurgeDateUpdated(lhs), .lastPurgeDateUpdated(rhs)):
            return lhs == rhs
        default:
            return false
        }
    }
}
