# Redux Migration Plan: ShiftScheduler TCA → Redux

## Executive Summary

This document outlines a comprehensive migration plan to transition ShiftScheduler from The Composable Architecture (TCA) to a Redux-based architecture pattern, following the implementation model from ToDoAppCompositeArchitecture.

### Migration Rationale

- **Swift 6 Compliance Issues**: TCA is experiencing significant challenges with Swift 6's strict concurrency checking
- **Simpler Mental Model**: Redux's unidirectional data flow is easier to understand and debug
- **Better Testability**: Pure reducer functions and middleware pattern enable comprehensive unit testing
- **No External Dependencies**: Redux implementation is self-contained, eliminating TCA dependency
- **Native Swift 6 Support**: Redux pattern leverages @Observable and modern concurrency primitives

---

## Architecture Comparison

### TCA (Current)
```swift
@Reducer
struct ScheduleFeature {
    @ObservableState struct State { }
    enum Action { }
    @Dependency(\.calendarClient) var calendarClient
    var body: some Reducer<State, Action> { }
}
```

### Redux (Target)
```swift
struct AppState {
    var schedule: ScheduleState = ScheduleState()
}

enum AppAction {
    case schedule(ScheduleAction)
}

@Observable
class Store {
    private(set) var state: AppState
    func dispatch(action: AppAction) { }
}
```

---

## Current State Analysis

### TCA Features to Migrate

| Feature | Lines of Code | Complexity | Dependencies |
|---------|---------------|------------|--------------|
| AppFeature | 94 | Low | calendarClient, persistenceClient |
| ScheduleFeature | 429 | High | calendarClient, shiftSwitchClient |
| TodayFeature | 300 | Medium | calendarClient, shiftSwitchClient |
| LocationsFeature | 195 | Medium | persistenceClient |
| ShiftTypesFeature | 384 | High | persistenceClient |
| AddEditLocationFeature | ~150 | Low | persistenceClient |
| AddEditShiftTypeFeature | 384 | Medium | persistenceClient |
| ChangeLogFeature | Unknown | Medium | persistenceClient |
| ScheduleShiftFeature | Unknown | Low | calendarClient |
| SettingsFeature | Unknown | Low | persistenceClient |

**Total Estimated LOC**: ~2,500+ lines

### TCA Dependencies (Clients)

| Client | Purpose | Complexity |
|--------|---------|------------|
| CalendarClient | EventKit calendar operations | High |
| EventKitClient | Low-level EventKit abstraction | High |
| ShiftSwitchClient | Shift switching with undo/redo | High |
| PersistenceClient | JSON file persistence | Medium |
| CurrentDayClient | Date utilities | Low |
| UserProfileClient | User settings management | Low |
| ChangeLogRepositoryClient | Change log persistence | Medium |

---

## Redux Implementation Architecture

### Core Components

#### 1. Store (Single Source of Truth)
```swift
@Observable
@MainActor
class Store {
    private(set) var state: AppState
    private let reducer: @MainActor (AppState, AppAction) -> AppState
    private let middlewares: [Middleware]

    func dispatch(action: AppAction) {
        state = reducer(state, action)
        middlewares.forEach { middleware in
            middleware(state, action, dispatch)
        }
    }
}
```

#### 2. AppState (Composite State)
```swift
struct AppState: Equatable {
    var selectedTab: Tab = .today
    var userProfile: UserProfile = UserProfile(userId: UUID(), displayName: "User")

    // Feature States
    var today: TodayState = TodayState()
    var schedule: ScheduleState = ScheduleState()
    var shiftTypes: ShiftTypesState = ShiftTypesState()
    var locations: LocationsState = LocationsState()
    var changeLog: ChangeLogState = ChangeLogState()
    var settings: SettingsState = SettingsState()
}
```

#### 3. Actions (Enum Hierarchy)
```swift
enum AppAction: Equatable {
    case appLifecycle(AppLifecycleAction)
    case today(TodayAction)
    case schedule(ScheduleAction)
    case shiftTypes(ShiftTypesAction)
    case locations(LocationsAction)
    case changeLog(ChangeLogAction)
    case settings(SettingsAction)
}

enum TodayAction: Equatable {
    case task
    case loadShifts
    case shiftsLoaded(Result<[ScheduledShift], Error>)
    case switchShiftTapped(ScheduledShift)
    // ... more actions
}
```

#### 4. Reducers (Pure Functions)
```swift
func appReducer(state: AppState, action: AppAction) -> AppState {
    var state = state
    switch action {
    case .appLifecycle(let action):
        state = appLifecycleReducer(state: state, action: action)
    case .today(let action):
        state.today = todayReducer(state: state.today, action: action, appState: state)
    case .schedule(let action):
        state.schedule = scheduleReducer(state: state.schedule, action: action)
    // ... more cases
    }
    return state
}

func todayReducer(state: TodayState, action: TodayAction, appState: AppState) -> TodayState {
    var state = state
    switch action {
    case .task:
        state.isLoading = true
    case .loadShifts:
        state.isLoading = true
    case .shiftsLoaded(.success(let shifts)):
        state.isLoading = false
        state.scheduledShifts = shifts
    // ... more cases
    }
    return state
}
```

#### 5. Middleware (Side Effects)
```swift
typealias Middleware = @MainActor @Sendable (AppState, AppAction, @escaping (AppAction) -> Void) -> Void

func calendarMiddleware(state: AppState, action: AppAction, dispatch: @escaping (AppAction) -> Void) {
    switch action {
    case .today(.loadShifts):
        Task {
            do {
                let shifts = try await CalendarService.shared.fetchShifts()
                dispatch(.today(.shiftsLoaded(.success(shifts))))
            } catch {
                dispatch(.today(.shiftsLoaded(.failure(error))))
            }
        }
    // ... more cases
    }
}
```

#### 6. Service Layer (Dependencies)
```swift
// Protocol-based services for testing
protocol CalendarServiceProtocol {
    func fetchShifts(start: Date, end: Date) async throws -> [ScheduledShift]
    func deleteShift(eventId: String) async throws
}

// Production implementation
@MainActor
class CalendarService: CalendarServiceProtocol {
    static let shared = CalendarService()

    func fetchShifts(start: Date, end: Date) async throws -> [ScheduledShift] {
        // EventKit implementation
    }
}

// Test mock
class MockCalendarService: CalendarServiceProtocol {
    var mockShifts: [ScheduledShift] = []
    func fetchShifts(start: Date, end: Date) async throws -> [ScheduledShift] {
        return mockShifts
    }
}
```

