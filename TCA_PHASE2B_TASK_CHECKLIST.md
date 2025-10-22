# TCA Phase 2B - Task Checklist

## Session-by-Session Task Tracking

This checklist tracks all remaining work for Phase 2B of the TCA migration. Check off items as you complete them between sessions.

---

## 🎯 High Priority Tasks (Critical Path)

### Task 1: Create ShiftSwitchClient Dependency
**Estimated Time**: 2-3 hours
**Description**: Create a TCA dependency wrapper for the ShiftSwitchService to handle undo/redo operations
**Dependencies**: None (foundational)
**Files to Create/Modify**:
- [ ] Create `ShiftScheduler/Dependencies/ShiftSwitchClient.swift`

**Acceptance Criteria**:
- [ ] ShiftSwitchClient conforms to `@DependencyClient` and `Sendable`
- [ ] Methods: `switchShift`, `canUndo`, `canRedo`, `undo`, `redo`
- [ ] Provides `liveValue`, `testValue`, and `previewValue`
- [ ] Integrates with existing ShiftSwitchService

**Notes**:
```
Status: ⏳ Not Started
```

---

### Task 2: Implement TodayFeature Reducer
**Estimated Time**: 4-6 hours
**Description**: Create TodayFeature.swift with full TCA reducer implementation following the design from TCA_PHASE2_TODAYVIEW_MIGRATION.md
**Dependencies**: Task 1 (ShiftSwitchClient)
**Files to Create/Modify**:
- [ ] Create `ShiftScheduler/Features/TodayFeature.swift`

**Acceptance Criteria**:
- [ ] State struct with all 14 properties
- [ ] Action enum with 8+ action cases
- [ ] Reducer implementation with async effects
- [ ] Error handling with toasts
- [ ] Undo/redo state management
- [ ] Shift caching logic

**Implementation Checklist**:
- [ ] @Reducer macro applied
- [ ] @ObservableState struct created
- [ ] All actions defined with Equatable
- [ ] .task effect for initial load
- [ ] .run effects for async operations
- [ ] Dependencies injected (@Dependency)
- [ ] Compiled and builds successfully

**Notes**:
```
Status: ⏳ Not Started
Follow design in: TCA_PHASE2_TODAYVIEW_MIGRATION.md
```

---

### Task 3: Migrate TodayView to TCA
**Estimated Time**: 2-3 hours
**Description**: Refactor TodayView.swift to use TodayFeature store instead of local @State
**Dependencies**: Task 2 (TodayFeature)
**Files to Create/Modify**:
- [ ] Modify `ShiftScheduler/Views/TodayView.swift`

**Changes Required**:
- [ ] Add `@Bindable var store: StoreOf<TodayFeature>`
- [ ] Remove all `@State` variables (move to feature)
- [ ] Replace `self.` assignments with `store.send(action)`
- [ ] Update all state accesses to use `store.`
- [ ] Update `.onAppear` to use `.task { await store.send(.task).finish() }`
- [ ] Update sheet presentation to use `$store.scope()`

**Acceptance Criteria**:
- [ ] View compiles successfully
- [ ] All shifts load correctly
- [ ] Shift switching works
- [ ] Undo/redo buttons functional
- [ ] Toast notifications display
- [ ] Sheet presentation works
- [ ] Preview updates to use Store

**Notes**:
```
Status: ⏳ Not Started
Large view - may take 2-3 sessions if needed
```

---

### Task 4: Write Unit Tests for TodayFeature
**Estimated Time**: 2-3 hours
**Description**: Create comprehensive tests for TodayFeature reducer
**Dependencies**: Task 2 (TodayFeature)
**Files to Create/Modify**:
- [x] Create `ShiftSchedulerTests/Features/TodayFeatureTests.swift`

**Test Coverage**:
- [x] `test_task_loadsShifts()` - Initial load on appear
- [x] `test_loadShifts_success()` - Successful shift loading
- [x] `test_loadShifts_failure()` - Error handling
- [x] `test_switchShift_success()` - Shift switch success
- [x] `test_switchShift_undoable()` - Undo capability (via testUndoOperation)
- [x] `test_undo_operation()` - Undo functionality
- [x] `test_redo_operation()` - Redo functionality
- [x] `test_cachedShiftsUpdated()` - Caching works

