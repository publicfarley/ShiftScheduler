import Foundation

/// Root application state - Single source of truth
/// Contains all feature states and global application state
struct AppState: Equatable {
    /// Currently selected tab
    var selectedTab: Tab = .today

    /// User profile information
    var userProfile: UserProfile = UserProfile(userId: UUID(), displayName: "")

    /// Whether user has configured their name (onboarding gate)
    var isNameConfigured: Bool = false

    /// Whether user profile has been loaded from persistence (prevents modal flash)
    var isProfileLoaded: Bool = false

    /// Calendar authorization status
    var isCalendarAuthorized: Bool = false

    /// Whether calendar authorization has been verified on startup
    var isCalendarAuthorizationVerified: Bool = false

    /// Whether app initialization is complete (locations and shift types loaded)
    var isInitializationComplete: Bool = false

    /// Error message if initialization fails (prevents app startup)
    var initializationError: String? = nil

    // MARK: - Feature States

    /// Today feature state
    var today: TodayState = TodayState()

    /// Schedule feature state
    var schedule: ScheduleState = ScheduleState()

    /// Shift types feature state
    var shiftTypes: ShiftTypesState = ShiftTypesState()

    /// Locations feature state
    var locations: LocationsState = LocationsState()

    /// Change log feature state
    var changeLog: ChangeLogState = ChangeLogState()

    /// Settings feature state
    var settings: SettingsState = SettingsState()
}

// MARK: - Today State

/// State for the Today feature (daily shift overview)
struct TodayState: Equatable {
    /// All scheduled shifts loaded from calendar
    var scheduledShifts: [ScheduledShift] = []

    /// Loading state
    var isLoading: Bool = false

    /// Error message if any
    var errorMessage: String? = nil

    /// Sheet presentation for shift switching
    var showSwitchShiftSheet: Bool = false

    /// Toast notification
    var toastMessage: ToastMessage? = nil

    /// Cached today's shift
    var todayShift: ScheduledShift? = nil

    /// Cached tomorrow's shift
    var tomorrowShift: ScheduledShift? = nil

    /// Count of shifts this week
    var thisWeekShiftsCount: Int = 0

    /// Count of completed shifts this week
    var completedThisWeek: Int = 0

    /// Undo availability state
    var canUndo: Bool = false

    /// Redo availability state
    var canRedo: Bool = false

    /// Selected shift for switching operations
    var selectedShift: ScheduledShift? = nil

    /// Sheet presentation for editing shift notes
    var showEditNotesSheet: Bool = false

    /// Notes being edited for today's shift
    var quickActionsNotes: String = ""

    /// Shift awaiting deletion confirmation
    var deleteShiftConfirmationShift: ScheduledShift? = nil

    /// Sheet presentation for adding a new shift
    var showAddShiftSheet: Bool = false

    /// Current error for Add Shift operations
    var currentError: ScheduleError? = nil
}

// MARK: - Schedule State

/// State for the Schedule feature (calendar view with shift management)
struct ScheduleState: Equatable {
    /// All scheduled shifts for the current month
    var scheduledShifts: [ScheduledShift] = []

    /// The currently selected date (defaults to today at start of day)
    var selectedDate: Date = Calendar.current.startOfDay(for: Date())

    /// General loading state
    var isLoading: Bool = false

    /// Calendar authorization state
    var isCalendarAuthorized: Bool = false

    /// Error message (legacy string-based)
    var errorMessage: String? = nil

    /// Typed error for better handling
    var currentError: ScheduleError? = nil

    /// Search/filter text
    var searchText: String = ""

    /// Toast notification
    var toastMessage: ToastMessage? = nil

    /// Sheet presentation for adding a new shift
    var showAddShiftSheet: Bool = false

    /// Undo stack for shift switching operations
    var undoStack: [ChangeLogEntry] = []

    /// Redo stack for shift switching operations
    var redoStack: [ChangeLogEntry] = []

    // MARK: - Granular Loading States

    /// Loading state for adding a shift
    var isAddingShift: Bool = false

    /// Loading state for deleting a shift
    var isDeletingShift: Bool = false

    /// Loading state for switching a shift
    var isSwitchingShift: Bool = false

    /// Loading state for restoring undo/redo stacks
    var isRestoringStacks: Bool = false

    // MARK: - Success Feedback

    /// Success message to display
    var successMessage: String? = nil

    /// Whether to show success toast
    var showSuccessToast: Bool = false

    // MARK: - Detail View State

    /// Selected shift ID for detail view (used to track which shift is being viewed)
    var selectedShiftId: UUID? = nil

    /// Selected shift for detail view
    var selectedShiftForDetail: ScheduledShift? = nil

    /// Whether detail view is shown
    var showShiftDetail: Bool = false

    /// Whether switch shift sheet is shown
    var showSwitchShiftSheet: Bool = false

