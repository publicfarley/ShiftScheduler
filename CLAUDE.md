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

## UI Patterns

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