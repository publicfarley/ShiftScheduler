import Foundation

// MARK: - App Root Reducer

/// Root reducer that delegates to feature reducers
/// Composes all feature reducers into a single pure function
func appReducer(state: AppState, action: AppAction) -> AppState {
    var state = state

    switch action {
    case .appLifecycle(let action):
        state = appLifecycleReducer(state: state, action: action)

    case .today(let action):
        state.today = todayReducer(state: state.today, action: action)

    case .schedule(let action):
        state.schedule = scheduleReducer(state: state.schedule, action: action)

    case .shiftTypes(let action):
        state.shiftTypes = shiftTypesReducer(state: state.shiftTypes, action: action)

    case .locations(let action):
        state.locations = locationsReducer(state: state.locations, action: action)

    case .changeLog(let action):
        state.changeLog = changeLogReducer(state: state.changeLog, action: action)

    case .settings(let action):
        state.settings = settingsReducer(state: state.settings, action: action)
    }

    return state
}

// MARK: - App Lifecycle Reducer

/// Handles app-level lifecycle actions (init, tab selection, profile updates)
func appLifecycleReducer(state: AppState, action: AppLifecycleAction) -> AppState {
    var state = state

    switch action {
    case .onAppAppear:
        break

    case .tabSelected(let tab):
        state.selectedTab = tab

    case .displayNameChanged(let newName):
        state.userProfile.displayName = newName
        state.isNameConfigured = !newName.trimmingCharacters(in: .whitespaces).isEmpty

    case .userProfileUpdated(let profile):
        state.userProfile = profile
        state.isNameConfigured = !profile.displayName.trimmingCharacters(in: .whitespaces).isEmpty

    case .profileLoaded:
        state.isProfileLoaded = true

    case .verifyCalendarAccessOnStartup:
        // Middleware will handle the actual verification
        break

    case .calendarAccessVerified(let isAuthorized):
        state.isCalendarAuthorized = isAuthorized
        state.isCalendarAuthorizationVerified = true

    case .requestCalendarAccess:
        // Middleware will handle the request
        break

    case .calendarAccessRequested(.success(let isAuthorized)):
        state.isCalendarAuthorized = isAuthorized
        state.isCalendarAuthorizationVerified = true

    case .calendarAccessRequested(.failure):
        // Keep previous state, user can retry
        state.isCalendarAuthorizationVerified = true

    case .loadInitialData:
        // Middleware will handle loading locations and shift types
        break

    case .initializationComplete(.success):
        state.isInitializationComplete = true
        state.initializationError = nil

    case .initializationComplete(.failure(let error)):
        // Don't mark as complete on failure - prevents app startup
        state.isInitializationComplete = false
        state.initializationError = error.localizedDescription

    case .significantTimeChange:
        // Middleware will handle refreshing Today and Schedule views
        break
    }

    return state
}

// MARK: - Today Reducer