---

## Migration Strategy

### Phase-Based Approach

We'll migrate in 6 phases, starting with foundation and progressing through features:

1. **Phase 1: Redux Foundation** (3-5 days)
2. **Phase 2: Service Layer** (3-5 days)
3. **Phase 3: Simple Features** (5-7 days)
4. **Phase 4: Complex Features** (7-10 days)
5. **Phase 5: Integration & Testing** (3-5 days)
6. **Phase 6: TCA Removal & Cleanup** (2-3 days)

**Total Estimated Duration**: 23-35 days

---

## Phase 1: Redux Foundation

### Goal
Establish core Redux infrastructure without removing TCA

### Tasks

#### 1.1 Create Redux Core Directory Structure
```
ShiftScheduler/
├── Redux/
│   ├── Store/
│   │   └── Store.swift
│   ├── State/
│   │   └── AppState.swift
│   ├── Action/
│   │   └── AppAction.swift
│   ├── Reducer/
│   │   └── AppReducer.swift
│   └── Middleware/
│       └── LoggingMiddleware.swift
```

#### 1.2 Implement Store.swift
```swift
import Foundation
import Observation

typealias Middleware = @MainActor @Sendable (AppState, AppAction, @escaping (AppAction) -> Void) -> Void

@Observable
@MainActor
class Store {
    private(set) var state: AppState
    private let reducer: @MainActor (AppState, AppAction) -> AppState
    private let middlewares: [Middleware]

    init(
        state: AppState,
        reducer: @escaping @MainActor (AppState, AppAction) -> AppState,
        middlewares: [Middleware] = []
    ) {
        self.state = state
        self.reducer = reducer
        self.middlewares = middlewares
    }

    func dispatch(action: AppAction) {
        Logger.debug("[Redux] Dispatching action: \(String(describing: action))")

        // Phase 1: Update state (pure, synchronous)
        state = reducer(state, action)

        // Phase 2: Execute middlewares (side effects, can be async)
        middlewares.forEach { middleware in
            middleware(state, action, dispatch)
        }
    }
}
```

#### 1.3 Implement AppState.swift
```swift
struct AppState: Equatable {
    var selectedTab: Tab = .today
    var userProfile: UserProfile = UserProfile(userId: UUID(), displayName: "User")

    // Feature states (will be added incrementally)
    var today: TodayState = TodayState()
    var schedule: ScheduleState = ScheduleState()
    var shiftTypes: ShiftTypesState = ShiftTypesState()
    var locations: LocationsState = LocationsState()
    var changeLog: ChangeLogState = ChangeLogState()
    var settings: SettingsState = SettingsState()
}

// Feature state structs
struct TodayState: Equatable {
    var scheduledShifts: [ScheduledShift] = []
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var todayShift: ScheduledShift? = nil
    var tomorrowShift: ScheduledShift? = nil
    var thisWeekShiftsCount: Int = 0
    var completedThisWeek: Int = 0
    var canUndo: Bool = false
    var canRedo: Bool = false
    var selectedShift: ScheduledShift? = nil
}

struct ScheduleState: Equatable {
    var scheduledShifts: [ScheduledShift] = []
    var selectedDate: Date = Date()
    var isLoading: Bool = false
    var isCalendarAuthorized: Bool = false
    var errorMessage: String? = nil
    var searchText: String = ""
    var toastMessage: ToastMessage? = nil
    var showAddShiftSheet: Bool = false
    var undoStack: [ShiftSwitchOperation] = []
    var redoStack: [ShiftSwitchOperation] = []

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    var filteredShifts: [ScheduledShift] {
        if searchText.isEmpty {
            return shiftsForSelectedDate
        }
        return shiftsForSelectedDate.filter { shift in
            shift.shiftType?.title.localizedCaseInsensitiveContains(searchText) ?? false
        }
    }

    var shiftsForSelectedDate: [ScheduledShift] {
        scheduledShifts.filter { shift in
            Calendar.current.isDate(shift.date, inSameDayAs: selectedDate)
        }
    }
}

// ... more state structs
```

#### 1.4 Implement AppAction.swift
```swift
enum AppAction: Equatable {
    case appLifecycle(AppLifecycleAction)
    case today(TodayAction)
    case schedule(ScheduleAction)
    case shiftTypes(ShiftTypesAction)
    case locations(LocationsAction)
    case changeLog(ChangeLogAction)
    case settings(SettingsAction)

    static func == (lhs: AppAction, rhs: AppAction) -> Bool {
        switch (lhs, rhs) {
        case (.appLifecycle(let a), .appLifecycle(let b)):
            return a == b
        case (.today(let a), .today(let b)):
            return a == b
        case (.schedule(let a), .schedule(let b)):
            return a == b
        // ... more cases
        default:
            return false
        }
    }
}

enum AppLifecycleAction: Equatable {
    case onAppear
    case tabSelected(Tab)
    case userProfileUpdated(UserProfile)
}

enum TodayAction: Equatable {
    case task
    case loadShifts
    case shiftsLoaded(Result<[ScheduledShift], Error>)
    case switchShiftTapped(ScheduledShift)
    case performSwitchShift(ScheduledShift, ShiftType, String?)
    case shiftSwitched(Result<Void, Error>)
    case updateCachedShifts
    case updateUndoRedoStates

    // Custom Equatable for Result types
    static func == (lhs: TodayAction, rhs: TodayAction) -> Bool {
        switch (lhs, rhs) {
        case (.task, .task), (.loadShifts, .loadShifts):
            return true
        case (.shiftsLoaded(.success), .shiftsLoaded(.success)):
            return true
        case (.shiftsLoaded(.failure), .shiftsLoaded(.failure)):
            return true
        case (.switchShiftTapped(let a), .switchShiftTapped(let b)):
            return a.id == b.id
        // ... more cases
        default:
            return false
        }
    }
}

// ... more action enums
```

