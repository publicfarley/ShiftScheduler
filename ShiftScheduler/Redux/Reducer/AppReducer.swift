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
    case .onAppear:
        // ReduxLogger.debug("App appeared")
        break

    case .tabSelected(let tab):
        // ReduxLogger.debug("Tab selected: \(String(describing: tab))")
        state.selectedTab = tab

    case .userProfileUpdated(let profile):
        // ReduxLogger.debug("User profile updated: \(profile.displayName)")
        state.userProfile = profile
    }

    return state
}

// MARK: - Today Reducer

/// Handles Today feature state updates
func todayReducer(state: TodayState, action: TodayAction) -> TodayState {
    var state = state

    switch action {
    case .task:
        state.isLoading = true

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

        state.todayShift = state.scheduledShifts.first { shift in
            Calendar.current.isDate(shift.date, inSameDayAs: today)
        }

        state.tomorrowShift = state.scheduledShifts.first { shift in
            Calendar.current.isDate(shift.date, inSameDayAs: tomorrow)
        }

        let weekStart = Calendar.current.date(
            from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        ) ?? today
        let weekEnd = Calendar.current.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart

        let thisWeekShifts = state.scheduledShifts.filter { shift in
            shift.date >= weekStart && shift.date < weekEnd
        }

        state.thisWeekShiftsCount = thisWeekShifts.count
        let completedCount = thisWeekShifts.filter { shift in
            shift.date < today
        }.count
        state.completedThisWeek = completedCount

    case .updateUndoRedoStates:
        // Undo/redo disabled for now (future implementation)
        state.canUndo = false
        state.canRedo = false
    }

    return state
}

// MARK: - Schedule Reducer

/// Handles Schedule feature state updates with complex undo/redo logic
func scheduleReducer(state: ScheduleState, action: ScheduleAction) -> ScheduleState {
    var state = state

    switch action {
    case .task:
        state.isLoading = true

    case .checkAuthorization:
        break // Handled by middleware

    case .authorizationChecked(let isAuthorized):
        state.isCalendarAuthorized = isAuthorized

    case .loadShifts:
        state.isLoading = true
        state.errorMessage = nil

    case .selectedDateChanged(let date):
        state.selectedDate = date
        state.searchText = ""

    case .searchTextChanged(let text):
        state.searchText = text

    case .addShiftButtonTapped:
        state.showAddShiftSheet = true

    case .deleteShift:
        state.isLoading = true

    case .shiftDeleted(.success):
        state.isLoading = false
        state.toastMessage = .success("Shift deleted")

    case .shiftDeleted(.failure(let error)):
        state.isLoading = false
        state.toastMessage = .error("Failed to delete shift: \(error.localizedDescription)")

    case .switchShiftTapped:
        break // UI handles sheet presentation

    case .performSwitchShift:
        state.isLoading = true

    case .shiftSwitched(.success(let operation)):
        state.isLoading = false
        state.toastMessage = .success("Shift switched successfully")
        state.undoStack.append(operation)
        state.redoStack.removeAll()

    case .shiftSwitched(.failure(let error)):
        state.isLoading = false
        state.toastMessage = .error("Failed to switch shift: \(error.localizedDescription)")

    case .shiftsLoaded(.success(let shifts)):
        state.isLoading = false
        state.scheduledShifts = shifts
        state.errorMessage = nil

    case .shiftsLoaded(.failure(let error)):
        state.isLoading = false
        state.errorMessage = error.localizedDescription

    case .stacksRestored(.success(let stacks)):
        state.undoStack = stacks.undo
        state.redoStack = stacks.redo

    case .stacksRestored(.failure(let error)):
        state.errorMessage = "Failed to restore undo/redo: \(error.localizedDescription)"

    case .undo:
        guard !state.undoStack.isEmpty else {
            state.toastMessage = .error("No operation to undo")
            return state
        }
        state.isLoading = true

    case .undoCompleted(.success):
        state.isLoading = false
        if !state.undoStack.isEmpty {
            let operation = state.undoStack.removeLast()
            state.redoStack.append(operation)
        }
        state.toastMessage = .success("Undo successful")

    case .undoCompleted(.failure(let error)):
        state.isLoading = false
        state.toastMessage = .error("Undo failed: \(error.localizedDescription)")

    case .redo:
        guard !state.redoStack.isEmpty else {
            state.toastMessage = .error("No operation to redo")
            return state
        }
        state.isLoading = true

    case .redoCompleted(.success):
        state.isLoading = false
        if !state.redoStack.isEmpty {
            let operation = state.redoStack.removeLast()
            state.undoStack.append(operation)
        }
        state.toastMessage = .success("Redo successful")

    case .redoCompleted(.failure(let error)):
        state.isLoading = false
        state.toastMessage = .error("Redo failed: \(error.localizedDescription)")

    // MARK: - Filter Actions

    case .filterSheetToggled(let show):
        state.showFilterSheet = show

    case .filterDateRangeChanged(let startDate, let endDate):
        state.filterDateRangeStart = startDate
        state.filterDateRangeEnd = endDate
        let startStr = startDate?.formatted(date: .abbreviated, time: .omitted) ?? "nil"
        let endStr = endDate?.formatted(date: .abbreviated, time: .omitted) ?? "nil"
        // ReduxLogger.debug("Date range filter applied: \(startStr) to \(endStr)")

    case .filterLocationChanged(let location):
        state.filterSelectedLocation = location
        // ReduxLogger.debug("Location filter set to: \(location?.name ?? "All Locations") (id: \(location?.id.uuidString.prefix(8) ?? "none"))")

    case .filterShiftTypeChanged(let shiftType):
        state.filterSelectedShiftType = shiftType
        // ReduxLogger.debug("Shift type filter set to: \(shiftType?.title ?? "All Shift Types") (symbol: \(shiftType?.symbol ?? "none"))")

    case .clearFilters:
        state.filterDateRangeStart = nil
        state.filterDateRangeEnd = nil
        state.filterSelectedLocation = nil
        state.filterSelectedShiftType = nil
        state.searchText = ""
        state.showFilterSheet = false
        // ReduxLogger.debug("All filters cleared")
    }

    return state
}

// MARK: - Shift Types Reducer

/// Handles Shift Types feature state updates
func shiftTypesReducer(state: ShiftTypesState, action: ShiftTypesAction) -> ShiftTypesState {
    var state = state

    switch action {
    case .task, .refreshShiftTypes:
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
    case .task, .refreshLocations:
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
    case .task:
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
        state.toastMessage = .success("Old entries purged")

    case .purgeCompleted(.failure(let error)):
        state.isLoading = false
        state.toastMessage = .error("Purge failed: \(error.localizedDescription)")
    }

    return state
}

// MARK: - Settings Reducer

/// Handles Settings feature state updates
func settingsReducer(state: SettingsState, action: SettingsAction) -> SettingsState {
    var state = state

    switch action {
    case .task:
        state.isLoading = true

    case .displayNameChanged(let name):
        state.displayName = name
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
        state.userId = profile.userId
        state.displayName = profile.displayName

    case .settingsLoaded(.failure(let error)):
        state.isLoading = false
        state.errorMessage = "Failed to load settings: \(error.localizedDescription)"

    case .clearUnsavedChanges:
        state.hasUnsavedChanges = false
    }

    return state
}
