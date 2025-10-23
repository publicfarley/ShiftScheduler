# Phase 2: Redux Service Layer - Implementation Plan

**Status**: 🟡 **READY TO START**
**Estimated Duration**: 3-5 days
**Priority**: HIGH

---

## Phase 2 Overview

Phase 2 establishes a protocol-based service layer that bridges Redux actions to external operations (calendar, persistence, etc.). This layer separates Redux from external dependencies and enables testable middleware.

### Key Goals
1. Define service protocols for all external operations
2. Implement production services wrapping existing implementations
3. Create mock services for testing
4. Implement ServiceContainer for dependency injection
5. Integrate services into Redux middleware

---

## Phase 2 Task Breakdown

### Task 1: Create Service Protocols

#### 1.1 CalendarServiceProtocol.swift
```swift
protocol CalendarServiceProtocol: Sendable {
    func requestAuthorization() async -> Bool
    func isAuthorized() -> Bool
    func fetchShifts(start: Date, end: Date) async throws -> [ScheduledShift]
    func createShift(_ shift: ScheduledShift) async throws -> String
    func updateShift(eventId: String, shift: ScheduledShift) async throws
    func deleteShift(eventId: String) async throws
}
```

**File**: `ShiftScheduler/Redux/Services/Protocols/CalendarServiceProtocol.swift`
**Purpose**: Abstract calendar operations
**Dependencies**: EventKit (via existing EventKitClient)

#### 1.2 PersistenceServiceProtocol.swift
```swift
protocol PersistenceServiceProtocol: Sendable {
    func fetchLocations() async throws -> [Location]
    func saveLocation(_ location: Location) async throws
    func deleteLocation(_ location: Location) async throws

    func fetchShiftTypes() async throws -> [ShiftType]
    func saveShiftType(_ shiftType: ShiftType) async throws
    func updateShiftType(_ shiftType: ShiftType) async throws
    func deleteShiftType(_ shiftType: ShiftType) async throws

    func saveUserProfile(_ profile: UserProfile) async throws
    func fetchUserProfile() async throws -> UserProfile?
}
```

**File**: `ShiftScheduler/Redux/Services/Protocols/PersistenceServiceProtocol.swift`
**Purpose**: Abstract persistence operations
**Dependencies**: JSON file system

#### 1.3 ShiftSwitchServiceProtocol.swift
```swift
protocol ShiftSwitchServiceProtocol: Sendable {
    func switchShift(
        eventId: String,
        date: Date,
        oldShift: ShiftType,
        newShift: ShiftType,
        reason: String?
    ) async throws -> ChangeLogEntry

    func undoOperation(_ operation: ChangeLogEntry) async throws
    func redoOperation(_ operation: ChangeLogEntry) async throws
    func persistStacks(undo: [ChangeLogEntry], redo: [ChangeLogEntry]) async
    func restoreStacks() async throws -> (undo: [ChangeLogEntry], redo: [ChangeLogEntry])
}
```

**File**: `ShiftScheduler/Redux/Services/Protocols/ShiftSwitchServiceProtocol.swift`
**Purpose**: Shift switching with undo/redo
**Dependencies**: Calendar + Persistence

#### 1.4 CurrentDayServiceProtocol.swift
```swift
protocol CurrentDayServiceProtocol: Sendable {
    func getCurrentDate() -> Date
    func getTodayDate() -> Date
    func getTomorrowDate() -> Date
    func getYesterdayDate() -> Date

    func isToday(_ date: Date) -> Bool
    func isTomorrow(_ date: Date) -> Bool
    func isYesterday(_ date: Date) -> Bool
    func daysBetween(_ date1: Date, _ date2: Date) -> Int
}
```

**File**: `ShiftScheduler/Redux/Services/Protocols/CurrentDayServiceProtocol.swift`
**Purpose**: Date utility operations
**Dependencies**: Foundation

---

### Task 2: Implement Production Services

#### 2.1 CalendarService.swift
Wrap existing EventKitClient and CalendarClient

```swift
@MainActor
class CalendarService: CalendarServiceProtocol {
    static let shared = CalendarService()
    private let eventKitClient: EventKitClient
    private let calendarClient: CalendarClient

    // Implementation wrapping existing clients
}
```

#### 2.2 PersistenceService.swift
Wrap existing persistence layer

```swift
@MainActor
class PersistenceService: PersistenceServiceProtocol {
    static let shared = PersistenceService()

    // Load from JSON files
    // Save to JSON files
    // Handle Codable encoding/decoding
}
```

#### 2.3 ShiftSwitchService.swift
Coordinate calendar + persistence for shift switches

```swift
@MainActor
class ShiftSwitchService: ShiftSwitchServiceProtocol {
    static let shared = ShiftSwitchService()
    private let calendarService: CalendarServiceProtocol
    private let persistenceService: PersistenceServiceProtocol

    // Coordinate shift switching across services
    // Manage undo/redo stacks
    // Track operations in change log
}
```

#### 2.4 CurrentDayService.swift
Pure date utility service