#### 1.5 Implement AppReducer.swift
```swift
import OSLog

private let logger = OSLog.Logger(subsystem: "com.shiftscheduler.app", category: "Redux")

func appReducer(state: AppState, action: AppAction) -> AppState {
    var state = state

    switch action {
    case .appLifecycle(let action):
        state = appLifecycleReducer(state: state, action: action)

    case .today(let action):
        state.today = todayReducer(state: state.today, action: action)

    case .schedule(let action):
        state.schedule = scheduleReducer(state: state.schedule, action: action)

    case .shiftTypes(let action):
        state.shiftTypes = shiftTypesReducer(state: state.shiftTypes, action: action)

    case .locations(let action):
        state.locations = locationsReducer(state: state.locations, action: action)

    case .changeLog(let action):
        state.changeLog = changeLogReducer(state: state.changeLog, action: action)

    case .settings(let action):
        state.settings = settingsReducer(state: state.settings, action: action)
    }

    return state
}

func appLifecycleReducer(state: AppState, action: AppLifecycleAction) -> AppState {
    var state = state

    switch action {
    case .onAppear:
        logger.debug("App appeared")

    case .tabSelected(let tab):
        state.selectedTab = tab

    case .userProfileUpdated(let profile):
        state.userProfile = profile
    }

    return state
}
```

#### 1.6 Implement LoggingMiddleware.swift
```swift
import OSLog

private let logger = OSLog.Logger(subsystem: "com.shiftscheduler.app", category: "Middleware")

func loggingMiddleware(state: AppState, action: AppAction, dispatch: @escaping (AppAction) -> Void) {
    logger.debug("[Middleware] Action dispatched: \(String(describing: action))")
    logger.debug("[Middleware] Current state tab: \(state.selectedTab)")
}
```

#### 1.7 Create Test Store in App Entry Point
```swift
import SwiftUI

@main
struct ShiftSchedulerApp: App {
    // Keep TCA store for now
    @State private var tcaStore = ComposableArchitecture.Store(
        initialState: AppFeature.State()
    ) {
        AppFeature()
    }

    // Add Redux store (parallel testing)
    @State private var reduxStore = Store(
        state: AppState(),
        reducer: appReducer,
        middlewares: [loggingMiddleware]
    )

    var body: some Scene {
        WindowGroup {
            // Use TCA for now
            AppView(store: tcaStore)

            // TODO: Switch to Redux once migration complete
            // ReduxAppView(store: reduxStore)
        }
    }
}
```

### Phase 1 Deliverables

- ✅ Store.swift with dispatch mechanism
- ✅ AppState.swift with all feature states
- ✅ AppAction.swift with action hierarchy
- ✅ AppReducer.swift with reducer composition
- ✅ LoggingMiddleware.swift for debugging
- ✅ Parallel Redux store instantiation (not yet used)
- ✅ All code compiles with Swift 6 strict concurrency

### Phase 1 Testing

Run build to verify:
```bash
xcodebuild -project ShiftScheduler.xcodeproj \
  -scheme ShiftScheduler \
  -destination 'platform=iOS Simulator,id=490A490A-C97A-43EE-978E-148A74A72499' \
  build
```

---

## Phase 2: Service Layer

### Goal
Create protocol-based service layer to replace TCA dependency injection

### Tasks

#### 2.1 Create Services Directory
```
ShiftScheduler/
├── Services/
│   ├── Protocols/
│   │   ├── CalendarServiceProtocol.swift
│   │   ├── PersistenceServiceProtocol.swift
│   │   ├── ShiftSwitchServiceProtocol.swift
│   │   └── CurrentDayServiceProtocol.swift
│   ├── Production/
│   │   ├── CalendarService.swift
│   │   ├── PersistenceService.swift
│   │   ├── ShiftSwitchService.swift
│   │   └── CurrentDayService.swift
│   └── Mock/
│       ├── MockCalendarService.swift
│       ├── MockPersistenceService.swift
│       ├── MockShiftSwitchService.swift
│       └── MockCurrentDayService.swift
```

#### 2.2 Define Service Protocols

**CalendarServiceProtocol.swift**
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

**PersistenceServiceProtocol.swift**
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

**ShiftSwitchServiceProtocol.swift**
```swift
protocol ShiftSwitchServiceProtocol: Sendable {
    func switchShift(
        eventId: String,
        date: Date,
        oldShift: ShiftType,
        newShift: ShiftType,
        reason: String?
    ) async throws -> ShiftSwitchOperation

    func undoOperation(_ operation: ShiftSwitchOperation) async throws
    func redoOperation(_ operation: ShiftSwitchOperation) async throws
    func persistStacks(undo: [ShiftSwitchOperation], redo: [ShiftSwitchOperation]) async
    func restoreStacks() async throws -> (undo: [ShiftSwitchOperation], redo: [ShiftSwitchOperation])
}
```

#### 2.3 Implement Production Services

Wrap existing TCA clients initially:

**CalendarService.swift**
```swift
@MainActor
class CalendarService: CalendarServiceProtocol {
    static let shared = CalendarService()

    private let eventKitClient: EventKitClient
    private let calendarClient: CalendarClient

    private init() {
        // Use TCA dependency values temporarily
        self.eventKitClient = EventKitClient.liveValue
        self.calendarClient = CalendarClient.liveValue
    }

    nonisolated func requestAuthorization() async -> Bool {
        await MainActor.run {
            eventKitClient.requestAuthorization()
        }
    }

    nonisolated func isAuthorized() -> Bool {
        eventKitClient.isAuthorized()
    }

    nonisolated func fetchShifts(start: Date, end: Date) async throws -> [ScheduledShift] {
        let shiftData = try await calendarClient.fetchShiftsInRange(start, end)
        return shiftData.map { data in
            ScheduledShift(
                id: UUID(),
                eventIdentifier: data.eventIdentifier,
                shiftType: nil,
                date: data.date
            )
        }
    }

    // ... more methods
}
```

#### 2.4 Implement Mock Services

**MockCalendarService.swift**
```swift
class MockCalendarService: CalendarServiceProtocol {
    var isAuthorizedValue = true
    var mockShifts: [ScheduledShift] = []
    var shouldThrowError = false

    nonisolated func requestAuthorization() async -> Bool {
        isAuthorizedValue
    }

    nonisolated func isAuthorized() -> Bool {
        isAuthorizedValue
    }

    nonisolated func fetchShifts(start: Date, end: Date) async throws -> [ScheduledShift] {
        if shouldThrowError {
            throw NSError(domain: "MockError", code: 1)
        }
        return mockShifts
    }

    // ... more methods
}
```

#### 2.5 Create Service Container

**ServiceContainer.swift**
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

### Phase 2 Deliverables

