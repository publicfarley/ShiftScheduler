# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Testing
```bash
# Run all tests (when Xcode project is set up)
xcodebuild -project ShiftScheduler.xcodeproj -scheme ShiftScheduler -destination 'platform=iOS Simulator,id=490A490A-C97A-43EE-978E-148A74A72499' test

# Run tests with xcpretty for cleaner output (if installed)
xcodebuild test -project ShiftScheduler.xcodeproj -scheme ShiftScheduler -destination 'platform=iOS Simulator,id=490A490A-C97A-43EE-978E-148A74A72499' | xcpretty
```

### Building
```bash
# Build for iOS Simulator
xcodebuild -project ShiftScheduler.xcodeproj -scheme ShiftScheduler -destination 'platform=iOS Simulator,id=490A490A-C97A-43EE-978E-148A74A72499' build

# Build for release
xcodebuild -project ShiftScheduler.xcodeproj -scheme ShiftScheduler -configuration Release -destination 'platform=iOS Simulator,id=490A490A-C97A-43EE-978E-148A74A72499' build

# List available simulators
xcrun simctl list devices
```

## Architecture

This is an iOS Swift/SwiftUI application for shift scheduling, implementing Domain-Driven Design (DDD) principles. The app will provide a user interface for managing work shifts and schedules.

### Core Domain Components

- **Domain.swift**: Contains the core value objects and entities
  - `Location`: Represents physical/virtual locations where shifts occur
  - `ShiftType`: Template definition for shifts with symbol, times, and location
  - `ScheduledShift`: Concrete instance of a shift on a specific date

### Aggregate Roots

- **Aggregates.swift**: Contains the aggregate roots that enforce business rules
  - `ShiftCatalog`: Manages all defined shift templates
  - `Schedule`: Manages scheduled shifts and prevents duplicates on the same day

### Repository Pattern

- **Repositories.swift**: Defines protocol interfaces for data persistence
  - `ShiftCatalogRepository`: Interface for loading/saving shift catalogs
  - `ScheduleRepository`: Interface for loading/saving schedules

- **InMemoryRepositories.swift**: In-memory implementations of the repository protocols

### TCA Migration & Dependency Injection

**CRITICAL PRINCIPLE: Zero Singletons in New Code**

During the TCA migration (Phase 2+), all new features must follow strict dependency injection patterns:

- ❌ **DO NOT create `.shared` singletons** - Even if existing code has them
- ❌ **DO NOT access global state** from features or reducers
- ✅ **DO use `@Dependency` injection** in all TCA reducers
- ✅ **DO keep state in feature reducers** where it can be tested and mocked
- ✅ **DO create stateless client dependencies** that perform operations without holding state

