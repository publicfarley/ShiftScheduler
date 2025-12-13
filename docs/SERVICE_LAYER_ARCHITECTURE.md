# ShiftScheduler Service Layer Architecture Overview

## Executive Summary

The ShiftScheduler codebase has successfully migrated from a singleton-based service architecture to a TCA (The Composable Architecture) dependency injection pattern. The service layer is cleanly separated into:

1. **TCA Dependency Clients** - Modern, stateless service clients for dependency injection
2. **Repository Pattern** - Actor-based JSON persistence layer
3. **Protocol Abstractions** - Minimal legacy protocols (mostly replaced)
4. **Domain Models** - Value-type domain objects with full Sendable compliance

---

## 1. TCA Dependency Clients (Location: `/Dependencies/`)

All modern services follow the TCA `@DependencyClient` pattern with three implementations: `liveValue`, `testValue`, and `previewValue`.

### 1.1 CalendarClient
**File:** `CalendarClient.swift`

**Purpose:** Abstraction over EventKit for calendar shift management

**Interface:**
```swift
@DependencyClient
struct CalendarClient {
    var isAuthorized: @Sendable () -> Bool
    var createShift: @Sendable (ShiftType, Date) async throws -> String
    var fetchShifts: @Sendable (Date) async throws -> [ScheduledShiftData]
    var fetchShiftsInRange: @Sendable (Date, Date) async throws -> [ScheduledShiftData]
    var deleteShift: @Sendable (String) async throws -> Void
    var checkForDuplicate: @Sendable (UUID, Date) async throws -> Bool
    var updateShift: @Sendable (String, ShiftType) async throws -> Void
    var requestAuthorization: @Sendable () async -> Bool
}
```

**Dependencies:** Internally uses `EventKitClient`

**Status:** ✅ Live implementation complete

**Usage Pattern:**
```swift
@Reducer
struct MyFeature {
    @Dependency(\.calendarClient) var calendarClient
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            case .loadShifts:
                return .run { send in
                    let shifts = try await calendarClient.fetchShifts(Date())
                    await send(.shiftsLoaded(shifts))
                }
        }
    }
}
```

---

### 1.2 EventKitClient
**File:** `EventKitClient.swift`

**Purpose:** Low-level direct EventKit operations (marked `@MainActor`)

**Interface:**
```swift
@MainActor
@DependencyClient
struct EventKitClient {
    var checkAuthorizationStatus: () -> EKAuthorizationStatus
    var requestFullAccess: () async -> Bool
    var getOrCreateAppCalendar: () async throws -> String
    var createEvent: (String, Date, Date, Bool, String?) async throws -> String
    struct EventData: Sendable {
        let eventIdentifier: String
        let title: String?
        let startDate: Date
        let endDate: Date
        let isAllDay: Bool
        let notes: String?
        let location: String?
    }
    var fetchEvents: (Date, Date) async throws -> [EventData]
    var deleteEvent: (String) async throws -> Void
    var updateEvent: (String, String, Date, Date, Bool, String?) async throws -> Void
}
```

**Status:** ✅ Live implementation complete

**Key Details:**
- Maintains internal cache of app calendar identifier
- Creates dedicated "functioncraft.shiftscheduler" calendar on first use
- All event notes encode the ShiftType ID for recovery
- Thread-safe via @MainActor isolation

---

### 1.3 CurrentDayClient
**File:** `CurrentDayClient.swift`

**Purpose:** Date/time utilities replacing deprecated singleton managers

**Interface:**
```swift
@DependencyClient
struct CurrentDayClient {
    var getCurrentDate: @Sendable () -> Date
    var getTodayDate: @Sendable () -> Date
    var getTomorrowDate: @Sendable () -> Date
    var getYesterdayDate: @Sendable () -> Date
    var isToday: @Sendable (Date) -> Bool
    var isTomorrow: @Sendable (Date) -> Bool
    var isYesterday: @Sendable (Date) -> Bool
    var daysBetween: @Sendable (Date, Date) -> Int
}
```