- ✅ Service protocols for all dependencies
- ✅ Production service implementations (wrapping TCA clients)
- ✅ Mock service implementations for testing
- ✅ ServiceContainer for dependency injection
- ✅ All services marked @MainActor or nonisolated appropriately
- ✅ Swift 6 concurrency compliant

### Phase 2 Testing

Create simple unit test:
```swift
@Test func testMockCalendarService() async throws {
    let service = MockCalendarService()
    service.mockShifts = [
        ScheduledShift(id: UUID(), eventIdentifier: "test", shiftType: nil, date: Date())
    ]

    let shifts = try await service.fetchShifts(start: Date(), end: Date())
    #expect(shifts.count == 1)
}
```

---

## Phase 3: Simple Features Migration

### Goal
Migrate simple features (Locations, Settings) to Redux pattern

### Tasks

#### 3.1 Migrate LocationsFeature

**Redux/State/LocationsState.swift**
```swift
struct LocationsState: Equatable {
    var locations: [Location] = []
    var searchText: String = ""
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var showAddEditSheet: Bool = false
    var editingLocation: Location? = nil

    var filteredLocations: [Location] {
        if searchText.isEmpty {
            return locations
        }
        return locations.filter { location in
            location.name.localizedCaseInsensitiveContains(searchText) ||
            location.address.localizedCaseInsensitiveContains(searchText)
        }
    }
}
```

**Redux/Action/LocationsAction.swift**
```swift
enum LocationsAction: Equatable {
    case task
    case searchTextChanged(String)
    case addButtonTapped
    case editLocation(Location)
    case deleteLocation(Location)
    case locationsLoaded(Result<[Location], Error>)
    case locationDeleted(Result<Void, Error>)
    case addEditSheetDismissed
    case refreshLocations

    // Equatable implementation...
}
```

**Redux/Reducer/LocationsReducer.swift**
```swift
func locationsReducer(state: LocationsState, action: LocationsAction) -> LocationsState {
    var state = state

    switch action {
    case .task:
        state.isLoading = true

    case .searchTextChanged(let text):
        state.searchText = text

    case .addButtonTapped:
        state.showAddEditSheet = true
        state.editingLocation = nil

    case .editLocation(let location):
        state.showAddEditSheet = true
        state.editingLocation = location

    case .deleteLocation:
        state.isLoading = true

    case .locationsLoaded(.success(let locations)):
        state.isLoading = false
        state.locations = locations
        state.errorMessage = nil

    case .locationsLoaded(.failure(let error)):
        state.isLoading = false
        state.errorMessage = "Failed to load: \(error.localizedDescription)"

    case .locationDeleted(.success):
        state.isLoading = false

    case .locationDeleted(.failure(let error)):
        state.isLoading = false
        state.errorMessage = "Failed to delete: \(error.localizedDescription)"

    case .addEditSheetDismissed:
        state.showAddEditSheet = false
        state.editingLocation = nil

    case .refreshLocations:
        state.isLoading = true
    }

    return state
}
```

**Redux/Middleware/LocationsMiddleware.swift**
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

    case .deleteLocation(let location):
        Task {
            do {
                try await services.persistenceService.deleteLocation(location)
                dispatch(.locations(.locationDeleted(.success(()))))
                dispatch(.locations(.refreshLocations))
            } catch {
                dispatch(.locations(.locationDeleted(.failure(error))))
            }
        }

    default:
        break
    }
}
```

**SwiftUIViews/Redux/LocationsView.swift**
```swift
struct LocationsView: View {
    var store: Store

    var body: some View {
        NavigationStack {
            if store.state.locations.isLoading {
                ProgressView()
            } else {
                List {
                    ForEach(store.state.locations.filteredLocations) { location in
                        LocationRow(location: location, onEdit: {
                            store.dispatch(action: .locations(.editLocation(location)))
                        })
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { index in
                            let location = store.state.locations.filteredLocations[index]
                            store.dispatch(action: .locations(.deleteLocation(location)))
                        }
                    }
                }
                .searchable(text: Binding(
                    get: { store.state.locations.searchText },
                    set: { store.dispatch(action: .locations(.searchTextChanged($0))) }
                ))
            }
        }
        .navigationTitle("Locations")
        .toolbar {
            Button("Add") {
                store.dispatch(action: .locations(.addButtonTapped))
            }
        }
        .sheet(isPresented: Binding(
            get: { store.state.locations.showAddEditSheet },
            set: { if !$0 { store.dispatch(action: .locations(.addEditSheetDismissed)) } }
        )) {
            AddEditLocationView(
                location: store.state.locations.editingLocation,
                onSave: { location in
                    // Save logic handled by middleware
                    store.dispatch(action: .locations(.refreshLocations))
                }
            )
        }
        .task {
            store.dispatch(action: .locations(.task))
        }
    }
}
```

#### 3.2 Migrate SettingsFeature

Similar pattern to Locations (simpler, no complex dependencies)

### Phase 3 Deliverables

- ✅ LocationsState, LocationsAction, locationsReducer
- ✅ LocationsMiddleware with PersistenceService integration
- ✅ Redux-based LocationsView
- ✅ SettingsState, SettingsAction, settingsReducer
- ✅ Redux-based SettingsView
- ✅ Unit tests for reducers and middleware
- ✅ TCA Locations/Settings features still present but unused

### Phase 3 Testing

Test reducer purity:
```swift
@Test func testLocationsReducer_searchTextChanged() {
    var state = LocationsState()
    state = locationsReducer(state: state, action: .searchTextChanged("Test"))
    #expect(state.searchText == "Test")
}

@Test func testLocationsReducer_locationsLoaded() {
    var state = LocationsState(isLoading: true)
    let locations = [Location(id: UUID(), name: "Office", address: "123 Main St")]
    state = locationsReducer(state: state, action: .locationsLoaded(.success(locations)))
    #expect(state.isLoading == false)
    #expect(state.locations.count == 1)
}
```

---

## Phase 4: Complex Features Migration

### Goal
Migrate complex features (Schedule, Today, ShiftTypes) with side effects

### Tasks

#### 4.1 Migrate ScheduleFeature

**Key Challenges:**
- Complex undo/redo logic
- Calendar authorization
- Shift switching with state restoration
- Multiple async operations

**Redux/State/ScheduleState.swift**
```swift
struct ScheduleState: Equatable {
    var scheduledShifts: [ScheduledShift] = []
    var selectedDate: Date = Date()
    var isLoading: Bool = false
    var isCalendarAuthorized: Bool = false
    var errorMessage: String? = nil
    var searchText: String = ""
    var toastMessage: ToastMessage? = nil
    var showAddShiftSheet: Bool = false
    var undoStack: [ShiftSwitchOperation] = []
    var redoStack: [ShiftSwitchOperation] = []

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    var filteredShifts: [ScheduledShift] {
        if searchText.isEmpty { return shiftsForSelectedDate }
        return shiftsForSelectedDate.filter { shift in
            shift.shiftType?.title.localizedCaseInsensitiveContains(searchText) ?? false
        }
    }