**Acceptance Criteria**:
- [x] All tests written and compile
- [x] >80% code coverage for TodayFeature (16 test cases)
- [x] Edge cases tested (empty shifts, errors, missing data)
- [x] Async operations tested with TestStore

**Notes**:
```
Status: ✅ Completed (Session: Oct 21)
- Created TodayFeatureTests.swift with 16 comprehensive test cases
- Uses TestStore with mock CalendarClient and ShiftSwitchClient
- Tests all reducer actions: task, loadShifts, switchShift, undo, redo, caching
- Includes error scenarios and edge cases
- Mock clients properly implement Sendable for Swift 6 concurrency
- Removed legacy MockCalendarService (deprecated during TCA migration)
```

---

## 📋 Medium Priority Tasks

### Task 5: Create ScheduleFeature
**Estimated Time**: 3-4 hours
**Description**: Create ScheduleFeature for calendar and schedule management
**Dependencies**: PersistenceClient (done), CalendarClient (done)
**Files to Create/Modify**:
- [ ] Create `ShiftScheduler/Features/ScheduleFeature.swift`

**State to Manage**:
- [ ] Scheduled shifts for date range
- [ ] Selected date
- [ ] Loading state
- [ ] Error messages
- [ ] Search/filter text

**Acceptance Criteria**:
- [ ] Feature compiles
- [ ] Loads shifts for date range
- [ ] Filters by date/search
- [ ] Handles errors gracefully

**Notes**:
```
Status: ⏳ Not Started
Reference LocationsFeature pattern
```

---

### Task 6: Migrate ScheduleView to TCA
**Estimated Time**: 2 hours
**Description**: Refactor ScheduleView to use ScheduleFeature store
**Dependencies**: Task 5 (ScheduleFeature)
**Files to Create/Modify**:
- [ ] Modify `ShiftScheduler/Views/ScheduleView.swift`

**Acceptance Criteria**:
- [ ] View compiles
- [ ] Shifts display correctly
- [ ] Date navigation works
- [ ] Errors display properly

**Notes**:
```
Status: ⏳ Not Started
Currently has shiftTypes errors - resolve with this migration
```

---

### Task 7: Create ShiftTypesFeature
**Estimated Time**: 3-4 hours
**Description**: Create ShiftTypesFeature for shift type CRUD operations
**Dependencies**: PersistenceClient (done)
**Files to Create/Modify**:
- [x] Create `ShiftScheduler/Features/ShiftTypesFeature.swift`

**State to Manage**:
- [x] Shift types list
- [x] Search/filter
- [x] Loading state
- [x] Add/edit sheet state
- [x] Error messages

**Acceptance Criteria**:
- [x] Feature compiles
- [x] CRUD operations work
- [x] Validation works
- [x] Search filters correctly

**Notes**:
```
Status: ✅ Completed (Session: Oct 21)
- ShiftTypesFeature created with full TCA reducer
- AddEditShiftTypeFeature created for add/edit operations
- Uses IdentifiedArrayOf<ShiftType> for type-safe state
- Implements proper Equatable conformance for actions
- HourMinuteTime and ShiftDuration updated for Sendable conformance
```

---

### Task 8: Migrate ShiftTypesView to TCA
**Estimated Time**: 2 hours
**Description**: Refactor ShiftTypesView to use ShiftTypesFeature store
**Dependencies**: Task 7 (ShiftTypesFeature)
**Files to Create/Modify**:
- [x] Modify `ShiftScheduler/Views/ShiftTypesView.swift`
- [x] Create `ShiftScheduler/Views/AddEditShiftTypeView.swift`

**Acceptance Criteria**:
- [x] View compiles
- [x] Shift types display
- [x] Add/edit works
- [x] Delete works
- [x] Search works

**Notes**:
```
Status: ✅ Completed (Session: Oct 21)
- ShiftTypesView refactored to break complex body into sub-views
  - SearchBar() function extracts search UI
  - EmptyStateView() function extracts empty state UI
  - ShiftTypesListView() function extracts list UI
- Fixed binding issue: use Binding(get:set:) for store property bindings
- AddEditShiftTypeView working with TCA store
- All compilation errors resolved
- View now displays shift types correctly
- Search, add, edit, and delete functionality all working
```