**Status:** ✅ Live implementation complete

**Note:** Replacement for deprecated `CurrentDayManager.shared` and `CurrentDayObserverManager.shared`

---

### 1.4 PersistenceClient
**File:** `PersistenceClient.swift`

**Purpose:** Unified data persistence facade covering ShiftTypes, Locations, and ChangeLogEntries

**Interface:**
```swift
@DependencyClient
struct PersistenceClient: Sendable {
    // ShiftType Operations
    var fetchShiftTypes: @Sendable () async throws -> [ShiftType]
    var fetchShiftType: @Sendable (UUID) async throws -> ShiftType?
    var saveShiftType: @Sendable (ShiftType) async throws -> Void
    var updateShiftType: @Sendable (ShiftType) async throws -> Void
    var deleteShiftType: @Sendable (ShiftType) async throws -> Void
    
    // Location Operations
    var fetchLocations: @Sendable () async throws -> [Location]
    var fetchLocation: @Sendable (UUID) async throws -> Location?
    var saveLocation: @Sendable (Location) async throws -> Void
    var updateLocation: @Sendable (Location) async throws -> Void
    var deleteLocation: @Sendable (Location) async throws -> Void
    var canDeleteLocation: @Sendable (Location) async throws -> Bool
    var safeDeleteLocation: @Sendable (Location) async throws -> Void  // Throws LocationDeletionError
    
    // ChangeLogEntry Operations
    var fetchChangeLogEntries: @Sendable () async throws -> [ChangeLogEntry]
    var saveChangeLogEntry: @Sendable (ChangeLogEntry) async throws -> Void
    var deleteOldChangeLogEntries: @Sendable (Date) async throws -> Void
}
```

**Status:** ✅ Live implementation complete

**Backs Multiple Repositories:**
- `ShiftTypeRepository()` - JSON file: shiftTypes.json
- `LocationRepository()` - JSON file: locations.json
- `ChangeLogRepository()` - JSON file: changelog.json

**Data Directory:** `~/Documents/ShiftSchedulerData/`

---

### 1.5 ShiftSwitchClient
**File:** `ShiftSwitchClient.swift`

**Purpose:** Shift switching and change logging operations

**Interface:**
```swift
@DependencyClient
struct ShiftSwitchClient: Sendable {
    var switchShift: @Sendable (
        String,      // eventIdentifier
        Date,        // scheduledDate
        ShiftType,   // oldShiftType
        ShiftType,   // newShiftType
        String?      // reason
    ) async throws -> UUID  // Returns change log entry ID
}
```

**Status:** ⚠️ Incomplete - currently maps to testValue placeholder

**Current Implementation:** `testValue` (no-op)

**Note:** Should implement actual shift switching + changelog persistence

---

### 1.6 UserProfileClient
**File:** `UserProfileClient.swift`

**Purpose:** User profile management

**Interface:**
```swift
@DependencyClient
struct UserProfileClient: Sendable {
    var getCurrentProfile: @Sendable () -> UserProfile
    var updateDisplayName: @Sendable (String) -> Void
    var resetUserProfile: @Sendable () -> Void
}
```

**Status:** ⚠️ Incomplete - currently placeholder with nonisolated static members

**Note:** Replacement for deprecated `UserProfileManager.shared`

---

### 1.7 ChangeLogRepositoryClient
**File:** `ChangeLogRepositoryClient.swift`

**Purpose:** Direct change log repository access

**Interface:**
```swift
@DependencyClient
struct ChangeLogRepositoryClient: Sendable {
    var save: @Sendable (ChangeLogEntry) async throws -> Void
    var fetchAll: @Sendable () async throws -> [ChangeLogEntry]
    var fetchInRange: @Sendable (Date, Date) async throws -> [ChangeLogEntry]
    var fetchRecent: @Sendable (Int) async throws -> [ChangeLogEntry]
    var deleteOlderThan: @Sendable (Date) async throws -> Void
    var deleteAll: @Sendable () async throws -> Void
}
```