    var shiftsForSelectedDate: [ScheduledShift] {
        scheduledShifts.filter { shift in
            Calendar.current.isDate(shift.date, inSameDayAs: selectedDate)
        }
    }
}
```

**Redux/Action/ScheduleAction.swift**
```swift
enum ScheduleAction: Equatable {
    case task
    case checkAuthorization
    case authorizationChecked(Bool)
    case loadShifts
    case selectedDateChanged(Date)
    case searchTextChanged(String)
    case addShiftButtonTapped
    case deleteShift(ScheduledShift)
    case shiftDeleted(Result<Void, Error>)
    case switchShiftTapped(ScheduledShift)
    case performSwitchShift(ScheduledShift, ShiftType, String?)
    case shiftSwitched(Result<ShiftSwitchOperation, Error>)
    case shiftsLoaded(Result<[ScheduledShift], Error>)
    case stacksRestored(Result<(undo: [ShiftSwitchOperation], redo: [ShiftSwitchOperation]), Error>)
    case undo
    case redo
    case undoCompleted(Result<Void, Error>)
    case redoCompleted(Result<Void, Error>)

    // Equatable implementation...
}
```

**Redux/Reducer/ScheduleReducer.swift**
```swift
func scheduleReducer(state: ScheduleState, action: ScheduleAction) -> ScheduleState {
    var state = state

    switch action {
    case .task:
        state.isLoading = true

    case .checkAuthorization:
        break // Handled by middleware

    case .authorizationChecked(let isAuthorized):
        state.isCalendarAuthorized = isAuthorized

    case .loadShifts:
        state.isLoading = true
        state.errorMessage = nil

    case .selectedDateChanged(let date):
        state.selectedDate = date
        state.searchText = ""

    case .searchTextChanged(let text):
        state.searchText = text

    case .addShiftButtonTapped:
        state.showAddShiftSheet = true

    case .deleteShift:
        break // Handled by middleware

    case .shiftDeleted(.success):
        state.toastMessage = .success("Shift deleted")

    case .shiftDeleted(.failure(let error)):
        state.toastMessage = .error("Delete failed: \(error.localizedDescription)")

    case .switchShiftTapped:
        break // UI handles presenting sheet

    case .performSwitchShift:
        state.isLoading = true

    case .shiftSwitched(.success(let operation)):
        state.isLoading = false
        state.toastMessage = .success("Shift switched successfully")
        state.undoStack.append(operation)
        state.redoStack.removeAll()

    case .shiftSwitched(.failure(let error)):
        state.isLoading = false
        state.toastMessage = .error("Switch failed: \(error.localizedDescription)")

    case .shiftsLoaded(.success(let shifts)):
        state.isLoading = false
        state.scheduledShifts = shifts
        state.errorMessage = nil

    case .shiftsLoaded(.failure(let error)):
        state.isLoading = false
        state.errorMessage = error.localizedDescription

    case .stacksRestored(.success(let stacks)):
        state.undoStack = stacks.undo
        state.redoStack = stacks.redo

    case .stacksRestored(.failure(let error)):
        state.errorMessage = "Failed to restore undo/redo: \(error.localizedDescription)"

    case .undo:
        guard !state.undoStack.isEmpty else {
            state.toastMessage = .error("No operation to undo")
            return state
        }
        state.isLoading = true

    case .undoCompleted(.success):
        state.isLoading = false
        if !state.undoStack.isEmpty {
            let operation = state.undoStack.removeLast()
            state.redoStack.append(operation)
        }
        state.toastMessage = .success("Undo successful")

    case .undoCompleted(.failure(let error)):
        state.isLoading = false
        state.toastMessage = .error("Undo failed: \(error.localizedDescription)")

    case .redo:
        guard !state.redoStack.isEmpty else {
            state.toastMessage = .error("No operation to redo")
            return state
        }
        state.isLoading = true

    case .redoCompleted(.success):
        state.isLoading = false
        if !state.redoStack.isEmpty {
            let operation = state.redoStack.removeLast()
            state.undoStack.append(operation)
        }
        state.toastMessage = .success("Redo successful")

    case .redoCompleted(.failure(let error)):
        state.isLoading = false
        state.toastMessage = .error("Redo failed: \(error.localizedDescription)")
    }

    return state
}
```

**Redux/Middleware/ScheduleMiddleware.swift**
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

    case .checkAuthorization:
        Task {
            let isAuthorized = await services.calendarService.requestAuthorization()
            dispatch(.schedule(.authorizationChecked(isAuthorized)))
        }

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

    case .selectedDateChanged:
        dispatch(.schedule(.loadShifts))

    case .deleteShift(let shift):
        Task {
            do {
                try await services.calendarService.deleteShift(eventId: shift.eventIdentifier)
                dispatch(.schedule(.shiftDeleted(.success(()))))
                dispatch(.schedule(.loadShifts))
            } catch {
                dispatch(.schedule(.shiftDeleted(.failure(error))))
            }
        }

    case .performSwitchShift(let shift, let newShiftType, let reason):
        Task {
            guard let oldShiftType = shift.shiftType else {
                let error = NSError(domain: "ScheduleError", code: 1, userInfo: [
                    NSLocalizedDescriptionKey: "Current shift type not found"
                ])
                dispatch(.schedule(.shiftSwitched(.failure(error))))
                return
            }

            do {
                let operation = try await services.shiftSwitchService.switchShift(
                    eventId: shift.eventIdentifier,
                    date: shift.date,
                    oldShift: oldShiftType,
                    newShift: newShiftType,
                    reason: reason
                )
                dispatch(.schedule(.shiftSwitched(.success(operation))))

                // Persist stacks
                let undoStack = state.schedule.undoStack + [operation]
                await services.shiftSwitchService.persistStacks(
                    undo: undoStack,
                    redo: []
                )

                // Reload shifts
                dispatch(.schedule(.loadShifts))
            } catch {
                dispatch(.schedule(.shiftSwitched(.failure(error))))
            }
        }

    case .undo:
        Task {
            guard let operation = state.schedule.undoStack.last else { return }

            do {
                try await services.shiftSwitchService.undoOperation(operation)
                dispatch(.schedule(.undoCompleted(.success(()))))

                // Persist updated stacks
                var undoStack = state.schedule.undoStack
                undoStack.removeLast()
                var redoStack = state.schedule.redoStack
                redoStack.append(operation)

                await services.shiftSwitchService.persistStacks(
                    undo: undoStack,
                    redo: redoStack
                )

                dispatch(.schedule(.loadShifts))
            } catch {
                dispatch(.schedule(.undoCompleted(.failure(error))))
            }
        }

    case .redo:
        Task {
            guard let operation = state.schedule.redoStack.last else { return }

            do {
                try await services.shiftSwitchService.redoOperation(operation)
                dispatch(.schedule(.redoCompleted(.success(()))))

                // Persist updated stacks
                var undoStack = state.schedule.undoStack
                undoStack.append(operation)
                var redoStack = state.schedule.redoStack
                redoStack.removeLast()

                await services.shiftSwitchService.persistStacks(
                    undo: undoStack,
                    redo: redoStack
                )

                dispatch(.schedule(.loadShifts))
            } catch {
                dispatch(.schedule(.redoCompleted(.failure(error))))
            }
        }

    default:
        break
    }
}
```

