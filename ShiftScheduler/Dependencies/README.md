# TCA Dependencies

This directory contains all TCA Dependency Clients that provide controlled access to external systems.

## What are Dependencies?

In TCA, dependencies are the way to access external systems (APIs, databases, calendars, etc.) from your reducers. They provide:

1. **Testability** - Easy mocking in tests
2. **Controlled side effects** - All external access is explicit
3. **Consistent interface** - Same API for live, test, and preview contexts

## Current Dependencies

### CalendarClient
Provides access to calendar operations via EventKit.

**File:** `CalendarClient.swift`

**Operations:**
- `isAuthorized()` - Check calendar access status
- `createShift(ShiftType, Date)` - Create new calendar event
- `fetchShifts(Date)` - Get shifts for specific date
- `fetchShiftsInRange(Date, Date)` - Get shifts in date range
- `deleteShift(String)` - Delete shift by event ID
- `checkForDuplicate(UUID, Date)` - Check for duplicate shifts
- `updateShift(String, ShiftType)` - Update existing shift

**Status:** ✅ Live implementation complete

### SwiftDataClient
Provides access to SwiftData model operations.

**File:** `SwiftDataClient.swift`

**Operations:**

**ShiftType:**
- `fetchShiftTypes()` - Get all shift types
- `fetchShiftType(UUID)` - Get specific shift type
- `saveShiftType(ShiftType)` - Create new shift type
- `updateShiftType(ShiftType)` - Update existing shift type
- `deleteShiftType(ShiftType)` - Delete shift type

**Location:**
- `fetchLocations()` - Get all locations
- `fetchLocation(UUID)` - Get specific location
- `saveLocation(Location)` - Create new location
- `updateLocation(Location)` - Update existing location
- `deleteLocation(Location)` - Delete location

**ChangeLogEntry:**
- `fetchChangeLogEntries()` - Get all change log entries
- `saveChangeLogEntry(ChangeLogEntry)` - Create change log entry
- `deleteOldChangeLogEntries(Date)` - Clean up old entries

**Status:** ⚠️ Live implementation pending (Phase 2)

### ChangeLogRepositoryClient
Provides access to change log repository operations.

**File:** `ChangeLogRepositoryClient.swift`

**Operations:**
- `save(ChangeLogEntry)` - Save change log entry
- `fetchAll()` - Get all entries
- `fetchInRange(Date, Date)` - Get entries in date range
- `fetchRecent(Int)` - Get N most recent entries
- `deleteOlderThan(Date)` - Clean up old entries
- `deleteAll()` - Clear all entries

**Status:** ⚠️ Live implementation pending (Phase 2)

## Dependency Pattern

Each dependency client follows this structure:

```swift
@DependencyClient
struct MyClient: Sendable {
    var operation: @Sendable (Args) async throws -> Result = { _ in defaultValue }
}

extension MyClient: DependencyKey {
    static let liveValue = MyClient(
        operation: { args in
            // Real implementation
        }
    )

    static let testValue = MyClient()  // Unimplemented, will fail

    static let previewValue = MyClient(
        operation: { _ in /* mock data */ }
    )
}

extension DependencyValues {
    var myClient: MyClient {
        get { self[MyClient.self] }
        set { self[MyClient.self] = newValue }
    }
}
```

## Using Dependencies in Reducers

```swift
@Reducer
struct MyFeature {
    @Dependency(\.calendarClient) var calendarClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .loadData:
                return .run { send in
                    let shifts = try await calendarClient.fetchShifts(Date())
                    await send(.shiftsLoaded(shifts))
                }
            }
        }
    }
}
```

## Testing with Dependencies

```swift
@Test
func testFeature() async {
    let store = TestStore(initialState: MyFeature.State()) {
        MyFeature()
    } withDependencies: {
        // Override dependencies for testing
        $0.calendarClient.fetchShifts = { @Sendable _ in
            [/* mock shifts */]
        }
    }

    await store.send(.loadData)
    await store.receive(\.shiftsLoaded)
}
```

## Common Built-in Dependencies

TCA provides several built-in dependencies:

- `\.uuid` - UUID generation
- `\.date` - Current date/time
- `\.continuousClock` - Time-based operations (sleep, debounce)
- `\.dismiss` - Dismiss presented views
- `\.mainQueue` - Main queue scheduling
- `\.urlSession` - Network requests

## Phase 2 TODO: Implement Live Dependencies

### SwiftDataClient Live Implementation

The live implementation needs access to the app's ModelContext. There are two approaches:

**Approach 1: Pass ModelContext through environment**
```swift
static func liveValue(context: ModelContext) -> SwiftDataClient {
    SwiftDataClient(
        fetchLocations: {
            let descriptor = FetchDescriptor<Location>()
            return try context.fetch(descriptor)
        }
        // ...
    )
}
```

**Approach 2: Create a shared ModelContainer dependency**
```swift
@DependencyClient
struct ModelContainerClient {
    var context: @Sendable () -> ModelContext
}

// Then use in SwiftDataClient
@Dependency(\.modelContainer) var modelContainer

var fetchLocations = {
    let context = modelContainer.context()
    return try context.fetch(FetchDescriptor<Location>())
}
```

### ChangeLogRepositoryClient Live Implementation

Similar to SwiftDataClient, this needs access to the repository instance:

```swift
static func liveValue(repository: any ChangeLogRepositoryProtocol) -> ChangeLogRepositoryClient {
    ChangeLogRepositoryClient(
        save: { entry in
            try await repository.save(entry)
        }
        // ...
    )
}
```

## Guidelines

1. **All operations are @Sendable** - For thread safety
2. **Async by default** - Use async/await for all I/O
3. **Throw errors** - Don't catch, let caller handle
4. **No state in clients** - Clients should be stateless
5. **Default implementations** - Provide test and preview values
6. **Naming** - Use clear, action-oriented names

## Anti-patterns to Avoid

❌ **DON'T access singletons in reducers**
```swift
// Bad
let service = CalendarService.shared
```

✅ **DO use dependency injection**
```swift
// Good
@Dependency(\.calendarClient) var calendarClient
```

❌ **DON'T perform I/O directly in reducers**
```swift
// Bad
case .load:
    state.data = try await api.fetch()  // Never!
```

✅ **DO use effects**
```swift
// Good
case .load:
    return .run { send in
        let data = try await api.fetch()
        await send(.dataLoaded(data))
    }
```

❌ **DON'T mix live/test implementations**
```swift
// Bad
static let liveValue = MyClient(
    operation: { _ in
        #if DEBUG
        return mockData
        #else
        return realData
        #endif
    }
)
```

✅ **DO provide separate implementations**
```swift
// Good
static let liveValue = MyClient(operation: { _ in realData })
static let previewValue = MyClient(operation: { _ in mockData })
```

## Resources

- [TCA Dependencies Documentation](https://pointfreeco.github.io/swift-dependencies/main/documentation/dependencies/)
- [Example CalendarClient.swift](./CalendarClient.swift) - Complete implementation