**Status:** ⚠️ Incomplete - liveValue contains fatalError() calls

**Note:** PersistenceClient likely supersedes this, but kept as secondary option

---

## 2. Repository Pattern (Location: `/Persistence/`)

Repositories handle JSON file-based persistence. All implemented as **Actors** for thread-safe concurrent access.

### 2.1 LocationRepository
**File:** `LocationRepository.swift`

```swift
actor LocationRepository: Sendable {
    static let defaultDirectory: URL  // ~/Documents/ShiftSchedulerData/
    
    func fetchAll() async throws -> [Location]
    func fetch(id: UUID) async throws -> Location?
    func save(_ location: Location) async throws
    func delete(id: UUID) async throws
}
```

**Persistence:** `locations.json`

---

### 2.2 ShiftTypeRepository
**File:** `ShiftTypeRepository.swift`

```swift
actor ShiftTypeRepository: Sendable {
    func fetchAll() async throws -> [ShiftType]
    func fetch(id: UUID) async throws -> ShiftType?
    func save(_ shiftType: ShiftType) async throws
    func delete(id: UUID) async throws
}
```

**Persistence:** `shiftTypes.json`

---

### 2.3 ChangeLogRepository
**File:** `ChangeLogRepository.swift`

```swift
actor ChangeLogRepository: ChangeLogRepositoryProtocol {
    nonisolated func fetchAll() async throws -> [ChangeLogEntry]
    nonisolated func fetch(from startDate: Date, to endDate: Date) async throws -> [ChangeLogEntry]
    nonisolated func fetchRecent(limit: Int) async throws -> [ChangeLogEntry]
    nonisolated func save(_ entry: ChangeLogEntry) async throws
    nonisolated func deleteEntriesOlderThan(_ date: Date) async throws
    nonisolated func deleteAll() async throws
}
```

**Persistence:** `changelog.json`

**Protocol:** Implements `ChangeLogRepositoryProtocol`

---

## 3. Protocol Abstractions (Location: `/Protocols/`)

Minimal legacy protocols, mostly superseded by TCA clients:

### 3.1 CalendarServiceProtocol
**File:** `CalendarServiceProtocol.swift`

**Status:** Legacy - superseded by CalendarClient

```swift
protocol CalendarServiceProtocol: Sendable {
    nonisolated var isAuthorized: Bool { get }
    nonisolated func createShiftEvent(from shiftType: ShiftType, on date: Date) async throws -> String
    nonisolated func fetchShifts(for date: Date) async throws -> [ScheduledShiftData]
    nonisolated func fetchShifts(from startDate: Date, to endDate: Date) async throws -> [ScheduledShiftData]
    nonisolated func deleteShift(withIdentifier identifier: String) async throws
    nonisolated func checkForDuplicateShift(shiftTypeId: UUID, on date: Date) async throws -> Bool
    nonisolated func updateShiftEvent(identifier: String, to newShiftType: ShiftType) async throws
}
```

---

### 3.2 DateProviderProtocol
**File:** `DateProviderProtocol.swift`

**Status:** Legacy - superseded by CurrentDayClient

```swift
protocol DateProviderProtocol: Sendable {
    func now() -> Date
    func today() -> Date
    func tomorrow() -> Date
}

struct SystemDateProvider: DateProviderProtocol {
    // Implementation using Calendar.current
}
```

---

### 3.3 ChangeLogRepositoryProtocol
**File:** `ChangeLogRepositoryProtocol.swift`

**Status:** Still active - implemented by ChangeLogRepository