**SwiftUIViews/Redux/ScheduleView.swift**
```swift
struct ScheduleView: View {
    var store: Store

    var body: some View {
        NavigationStack {
            VStack {
                if store.state.schedule.isLoading {
                    ProgressView()
                } else {
                    CalendarMonthView(
                        selectedDate: Binding(
                            get: { store.state.schedule.selectedDate },
                            set: { store.dispatch(action: .schedule(.selectedDateChanged($0))) }
                        ),
                        shifts: store.state.schedule.scheduledShifts
                    )

                    List {
                        ForEach(store.state.schedule.filteredShifts) { shift in
                            ShiftRow(
                                shift: shift,
                                onSwitch: {
                                    store.dispatch(action: .schedule(.switchShiftTapped(shift)))
                                },
                                onDelete: {
                                    store.dispatch(action: .schedule(.deleteShift(shift)))
                                }
                            )
                        }
                    }
                    .searchable(text: Binding(
                        get: { store.state.schedule.searchText },
                        set: { store.dispatch(action: .schedule(.searchTextChanged($0))) }
                    ))
                }
            }
            .navigationTitle("Schedule")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack {
                        Button("Undo") {
                            store.dispatch(action: .schedule(.undo))
                        }
                        .disabled(!store.state.schedule.canUndo)

                        Button("Redo") {
                            store.dispatch(action: .schedule(.redo))
                        }
                        .disabled(!store.state.schedule.canRedo)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Shift") {
                        store.dispatch(action: .schedule(.addShiftButtonTapped))
                    }
                }
            }
            .task {
                store.dispatch(action: .schedule(.task))
            }
        }
    }
}
```

#### 4.2 Migrate TodayFeature

Similar complexity to Schedule, but simpler UI

#### 4.3 Migrate ShiftTypesFeature

Medium complexity with CRUD operations

### Phase 4 Deliverables

- ✅ ScheduleState, ScheduleAction, scheduleReducer
- ✅ ScheduleMiddleware with complex async flows
- ✅ Redux-based ScheduleView
- ✅ TodayState, TodayAction, todayReducer
- ✅ Redux-based TodayView
- ✅ ShiftTypesState, ShiftTypesAction, shiftTypesReducer
- ✅ Redux-based ShiftTypesView
- ✅ Comprehensive unit tests for reducers
- ✅ Integration tests for middleware
- ✅ TCA features still present but unused

### Phase 4 Testing

Test complex middleware flows:
```swift
@Test func testScheduleMiddleware_switchShift() async {
    let mockShiftSwitch = MockShiftSwitchService()
    let services = ServiceContainer.mock(shiftSwitch: mockShiftSwitch)

    var dispatchedActions: [AppAction] = []
    let mockDispatch: (AppAction) -> Void = { action in
        dispatchedActions.append(action)
    }

    let state = AppState()
    let shift = ScheduledShift(id: UUID(), eventIdentifier: "test", shiftType: nil, date: Date())
    let newShift = ShiftType(/* ... */)

    scheduleMiddleware(
        state: state,
        action: .schedule(.performSwitchShift(shift, newShift, "Test reason")),
        dispatch: mockDispatch,
        services: services
    )

    // Wait for async operation
    try await Task.sleep(nanoseconds: 100_000_000)

    #expect(dispatchedActions.contains(where: {
        if case .schedule(.shiftSwitched(.success)) = $0 { return true }
        return false
    }))
}
```

---

## Phase 5: Integration & Testing

### Goal
Wire Redux views into app, comprehensive testing, parallel TCA/Redux operation

### Tasks

#### 5.1 Create Redux Root View

**SwiftUIViews/Redux/ReduxAppView.swift**
```swift
struct ReduxAppView: View {
    var store: Store

    var body: some View {
        TabView(selection: Binding(
            get: { store.state.selectedTab },
            set: { store.dispatch(action: .appLifecycle(.tabSelected($0))) }
        )) {
            TodayView(store: store)
                .tabItem {
                    Label("Today", systemImage: "calendar.badge.clock")
                }
                .tag(Tab.today)

            ScheduleView(store: store)
                .tabItem {
                    Label("Schedule", systemImage: "calendar")
                }
                .tag(Tab.schedule)

            ShiftTypesView(store: store)
                .tabItem {
                    Label("Shift Types", systemImage: "list.bullet.clipboard")
                }
                .tag(Tab.shiftTypes)

            LocationsView(store: store)
                .tabItem {
                    Label("Locations", systemImage: "map")
                }
                .tag(Tab.locations)

            ChangeLogView(store: store)
                .tabItem {
                    Label("Change Log", systemImage: "clock.arrow.circlepath")
                }
                .tag(Tab.changeLog)

            SettingsView(store: store)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(Tab.settings)
        }
        .task {
            store.dispatch(action: .appLifecycle(.onAppear))
        }
    }
}
```