    /// Shift to confirm deletion for
    var deleteConfirmationShift: ScheduledShift? = nil

    /// Whether stacks have been restored from persistence
    var stacksRestored: Bool = false

    // MARK: - Filter State

    /// Start date for date range filtering (nil = no filter)
    var filterDateRangeStart: Date? = nil

    /// End date for date range filtering (nil = no filter)
    var filterDateRangeEnd: Date? = nil

    /// Selected location filter (nil = no location filter)
    var filterSelectedLocation: Location? = nil

    /// Selected shift type filter (nil = no shift type filter)
    var filterSelectedShiftType: ShiftType? = nil

    /// Whether the filter sheet is visible
    var showFilterSheet: Bool = false

    // MARK: - Overlap Resolution State

    /// Whether overlap resolution dialog is shown
    var showOverlapResolution: Bool = false

    /// Date with overlapping shifts
    var overlapDate: Date? = nil

    /// Shifts that overlap on the same date
    var overlappingShifts: [ScheduledShift] = []

    // MARK: - Sliding Window State

    /// The start date of the currently loaded shift data range
    var loadedRangeStart: Date? = nil

    /// The end date of the currently loaded shift data range
    var loadedRangeEnd: Date? = nil

    /// The month currently being displayed in the calendar view
    var displayedMonth: Date = Calendar.current.startOfDay(for: Date())

    /// Loading state for fetching additional shifts (during range fault)
    var isLoadingAdditionalShifts: Bool = false

    /// Trigger for scrolling to a specific date (set when jump-to-date is requested)
    var scrollToDateTrigger: Date? = nil

    // MARK: - Multi-Select State

    /// IDs of shifts currently selected for bulk operations
    var selectedShiftIds: Set<UUID> = []

    /// Whether the view is in multi-select mode
    var isInSelectionMode: Bool = false

    /// The current mode for multi-select (delete or add)
    var selectionMode: SelectionMode? = nil

    /// Whether to show bulk delete confirmation dialog
    var showBulkDeleteConfirmation: Bool = false

    /// Whether to show bulk add sheet for shift type selection
    var showBulkAddSheet: Bool = false

    /// Whether currently performing bulk add operation
    var isAddingToSelectedDates: Bool = false

    /// Dates selected for bulk add operations (used when in .add selection mode)
    var selectedDates: Set<Date> = []

    // MARK: - Bulk Add Mode State

    /// Mode for bulk add operations
    var bulkAddMode: BulkAddMode = .sameShiftForAll

    /// Date-to-ShiftType assignments for "different shift per date" mode
    var dateShiftAssignments: [Date: ShiftType] = [:]

    /// Last assigned shift type (used for "Repeat Last" button)
    var lastAssignedShiftType: ShiftType? = nil

    // MARK: - Computed Properties

    /// Undo/redo button states
    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    /// Filtered shifts based on all active filters and search text
    var filteredShifts: [ScheduledShift] {
        var result = scheduledShifts

        // Apply date range filter
        if let startDate = filterDateRangeStart, let endDate = filterDateRangeEnd {
            result = result.filter { shift in
                shift.date >= startDate && shift.date <= endDate
            }
        } else {
            // If no date range filter, use selected date
            // Use occursOn helper to include multi-day shifts
            result = result.filter { shift in
                shift.occursOn(date: selectedDate)
            }
        }

        // Apply location filter
        if let location = filterSelectedLocation {
            result = result.filter { shift in
                shift.shiftType?.location.id == location.id
            }
        }

        // Apply shift type filter
        if let shiftType = filterSelectedShiftType {
            result = result.filter { shift in
                shift.shiftType?.id == shiftType.id
            }
        }

        // Apply search text filter
        if !searchText.isEmpty {
            result = result.filter { shift in
                shift.shiftType?.title.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }

        return result
    }

    /// Shifts for the currently selected date
    /// Includes multi-day shifts that occur on the selected date
    var shiftsForSelectedDate: [ScheduledShift] {
        scheduledShifts.filter { shift in
            shift.occursOn(date: selectedDate)
        }
    }

    /// Whether any filters are active
    var hasActiveFilters: Bool {
        filterDateRangeStart != nil ||
        filterDateRangeEnd != nil ||
        filterSelectedLocation != nil ||
        filterSelectedShiftType != nil ||
        !searchText.isEmpty
    }

    /// Selected shifts based on selectedShiftIds
    var selectedShifts: [ScheduledShift] {
        let selectedIds = selectedShiftIds
        return scheduledShifts.filter { selectedIds.contains($0.id) }
    }

    /// Count of currently selected items (shifts or dates based on mode)
    var selectionCount: Int {
        switch selectionMode {
        case .delete:
            return selectedShiftIds.count
        case .add:
            return selectedDates.count
        case .none:
            return 0
        }
    }

    /// Whether user can delete selected shifts (must be in delete mode with selection)
    var canDeleteSelectedShifts: Bool {
        selectionMode == .delete && !selectedShiftIds.isEmpty
    }

    /// Whether user can add to selected dates (must be in add mode with selection)
    var canAddToSelectedDates: Bool {
        selectionMode == .add && !selectedDates.isEmpty
    }
}

// MARK: - SelectionMode Enum

/// Enum to track what mode multi-select is in
enum SelectionMode: Equatable {
    case delete  // Selecting existing shifts to delete
    case add     // Selecting empty dates to add shifts
}

// MARK: - BulkAddMode Enum

/// Enum to track mode for bulk add operations
enum BulkAddMode: Equatable, Sendable {
    case sameShiftForAll       // Apply same shift type to all selected dates
    case differentShiftPerDate // Assign different shift type per date
}

// MARK: - Shift Types State

/// State for the Shift Types feature (CRUD for shift templates)
struct ShiftTypesState: Equatable {
    /// All shift types loaded from persistence
    var shiftTypes: [ShiftType] = []