```swift
protocol ChangeLogRepositoryProtocol: Sendable {
    nonisolated func save(_ entry: ChangeLogEntry) async throws
    nonisolated func fetchAll() async throws -> [ChangeLogEntry]
    nonisolated func fetch(from startDate: Date, to endDate: Date) async throws -> [ChangeLogEntry]
    nonisolated func fetchRecent(limit: Int) async throws -> [ChangeLogEntry]
    nonisolated func deleteEntriesOlderThan(_ date: Date) async throws
    nonisolated func deleteAll() async throws
}
```

---

## 4. Domain Models (Location: `/Models/`, `/Domain/`)

All domain models are **Sendable** value types or structs for Swift 6 concurrency compliance.

### 4.1 ShiftType
**File:** `ShiftType.swift`

```swift
struct ShiftType: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: UUID
    var symbol: String
    var duration: ShiftDuration
    var title: String
    var shiftDescription: String
    var location: Location  // ✅ Non-optional, embedded aggregate
}
```

---

### 4.2 Location
**File:** `Location.swift`

```swift
struct Location: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: UUID
    var name: String
    var address: String
}
```

---

### 4.3 ScheduledShift
**File:** `ScheduledShift.swift`

```swift
struct ScheduledShift: Identifiable, Equatable, Sendable {
    let id: UUID
    let eventIdentifier: String  // EventKit event ID
    let shiftType: ShiftType?
    let date: Date
}
```

---

### 4.4 ScheduledShiftData
**File:** `ScheduledShiftData.swift`

```swift
struct ScheduledShiftData: Hashable, Equatable, Sendable {
    let eventIdentifier: String
    let shiftTypeId: UUID
    let date: Date
    let title: String
    let location: String?
}
```

**Purpose:** Intermediate representation when fetching from EventKit, bridges to ScheduledShift

---

### 4.5 UserProfile
**File:** `UserProfile.swift`

```swift
struct UserProfile: Codable, Equatable, Sendable, Hashable {
    let userId: UUID
    var displayName: String
}
```

---

### 4.6 ChangeLogEntry
**File:** `ChangeLogEntry.swift`

```swift
struct ChangeLogEntry: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let timestamp: Date
    let userId: UUID
    let userDisplayName: String
    let changeType: ChangeType
    let scheduledShiftDate: Date
    let oldShiftSnapshot: ShiftSnapshot?
    let newShiftSnapshot: ShiftSnapshot?
    let reason: String?
}
```

---

### 4.7 ShiftDuration
**File:** `ShiftDuration.swift`

```swift
enum ShiftDuration: Codable, Equatable, Hashable, Sendable {
    case allDay
    case scheduled(from: HourMinuteTime, to: HourMinuteTime)
    
    var isAllDay: Bool
    var startTimeString: String
    var endTimeString: String
    var timeRangeString: String
}

struct HourMinuteTime: Codable, Equatable, Hashable, Sendable {
    let hour: Int
    let minute: Int
}
```

---

## 5. Error Types

### 5.1 EventKitError
**File:** `EventKitError.swift`

```swift
enum EventKitError: LocalizedError {
    case notAuthorized
    case calendarNotFound
    case invalidDate
    case eventNotFound
    case saveFailed(Error)
    case deleteFailed(Error)
    case authorizationFailed(Error)
}
```

---

### 5.2 LocationDeletionError
**File:** `PersistenceClient.swift`

```swift
enum LocationDeletionError: LocalizedError {
    case locationInUse(count: Int)
}
```

---

## 6. Dependency Usage in Features

All TCA features use the `@Dependency` macro to inject clients:

**Example from TodayFeature:**
```swift
@Reducer
struct TodayFeature {
    @Dependency(\.calendarClient) var calendarClient
    @Dependency(\.shiftSwitchClient) var shiftSwitchClient
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            case .task:
                return .run { send in
                    let shifts = try await calendarClient.fetchShifts(Date())
                    await send(.shiftsLoaded(shifts))
                }
        }
    }
}
```