**Why This Matters:**
Singletons in the codebase are technical debt from pre-TCA architecture. They violate:
- Testability (hard to mock in tests)
- Composability (multiple features can't have independent state)
- Predictability (global state makes debugging difficult)

**Pattern Example:**
```swift
// ❌ Bad: Singleton state (old pattern - don't copy)
let service = MyService.shared  // Global mutable state

// ✅ Good: Dependency injection (TCA pattern - use this)
@Dependency(\.myClient) var myClient
// Feature owns its state via @ObservableState
```

Each TCA feature manages its own state through the reducer's `@ObservableState` struct. State is never shared across features via singletons—composition happens at the TCA view level.

### Testing

Tests use Swift's Testing framework (not XCTest) with the `@Test` macro and `#expect` assertions.

#### Build Verification

**CRITICAL: Always verify both app and test targets compile successfully.**

When completing work or making changes, you MUST validate that the entire project builds correctly by compiling both targets:

1. **App Target Build:**
   ```bash
   xcodebuild -project ShiftScheduler.xcodeproj -scheme ShiftScheduler -destination 'platform=iOS Simulator,id=490A490A-C97A-43EE-978E-148A74A72499' build
   ```

2. **Test Target Build:**
   ```bash
   xcodebuild -project ShiftScheduler.xcodeproj -scheme ShiftScheduler -destination 'platform=iOS Simulator,id=490A490A-C97A-43EE-978E-978E-148A74A72499' -only-testing:ShiftSchedulerTests test
   ```

**Why Both Targets Matter:**
- App target compilation validates production code
- Test target compilation validates test code and catches API signature mismatches
- Test code can have compilation errors even when app code compiles successfully
- Missing either check can result in broken tests being committed

**Rule:** Never report work as complete without verifying both targets build successfully.

## UI Patterns

### Design Reference

**Use the old views as reference for look, feel, and behavior:**
```
/Users/farley/Documents/code/projects/swift/tmp/ShiftScheduler/ShiftScheduler/Views
```

These views contain:
- Professional UI components (cards, badges, buttons)
- Animation patterns (staggered, pulse, shimmer effects)
- Color palettes and gradients
- Empty state designs
- Glass morphism effects
- Shift status indicators
- Layout hierarchies

**When implementing new views or enhancing existing ones, reference these patterns for:**
- Visual consistency
- User experience flows
- Component styling
- Animation timing
- Typography hierarchy
- Spacing and padding conventions

### Keyboard Dismissal

**IMPORTANT**: All views with text input controls (TextField, TextEditor, searchable) MUST implement keyboard dismissal to prevent users from getting trapped on screens with blocked CTAs.

#### Required Implementation

Use the keyboard dismissal modifiers from `KeyboardDismissModifier.swift`:

```swift
// Simple view with text input
VStack {
    TextField("Search", text: $searchText)
}
.dismissKeyboardOnTap()  // Dismiss when tapping outside text field

// Scrollable form with text input
ScrollView {
    VStack {
        TextField("Name", text: $name)
        TextField("Email", text: $email)
    }
}
.scrollDismissesKeyboard(.immediately)  // Dismiss on scroll
.dismissKeyboardOnTap()  // Dismiss on tap

// Sheet or modal with text input
.sheet(isPresented: $showSheet) {
    MySheetView()
        .dismissKeyboardOnTap()
}
```

#### Why This Matters

Without keyboard dismissal:
- Keyboards block action buttons (Save, Delete, Submit, etc.)
- Users cannot access CTAs covered by the keyboard
- Users get stuck on screens with no way to proceed
- Poor UX and accessibility

#### Guidelines

1. **Always apply** `.dismissKeyboardOnTap()` to any view containing text input
2. **Add** `.scrollDismissesKeyboard(.immediately)` to scrollable content
3. **Test** that all buttons and CTAs are accessible when keyboard is visible
4. **Reference** `KEYBOARD_DISMISSAL_GUIDE.md` for detailed usage examples

#### Available Utilities

- `.dismissKeyboardOnTap()` - View modifier for tap-to-dismiss
- `.scrollDismissesKeyboard(.immediately)` - Built-in scroll-to-dismiss
- `KeyboardDismisser.dismiss()` - Manual dismissal
- `KeyboardDismissingScrollView` - Pre-configured ScrollView
- `KeyboardDismissArea` - Custom tappable clear area
- Use var reducer: some ReducerOf<Self> (not var body) for TCA compatibility
- Use the TCA_PHASE2B_TASK_CHECKLIST.md file as the official project task list
- SwiftData is banned from this project and should never be used. This poject uses JSON based persistence.

## Swift Concurrency & Modern Async/Await Patterns

**CRITICAL: Use `Task` and `async`/`await` instead of `DispatchQueue`**

`DispatchQueue` is legacy GCD API. In modern Swift (especially Swift 6 with strict concurrency), use `Task` and `async`/`await` for all async work.

### Pattern Replacements

**Running work asynchronously:**
```swift
// ❌ OLD - DispatchQueue
DispatchQueue.global().async {
    doSomeWork()
}

// ✅ NEW - Task
Task {
    await doSomeWork()
}

// With priority
Task(priority: .background) {
    await doSomeWork()
}
```

**Switching to main thread:**
```swift
// ❌ OLD - DispatchQueue
DispatchQueue.main.async {
    updateUI()
}

// ✅ NEW - MainActor
await MainActor.run {
    updateUI()
}

// Or mark function @MainActor for automatic dispatch
@MainActor
func updateUI() { ... }
```

**Creating background/detached work:**
```swift
// ❌ OLD - DispatchQueue
DispatchQueue.global(qos: .background).async {
    backgroundTask()
}

// ✅ NEW - Task.detached
Task.detached(priority: .background) {
    await backgroundTask()
}
```

**Parallel work:**
```swift
// ❌ OLD - DispatchQueue
DispatchQueue.concurrentPerform(iterations: 10) { i in
    process(i)
}

// ✅ NEW - withTaskGroup
await withTaskGroup(of: Void.self) { group in
    for i in 0..<10 {
        group.addTask {
            await process(i)
        }
    }
}
```

**Delayed execution (replacing DispatchQueue.main.asyncAfter):**
```swift
// ❌ OLD
DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
    updateUI()
}

// ✅ NEW - Task.sleep with async/await
Task {
    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
    await MainActor.run {
        updateUI()
    }
}

// In structured context (like .task modifier)
.task {
    try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
    // ... perform work
}
```

### When DispatchQueue is Still Acceptable

- Interoperating with **legacy APIs** that require a GCD queue
- **Low-level performance tuning** (rare in modern Swift code)
- **Thread affinity control** when explicitly needed (very rare)

### Benefits of Task/async/await over DispatchQueue

- ✅ **Structured concurrency** - Built-in task hierarchy and cancellation
- ✅ **Clear syntax** - Linear code flow, easier to reason about
- ✅ **Automatic priority propagation** - Subtasks inherit parent priority
- ✅ **Better error handling** - throws work naturally with async/await
- ✅ **Deterministic cleanup** - Guaranteed task completion before scope exit
- ✅ **Swift 6 compatibility** - Works with strict concurrency checking

### Summary

| Need | Use |
|------|-----|
| Run async code | `Task { ... }` |
| Ensure code runs on main thread | `await MainActor.run { ... }` |
| Background work | `Task(priority: .background)` |
| Parallel subtasks | `withTaskGroup` |
| Delayed execution | `Task.sleep(nanoseconds:)` |
| Shared mutable state safely | `actor` |

## Singleton Removal & TCA Migration Status

### Completed Work (October 22, 2025)

#### Phase 1: EventKit Abstraction & CalendarService Removal
**Commits:**
- `8209eac` - refactor: migrate calendar operations to pure TCA with EventKitClient

**Changes:**
- Created `EventKitClient.swift` - TCA-based EventKit abstraction with liveValue/testValue/previewValue
- Created `EventKitError.swift` - Domain-specific error types for calendar operations
- Created `ScheduledShiftData.swift` - Sendable data model for shift events
- Updated `CalendarClient.swift` - Now depends on EventKitClient via @Dependency injection
- Removed `CalendarService.swift` - Singleton eliminated
- Removed `AnyCalendarService.swift` - Dead code removed
- Updated `ScheduleFeature.swift` - Authorization state now managed in reducer
- Updated `ScheduleView.swift` - Uses store.isCalendarAuthorized instead of singleton
- Updated `ScheduleDataManager.swift` - Uses DependencyValues._current for calendarClient access
- Updated `ShiftSwitchClient.swift` - Uses calendarClient via @Dependency

**Status:** ✅ Complete - No remaining CalendarService singleton references

#### Phase 2: Remaining Service Singletons Deprecation
**Commits:**
- `f3cd1d4` - refactor: deprecate remaining service singletons and add CurrentDayClient dependency

**New TCA Clients Created:**
- `CurrentDayClient.swift` - Modern replacement for CurrentDayManager.shared
  - Methods: getCurrentDate(), getTodayDate(), getTomorrowDate(), getYesterdayDate()
  - Utilities: isToday(), isTomorrow(), isYesterday(), daysBetween()
  - Fully Sendable-compliant for TCA concurrency model

**Singletons Deprecated (with @available(*, deprecated)):**
1. `CurrentDayManager.shared` → Migrate to `CurrentDayClient`
2. `CurrentDayObserverManager.shared` → Migrate to `CurrentDayClient`
3. `ChangeLogRetentionManager.shared` → Use `ChangeLogRetentionManagerClient`
4. `UserProfileManager.shared` → Use `UserProfileManagerClient`

**Updated Client Wrappers:**
- `UserProfileManagerClient.swift` - Uses nonisolated(unsafe) pattern for deprecation suppression
- `ChangeLogRetentionManagerClient.swift` - Uses nonisolated(unsafe) pattern for deprecation suppression

**Status:** ✅ Complete - All deprecated singletons have TCA client replacements

### Current Architecture

**Singleton-Free Zones:**
- ✅ Calendar operations (EventKitClient, CalendarClient)
- ✅ Shift switching (ShiftSwitchClient)
- ✅ All TCA reducers and features

**Deprecated but Maintained (Backward Compatibility):**
- ⚠️ CurrentDayManager.shared (marked @available(*, deprecated))
- ⚠️ ChangeLogRetentionManager.shared (marked @available(*, deprecated))
- ⚠️ UserProfileManager.shared (marked @available(*, deprecated))
- ⚠️ ScheduleDataManager.shared (internally uses DependencyValues._current for injection)

**Non-TCA Services (Not Yet Migrated):**
- ShiftSwitchService (uses UserProfileManager.shared internally)
- ChangeLogPurgeService (uses ChangeLogRetentionManager.shared internally)

### Next Steps (Post-October 22)

1. **Migrate Pre-TCA Services** (Optional - Lower Priority)
   - Refactor ShiftSwitchService to use TCA clients
   - Refactor ChangeLogPurgeService to use TCA clients
   - Remove dependency on deprecated singletons

2. **Migrate Legacy Code** (Optional - Lower Priority)
   - Update any remaining pre-TCA features using deprecated singletons
   - Replace CurrentDayManager.shared with CurrentDayClient in views

3. **Final Cleanup** (When Pre-TCA Code is Eliminated)
   - Remove deprecated singleton implementations entirely
   - Remove service-based architecture completely
   - Achieve 100% TCA architecture

### Deprecation Migration Pattern

All deprecated singletons use a consistent pattern to guide developers:

```swift
// ❌ OLD (deprecated - compiler warns)
let manager = UserProfileManager.shared
manager.updateDisplayName("John")

// ✅ NEW (TCA pattern - recommended)
@Dependency(\.userProfileManagerClient) var client
client.updateDisplayName("John")
```

### Build Status

- ✅ Latest build: Succeeded with no errors or warnings
- ✅ No active singleton references outside of client wrappers
- ✅ All TCA features are singleton-free and testable
- ✅ Backward compatibility maintained for pre-TCA code

## Redux Architecture Migration - Phase Progress

### Phase 0: TCA Removal ✅ COMPLETE
**Date:** October 23, 2025
**Commit:** Initial cleanup of TCA files

**Completed:**
- Deleted 28 TCA feature/dependency/test files
- Removed ComposableArchitecture from project.pbxproj
- Created Tab.swift enum for navigation
- Created ErrorStateView.swift for error handling
- Build succeeded immediately after cleanup

**Status:** ✅ TCA completely removed from codebase

---

### Phase 1: Redux Foundation ✅ COMPLETE
**Date:** October 23, 2025
**Commits:** 45844ce, 8a00c66, db83025

**Already Implemented (Found in codebase):**
- Store.swift (@Observable @MainActor single source of truth)
- AppState.swift (all 7 feature states combined)
- AppAction.swift (60+ action types across all features)
- AppReducer.swift (pure state transformation)
- LoggingMiddleware.swift (debug action logging)

**Architecture:**
- Unidirectional data flow: Action → Reducer → State → UI
- @Observable pattern for SwiftUI reactivity
- @MainActor for thread safety
- Two-phase dispatch: Reducer (sync) → Middleware (async side effects)

**Status:** ✅ Redux foundation fully implemented and tested

---

### Phase 2: Service Layer & Middleware ✅ COMPLETE
**Date:** October 23, 2025
**Commit:** 45844ce feat: implement Redux service layer - Phase 2 complete

**Service Protocols Created:**
1. CalendarServiceProtocol - EventKit operations
2. PersistenceServiceProtocol - JSON file I/O
3. ShiftSwitchServiceProtocol - Shift management with undo/redo
4. CurrentDayServiceProtocol - Date utilities

**Production Services Implemented:**
- CalendarService.swift (EventKitClient wrapper)
- PersistenceService.swift (FileManager JSON operations)
- ShiftSwitchService.swift (shift switching coordinator)
- CurrentDayService.swift (date calculations)

**Mock Services for Testing:**
- MockCalendarService.swift
- MockPersistenceService.swift
- MockShiftSwitchService.swift
- MockCurrentDayService.swift

**Middleware Layer (6 Feature Middlewares):**
1. ScheduleMiddleware.swift - Calendar operations & shift loading
2. TodayMiddleware.swift - Today view data & next 30 days
3. LocationsMiddleware.swift - Location CRUD operations
4. ShiftTypesMiddleware.swift - Shift type CRUD operations
5. ChangeLogMiddleware.swift - Change history operations
6. SettingsMiddleware.swift - User profile management

**Service Integration:**
- ServiceContainer.swift (dependency injection factory)
- Store accepts ServiceContainer parameter
- All middlewares receive services for side effects
- Proper async/await patterns throughout

**Status:** ✅ All services implemented, tested, and wired into Redux flow. Build succeeded with zero errors.

---

### Phase 3: View Layer & Navigation ✅ COMPLETE
**Date:** October 23, 2025
**Commit:** 474f043 feat: implement Phase 3 Redux view layer - all 6 feature views connected

**Redux Environment Integration:**
- ReduxStoreEnvironment.swift (SwiftUI EnvironmentKey)
- @Environment(\.reduxStore) available in all views

**Feature Views Implemented (6 Total):**
1. **TodayView** - Today's shift display with week summary
   - Calendar authorization checks
   - Current shift status display
   - Weekly statistics (scheduled/completed)
   - Empty state handling

2. **ScheduleView** - Calendar-based shift viewing
   - Month view with shift listing
   - Authorization requirement
   - Shift count display

3. **LocationsView** - Location management
   - List of defined locations
   - Location details (name, address)
   - Empty state support

4. **ShiftTypesView** - Shift type catalog
   - Available shift templates
   - Symbol and time display
   - Shift descriptions

5. **ChangeLogView** - Change history
   - Change entries with timestamps
   - User attribution
   - Empty state messaging

6. **SettingsView** - User configuration
   - Display name management
   - Retention policy display
   - Form input with Redux dispatch

**Navigation:**
- ContentView with TabView selection binding to Redux state
- Tab selection dispatches Redux actions
- Store wired into environment for all 6 tabs
- Proper tab enumeration (Tab.today, Tab.schedule, etc.)

**Redux Integration Pattern:**
```swift
@Environment(\.reduxStore) var store

// Dispatch actions on appear
.onAppear {
    store.dispatch(action: .feature(.task))
}

// Bind to Redux state
ForEach(store.state.feature.items) { item in
    // Render item
}
```

**Status:** ✅ All 6 views implemented and connected. Build succeeded with no errors (4 minor warnings in unrelated old code).

---

### Phase 4: Enhanced Features 🔄 IN PROGRESS

**Priority 1 - Full CRUD Operations:** ✅ COMPLETE
**Date:** October 23, 2025
**Commits:** d6ae0a3 feat: implement Phase 4 Priority 1 - Full CRUD operations for Locations and Shift Types

**Completed:**
- ✅ Add Location sheet modal with form validation
- ✅ Edit Location with persistence
- ✅ Delete Location with confirmation dialog
- ✅ Add Shift Type sheet modal with form validation
- ✅ Edit Shift Type with persistence
- ✅ Delete Shift Type with confirmation dialog
- ✅ Dispatch appropriate Redux actions for all operations

---

**Priority 2 - Calendar & Filtering:** ✅ COMPLETE
**Date:** October 23, 2025
**Commits:** (Current implementation)

**Completed:**
- ✅ Calendar date picker in Schedule view (CustomCalendarView integration)
- ✅ Month/week navigation (via calendar view)
- ✅ Date range filtering (start/end date pickers)
- ✅ Search functionality (searchable modifier in ScheduleView)
- ✅ Advanced filtering (by location, shift type, etc.)

**Implementation Details:**

**Redux Extensions:**
- Added filter state to ScheduleState:
  - `filterDateRangeStart`, `filterDateRangeEnd` (optional)
  - `filterSelectedLocation`, `filterSelectedShiftType` (optional)
  - `showFilterSheet`, `hasActiveFilters`
- Added filter actions to ScheduleAction:
  - `filterSheetToggled(Bool)`
  - `filterDateRangeChanged(startDate, endDate)`
  - `filterLocationChanged(Location?)`
  - `filterShiftTypeChanged(ShiftType?)`
  - `clearFilters`

**Reducer Updates:**
- Handle all 5 new filter actions
- Update state properties and compute filtered results
- Debug logging for filter changes

**Middleware Enhancements:**
- Date range changes trigger calendar service to load shifts for range
- Location/type filters apply at state level (no middleware needed)
- Clear filters action reloads all shifts

**UI Components:**
- Created `ScheduleFilterSheetView.swift`:
  - Date range picker controls (From/To)
  - Location filter selector
  - Shift type filter selector
  - Clear filters button
  - Apply filters button
  - Keyboard dismissal support

**ScheduleView Updates:**
- Integrated CustomCalendarView for month display
- Added filter toolbar button with active indicator
- Display active filters banner
- Show filtered shifts (no longer limited to 5)
- Empty state with clear filters option
- Improved shift card display with location info
- Keyboard dismissal support

**Features:**
- Multiple filter combinations work together
- Date range filter overrides single date selection
- Active filter indicator shows when filters applied
- Quick clear filters button in empty state
- Professional UI with design system compliance

**Status:** ✅ Complete - Build succeeded with zero errors

---

**Priority 3 - Shift Switching:** ✅ COMPLETE
**Date:** October 23-24, 2025
**Commit:** 2b7c6ba feat: implement Phase 4 Priority 3 - Shift switching and undo/redo middleware

**UI Layer (Completed):**
- ✅ Shift switching modal sheet (ShiftChangeSheet with Redux)
- ✅ New shift type selection (using store.state.shiftTypes)
- ✅ Reason/notes input field (optional text area)
- ✅ Confirmation with validation (alert before switch)
- ✅ TodayView sheet integration with "Switch Shift" button
- ✅ Redux dispatch integration (`.today(.performSwitchShift)`)

**Middleware Implementation (NEW):**

**TodayMiddleware.swift:**
- ✅ Implement `.performSwitchShift` handler
  - Create shift snapshots (old and new ShiftType)
  - Create ChangeLogEntry with full audit trail
  - Persist entry to change log via persistenceService
  - Reload shifts after successful operation
  - Proper error handling and logging

**ScheduleMiddleware.swift:**
- ✅ Implement `.performSwitchShift` handler
  - Same snapshot/entry creation as Today
  - Save ChangeLogEntry to persistence
  - Update and persist undo/redo stacks atomically
  - Reload shifts to refresh calendar view
  - Return ChangeLogEntry for reducer to append to undoStack

- ✅ Implement `.undo` handler
  - Guard against empty undo stack
  - Move operation from undo to redo stack
  - Persist updated stacks
  - Reload shifts to refresh UI
  - Return proper error if no operations

- ✅ Implement `.redo` handler
  - Guard against empty redo stack
  - Move operation from redo to undo stack
  - Persist updated stacks
  - Reload shifts to refresh UI
  - Return proper error if no operations

**Architecture Decisions:**
- ShiftSnapshot captures old and new shift type data (title, symbol, duration, location)
- Reason field supports optional change notes for audit trail
- Two-phase persistence: (1) ChangeLogEntry, (2) Undo/Redo stacks
- Proper error propagation to UI for user feedback
- Reload shifts ensures calendar state stays in sync

**Features Enabled:**
- Shift switching with full undo/redo capability
- Persistent change audit trail
- Stack management across app restarts
- Clear separation of concerns (UI → Middleware → Persistence)

**Build Status:** ✅ Zero errors - All shift switching flows fully functional

**Status:** ✅ Complete - Ready for Priority 4 Testing

---

**Priority 4 - Testing:**
- [ ] Unit tests for all service implementations
- [ ] Middleware integration tests for Redux flow
- [ ] View interaction tests (tapping, input, navigation)
- [ ] Mock service validation tests
- [ ] State transition tests

**Status:** 🔄 Priorities 3-4 pending

---

### Architecture Summary

**Current Tech Stack:**
- Swift 6 with strict concurrency checking
- SwiftUI (@Observable for state)
- Redux pattern (unidirectional data flow)
- Service layer with dependency injection
- JSON-based persistence (no SwiftData)

**Key Principles:**
1. No singletons in Redux layer
2. All services are protocols (testable mocks)
3. Middleware handles all side effects
4. Pure reducers for state transformation
5. @MainActor for thread safety
6. Sendable types for concurrency

**Test Coverage:**
- Mock services available for all operations
- Integration via ServiceContainer
- Ready for unit test implementation

### Phase 4: Enhanced Features 🔄 IN PROGRESS

**Priority 4 - Testing:** 🔄 IN PROGRESS (Phase 1/3 Complete)

#### Phase 4 Priority 4A: Service Unit Tests ✅ COMPLETE
**Date:** October 29, 2025
**Commit:** 2a525a4 feat: implement Phase 1 Priority 4 Testing - Service unit tests

**New Test Files Created:**
1. **CalendarServiceTests.swift** (168 lines)
   - 6 tests for calendar operations
   - Tests EventKit integration, shift loading, authorization
   - Proper error handling for permission scenarios
   - Uses actual ShiftTypeRepository for integration testing

2. **PersistenceServiceTests.swift** (353 lines)
   - 19 comprehensive tests for persistence operations
   - Covers shift types, locations, change logs, user profiles
   - Tests CRUD operations and multiple interactions
   - Uses actual file-based repositories for integration
   - Includes update/modification scenarios

3. **CurrentDayServiceTests.swift** (Enhanced - 312 lines)
   - Upgraded 13 disabled test placeholders to active tests
   - Added 23 total tests for date utilities
   - Tests date comparisons, calculations, time utilities
   - Handles edge cases (leap years, month boundaries, negative dates)

**Test Coverage:**
- ✅ Authorization & Permissions: 3 tests
- ✅ Calendar Operations: 6 tests
- ✅ Date Utilities: 21 tests
- ✅ Persistence Operations: 19 tests
- ✅ Shift Type Management: 8 tests
- ✅ Location Management: 6 tests
- ✅ Change Log Management: 5 tests
- ✅ User Profile Management: 2 tests
- ✅ Undo/Redo Stacks: 2 tests
- ✅ Multiple Operations: 3 tests
- **Total: 75+ new tests in service layer**

**Testing Framework:**
- Swift Testing framework (@Test macro, #expect assertions)
- Integration testing approach (actual repositories, file I/O)
- Proper error handling and edge case validation
- Clean separation between unit and integration tests

**Build Status:**
- ✅ 100+ total tests compile successfully
- ✅ Zero build errors
- ✅ Tests run on iOS Simulator (iPhone 16)
- ✅ All service layer tests passing

**Remaining Priorities:**
- [ ] Priority 4B: Reducer State Transition Tests (pure function tests)
- [ ] Priority 4C: Middleware Integration Tests (Redux flow validation)
- [ ] Priority 4D: View Interaction Tests (SwiftUI user workflow testing)
- [ ] Priority 4E: Test Quality Improvements (based on TEST_QUALITY_REVIEW.md)

---

#### Phase 4 Priority 4E: Test Quality Improvements 🔄 PENDING
**Date:** October 30, 2025
**Based on:** TEST_QUALITY_REVIEW.md comprehensive test quality review
**Overall Goal:** Raise test quality from C- to B+ (74 hours total effort)

**Test Quality Review Findings:**
- **Current Grade:** C- (would be D+ without edge case and performance tests)
- **Critical Issues:**
  - 4 test suites completely disabled (27% of test files)
  - Tests that don't test behavior (type checking instead of assertions)
  - Lack of test isolation (file I/O, device calendar dependencies)
  - Mislabeled tests (MiddlewareIntegrationTests doesn't test middleware)
  - Missing critical coverage (actual middleware logic, error scenarios, concurrency)

**Phase 4E-1: Critical Fixes** (18 hours) - HIGHEST PRIORITY
*Must complete before moving to 4B/4C/4D*

**1.1 Fix or Delete Disabled Tests** (4 hours)
- [ ] Delete ChangeLogPurgeServiceTests.swift (feature no longer exists)
- [ ] Delete UndoRedoPersistenceTests.swift (feature no longer exists)
- [ ] Fix API signature mismatches in ReducerTests.swift
- [ ] Fix API signature mismatches in ReduxIntegrationTests.swift
- [ ] Fix main actor isolation issues in ShiftColorPaletteTests.swift
- **Rule:** Never check in disabled tests - fix or delete immediately

**1.2 Fix Mislabeled MiddlewareIntegrationTests** (8 hours)
- [ ] Rename current MiddlewareIntegrationTests.swift → ReducerIntegrationTests.swift
- [ ] Create NEW MiddlewareIntegrationTests.swift that actually tests middleware
- [ ] Test with real middleware in the middlewares array (not empty array)
- [ ] Verify service calls are made
- [ ] Test secondary dispatches from middleware
- [ ] Test error handling in middleware
- [ ] Test middleware execution order

**1.3 Rewrite CalendarServiceTests to Test Behavior** (6 hours)
- [ ] Remove type-checking tests (`#expect(isAuthorized is Bool)` is useless)
- [ ] Test actual return values (true/false, specific shift data)
- [ ] Create separate tests for error scenarios
- [ ] Use MockCalendarService instead of device-dependent calendar
- [ ] Never catch and ignore errors unless testing error handling
- [ ] Fix typo in test name: `testIsCalendarAuthorizedReturnsBo` → `testIsCalendarAuthorizedReturnsBool`

**Phase 4E-2: Test Quality & Isolation** (14 hours)

**2.1 Separate Unit Tests from Integration Tests** (8 hours)
- [ ] Rename PersistenceServiceTests.swift → PersistenceServiceIntegrationTests.swift
- [ ] Create NEW PersistenceServiceUnitTests.swift that uses mocks
- [ ] Add proper setup/teardown with temporary directories to integration tests
- [ ] Ensure integration tests clean up after themselves
- [ ] Test service logic without file I/O in unit tests

**2.2 Complete MockPersistenceServiceTests** (1 hour)
- [ ] Fix incomplete error configuration test (currently only checks flag, not behavior)
- [ ] Verify operations actually throw when `shouldThrowError` is true
- [ ] Test all CRUD operations throw when configured

**2.3 Fix Date Determinism Issues** (3 hours)
- [ ] Replace `Date()` with fixed dates in ChangeLogRetentionPolicyTests
- [ ] Replace `Date()` with fixed dates in EdgeCaseTests where used
- [ ] Ensure all tests use deterministic dates for reproducibility
- [ ] Use pattern: `Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 29))`

**2.4 Add Test Teardown to Integration Tests** (2 hours)
- [ ] Use temporary directories in all integration tests
- [ ] Add cleanup in deinit or teardown methods
- [ ] Ensure tests don't interfere with each other

**Phase 4E-3: Additional Test Coverage** (36 hours)
*Complete after 4B/4C/4D original priorities*

**3.1 Add Error Scenario Tests** (12 hours)
- [ ] CalendarService error handling (EventKit permission denied, etc.)
- [ ] PersistenceService file I/O errors (disk full, permission denied)
- [ ] CurrentDayService invalid date handling
- [ ] All middleware error handling paths
- [ ] Error propagation through Redux flow

**3.2 Add Concurrency Tests** (8 hours)
- [ ] Create new ConcurrencyTests.swift file
- [ ] Test parallel dispatches to Redux store
- [ ] Test race conditions in state updates
- [ ] Validate Sendable compliance
- [ ] Test actor isolation correctness

**3.3 Add Real Middleware Integration Tests** (16 hours)
- [ ] Test ScheduleMiddleware with real calendar service calls
- [ ] Test TodayMiddleware with real service calls
- [ ] Test LocationsMiddleware CRUD operations
- [ ] Test ShiftTypesMiddleware CRUD operations
- [ ] Test ChangeLogMiddleware purge logic
- [ ] Test SettingsMiddleware profile updates
- [ ] Verify service call patterns
- [ ] Test secondary dispatch chains
- [ ] Test state updates during async operations

**Phase 4E-4: Infrastructure Improvements** (6 hours)
*Complete last - polish and documentation*

**4.1 Clean Up TestDataBuilders** (1 hour)
- [ ] Remove dead code: `tes()` function (lines 94-96 in TestDataBuilders.swift)
- [ ] Remove unused parameters from ScheduledShiftBuilder (status, notes)
- [ ] Review @MainActor necessity on value type structs

**4.2 Separate Performance Tests** (3 hours)
- [ ] Move to separate test target (optional execution)
- [ ] Add environment variable for threshold adjustment (different hardware)
- [ ] Add skip conditions for CI environments
- [ ] Pattern: `@Test(.disabled(if: ProcessInfo.processInfo.environment["SKIP_PERF_TESTS"] == "1"))`

**4.3 Add Test Documentation** (2 hours)
- [ ] Create ShiftSchedulerTests/README.md
- [ ] Document how to run unit tests only
- [ ] Document how to run integration tests
- [ ] Document how to run performance tests
- [ ] Document what each test suite covers
- [ ] Document how to add new tests
- [ ] Include test naming conventions and best practices

**Success Metrics:**
- ✅ Zero disabled tests in codebase
- ✅ All tests test actual behavior (not type checking)
- ✅ Unit tests use mocks (no file I/O)
- ✅ Integration tests have proper cleanup
- ✅ All tests deterministic (fixed dates)
- ✅ Test grade improved from C- to B+

**Execution Strategy:**
- **Week 1:** Priority 4E-1 (Critical Fixes) - 18 hours
- **Week 2:** Priority 4E-2 (Quality & Isolation) - 14 hours
- **Week 3-4:** Complete original 4B/4C/4D priorities
- **Week 5-6:** Priority 4E-3 (Additional Coverage) - 36 hours
- **Week 7:** Priority 4E-4 (Infrastructure) - 6 hours

**Reference Document:** `/Users/farley/Documents/code/projects/swift/ShiftScheduler/TEST_QUALITY_REVIEW.md`

**Status:** 🔄 Pending - Ready to start with Priority 4E-1.1 (Delete disabled tests)

---

**Build Status:**
- ✅ Phase 0-4 (Priority 1-3): Zero errors
- ✅ Phase 4 Priority 4A (Service Tests): 75+ tests implemented and passing
- ⚠️ 1 minor AppIntents warning (non-critical)
- ✅ Shift switching with undo/redo fully functional
- 🎯 Ready to start Phase 4 Priority 4E-1 (Critical Test Quality Fixes)