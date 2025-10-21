# TCA Migration - Phase 1 Setup

This document describes Phase 1 of migrating ShiftScheduler to The Composable Architecture (TCA).

## What Has Been Created

### Directory Structure

```
ShiftScheduler/
├── Dependencies/          # TCA Dependency Clients
│   ├── CalendarClient.swift
│   ├── ChangeLogRepositoryClient.swift
│   └── SwiftDataClient.swift
├── Features/             # TCA Reducers/Features
│   ├── AppFeature.swift
│   └── LocationsFeature.swift
└── ... (existing directories)
```

### Dependency Clients

**CalendarClient.swift** - Wraps the existing `CalendarService` for TCA
- Provides controlled access to calendar operations
- Includes live, test, and preview implementations
- All methods are async and Sendable for thread safety

**SwiftDataClient.swift** - Abstracts SwiftData operations
- CRUD operations for ShiftType, Location, ChangeLogEntry
- Live implementation placeholder (needs ModelContext wiring)
- Test and preview mocks provided

**ChangeLogRepositoryClient.swift** - Wraps change log repository
- Repository pattern for change log persistence
- Live implementation placeholder
- Test and preview mocks provided

### Features (Reducers)

**AppFeature.swift** - Root feature coordinating the entire app
- Manages tab selection
- User profile state
- Entry point for all sub-features (to be added)

**LocationsFeature.swift** - Example feature demonstrating TCA patterns
- Complete CRUD operations for locations
- Search functionality
- Add/Edit sheet presentation
- Demonstrates:
  - `@Reducer` macro
  - `@ObservableState` for state management
  - `@Presents` for sheet presentation
  - `BindingReducer` for two-way binding
  - Error handling and loading states
  - TaskResult pattern for async operations

## Required: Add TCA Package Dependency

**IMPORTANT:** You must add the TCA package to your Xcode project before the code will compile.

### Steps to Add TCA:

1. **Open Xcode Project**
   ```bash
   open ShiftScheduler.xcodeproj
   ```

2. **Add Package Dependency**
   - In Xcode, go to **File → Add Package Dependencies...**
   - Enter the URL: `https://github.com/pointfreeco/swift-composable-architecture`
   - Select version: **1.0.0 or later** (recommend "Up to Next Major Version")
   - Click **Add Package**
   - Ensure "ComposableArchitecture" is added to the ShiftScheduler target

3. **Add Files to Xcode Project**

   The new Swift files have been created but need to be added to the Xcode project:

   - In Xcode, right-click on the `ShiftScheduler` group
   - Select **Add Files to "ShiftScheduler"...**
   - Navigate to and select the new directories:
     - `Dependencies/` (all 3 files)
     - `Features/` (both files)
   - Ensure "Copy items if needed" is **unchecked** (files are already in the right place)
   - Ensure "Add to targets" includes **ShiftScheduler**
   - Click **Add**

4. **Verify Build**

   Build the project to verify TCA is properly integrated:
   ```bash
   xcodebuild -project ShiftScheduler.xcodeproj -scheme ShiftScheduler -destination 'platform=iOS Simulator,id=490A490A-C97A-43EE-978E-148A74A72499' build
   ```

## What's Next: Phase 2

Once TCA is added and the project builds, Phase 2 will:

1. **Implement Live Dependency Clients**
   - Wire up `SwiftDataClient` with ModelContext
   - Wire up `ChangeLogRepositoryClient` with repository
   - Complete calendar authorization flow

2. **Create Core Features**
   - **ScheduleFeature** - Calendar and shift management with caching
   - **ShiftSwitchFeature** - Undo/redo system
   - **ShiftTypesFeature** - Shift type CRUD

3. **Migrate Views**
   - Start with simple views (About, Settings)
   - Progress to complex views (TodayView, ScheduleView)

## TCA Architecture Overview

### Key Concepts

**State** - Single source of truth
```swift
@ObservableState
struct State: Equatable {
    var locations: IdentifiedArrayOf<Location> = []
    var isLoading = false
    // ...
}
```

**Actions** - Everything that can happen
```swift
enum Action: Equatable {
    case task
    case addButtonTapped
    case locationsLoaded(TaskResult<[Location]>)
    // ...
}
```

**Reducer** - Pure function evolving state
```swift
var body: some ReducerOf<Self> {
    Reduce { state, action in
        switch action {
        case .task:
            return .run { send in
                // async work
            }
        }
    }
}
```

**Dependencies** - Controlled side effects
```swift
@Dependency(\.swiftDataClient) var swiftDataClient
```

### Benefits

1. **Testability** - Every feature fully testable without UI
2. **Predictability** - State changes are explicit and traceable
3. **Composition** - Features compose together cleanly
4. **Side Effect Management** - All async operations declared as Effects
5. **Built-in Tools** - Time travel debugging, exhaustive testing

## Example: LocationsFeature Usage

Once Phase 2 is complete, views will use stores like this:

```swift
struct LocationsView: View {
    @Bindable var store: StoreOf<LocationsFeature>

    var body: some View {
        List(store.filteredLocations) { location in
            LocationRow(location: location)
        }
        .searchable(text: $store.searchText)
        .task { await store.send(.task).finish() }
        .sheet(item: $store.scope(state: \.addEditSheet, action: \.addEditSheet)) { store in
            AddEditLocationView(store: store)
        }
    }
}
```

## Testing Example

TCA makes testing straightforward:

```swift
@Test
func testAddLocation() async {
    let store = TestStore(initialState: LocationsFeature.State()) {
        LocationsFeature()
    } withDependencies: {
        $0.swiftDataClient.saveLocation = { @Sendable _ in }
    }

    await store.send(.addButtonTapped) {
        $0.addEditSheet = AddEditLocationFeature.State(mode: .add)
    }
}
```

## Resources

- [Official TCA Documentation](https://pointfreeco.github.io/swift-composable-architecture/main/documentation/composablearchitecture/)
- [Point-Free Videos](https://www.pointfree.co/collections/composable-architecture)
- [TCA Examples](https://github.com/pointfreeco/swift-composable-architecture/tree/main/Examples)

## Notes

- All dependency clients have `liveValue`, `testValue`, and `previewValue` implementations
- Live implementations are currently placeholders and will be completed in Phase 2
- `LocationsFeature` serves as a complete example of the TCA pattern
- The existing codebase remains untouched and functional during migration