**Features Using Dependencies:**
- `ScheduleFeature` - Uses: calendarClient, shiftSwitchClient
- `TodayFeature` - Uses: calendarClient, shiftSwitchClient
- `LocationsFeature` - Uses: persistenceClient
- `AddEditLocationFeature` - Uses: persistenceClient
- `ShiftTypesFeature` - Uses: persistenceClient
- `ChangeLogFeature` - Uses: persistenceClient
- `SettingsFeature` - Uses: userProfileClient, calendarClient
- `AppFeature` - Uses: calendarClient, persistenceClient
- `ScheduleShiftFeature` - Uses: calendarClient

---

## 7. Dependency Registration Pattern

Each client follows this pattern for DependencyValues extension:

```swift
extension DependencyValues {
    var calendarClient: CalendarClient {
        get { self[CalendarClient.self] }
        set { self[CalendarClient.self] = newValue }
    }
}
```

This allows features to access via:
```swift
@Dependency(\.calendarClient) var calendarClient
```

---

## 8. Testing Pattern

Each client provides three implementations:

```swift
extension CalendarClient: DependencyKey {
    /// Production implementation
    static let liveValue: CalendarClient = {
        // Real EventKit operations
    }()
    
    /// Test implementation (will fail if methods called)
    static let testValue = CalendarClient()
    
    /// Preview implementation (safe mock data)
    static let previewValue = CalendarClient(
        isAuthorized: { true },
        createShift: { _, _ in "preview-id" },
        // ...
    )
}
```

**Usage in tests:**
```swift
let store = TestStore(initialState: MyFeature.State()) {
    MyFeature()
} withDependencies: {
    $0.calendarClient.fetchShifts = { @Sendable _ in
        [/* mock shifts */]
    }
}
```

---

## 9. Architecture Summary Table

| Component | Type | Status | Sendable | Testable |
|-----------|------|--------|----------|----------|
| CalendarClient | TCA Client | ✅ Live | ✅ Yes | ✅ Yes |
| EventKitClient | TCA Client (@MainActor) | ✅ Live | ✅ Yes | ✅ Yes |
| CurrentDayClient | TCA Client | ✅ Live | ✅ Yes | ✅ Yes |
| PersistenceClient | TCA Client | ✅ Live | ✅ Yes | ✅ Yes |
| ShiftSwitchClient | TCA Client | ⚠️ Stub | ✅ Yes | ✅ Yes |
| UserProfileClient | TCA Client | ⚠️ Stub | ✅ Yes | ✅ Yes |
| ChangeLogRepositoryClient | TCA Client | ⚠️ Stub | ✅ Yes | ✅ Yes |
| LocationRepository | Actor | ✅ Live | ✅ Yes | ✅ Yes |
| ShiftTypeRepository | Actor | ✅ Live | ✅ Yes | ✅ Yes |
| ChangeLogRepository | Actor | ✅ Live | ✅ Yes | ✅ Yes |
| EventKitError | Error Type | ✅ Live | ✅ Yes | N/A |
| LocationDeletionError | Error Type | ✅ Live | ✅ Yes | N/A |

---

## 10. Data Flow Example

**Scenario: Load shifts for a date**

1. **Feature sends action:**
   ```swift
   case .loadShifts:
       return .run { send in
           let shifts = try await calendarClient.fetchShifts(date)
           await send(.shiftsLoaded(shifts))
       }
   ```

2. **CalendarClient.fetchShifts:**
   - Calls EventKitClient.fetchEvents()
   - Filters for app calendar events
   - Extracts ShiftType ID from event notes
   - Returns [ScheduledShiftData]

3. **EventKitClient.fetchEvents:**
   - Gets app calendar identifier (cached or created)
   - Creates EventKit predicate for date range
   - Returns [EventData] with Sendable compliance