/// Handles Today feature state updates
func todayReducer(state: TodayState, action: TodayAction) -> TodayState {
    var state = state

    switch action {
    case .loadShifts:
        state.isLoading = true

    case .shiftsLoaded(.success(let shifts)):
        state.isLoading = false
        state.scheduledShifts = shifts
        state.errorMessage = nil

    case .shiftsLoaded(.failure(let error)):
        state.isLoading = false
        state.errorMessage = "Failed to load shifts: \(error.localizedDescription)"

    case .switchShiftTapped(let shift):
        state.selectedShift = shift
        state.showSwitchShiftSheet = true

    case .performSwitchShift:
        state.isLoading = true

    case .shiftSwitched(.success):
        state.isLoading = false
        state.showSwitchShiftSheet = false
        state.selectedShift = nil
        state.toastMessage = .success("Shift switched successfully")

    case .shiftSwitched(.failure(let error)):
        state.isLoading = false
        state.toastMessage = .error("Failed to switch shift: \(error.localizedDescription)")

    case .toastMessageCleared:
        state.toastMessage = nil

    case .switchShiftSheetDismissed:
        state.showSwitchShiftSheet = false
        state.selectedShift = nil

    case .updateCachedShifts:
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today

        // Use occursOn helper to include multi-day shifts that span today/tomorrow
        state.todayShift = state.scheduledShifts.first { shift in
            shift.occursOn(date: today)
        }

        state.tomorrowShift = state.scheduledShifts.first { shift in
            shift.occursOn(date: tomorrow)
        }

        let next7DaysEnd = Calendar.current.date(byAdding: .day, value: 6, to: today) ?? today

        let next7DaysShifts = state.scheduledShifts.filter { shift in
            shift.date >= today && shift.date <= next7DaysEnd
        }

        state.thisWeekShiftsCount = next7DaysShifts.count
        state.completedThisWeek = 0  // No completed shifts in next 7 days range

    case .updateUndoRedoStates:
        // Undo/redo disabled for now (future implementation)
        state.canUndo = false
        state.canRedo = false

    // MARK: - Quick Actions

    case .editNotesSheetToggled(let show):
        state.showEditNotesSheet = show
        // Don't clear quickActionsNotes here - it's needed by middleware to persist
        // Notes will be re-initialized from shift.notes when sheet reopens

    case .quickActionsNotesChanged(let notes):
        state.quickActionsNotes = notes

    case .deleteShiftRequested(let shift):
        state.deleteShiftConfirmationShift = shift

    case .deleteShiftConfirmed:
        // Middleware will handle the actual deletion
        break

    case .deleteShiftCancelled:
        state.deleteShiftConfirmationShift = nil

    case .shiftDeleted(.success):
        state.deleteShiftConfirmationShift = nil
        // Toast message will be handled by middleware dispatch

    case .shiftDeleted(.failure(let error)):
        state.deleteShiftConfirmationShift = nil
        state.errorMessage = "Failed to delete shift: \(error.localizedDescription)"

    // MARK: - Add Shift

    case .addShiftButtonTapped:
        state.showAddShiftSheet = true

    case .addShiftSheetToggled(let show):
        state.showAddShiftSheet = show

    case .addShiftSheetDismissed:
        state.showAddShiftSheet = false
        state.currentError = nil

    // MARK: - Add Shift Operations

    case .addShift:
        // Middleware will handle the actual shift creation
        state.currentError = nil

    case .addShiftResponse(.success):
        state.showAddShiftSheet = false
        state.currentError = nil

    case .addShiftResponse(.failure(let error)):
        state.currentError = error
        state.showAddShiftSheet = true  // Keep sheet open to allow retry

    case .dismissError:
        state.currentError = nil

    // MARK: - Sick Day Actions

    case .markShiftAsSick(_, _):
        state.isLoading = true

    case .unmarkShiftAsSick(_):
        state.isLoading = true

    case .shiftMarkedAsSick(.success):
        state.isLoading = false
        state.showMarkAsSickSheet = false
        state.toastMessage = .success("Shift status updated")

    case .shiftMarkedAsSick(.failure(let error)):
        state.isLoading = false
        state.currentError = error as? ScheduleError ?? .unknown(error.localizedDescription)

    case .markAsSickSheetToggled(let show):
        state.showMarkAsSickSheet = show
    }

    return state
}

// MARK: - Schedule Reducer