```swift
@MainActor
class CurrentDayService: CurrentDayServiceProtocol {
    static let shared = CurrentDayService()

    // Simple date math helpers
    // No persistence needed
}
```

---

### Task 3: Create Mock Services

#### 3.1 MockCalendarService.swift
```swift
class MockCalendarService: CalendarServiceProtocol {
    var isAuthorizedValue = true
    var mockShifts: [ScheduledShift] = []
    var shouldThrowError = false

    // Mock implementations for testing
}
```

#### 3.2 MockPersistenceService.swift
```swift
class MockPersistenceService: PersistenceServiceProtocol {
    var mockLocations: [Location] = []
    var mockShiftTypes: [ShiftType] = []
    var mockUserProfile: UserProfile?
    var shouldThrowError = false

    // In-memory mock implementations
}
```

#### 3.3 MockShiftSwitchService.swift
```swift
class MockShiftSwitchService: ShiftSwitchServiceProtocol {
    var mockOperations: [ChangeLogEntry] = []
    var shouldThrowError = false

    // Mock switch operations
}
```

#### 3.4 MockCurrentDayService.swift
```swift
class MockCurrentDayService: CurrentDayServiceProtocol {
    var mockCurrentDate = Date()

    // Mock date operations with controllable dates
}
```

---

### Task 4: ServiceContainer Implementation

```swift
@MainActor
struct ServiceContainer {
    let calendarService: CalendarServiceProtocol
    let persistenceService: PersistenceServiceProtocol
    let shiftSwitchService: ShiftSwitchServiceProtocol
    let currentDayService: CurrentDayServiceProtocol

    static let production = ServiceContainer(
        calendarService: CalendarService.shared,
        persistenceService: PersistenceService.shared,
        shiftSwitchService: ShiftSwitchService.shared,
        currentDayService: CurrentDayService.shared
    )

    static func mock(
        calendar: CalendarServiceProtocol? = nil,
        persistence: PersistenceServiceProtocol? = nil,
        shiftSwitch: ShiftSwitchServiceProtocol? = nil,
        currentDay: CurrentDayServiceProtocol? = nil
    ) -> ServiceContainer {
        ServiceContainer(
            calendarService: calendar ?? MockCalendarService(),
            persistenceService: persistence ?? MockPersistenceService(),
            shiftSwitchService: shiftSwitch ?? MockShiftSwitchService(),
            currentDayService: currentDay ?? MockCurrentDayService()
        )
    }
}
```

**File**: `ShiftScheduler/Redux/Services/ServiceContainer.swift`
**Purpose**: Dependency injection container for services

---

### Task 5: Integrate Services into Store

Update Store.swift to accept services:

```swift
@Observable
@MainActor
class Store {
    private(set) var state: AppState
    private let reducer: @MainActor (AppState, AppAction) -> AppState
    private let middlewares: [Middleware]
    private let services: ServiceContainer

    init(
        state: AppState,
        reducer: @escaping @MainActor (AppState, AppAction) -> AppState,
        services: ServiceContainer = .production,
        middlewares: [Middleware] = []
    ) {
        self.state = state
        self.reducer = reducer
        self.services = services
        self.middlewares = middlewares
    }
}
```

---

### Task 6: Create Service-Based Middleware

#### 6.1 ScheduleMiddleware.swift
```swift
func scheduleMiddleware(
    state: AppState,
    action: AppAction,
    dispatch: @escaping (AppAction) -> Void,
    services: ServiceContainer
) {
    guard case .schedule(let scheduleAction) = action else { return }

    switch scheduleAction {
    case .task:
        // Restore undo/redo stacks
        Task {
            do {
                let stacks = try await services.shiftSwitchService.restoreStacks()
                dispatch(.schedule(.stacksRestored(.success(stacks))))
            } catch {
                dispatch(.schedule(.stacksRestored(.failure(error))))
            }
        }
        // Check authorization
        dispatch(.schedule(.checkAuthorization))
        // Load shifts
        dispatch(.schedule(.loadShifts))

    case .loadShifts:
        Task {
            let selectedDate = state.schedule.selectedDate
            let calendar = Calendar.current
            let startOfMonth = calendar.dateComponents([.year, .month], from: selectedDate)
            let startDate = calendar.date(from: startOfMonth) ?? selectedDate
            let endDate = calendar.date(byAdding: .month, value: 1, to: startDate) ?? selectedDate

            do {
                let shifts = try await services.calendarService.fetchShifts(
                    start: startDate,
                    end: endDate
                )
                dispatch(.schedule(.shiftsLoaded(.success(shifts))))
            } catch {
                dispatch(.schedule(.shiftsLoaded(.failure(error))))
            }
        }
    // ... more cases
    }
}
```

#### 6.2 TodayMiddleware.swift
Similar pattern for Today feature