4. **Feature receives response:**
   ```swift
   case let .shiftsLoaded(shifts):
       state.scheduledShifts = shifts.map { data in
           let shiftType = try? await persistenceClient.fetchShiftType(data.shiftTypeId)
           return ScheduledShift(from: data, shiftType: shiftType)
       }
   ```

---

## 11. Key Design Principles Implemented

✅ **Zero Singletons in TCA Code**
- All dependencies injected via @Dependency macro
- No .shared patterns in active features

✅ **Sendable Compliance**
- All closures marked @Sendable
- All models are Sendable value types
- Ready for Swift 6 strict concurrency

✅ **Actor-based Concurrency**
- Repositories implemented as Actors
- EventKitClient marked @MainActor
- No race conditions possible

✅ **Testability**
- All clients have testValue, previewValue, liveValue
- Easy to mock in unit tests
- No side effects in pure value objects

✅ **Error Handling**
- Domain-specific error types (EventKitError, LocationDeletionError)
- Proper async/await with throws
- No force unwraps (!)

✅ **Separation of Concerns**
- Clients = stateless operations
- Repositories = persistence layer
- Features = state management
- Models = domain values

---

## 12. Migration Status

### Completed (October 22, 2025)
- EventKitClient fully implemented
- CalendarClient fully implemented  
- CurrentDayClient fully implemented
- PersistenceClient fully implemented
- All repositories functioning
- All TCA features migrated

### Pending
- ShiftSwitchClient live implementation
- UserProfileClient live implementation
- ChangeLogRepositoryClient live implementation

---

## 13. File Structure

```
ShiftScheduler/
├── Dependencies/
│   ├── CalendarClient.swift           ✅ Complete
│   ├── EventKitClient.swift           ✅ Complete
│   ├── EventKitError.swift
│   ├── CurrentDayClient.swift         ✅ Complete
│   ├── PersistenceClient.swift        ✅ Complete
│   ├── ShiftSwitchClient.swift        ⚠️ Stub
│   ├── UserProfileClient.swift        ⚠️ Stub
│   ├── ChangeLogRepositoryClient.swift ⚠️ Stub
│   └── README.md                      (Excellent documentation!)
├── Persistence/
│   ├── LocationRepository.swift       ✅ Complete
│   ├── ShiftTypeRepository.swift      ✅ Complete
│   └── ChangeLogRepository.swift      ✅ Complete
├── Repositories/
│   └── ChangeLogRepositoryProtocol.swift
├── Protocols/
│   ├── CalendarServiceProtocol.swift  (Legacy)
│   ├── DateProviderProtocol.swift     (Legacy)
│   └── UserDefaultsProtocol.swift     (Removed)
├── Models/
│   ├── ShiftType.swift                ✅ Sendable
│   ├── Location.swift                 ✅ Sendable
│   ├── ScheduledShift.swift           ✅ Sendable
│   ├── ScheduledShiftData.swift       ✅ Sendable
│   └── ShiftDuration.swift            ✅ Sendable
├── Domain/
│   ├── UserProfile.swift              ✅ Sendable
│   ├── ChangeLogEntry.swift           ✅ Sendable
│   ├── ChangeType.swift
│   └── ChangeLogRetentionPolicy.swift
└── Features/
    ├── ScheduleFeature.swift          (Uses: calendarClient, shiftSwitchClient)
    ├── TodayFeature.swift             (Uses: calendarClient, shiftSwitchClient)
    ├── LocationsFeature.swift         (Uses: persistenceClient)
    ├── AddEditLocationFeature.swift   (Uses: persistenceClient)
    ├── ShiftTypesFeature.swift        (Uses: persistenceClient)
    ├── ChangeLogFeature.swift         (Uses: persistenceClient)
    ├── SettingsFeature.swift          (Uses: userProfileClient, calendarClient)
    ├── AppFeature.swift               (Uses: calendarClient, persistenceClient)
    └── ScheduleShiftFeature.swift     (Uses: calendarClient)
```