    /// Search text for filtering shift types
    var searchText: String = ""

    /// Loading state
    var isLoading: Bool = false

    /// Error message if any
    var errorMessage: String? = nil

    /// Presented add/edit sheet
    var showAddEditSheet: Bool = false

    /// Shift type being edited (nil for add mode)
    var editingShiftType: ShiftType? = nil

    // MARK: - Computed Properties

    /// Filtered shift types based on search text
    var filteredShiftTypes: [ShiftType] {
        if searchText.isEmpty {
            return shiftTypes
        }
        return shiftTypes.filter { shiftType in
            shiftType.title.localizedCaseInsensitiveContains(searchText) ||
            shiftType.symbol.localizedCaseInsensitiveContains(searchText) ||
            shiftType.location.name.localizedCaseInsensitiveContains(searchText)
        }
    }
}

// MARK: - Locations State

/// State for the Locations feature (location CRUD)
struct LocationsState: Equatable {
    /// All locations loaded from persistence
    var locations: [Location] = []

    /// Search text for filtering locations
    var searchText: String = ""

    /// Loading state
    var isLoading: Bool = false

    /// Error message if any
    var errorMessage: String? = nil

    /// Presented add/edit sheet
    var showAddEditSheet: Bool = false

    /// Location being edited (nil for add mode)
    var editingLocation: Location? = nil

    // MARK: - Computed Properties

    /// Filtered locations based on search text
    var filteredLocations: [Location] {
        if searchText.isEmpty {
            return locations
        }
        return locations.filter { location in
            location.name.localizedCaseInsensitiveContains(searchText) ||
            location.address.localizedCaseInsensitiveContains(searchText)
        }
    }
}

// MARK: - Change Log State

/// State for the Change Log feature (history of shift operations)
struct ChangeLogState: Equatable {
    /// All change log entries
    var entries: [ChangeLogEntry] = []

    /// Loading state
    var isLoading: Bool = false

    /// Error message if any
    var errorMessage: String? = nil

    /// Search/filter text
    var searchText: String = ""

    /// Toast notification
    var toastMessage: ToastMessage? = nil

    // MARK: - Computed Properties

    /// Filtered entries based on search text, sorted newest first
    var filteredEntries: [ChangeLogEntry] {
        let filtered = searchText.isEmpty ? entries : entries.filter { entry in
            entry.userDisplayName.localizedCaseInsensitiveContains(searchText) ||
            entry.changeType.displayName.localizedCaseInsensitiveContains(searchText)
        }
        // Sort by timestamp in descending order (newest first)
        return filtered.sorted { $0.timestamp > $1.timestamp }
    }
}

// MARK: - Settings State

/// State for the Settings feature (user preferences)
struct SettingsState: Equatable {
    /// Change log retention policy
    var retentionPolicy: ChangeLogRetentionPolicy = .forever

    // MARK: - Purge Statistics

    /// Total number of change log entries
    var totalChangeLogEntries: Int = 0

    /// Number of entries that would be purged with current policy
    var entriesToBePurged: Int = 0

    /// Date of oldest change log entry
    var oldestEntryDate: Date? = nil

    /// Date of last purge operation
    var lastPurgeDate: Date? = nil

    /// Whether automatic purge on app launch is enabled
    var autoPurgeEnabled: Bool = true

    /// Whether a purge operation is currently in progress
    var isPurging: Bool = false

    /// Whether a calendar resync operation is currently in progress
    var isResyncingCalendar: Bool = false

    /// Loading state
    var isLoading: Bool = false

    /// Error message if any
    var errorMessage: String? = nil

    /// Toast notification
    var toastMessage: ToastMessage? = nil

    /// Whether changes have been made but not saved
    var hasUnsavedChanges: Bool = false
}