#### 6.3 LocationsMiddleware.swift
```swift
func locationsMiddleware(
    state: AppState,
    action: AppAction,
    dispatch: @escaping (AppAction) -> Void,
    services: ServiceContainer
) {
    guard case .locations(let locAction) = action else { return }

    switch locAction {
    case .task, .refreshLocations:
        Task {
            do {
                let locations = try await services.persistenceService.fetchLocations()
                dispatch(.locations(.locationsLoaded(.success(locations))))
            } catch {
                dispatch(.locations(.locationsLoaded(.failure(error))))
            }
        }
    // ... more cases
    }
}
```

#### 6.4 ShiftTypesMiddleware.swift
Similar pattern for ShiftTypes feature

#### 6.5 ChangeLogMiddleware.swift
Similar pattern for ChangeLog feature

#### 6.6 SettingsMiddleware.swift
Similar pattern for Settings feature

---

## Phase 2 Directory Structure

```
ShiftScheduler/Redux/Services/
├── Protocols/
│   ├── CalendarServiceProtocol.swift
│   ├── PersistenceServiceProtocol.swift
│   ├── ShiftSwitchServiceProtocol.swift
│   └── CurrentDayServiceProtocol.swift
├── Production/
│   ├── CalendarService.swift
│   ├── PersistenceService.swift
│   ├── ShiftSwitchService.swift
│   └── CurrentDayService.swift
├── Mocks/
│   ├── MockCalendarService.swift
│   ├── MockPersistenceService.swift
│   ├── MockShiftSwitchService.swift
│   └── MockCurrentDayService.swift
├── ServiceContainer.swift
└── README.md (documentation)

ShiftScheduler/Redux/Middleware/
├── LoggingMiddleware.swift (existing)
├── ScheduleMiddleware.swift
├── TodayMiddleware.swift
├── LocationsMiddleware.swift
├── ShiftTypesMiddleware.swift
├── ChangeLogMiddleware.swift
└── SettingsMiddleware.swift
```

---

## Phase 2 Testing Strategy

### Unit Tests for Services
```swift
@Test func testCalendarService_fetchShifts() async throws {
    let service = CalendarService.shared
    let shifts = try await service.fetchShifts(start: Date(), end: Date())
    #expect(!shifts.isEmpty)
}

@Test func testMockCalendarService() async throws {
    let service = MockCalendarService()
    service.mockShifts = [/* test shifts */]
    let shifts = try await service.fetchShifts(start: Date(), end: Date())
    #expect(shifts.count == 1)
}
```

### Middleware Tests
```swift
@Test func testScheduleMiddleware_loadShifts() async {
    let mockCalendar = MockCalendarService()
    mockCalendar.mockShifts = [/* test shifts */]
    let services = ServiceContainer.mock(calendar: mockCalendar)

    var dispatchedActions: [AppAction] = []
    let mockDispatch: (AppAction) -> Void = { action in
        dispatchedActions.append(action)
    }

    scheduleMiddleware(
        state: AppState(),
        action: .schedule(.loadShifts),
        dispatch: mockDispatch,
        services: services
    )

    try await Task.sleep(nanoseconds: 100_000_000)
    #expect(dispatchedActions.contains { /* verify action */ })
}
```

---

## Phase 2 Deliverables

- ✅ 4 service protocols (Calendar, Persistence, ShiftSwitch, CurrentDay)
- ✅ 4 production service implementations
- ✅ 4 mock service implementations
- ✅ ServiceContainer for dependency injection
- ✅ 6 feature middleware implementations
- ✅ Store updated to accept services
- ✅ Service integration tests
- ✅ Middleware unit tests
- ✅ All code Swift 6 compliant

---

## Phase 2 Success Criteria

✅ All service protocols defined
✅ Production services wrap existing implementations
✅ Mock services work with Redux
✅ ServiceContainer provides clean dependency injection
✅ All middlewares integrated with services
✅ Services are testable and mockable
✅ No external dependencies in middleware
✅ Async operations properly handled
✅ All tests passing
✅ Zero compilation errors/warnings

---

## Estimated Timeline

| Task | Duration | Days |
|------|----------|------|
| 1. Service Protocols | 4-6 hours | 0.5-1 |
| 2. Production Services | 6-8 hours | 1 |
| 3. Mock Services | 4-6 hours | 0.5-1 |
| 4. ServiceContainer | 2-3 hours | 0.3 |
| 5. Middleware Integration | 8-10 hours | 1-1.5 |
| 6. Testing | 6-8 hours | 1 |
| **Total** | **30-41 hours** | **3.3-5.3 days** |

---

## Dependencies

- Phase 1: ✅ COMPLETE (Redux foundation)
- Existing Services: Already in codebase (EventKitClient, etc.)
- Domain Models: ✅ Available (Location, ShiftType, ScheduledShift, etc.)

---

## Notes

- Services wrap existing implementations to minimize refactoring
- Protocols make testing easier with mocks
- ServiceContainer follows dependency injection pattern
- Middleware delegates to services for side effects
- No changes to existing service implementations needed
- Can be developed and tested independently

---

**Phase 2 Status**: 🟡 READY TO START
**Next Step**: Implement service protocols (Task 1)