/// Handles Schedule feature state updates with complex undo/redo logic
func scheduleReducer(state: ScheduleState, action: ScheduleAction) -> ScheduleState {
    var state = state

    switch action {
    case .initializeAndLoadScheduleData:
        state.isLoading = true
        state.isRestoringStacks = true

    case .checkAuthorization:
        break // Handled by middleware

    case .authorizationChecked(let isAuthorized):
        state.isCalendarAuthorized = isAuthorized

    case .loadShifts:
        state.isLoading = true
        state.errorMessage = nil
        state.currentError = nil

    case .selectedDateChanged(let date):
        state.selectedDate = date
        state.searchText = ""

    case .searchTextChanged(let text):
        state.searchText = text

    // MARK: - Detail View

    case .shiftTapped(let shift):
        state.selectedShiftId = shift.id
        state.selectedShiftForDetail = shift
        state.showShiftDetail = true

    case .shiftDetailDismissed:
        state.showShiftDetail = false
        state.selectedShiftId = nil
        state.selectedShiftForDetail = nil
        state.showSwitchShiftSheet = false

    // MARK: - Add Shift

    case .addShiftSheetToggled(let show):
        state.showAddShiftSheet = show

    case .addShiftButtonTapped:
        state.showAddShiftSheet = true

    case .addShift:
        state.isAddingShift = true
        state.currentError = nil

    case .addShiftResponse(.success):
        state.isAddingShift = false
        state.showAddShiftSheet = false
        state.successMessage = "Shift added successfully"
        state.showSuccessToast = true

    case .addShiftResponse(.failure(let error)):
        state.isAddingShift = false
        state.currentError = error
        state.showAddShiftSheet = true  // Keep sheet open to allow retry

    case .addShiftSheetDismissed:
        state.showAddShiftSheet = false

    // MARK: - Delete Shift

    case .deleteShiftRequested(let shift):
        state.deleteConfirmationShift = shift

    case .deleteShiftConfirmed:
        guard let _ = state.deleteConfirmationShift else { break }
        state.isDeletingShift = true

    case .deleteShiftCancelled:
        state.deleteConfirmationShift = nil

    case .deleteShift:
        state.isDeletingShift = true
        state.currentError = nil

    case .shiftDeleted(.success):
        state.isDeletingShift = false
        state.deleteConfirmationShift = nil
        state.successMessage = "Shift deleted"
        state.showSuccessToast = true

    case .shiftDeleted(.failure(let error)):
        state.isDeletingShift = false
        state.currentError = error

    // MARK: - Overlap Resolution

    case .overlappingShiftsDetected(let date, let shifts):
        state.showOverlapResolution = true
        state.overlapDate = date
        state.overlappingShifts = shifts

    case .resolveOverlap:
        state.isLoading = true
        state.currentError = nil

    case .overlapResolved(.success):
        state.isLoading = false
        state.showOverlapResolution = false
        state.overlapDate = nil
        state.overlappingShifts = []
        state.successMessage = "Overlap resolved"
        state.showSuccessToast = true

    case .overlapResolved(.failure(let error)):
        state.isLoading = false
        state.currentError = error

    case .overlapResolutionDismissed:
        state.showOverlapResolution = false
        state.overlapDate = nil
        state.overlappingShifts = []

    // MARK: - Switch Shift

    case .switchShiftSheetToggled(let show):
        state.showSwitchShiftSheet = show

    case .switchShiftTapped:
        state.showSwitchShiftSheet = true

    case .performSwitchShift:
        state.isSwitchingShift = true
        state.currentError = nil

    case .shiftSwitched(.success(let operation)):
        state.isSwitchingShift = false
        state.showSwitchShiftSheet = false
        state.showShiftDetail = false
        state.successMessage = "Shift switched successfully"
        state.showSuccessToast = true
        state.undoStack.append(operation)
        state.redoStack.removeAll()

    case .shiftSwitched(.failure(let error)):
        state.isSwitchingShift = false
        state.currentError = error

    // MARK: - Load Shifts

    case .shiftsLoaded(.success(let shifts)):
        state.isLoading = false
        state.isRestoringStacks = false
        state.scheduledShifts = shifts
        state.errorMessage = nil
        state.currentError = nil

        // Update selectedShiftForDetail if shift ID is tracked and shift exists
        if let selectedShiftId = state.selectedShiftId,
           let updatedShift = shifts.first(where: { $0.id == selectedShiftId }) {
            state.selectedShiftForDetail = updatedShift
        }

    case .shiftsLoaded(.failure(let error)):
        state.isLoading = false
        state.isRestoringStacks = false
        state.errorMessage = error.localizedDescription

    // MARK: - Stack Restoration

    case .restoreUndoRedoStacks:
        state.isRestoringStacks = true

    case .stacksRestored(.success(let stacks)):
        state.isRestoringStacks = false
        state.undoStack = stacks.undo
        state.redoStack = stacks.redo
        state.stacksRestored = true

    case .stacksRestored(.failure(let error)):
        state.isRestoringStacks = false
        state.errorMessage = "Failed to restore undo/redo: \(error.localizedDescription)"

    case .undoRedoStackRestoreFailed(let error):
        state.isRestoringStacks = false
        state.currentError = error

    // MARK: - Undo/Redo

    case .undo:
        guard !state.undoStack.isEmpty else {
            state.currentError = .undoStackEmpty
            return state
        }
        state.isLoading = true

    case .undoCompleted(.success):
        state.isLoading = false
        if !state.undoStack.isEmpty {
            let operation = state.undoStack.removeLast()
            state.redoStack.append(operation)
        }
        state.successMessage = "Undo successful"
        state.showSuccessToast = true

    case .undoCompleted(.failure(let error)):
        state.isLoading = false
        state.errorMessage = "Undo failed: \(error.localizedDescription)"

    case .redo:
        guard !state.redoStack.isEmpty else {
            state.currentError = .redoStackEmpty
            return state
        }
        state.isLoading = true

    case .redoCompleted(.success):
        state.isLoading = false
        if !state.redoStack.isEmpty {
            let operation = state.redoStack.removeLast()
            state.undoStack.append(operation)
        }
        state.successMessage = "Redo successful"
        state.showSuccessToast = true

    case .redoCompleted(.failure(let error)):
        state.isLoading = false
        state.errorMessage = "Redo failed: \(error.localizedDescription)"

    // MARK: - Feedback

    case .dismissError:
        state.currentError = nil

    case .dismissSuccessToast:
        state.showSuccessToast = false
        state.successMessage = nil

    // MARK: - Filter Actions

    case .filterSheetToggled(let show):
        state.showFilterSheet = show

    case .filterDateRangeChanged(let startDate, let endDate):
        state.filterDateRangeStart = startDate
        state.filterDateRangeEnd = endDate

    case .filterLocationChanged(let location):
        state.filterSelectedLocation = location

    case .filterShiftTypeChanged(let shiftType):
        state.filterSelectedShiftType = shiftType

    case .clearFilters:
        state.filterDateRangeStart = nil
        state.filterDateRangeEnd = nil
        state.filterSelectedLocation = nil
        state.filterSelectedShiftType = nil
        state.searchText = ""
        state.showFilterSheet = false

    // MARK: - Sliding Window Actions

    case .displayedMonthChanged(let newMonth):
        state.displayedMonth = newMonth
        // Fault detection happens in middleware

    case .loadShiftsAroundMonth:
        state.isLoadingAdditionalShifts = true
        // Actual loading happens in middleware

    case .shiftsLoadedAroundMonth(.success(let result)):
        state.isLoadingAdditionalShifts = false
        state.scheduledShifts = result.shifts
        state.loadedRangeStart = result.rangeStart
        state.loadedRangeEnd = result.rangeEnd
        state.isLoading = false

    case .shiftsLoadedAroundMonth(.failure(let error)):
        state.isLoadingAdditionalShifts = false
        state.currentError = error as? ScheduleError ?? .unknown(error.localizedDescription)
        state.isLoading = false

    // MARK: - Navigation

    case .jumpToToday:
        let today = Calendar.current.startOfDay(for: Date())
        state.selectedDate = today
        state.displayedMonth = today
        state.scrollToDateTrigger = today
        state.searchText = ""

    case .scrollCompleted:
        state.scrollToDateTrigger = nil

    // MARK: - Multi-Select Actions

    case .enterSelectionMode(let mode, let firstId):
        state.isInSelectionMode = true
        state.selectionMode = mode
        // Initialize appropriate collection based on mode
        switch mode {
        case .delete:
            state.selectedShiftIds = [firstId]
        case .add:
            state.selectedShiftIds.removeAll()
            state.selectedDates.removeAll()
        }

    case .exitSelectionMode:
        state.isInSelectionMode = false
        state.selectionMode = nil
        state.selectedShiftIds.removeAll()
        state.selectedDates.removeAll()

    case .toggleShiftSelection(let shiftId):
        if state.selectedShiftIds.contains(shiftId) {
            state.selectedShiftIds.remove(shiftId)
        } else {
            // Enforce max selection limit
            if state.selectedShiftIds.count < 100 {
                state.selectedShiftIds.insert(shiftId)
            } else {
                // Could dispatch an error here if needed
                state.currentError = .unknown("Maximum 100 items can be selected")
            }
        }

    case .selectAllVisible:
        // Select all shifts (filtered view is handled by computed properties in state)
        // Enforce max selection limit of 100
        let allIds = state.scheduledShifts.map { $0.id }
        state.selectedShiftIds = Set(allIds.prefix(100))

    case .clearSelection:
        state.selectedShiftIds.removeAll()
        state.selectedDates.removeAll()

    case .bulkDeleteRequested:
        state.showBulkDeleteConfirmation = true

    case .bulkDeleteConfirmed:
        state.isDeletingShift = true
        state.currentError = nil

    case .bulkDeleteCompleted(.success(let count)):
        state.isDeletingShift = false
        state.isInSelectionMode = false
        state.selectionMode = nil
        state.selectedShiftIds.removeAll()
        state.showBulkDeleteConfirmation = false
        state.successMessage = "\(count) shifts deleted"
        state.showSuccessToast = true

    case .bulkDeleteCompleted(.failure(let error)):
        state.isDeletingShift = false
        state.currentError = error
        // Keep selection and mode active for retry

    // MARK: - Bulk Add Actions

    case .bulkAddRequested:
        state.showBulkAddSheet = true

    case .bulkAddCancelled:
        // User cancelled bulk add - close sheet and reset state
        state.showBulkAddSheet = false
        state.isInSelectionMode = false
        state.selectionMode = nil
        state.selectedDates.removeAll()
        state.dateShiftAssignments.removeAll()
        state.bulkAddMode = .sameShiftForAll  // Reset to default mode
        state.lastAssignedShiftType = nil
        state.currentError = nil

    case .bulkAddConfirmed:
        state.isAddingToSelectedDates = true
        state.currentError = nil

    case .bulkAddCompleted(.success(let shifts)):
        state.isAddingToSelectedDates = false
        state.isInSelectionMode = false
        state.selectionMode = nil
        state.selectedShiftIds.removeAll()
        state.selectedDates.removeAll()  // Clear selected dates after successful bulk add
        state.showBulkAddSheet = false
        // Add newly created shifts to the schedule
        state.scheduledShifts.append(contentsOf: shifts)
        state.successMessage = "\(shifts.count) shifts added"
        state.showSuccessToast = true

    case .bulkAddCompleted(.failure(let error)):
        state.isAddingToSelectedDates = false
        state.currentError = error
        // Keep selection and mode active for retry

    case .toggleDateSelection(let date):
        let normalizedDate = Calendar.current.startOfDay(for: date)
        if state.selectedDates.contains(where: { Calendar.current.isDate($0, inSameDayAs: normalizedDate) }) {
            state.selectedDates = Set(state.selectedDates.filter { !Calendar.current.isDate($0, inSameDayAs: normalizedDate) })
        } else {
            state.selectedDates.insert(normalizedDate)
        }

    case .clearSelectedDates:
        state.selectedDates.removeAll()

    // MARK: - Bulk Add Mode Actions

    case .bulkAddModeChanged(let newMode):
        state.bulkAddMode = newMode
        // Clear assignments when switching modes
        state.dateShiftAssignments.removeAll()
        state.lastAssignedShiftType = nil

    case .assignShiftToDate(let date, let shiftType):
        let normalizedDate = Calendar.current.startOfDay(for: date)
        state.dateShiftAssignments[normalizedDate] = shiftType
        state.lastAssignedShiftType = shiftType

    case .removeShiftAssignment(let date):
        let normalizedDate = Calendar.current.startOfDay(for: date)
        state.dateShiftAssignments.removeValue(forKey: normalizedDate)

    case .bulkAddDifferentShiftsConfirmed:
        state.isAddingToSelectedDates = true
        state.currentError = nil

    case .switchModeWarningConfirmed(let newMode):
        state.bulkAddMode = newMode
        state.dateShiftAssignments.removeAll()
        state.lastAssignedShiftType = nil

    // MARK: - Sick Day Actions

    case .markShiftAsSick(_, _):
        state.isLoading = true

    case .unmarkShiftAsSick(_):
        state.isLoading = true

    case .shiftMarkedAsSick(.success):
        state.isLoading = false
        state.showMarkAsSickSheet = false
        state.successMessage = "Shift status updated"
        state.showSuccessToast = true

    case .shiftMarkedAsSick(.failure(let error)):
        state.isLoading = false
        state.currentError = error as? ScheduleError ?? .unknown(error.localizedDescription)

    case .markAsSickSheetToggled(let show):
        state.showMarkAsSickSheet = show
    }

    return state
}

