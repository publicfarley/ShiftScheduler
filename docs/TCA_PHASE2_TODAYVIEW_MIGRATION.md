# TCA Phase 2: TodayView Migration Plan

## Overview
TodayView is a complex 2,209-line view that serves as the main dashboard for users to see their daily shift information. It requires significant refactoring to migrate to TCA.

## Current State (Pre-Migration)

### State Variables (Lines 63-81)
- `calendarService: CalendarService` - dependency singleton
- `currentDayManager: CurrentDayManager` - dependency singleton
- `scheduledShifts: [ScheduledShift]` - shift data
- `isLoading: Bool` - loading indicator
- `errorMessage: String?` - error handling
- `showSwitchShiftSheet: Bool` - sheet presentation
- `shiftSwitchService: ShiftSwitchService?` - undo/redo service
- `canUndo: Bool` - undo button state
- `canRedo: Bool` - redo button state
- `toastMessage: ToastMessage?` - toast notifications
- `todayShift: ScheduledShift?` - cached today's shift
- `tomorrowShift: ScheduledShift?` - cached tomorrow's shift
- `thisWeekShiftsCount: Int` - cached week stat
- `completedThisWeek: Int` - cached week stat

### Key Functions (Business Logic to Extract)
1. `updateCachedShifts()` - Computes derived state from scheduledShifts
2. `loadShifts()` - Async operation to fetch shifts from calendar
3. `initializeShiftSwitchService()` - Setup undo/redo service
4. `updateUndoRedoStates()` - Queries service for undo/redo availability
5. `handleShiftSwitch()` - Performs shift switch with undo support
6. `handleUndo()` - Executes undo operation
7. `handleRedo()` - Executes redo operation

### UI Components (Can Remain in View)
- `ShiftStatus` enum - Presentation state
- `StatusBadge` - Visual component
- `EnhancedTodayShiftCard` - Card component
- `EnhancedStatusBadge` - Status visual
- `TodayShiftCard` - Card component
- `QuickActionButton` - Button component
- `EnhancedQuickActionButton` - Enhanced button
- `EnhancedTomorrowShiftCard` - Card component
- `TomorrowShiftCard` - Card component
- `WeekStatView` - Stats component
- `EnhancedWeekStatView` - Enhanced stats
- `OptimizedTodayShiftCard` - Optimized card

## Migration Strategy

### Phase 2A: Create TodayFeature (TCA Reducer)
This feature will manage all application state and logic for TodayView.

**File**: `ShiftScheduler/Features/TodayFeature.swift`

#### State Structure
```swift
@ObservableState
struct State: Equatable {
    var scheduledShifts: [ScheduledShift] = []
    var isLoading: Bool = false
    var errorMessage: String?
    var showSwitchShiftSheet: Bool = false
    var toastMessage: ToastMessage?

    // Cached computations
    var todayShift: ScheduledShift?
    var tomorrowShift: ScheduledShift?
    var thisWeekShiftsCount: Int = 0
    var completedThisWeek: Int = 0

    // Undo/Redo state
    var canUndo: Bool = false
    var canRedo: Bool = false
}
```

#### Action Types
- `task` - Load initial data
- `loadShifts` - Fetch shifts from calendar
- `shiftsLoaded(TaskResult<[ScheduledShift]>)` - Handle shift fetch result
- `switchShift(ScheduledShift, ShiftType, String?)` - Switch a shift
- `shiftSwitched(Result<Void, Error>)` - Handle switch result
- `undo` - Perform undo
- `redo` - Perform redo
- `undoRedoStateUpdated(canUndo: Bool, canRedo: Bool)` - Update button states
- `toastMessageCleared` - Clear toast
- `sheetDismissed` - Handle sheet dismissal

#### Dependencies
- `calendarClient` - Fetch shifts from calendar
- `shiftSwitchService` - Perform shift operations with undo/redo
- `mainQueue` - Main thread dispatch
- `continuousClock` - Timing for retries

### Phase 2B: Update TodayView (View Migration)
Refactor TodayView to use TodayFeature store.

**Key Changes**:
1. Add `@Bindable var store: StoreOf<TodayFeature>`
2. Remove all `@State` variables (moved to feature)
3. Update all actions to use `store.send()`
4. Use computed properties from store state
5. Handle async operations through store effects
6. Bind form inputs to store state

### Phase 2C: Create Presentation Components (Optional)
Extract pure presentation logic into smaller, more testable components.

**Suggested Components**:
- `TodayShiftCard(shift: ScheduledShift)` - Today's shift display
- `TomorrowShiftCard(shift: ScheduledShift?)` - Tomorrow's shift display
- `WeekStatsCard(count: Int, completed: Int)` - Week statistics
- `QuickActionsView(shift: ScheduledShift?, onSwitch: () -> Void)` - Action buttons

## Implementation Steps

### Step 1: Create CalendarClient Extension
Add methods to CalendarClient (if not already present):
- `fetchTodaysShifts() async throws -> [ShiftData]`
- `fetchTomorrowsShifts() async throws -> [ShiftData]`
- `fetchCurrentWeekShifts() async throws -> [ShiftData]`

### Step 2: Implement ShiftSwitchService as TCA Dependency
Create `ShiftSwitchClient` dependency:
```swift
@DependencyClient
struct ShiftSwitchClient: Sendable {
    var switchShift: @Sendable (String, Date, ShiftType, ShiftType, String?) async throws -> Void
    var canUndo: @Sendable () async -> Bool
    var canRedo: @Sendable () async -> Bool
    var undo: @Sendable () async throws -> Void
    var redo: @Sendable () async throws -> Void
}
```

### Step 3: Create TodayFeature
Implement the full feature with:
- State management
- Action handling
- Async effects for shifts and undo/redo
- Error handling and toasts

### Step 4: Migrate TodayView
Replace view logic with store bindings:
- Initialize store with `.task { await store.send(.task).finish() }`
- Use `store.state` properties instead of `@State`
- Send actions for user interactions
- Handle sheet presentation with `$store.scope()`

### Step 5: Test
- Unit test TodayFeature reducer
- Integration test with mock calendar service
- UI test with preview store

## Dependencies to Create/Update

### Existing Dependencies to Update
- `CalendarClient` - May need additional fetch methods
- `PersistenceClient` - Already set up

### New Dependencies to Create
- `ShiftSwitchClient` - For undo/redo operations

## Estimated Effort
- **Create TodayFeature**: 4-6 hours
- **Migrate TodayView**: 2-3 hours
- **Testing**: 2-3 hours
- **Total**: 8-12 hours

## Risks & Mitigations
1. **Complex state management** - Break into smaller features if needed
2. **Performance with large shift lists** - Use filtering, pagination, or computed properties
3. **Undo/redo complexity** - Keep ShiftSwitchService pattern, just wrap in TCA
4. **Breaking existing functionality** - Comprehensive testing during migration

## Success Criteria
- ✅ TodayView displays correctly with TCA store
- ✅ All shift operations work (switch, undo, redo)
- ✅ Toast notifications display properly
- ✅ Sheet presentation works
- ✅ Error handling matches original behavior
- ✅ Performance is not degraded
- ✅ Unit tests pass
- ✅ Preview works

## Next Steps
1. Create CalendarClient extensions for shift fetching
2. Create ShiftSwitchClient dependency
3. Implement TodayFeature
4. Migrate TodayView
5. Write comprehensive tests