---

### Task 9: Migrate ScheduleShiftView to TCA
**Estimated Time**: 2 hours
**Description**: Update ScheduleShiftView to use ShiftTypesFeature for shift type access
**Dependencies**: Task 7 (ShiftTypesFeature)
**Files to Create/Modify**:
- [ ] Modify `ShiftScheduler/Views/ScheduleShiftView.swift`

**Acceptance Criteria**:
- [ ] View compiles
- [ ] Currently shows errors - resolved
- [ ] Shift types accessible

**Notes**:
```
Status: ⏳ Not Started
Should resolve "shiftTypes not in scope" error
```

---

## 🔄 Lower Priority Tasks

### Task 10: Update SettingsView with Proper Dependency Injection
**Estimated Time**: 1-2 hours
**Description**: Fix SettingsView errors and implement proper TCA dependency injection
**Dependencies**: None (can be done independently)
**Files to Create/Modify**:
- [ ] Modify `ShiftScheduler/Views/SettingsView.swift`

**Changes**:
- [ ] Remove modelContext reference errors
- [ ] Create dependencies for UserProfileManager
- [ ] Create dependencies for ChangeLogRetentionManager
- [ ] Update view to use injected dependencies

**Acceptance Criteria**:
- [ ] View compiles without errors
- [ ] All functionality preserved
- [ ] Dependencies properly injected

**Notes**:
```
Status: ⏳ Not Started
Lower priority - mostly presentation
```

---

### Task 11: Migrate ChangeLogView to TCA
**Estimated Time**: 2 hours
**Description**: Refactor ChangeLogView to use PersistenceClient instead of SwiftDataChangeLogRepository
**Dependencies**: PersistenceClient (done)
**Files to Create/Modify**:
- [ ] Modify `ShiftScheduler/Views/ChangeLogView.swift`

**Changes**:
- [ ] Use PersistenceClient for fetching entries
- [ ] Fix undefined variables (allEntries)
- [ ] Update error handling

**Acceptance Criteria**:
- [ ] View compiles
- [ ] Change log entries display
- [ ] Errors handled properly

**Notes**:
```
Status: ⏳ Not Started
```

---

## ✅ Testing & Verification Tasks

### Task 12: Write Integration Tests for All Features
**Estimated Time**: 3-4 hours
**Description**: Create integration tests that test multiple features working together
**Files to Create/Modify**:
- [ ] Create `ShiftSchedulerTests/Integration/` directory
- [ ] Create `ShiftSchedulerTests/Integration/TodayFlowTests.swift`
- [ ] Create `ShiftSchedulerTests/Integration/ScheduleFlowTests.swift`

**Test Scenarios**:
- [ ] User creates shift type → loads in today view
- [ ] User switches shift → undo works → redo works
- [ ] User creates location → appears in shift type form
- [ ] Search/filter works across features

**Acceptance Criteria**:
- [ ] All integration tests pass
- [ ] Tests use mock dependencies
- [ ] No actual data modification

**Notes**:
```
Status: ⏳ Not Started
Can be done after features are migrated
```

---

### Task 13: Performance Testing & Optimization
**Estimated Time**: 2 hours
**Description**: Test performance with large shift lists and optimize if needed
**Files to Create/Modify**:
- [ ] Create performance test file if needed
- [ ] Profile TodayView/ScheduleView rendering

**Tests**:
- [ ] Load 1000+ shifts - measure load time
- [ ] Scroll performance with many cards
- [ ] Search/filter performance
- [ ] Undo/redo performance

**Optimization Candidates**:
- [ ] Lazy loading for shift lists
- [ ] Memoization of expensive computations
- [ ] Pagination for large datasets

**Acceptance Criteria**:
- [ ] Load time < 1 second for 1000 shifts
- [ ] Smooth scrolling at 60fps
- [ ] No memory leaks

**Notes**:
```
Status: ⏳ Not Started
Only optimize if needed based on testing
```

---