// MARK: - Shift Types Reducer

/// Handles Shift Types feature state updates
func shiftTypesReducer(state: ShiftTypesState, action: ShiftTypesAction) -> ShiftTypesState {
    var state = state

    switch action {
    case .loadShiftTypes, .refreshShiftTypes:
        state.isLoading = true

    case .searchTextChanged(let text):
        state.searchText = text

    case .addButtonTapped:
        state.showAddEditSheet = true
        state.editingShiftType = nil

    case .editShiftType(let shiftType):
        state.showAddEditSheet = true
        state.editingShiftType = shiftType

    case .saveShiftType:
        state.isLoading = true
        state.errorMessage = nil

    case .shiftTypeSaved(.success):
        state.isLoading = false
        state.showAddEditSheet = false
        state.editingShiftType = nil
        state.errorMessage = nil

    case .shiftTypeSaved(.failure(let error)):
        state.isLoading = false
        state.errorMessage = "Failed to save shift type: \(error.localizedDescription)"
        state.showAddEditSheet = true  // Keep sheet open to allow retry

    case .deleteShiftType:
        state.isLoading = true

    case .shiftTypesLoaded(.success(let shiftTypes)):
        state.isLoading = false
        state.shiftTypes = shiftTypes
        state.errorMessage = nil

    case .shiftTypesLoaded(.failure(let error)):
        state.isLoading = false
        state.errorMessage = "Failed to load shift types: \(error.localizedDescription)"

    case .shiftTypeDeleted(.success):
        state.isLoading = false

    case .shiftTypeDeleted(.failure(let error)):
        state.isLoading = false
        state.errorMessage = "Failed to delete shift type: \(error.localizedDescription)"

    case .addEditSheetDismissed:
        state.showAddEditSheet = false
        state.editingShiftType = nil
    }

    return state
}

