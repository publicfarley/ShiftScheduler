# TCA Features

This directory contains all TCA Reducers (also called "Features") for the ShiftScheduler app.

## Current Features

### AppFeature
The root feature that coordinates all app functionality. This is the entry point for the TCA architecture.

**File:** `AppFeature.swift`

**Responsibilities:**
- Tab navigation state
- User profile management
- Coordinating sub-features

### LocationsFeature
Example feature demonstrating complete TCA patterns for CRUD operations.

**File:** `LocationsFeature.swift`

**Demonstrates:**
- List management with IdentifiedArray
- Search/filter functionality
- Sheet presentation with `@Presents`
- Add/Edit sub-feature
- Form validation
- Two-way binding with `BindingReducer`
- Error handling
- Loading states
- Async operations with TaskResult

## Planned Features (Phase 2+)

### ScheduleFeature
Manages the calendar view and shift scheduling with intelligent caching.

**Responsibilities:**
- Date selection
- Shift display for selected date
- Cache management (5-minute expiry)
- Predictive prefetching
- Flash-free UI updates

### ShiftSwitchFeature
Manages shift switching and undo/redo operations.

**Responsibilities:**
- Shift switching logic
- Undo/redo stack management
- Change log entry creation
- Persistence of undo/redo state

### ShiftTypesFeature
Manages shift type CRUD operations.

**Responsibilities:**
- Shift type list
- Search/filter
- Add/Edit/Delete operations
- Integration with Schedule

### TodayFeature
Complex dashboard showing today's shift, tomorrow's shift, and week stats.

**Responsibilities:**
- Today's shift display and status
- Tomorrow's shift preview
- Week statistics
- Quick actions (clock in/out, switch shift)
- Undo/redo integration

**Sub-features:**
- TodayShiftFeature
- TomorrowShiftFeature
- WeekStatsFeature
- QuickActionsFeature

### ChangeLogFeature
Displays audit trail of shift changes.

**Responsibilities:**
- Change log list
- Date filtering
- Retention policy enforcement

### SettingsFeature
App configuration.

**Responsibilities:**
- User preferences
- App settings

### AboutFeature
App information display.

**Responsibilities:**
- Version info
- Credits
- Links

## Feature Composition Pattern

Features can be composed in two ways:

### 1. Parent-Child with Scope

```swift
@Reducer
struct ParentFeature {
    @ObservableState
    struct State {
        var child = ChildFeature.State()
    }

    enum Action {
        case child(ChildFeature.Action)
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.child, action: \.child) {
            ChildFeature()
        }

        Reduce { state, action in
            // Parent logic
        }
    }
}
```

### 2. Optional Presentation with @Presents

```swift
@Reducer
struct ParentFeature {
    @ObservableState
    struct State {
        @Presents var sheet: SheetFeature.State?
    }

    enum Action {
        case sheet(PresentationAction<SheetFeature.Action>)
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            // Parent logic
        }
        .ifLet(\.$sheet, action: \.sheet) {
            SheetFeature()
        }
    }
}
```

## Testing Pattern

Every feature should have corresponding tests:

```swift
@Test
func testFeature() async {
    let store = TestStore(initialState: Feature.State()) {
        Feature()
    } withDependencies: {
        $0.swiftDataClient.fetchLocations = { @Sendable in
            [/* mock data */]
        }
    }

    await store.send(.task) {
        $0.isLoading = true
    }

    await store.receive(\.locationsLoaded) {
        $0.isLoading = false
        $0.locations = [/* expected data */]
    }
}
```

## Guidelines

1. **State is Equatable** - All state must conform to Equatable for testing
2. **Actions are Equatable** - All actions must be Equatable
3. **Dependencies are injected** - Use `@Dependency` macro, never singletons
4. **Effects return actions** - All async work returns actions via `.run { send in }`
5. **Reducers are pure** - No side effects in reducers, only in Effects
6. **Composition over inheritance** - Use Scope and ifLet to compose features
7. **Test everything** - Every feature should have comprehensive tests

## Common Patterns

### Loading Data on Appear

```swift
case .task:
    state.isLoading = true
    return .run { send in
        await send(.dataLoaded(
            TaskResult {
                try await dependency.fetchData()
            }
        ))
    }
```

### Form Validation

```swift
case .saveButtonTapped:
    state.validationErrors = validate(state: state)
    guard state.validationErrors.isEmpty else {
        return .none
    }
    // Proceed with save
```

### Error Handling

```swift
case let .dataLoaded(.success(data)):
    state.isLoading = false
    state.data = data
    state.errorMessage = nil
    return .none

case let .dataLoaded(.failure(error)):
    state.isLoading = false
    state.errorMessage = error.localizedDescription
    return .none
```

### Debouncing

```swift
enum CancelID { case search }

case let .searchTextChanged(text):
    state.searchText = text
    return .run { send in
        try await clock.sleep(for: .milliseconds(300))
        await send(.performSearch)
    }
    .cancellable(id: CancelID.search)
```

## Migration Strategy

1. **Create the feature structure** - State, Action, body
2. **Add dependencies** - Identify what external systems are needed
3. **Implement reducer logic** - Pure state transformations
4. **Add effects** - Async operations that return actions
5. **Handle all action cases** - Exhaustive switching
6. **Write tests** - Test all state transitions
7. **Update views** - Connect view to store
8. **Remove old code** - Clean up after migration

## Resources

- [TCA Documentation](https://pointfreeco.github.io/swift-composable-architecture/main/documentation/composablearchitecture/)
- [Example LocationsFeature.swift](./LocationsFeature.swift) - Reference implementation