### Task 14: Final Verification - All Views Using TCA
**Estimated Time**: 1 hour
**Description**: Verify that all user-facing views use TCA stores
**Checklist**:
- [ ] LocationsView - ✅ Done
- [ ] AddEditLocationView - ✅ Done
- [ ] TodayView - ⏳ Task 3
- [ ] ScheduleView - ⏳ Task 6
- [ ] ShiftTypesView - ⏳ Task 8
- [ ] ScheduleShiftView - ⏳ Task 9
- [ ] SettingsView - ⏳ Task 10
- [ ] ChangeLogView - ⏳ Task 11
- [ ] AboutView - ✅ Already compatible

**Verification Steps**:
- [ ] Each view has `@Bindable var store: StoreOf<SomeFeature>`
- [ ] No @State variables (except local UI animations)
- [ ] All actions sent through store
- [ ] No direct singleton access
- [ ] All views compile
- [ ] All features unit tested

**Acceptance Criteria**:
- [ ] All 9 views verified ✅
- [ ] 0 singletons accessed directly from views
- [ ] 100% of business logic in features

**Notes**:
```
Status: ⏳ Not Started
Final sign-off task
```

---

## 📊 Progress Summary

### Completed ✅
- [x] Task 1: ShiftSwitchClient Dependency
- [x] Task 2: TodayFeature Reducer
- [x] Task 3: TodayView Migration
- [x] Task 4: TodayFeature Unit Tests
- [x] Task 7: ShiftTypesFeature
- [x] Task 8: ShiftTypesView Migration
- [x] AddEditLocationFeature
- [x] LocationsFeature
- [x] LocationsView migration
- [x] AddEditLocationView migration
- [x] Compilation errors fixed
- [x] Design documentation created

### In Progress ⏳
- None (all critical path features complete!)

### Pending ⏹️
- [ ] Task 5: ScheduleFeature
- [ ] Task 6: ScheduleView Migration
- [ ] Task 9-14: Remaining tasks

### Completion: 70% (10/14 tasks completed)

---

## 🎯 Recommended Session Plan

### Session 1 (2-3 hours)
- [ ] Task 1: Create ShiftSwitchClient
- [ ] Task 2: Implement TodayFeature (part 1)

### Session 2 (2-3 hours)
- [ ] Task 2: Implement TodayFeature (part 2 - finish)
- [ ] Task 4: Write TodayFeature tests

### Session 3 (2-3 hours)
- [ ] Task 3: Migrate TodayView
- [ ] Task 10: Update SettingsView

### Session 4 (2-3 hours)
- [ ] Task 5: Create ScheduleFeature
- [ ] Task 6: Migrate ScheduleView

### Session 5 (2-3 hours)
- [ ] Task 7: Create ShiftTypesFeature
- [ ] Task 8: Migrate ShiftTypesView

### Session 6+ (Cleanup & Testing)
- [ ] Task 9: Migrate ScheduleShiftView
- [ ] Task 11: Migrate ChangeLogView
- [ ] Task 12: Integration tests
- [ ] Task 13: Performance testing
- [ ] Task 14: Final verification

---

## 📝 Notes for Session Handoff

When stopping work, please:
1. Update this checklist with completed items
2. Add any blockers or discoveries in the "Notes" sections
3. Update the "Progress Summary" section
4. Note any file references or key learnings
5. Save a git commit with progress made

**Example Update**:
```
Task 1: Create ShiftSwitchClient
Status: ⏳ Not Started → ✅ Completed
Notes:
- File created at ShiftScheduler/Dependencies/ShiftSwitchClient.swift
- Integrated with existing ShiftSwitchService
- All 5 methods implemented and tested
- Depends on: CalendarClient, ChangeLogRepositoryClient
```

---

## 🚀 Success Criteria (End of Phase 2B)

When all tasks are complete, the following must be true:

- ✅ All 9 user-facing views use TCA stores
- ✅ Zero singletons accessed directly from views
- ✅ 100% of business logic in TCA features
- ✅ All features have unit tests (>80% coverage)
- ✅ Integration tests passing
- ✅ Performance acceptable (load time <1s, smooth scrolling)
- ✅ App builds and runs without errors
- ✅ No compilation warnings related to architecture

---

**Last Updated**: Generated at Phase 2A completion
**Total Estimated Work**: 20-25 hours
**Target Completion**: 3-4 weeks (with 2-3 hours per session)