// MARK: - Locations Reducer

/// Handles Locations feature state updates
func locationsReducer(state: LocationsState, action: LocationsAction) -> LocationsState {
    var state = state

    switch action {
    case .loadLocations, .refreshLocations:
        state.isLoading = true

    case .searchTextChanged(let text):
        state.searchText = text

    case .addButtonTapped:
        state.showAddEditSheet = true
        state.editingLocation = nil

    case .editLocation(let location):
        state.showAddEditSheet = true
        state.editingLocation = location

    case .saveLocation:
        state.isLoading = true
        state.errorMessage = nil

    case .locationSaved(.success):
        state.isLoading = false
        state.showAddEditSheet = false
        state.editingLocation = nil
        state.errorMessage = nil

    case .locationSaved(.failure(let error)):
        state.isLoading = false
        state.errorMessage = "Failed to save location: \(error.localizedDescription)"
        state.showAddEditSheet = true  // Keep sheet open to allow retry

    case .deleteLocation:
        state.isLoading = true

    case .locationsLoaded(.success(let locations)):
        state.isLoading = false
        state.locations = locations
        state.errorMessage = nil

    case .locationsLoaded(.failure(let error)):
        state.isLoading = false
        state.errorMessage = "Failed to load locations: \(error.localizedDescription)"

    case .locationDeleted(.success):
        state.isLoading = false

    case .locationDeleted(.failure(let error)):
        state.isLoading = false
        state.errorMessage = "Failed to delete location: \(error.localizedDescription)"

    case .addEditSheetDismissed:
        state.showAddEditSheet = false
        state.editingLocation = nil
    }

    return state
}

