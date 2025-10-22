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