#### 5.2 Add Feature Flag for Redux

**App Entry Point**
```swift
@main
struct ShiftSchedulerApp: App {
    // Feature flag to toggle between TCA and Redux
    @AppStorage("useReduxArchitecture") private var useRedux = false

    @State private var tcaStore = ComposableArchitecture.Store(
        initialState: AppFeature.State()
    ) {
        AppFeature()
    }

    @State private var reduxStore: Store = {
        Store(
            state: AppState(),
            reducer: appReducer,
            middlewares: [
                loggingMiddleware,
                { state, action, dispatch in
                    let services = ServiceContainer.production
                    locationsMiddleware(state: state, action: action, dispatch: dispatch, services: services)
                    scheduleMiddleware(state: state, action: action, dispatch: dispatch, services: services)
                    todayMiddleware(state: state, action: action, dispatch: dispatch, services: services)
                    shiftTypesMiddleware(state: state, action: action, dispatch: dispatch, services: services)
                }
            ]
        )
    }()

    var body: some Scene {
        WindowGroup {
            if useRedux {
                ReduxAppView(store: reduxStore)
            } else {
                AppView(store: tcaStore)
            }
        }
    }
}
```

#### 5.3 Comprehensive Testing

**Unit Tests**
```swift
// Test all reducers
@Test func testAllReducers() {
    // Test every action in every reducer
}

// Test middleware in isolation
@Test func testAllMiddleware() {
    // Mock services, verify dispatched actions
}
```

**Integration Tests**
```swift
// Test full Redux flow
@Test func testFullReduxFlow_scheduleFeature() async {
    let store = Store(
        state: AppState(),
        reducer: appReducer,
        middlewares: [/* ... */]
    )

    store.dispatch(action: .schedule(.task))

    // Wait for async operations
    try await Task.sleep(nanoseconds: 500_000_000)

    #expect(store.state.schedule.isLoading == false)
}
```

**UI Tests** (if applicable)
```swift
@Test func testScheduleView_displaysShifts() {
    // UI testing with mock store
}
```

#### 5.4 Performance Testing

Compare Redux vs TCA:
- App launch time
- View rendering performance
- Memory usage
- State update latency

### Phase 5 Deliverables

- ✅ ReduxAppView with full tab navigation
- ✅ Feature flag for Redux/TCA toggle
- ✅ 100% reducer unit test coverage
- ✅ Middleware integration tests
- ✅ Performance benchmarks
- ✅ Side-by-side TCA/Redux operation verified
- ✅ Bug fixes for any Redux issues discovered

---

## Phase 6: TCA Removal & Cleanup

### Goal
Remove TCA dependency, delete TCA code, finalize Redux migration

### Tasks

#### 6.1 Switch Default to Redux

```swift
@main
struct ShiftSchedulerApp: App {
    @State private var reduxStore: Store = {
        Store(
            state: AppState(),
            reducer: appReducer,
            middlewares: [/* ... */]
        )
    }()

    var body: some Scene {
        WindowGroup {
            ReduxAppView(store: reduxStore)
        }
    }
}
```

#### 6.2 Delete TCA Features

```bash
rm -rf ShiftScheduler/Features/*.swift
rm -rf ShiftScheduler/Dependencies/*Client.swift  # Keep Services
```

#### 6.3 Remove TCA Dependency

**Package.swift** (if using SPM):
```swift
// Remove:
// .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.0.0")
```

**Xcode Project**: Remove ComposableArchitecture framework

#### 6.4 Update Documentation

- Update README.md with Redux architecture overview
- Update CLAUDE.md to remove TCA references
- Create REDUX_ARCHITECTURE.md with patterns and examples

#### 6.5 Final Testing

Run full test suite:
```bash
xcodebuild test -project ShiftScheduler.xcodeproj \
  -scheme ShiftScheduler \
  -destination 'platform=iOS Simulator,id=490A490A-C97A-43EE-978E-148A74A72499'
```

Build release:
```bash
xcodebuild -project ShiftScheduler.xcodeproj \
  -scheme ShiftScheduler \
  -configuration Release \
  -destination 'platform=iOS Simulator,id=490A490A-C97A-43EE-978E-148A74A72499' \
  build
```

### Phase 6 Deliverables

- ✅ TCA completely removed
- ✅ All tests passing
- ✅ App builds successfully
- ✅ Documentation updated
- ✅ Git history preserved with clear migration commits
- ✅ Production-ready Redux architecture

---

## Risk Mitigation

### Identified Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Redux introduces new Swift 6 issues | Low | High | Use nonisolated and @MainActor correctly from start |
| Complex features fail during migration | Medium | Medium | Parallel testing with TCA during Phases 3-5 |
| Performance regression | Low | Medium | Benchmark early in Phase 5 |
| Testing gaps | Medium | High | Comprehensive unit tests for each reducer/middleware |
| Undo/redo breaks during migration | Medium | High | Focus testing on ShiftSwitchService integration |

### Rollback Plan

Each phase maintains TCA code until Phase 6:
- If Redux fails, revert to TCA by flipping feature flag
- Git branches for each phase enable easy rollback
- No data loss (persistence layer unchanged)

---

## Success Criteria

Migration is successful when:

1. ✅ All TCA dependencies removed from project
2. ✅ Redux Store manages all app state
3. ✅ All features functional with Redux views
4. ✅ 90%+ test coverage on reducers and middleware
5. ✅ No Swift 6 concurrency warnings or errors
6. ✅ App performance equal to or better than TCA version
7. ✅ Undo/redo functionality preserved
8. ✅ All persistence operations working
9. ✅ Calendar integration functional
10. ✅ No user-facing regressions

---

## Timeline Summary

| Phase | Duration | Dependencies |
|-------|----------|--------------|
| Phase 1: Redux Foundation | 3-5 days | None |
| Phase 2: Service Layer | 3-5 days | Phase 1 |
| Phase 3: Simple Features | 5-7 days | Phase 1, 2 |
| Phase 4: Complex Features | 7-10 days | Phase 1, 2, 3 |
| Phase 5: Integration & Testing | 3-5 days | Phase 1-4 |
| Phase 6: TCA Removal | 2-3 days | Phase 1-5 |

**Total: 23-35 days**

---

## Post-Migration Improvements

After migration completes, consider:

1. **State Persistence**: Add middleware to persist AppState to UserDefaults
2. **Time Travel Debugging**: Store action history for debugging
3. **Performance Monitoring**: Middleware for tracking action dispatch times
4. **Action Logging**: Enhanced logging middleware with filtering
5. **Advanced Middleware**: Compose middleware for complex workflows
6. **State Snapshots**: Enable snapshot testing with Redux state
7. **Developer Tools**: Build custom Redux DevTools for debugging

---

## Appendix A: File Structure

```
ShiftScheduler/
├── Redux/
│   ├── Store/
│   │   └── Store.swift
│   ├── State/
│   │   ├── AppState.swift
│   │   ├── TodayState.swift
│   │   ├── ScheduleState.swift
│   │   ├── ShiftTypesState.swift
│   │   ├── LocationsState.swift
│   │   ├── ChangeLogState.swift
│   │   └── SettingsState.swift
│   ├── Action/
│   │   ├── AppAction.swift
│   │   ├── AppLifecycleAction.swift
│   │   ├── TodayAction.swift
│   │   ├── ScheduleAction.swift
│   │   ├── ShiftTypesAction.swift
│   │   ├── LocationsAction.swift
│   │   ├── ChangeLogAction.swift
│   │   └── SettingsAction.swift
│   ├── Reducer/
│   │   ├── AppReducer.swift
│   │   ├── AppLifecycleReducer.swift
│   │   ├── TodayReducer.swift
│   │   ├── ScheduleReducer.swift
│   │   ├── ShiftTypesReducer.swift
│   │   ├── LocationsReducer.swift
│   │   ├── ChangeLogReducer.swift
│   │   └── SettingsReducer.swift
│   └── Middleware/
│       ├── LoggingMiddleware.swift
│       ├── CalendarMiddleware.swift
│       ├── ScheduleMiddleware.swift
│       ├── TodayMiddleware.swift
│       ├── ShiftTypesMiddleware.swift
│       ├── LocationsMiddleware.swift
│       ├── ChangeLogMiddleware.swift
│       └── SettingsMiddleware.swift
├── Services/
│   ├── Protocols/
│   │   ├── CalendarServiceProtocol.swift
│   │   ├── PersistenceServiceProtocol.swift
│   │   ├── ShiftSwitchServiceProtocol.swift
│   │   └── CurrentDayServiceProtocol.swift
│   ├── Production/
│   │   ├── CalendarService.swift
│   │   ├── PersistenceService.swift
│   │   ├── ShiftSwitchService.swift
│   │   └── CurrentDayService.swift
│   ├── Mock/
│   │   ├── MockCalendarService.swift
│   │   ├── MockPersistenceService.swift
│   │   ├── MockShiftSwitchService.swift
│   │   └── MockCurrentDayService.swift
│   └── ServiceContainer.swift
├── SwiftUIViews/
│   └── Redux/
│       ├── ReduxAppView.swift
│       ├── TodayView.swift
│       ├── ScheduleView.swift
│       ├── ShiftTypesView.swift
│       ├── LocationsView.swift
│       ├── ChangeLogView.swift
│       └── SettingsView.swift
└── Domain/
    ├── Location.swift
    ├── ShiftType.swift
    ├── ScheduledShift.swift
    ├── UserProfile.swift
    ├── ChangeLogEntry.swift
    └── ToastMessage.swift
```

---

## Appendix B: Code Comparison Examples

### Before (TCA):

```swift
@Reducer
struct ScheduleFeature {
    @ObservableState
    struct State: Equatable {
        var scheduledShifts: [ScheduledShift] = []
        var isLoading: Bool = false
    }

    enum Action: Equatable {
        case loadShifts
        case shiftsLoaded(TaskResult<[ScheduledShift]>)
    }

    @Dependency(\.calendarClient) var calendarClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .loadShifts:
                state.isLoading = true
                return .run { send in
                    let result = await TaskResult {
                        try await calendarClient.fetchShiftsInRange(Date(), Date())
                    }
                    await send(.shiftsLoaded(result))
                }
            case .shiftsLoaded(.success(let shifts)):
                state.isLoading = false
                state.scheduledShifts = shifts
                return .none
            case .shiftsLoaded(.failure):
                state.isLoading = false
                return .none
            }
        }
    }
}
```

### After (Redux):

```swift
// State
struct ScheduleState: Equatable {
    var scheduledShifts: [ScheduledShift] = []
    var isLoading: Bool = false
}

// Action
enum ScheduleAction: Equatable {
    case loadShifts
    case shiftsLoaded(Result<[ScheduledShift], Error>)
}

// Reducer (Pure)
func scheduleReducer(state: ScheduleState, action: ScheduleAction) -> ScheduleState {
    var state = state
    switch action {
    case .loadShifts:
        state.isLoading = true
    case .shiftsLoaded(.success(let shifts)):
        state.isLoading = false
        state.scheduledShifts = shifts
    case .shiftsLoaded(.failure):
        state.isLoading = false
    }
    return state
}

// Middleware (Side Effects)
func scheduleMiddleware(
    state: AppState,
    action: AppAction,
    dispatch: @escaping (AppAction) -> Void,
    services: ServiceContainer
) {
    guard case .schedule(.loadShifts) = action else { return }

    Task {
        do {
            let shifts = try await services.calendarService.fetchShifts(
                start: Date(),
                end: Date()
            )
            dispatch(.schedule(.shiftsLoaded(.success(shifts))))
        } catch {
            dispatch(.schedule(.shiftsLoaded(.failure(error))))
        }
    }
}
```

**Key Differences:**
- Redux: Clear separation of pure reducer and side-effect middleware
- Redux: Explicit service injection (testable)
- Redux: No @Dependency macro magic
- Redux: Standard Swift patterns (Result, Task, async/await)

---

## Conclusion

This migration plan provides a systematic, low-risk approach to transitioning ShiftScheduler from TCA to Redux. By following the phased approach and maintaining parallel TCA/Redux operation until Phase 6, we can ensure a smooth migration with comprehensive testing and minimal disruption.

The Redux architecture will provide:
- ✅ **Swift 6 Compliance**: Native concurrency support without framework issues
- ✅ **Simplicity**: Clear unidirectional data flow
- ✅ **Testability**: Pure reducers and injectable services
- ✅ **Maintainability**: Standard Swift patterns, no proprietary abstractions
- ✅ **Performance**: Lightweight store with efficient state updates

**Next Step**: Review this plan and begin Phase 1 implementation.