// MARK: - Change Log Reducer

/// Handles Change Log feature state updates
func changeLogReducer(state: ChangeLogState, action: ChangeLogAction) -> ChangeLogState {
    var state = state

    switch action {
    case .loadChangeLogEntries:
        state.isLoading = true

    case .searchTextChanged(let text):
        state.searchText = text

    case .entriesLoaded(.success(let entries)):
        state.isLoading = false
        state.entries = entries
        state.errorMessage = nil

    case .entriesLoaded(.failure(let error)):
        state.isLoading = false
        state.errorMessage = "Failed to load entries: \(error.localizedDescription)"

    case .deleteEntry:
        state.isLoading = true

    case .entryDeleted(.success):
        state.isLoading = false

    case .entryDeleted(.failure(let error)):
        state.isLoading = false
        state.errorMessage = "Failed to delete entry: \(error.localizedDescription)"

    case .purgeOldEntries:
        state.isLoading = true

    case .purgeCompleted(.success):
        state.isLoading = false
        //state.toastMessage = .success("Old entries purged")

    case .purgeCompleted(.failure(let error)):
        state.isLoading = false
        state.errorMessage = "Failed to purge entries: \(error.localizedDescription)"
    }

    return state
}

// MARK: - Settings Reducer

/// Handles Settings feature state updates
func settingsReducer(state: SettingsState, action: SettingsAction) -> SettingsState {
    var state = state

    switch action {
    case .loadSettings:
        state.isLoading = true

    case .displayNameChanged:
        // displayName now managed at AppState level - no-op
        break

    case .retentionPolicyChanged(let policy):
        state.retentionPolicy = policy
        state.hasUnsavedChanges = true

    case .saveSettings:
        state.isLoading = true

    case .settingsSaved(.success):
        state.isLoading = false
        state.hasUnsavedChanges = false
        state.toastMessage = .success("Settings saved")

    case .settingsSaved(.failure(let error)):
        state.isLoading = false
        state.toastMessage = .error("Failed to save: \(error.localizedDescription)")

    case .settingsLoaded(.success(let profile)):
        state.isLoading = false
        state.retentionPolicy = profile.retentionPolicy

    case .settingsLoaded(.failure(let error)):
        state.isLoading = false
        state.errorMessage = "Failed to load settings: \(error.localizedDescription)"

    case .clearUnsavedChanges:
        state.hasUnsavedChanges = false

    // MARK: - Purge Statistics Cases

    case .loadPurgeStatistics:
        // Middleware will handle loading statistics
        break

    case .purgeStatisticsLoaded(let total, let toBePurged, let oldestDate):
        state.totalChangeLogEntries = total
        state.entriesToBePurged = toBePurged
        state.oldestEntryDate = oldestDate

    case .manualPurgeTriggered:
        state.isPurging = true

    case .manualPurgeCompleted(.success(let deletedCount)):
        state.isPurging = false
        state.lastPurgeDate = Date()
        state.toastMessage = .success("Purged \(deletedCount) entries successfully")

    case .manualPurgeCompleted(.failure(let error)):
        state.isPurging = false
        state.toastMessage = .error("Purge failed: \(error.localizedDescription)")

    case .autoPurgeToggled(let enabled):
        state.autoPurgeEnabled = enabled

    case .lastPurgeDateUpdated(let date):
        state.lastPurgeDate = date

    // MARK: - Calendar Resync Cases

    case .resyncCalendarEventsRequested:
        state.isResyncingCalendar = true
        state.errorMessage = nil

    case .resyncCalendarEventsCompleted(.success(let result)):
        state.isResyncingCalendar = false
        state.toastMessage = .success("Resynced \(result.updated) calendar event\(result.updated == 1 ? "" : "s")")

    case .resyncCalendarEventsCompleted(.failure(let error)):
        state.isResyncingCalendar = false
        state.errorMessage = "Calendar resync failed: \(error.localizedDescription)"
        state.toastMessage = .error("Calendar resync failed")

    case .toastMessageCleared:
        state.toastMessage = nil

    // MARK: - Shift Export Cases

    case .exportSheetToggled(let show):
        state.showExportSheet = show
        // Reset state when opening sheet
        if show {
            state.exportStartDate = nil
            state.exportEndDate = nil
            state.exportedSymbols = nil
            state.exportErrorMessage = nil
        }

    case .exportStartDateChanged(let date):
        state.exportStartDate = date
        state.exportErrorMessage = nil

    case .exportEndDateChanged(let date):
        state.exportEndDate = date
        state.exportErrorMessage = nil

    case .generateExport:
        state.isExporting = true
        state.exportErrorMessage = nil
        state.exportedSymbols = nil

    case .exportGenerated(let symbols):
        state.isExporting = false
        state.exportedSymbols = symbols
        state.exportErrorMessage = nil

    case .exportFailed(let error):
        state.isExporting = false
        state.exportErrorMessage = error
        state.exportedSymbols = nil

    case .copyToClipboard:
        // Middleware will handle clipboard operation
        state.toastMessage = .success("Copied to clipboard")

    case .resetExport:
        state.exportStartDate = nil
        state.exportEndDate = nil
        state.exportedSymbols = nil
        state.exportErrorMessage = nil
        state.isExporting = false
    }

    return state
}
