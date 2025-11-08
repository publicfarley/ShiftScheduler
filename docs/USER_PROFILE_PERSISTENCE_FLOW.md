# UserProfile Persistence Flow

## Overview

This document traces the complete flow of how a UserProfile update travels from UI interaction to persistent storage in the ShiftScheduler Redux architecture.

The flow follows Redux's unidirectional data pattern with three phases:
1. **Reducer** - Synchronous state update
2. **UI Yield** - Allow UI to reflect changes
3. **Middleware** - Asynchronous side effects including persistence

---

## Complete Step-by-Step Flow

### STEP 1: UI User Interaction

**File:** `ShiftScheduler/Views/SettingsView.swift`

**Lines 78-94:** User edits the display name in a TextField

```swift
TextField("Enter your name", text: $displayName)
    .textFieldStyle(.roundedBorder)
    .onChange(of: displayName) { _, newValue in
        // Update app state immediately for reactive UI
        Task {
            await store.dispatch(action: .appLifecycle(.displayNameChanged(newValue)))
        }

        // Debounce the save: cancel previous save task and schedule new one
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(nanoseconds: debounceDelay)
            if !Task.isCancelled {
                await saveDisplayName()
            }
        }
    }
```

**Key Points:**
- Debounce delay: 500ms (line 17: `500_000_000` nanoseconds)
- Immediately dispatch `.displayNameChanged` action for reactive UI
- Schedule a debounced save operation

---

### STEP 2: Initial State Update (Synchronous)

**File:** `ShiftScheduler/Redux/Core.swift`

**Lines 45-47:** Store receives the `.appLifecycle(.displayNameChanged(newValue))` action

```swift
public func dispatch(action: Action) async {
    // Phase 1: Apply reducer immediately (synchronous state update)
    state = reducer(state, action)
```

The store calls the root reducer with this action.

---

### STEP 3: Reducer Updates State (Synchronous)

**File:** `ShiftScheduler/Redux/Reducer/AppReducer.swift`

**Lines 7-34:** Root reducer delegates to app lifecycle reducer

```swift
nonisolated func appReducer(state: AppState, action: AppAction) -> AppState {
    var state = state

    switch action {
    case .appLifecycle(let action):
        state = appLifecycleReducer(state: state, action: action)
```

**Lines 39-95:** App lifecycle reducer handles the display name change

```swift
nonisolated func appLifecycleReducer(state: AppState, action: AppLifecycleAction) -> AppState {
    var state = state

    switch action {
    // ...
    case .displayNameChanged(let newName):
        state.userProfile.displayName = newName
        state.isNameConfigured = !newName.trimmingCharacters(in: .whitespaces).isEmpty
```

**Result:** The state is updated synchronously with the new display name.

---

### STEP 4: UI Re-renders (Synchronous)

**File:** `ShiftScheduler/Redux/Core.swift`

**Lines 49-51:** Yield to allow UI to update

```swift
// Phase 2: Yield to allow UI to update with reducer changes
// This ensures loading states, optimistic updates, etc. are visible
await Task.yield()
```

The UI immediately reflects the new display name due to `@Observable` and SwiftUI reactivity.

---

### STEP 5: Debounced Save Triggered

**File:** `ShiftScheduler/Views/SettingsView.swift`

**Lines 360-387:** After debounce delay (500ms), `saveDisplayName()` is called

```swift
private func saveDisplayName() async {
    saveStatus = .saving

    do {
        // Dispatch save settings action to middleware
        await store.dispatch(action: .settings(.saveSettings))

        // Wait for the save to complete by checking state changes
        try await Task.sleep(nanoseconds: 300_000_000) // 300ms for save to complete

        saveStatus = .saved

        // Auto-dismiss the "saved" indicator after 2 seconds
        try await Task.sleep(nanoseconds: saveSuccessDuration)
        if saveStatus == .saved {
            saveStatus = .idle
        }
    } catch {
        saveStatus = .error("Failed to save")
        // Reset error after 3 seconds...
    }
}
```

This dispatches the **`.settings(.saveSettings)`** action.

---

### STEP 6: Reducer Processes Save Action (Synchronous)

**File:** `ShiftScheduler/Redux/Reducer/AppReducer.swift`

**Lines 29-30:** Root reducer delegates to settings reducer

```swift
case .settings(let action):
    state.settings = settingsReducer(state: state.settings, action: action)
```

**Lines 674-743:** Settings reducer handles the save

```swift
nonisolated func settingsReducer(state: SettingsState, action: SettingsAction) -> SettingsState {
    var state = state

    switch action {
    // ...
    case .saveSettings:
        state.isLoading = true  // Show loading indicator
```

**Result:** The settings state is updated with loading flag.

---

### STEP 7: Middleware Processes Side Effects (Asynchronous)

**File:** `ShiftScheduler/Redux/Core.swift`

**Lines 53-79:** After reducer completes, middleware runs

```swift
// Phase 3: Execute middleware (async side effects)
// Capture current state and dependencies for middleware to use
let currentState = state
let services = services

let dispatchAction: Dispatcher<Action> = { [weak self] newAction in
    await self?.dispatch(action: newAction)
}

// Wait for all middleware to complete before returning
await withTaskGroup(of: Void.self) { group in
    for middleware in middlewares {
        group.addTask {
            await middleware(
                currentState,
                action,
                services,
                dispatchAction
            )
        }
    }
}
```

The `settingsMiddleware` function is called with the `.settings(.saveSettings)` action.

---

### STEP 8: Settings Middleware Intercepts Action (Asynchronous)

**File:** `ShiftScheduler/Redux/Middleware/SettingsMiddleware.swift`

**Lines 1-115:** Middleware handles the save settings action

```swift
func settingsMiddleware(
    state: AppState,
    action: AppAction,
    services: ServiceContainer,
    dispatch: Dispatcher<AppAction>,
) async {
    guard case .settings(let settingsAction) = action else { return }

    switch settingsAction {
    case .saveSettings:
        logger.debug("Saving settings")

        do {
            let profile = UserProfile(
                userId: state.userProfile.userId,
                displayName: state.userProfile.displayName,  // Uses updated display name
                retentionPolicy: state.settings.retentionPolicy,
                autoPurgeEnabled: state.settings.autoPurgeEnabled,
                lastPurgeDate: state.settings.lastPurgeDate
            )

            try await services.persistenceService.saveUserProfile(profile)
            await dispatch(.settings(.settingsSaved(.success(()))))

            // Update app-level user profile
            await dispatch(.appLifecycle(.userProfileUpdated(profile)))
        } catch {
            logger.error("Failed to save settings: \(error.localizedDescription)")
            await dispatch(.settings(.settingsSaved(.failure(error))))
        }
```

**Key Actions:**
- **Line 38-44:** Creates a `UserProfile` object with the updated display name from `state.userProfile.displayName`
- **Line 46:** Calls `services.persistenceService.saveUserProfile(profile)`

---

### STEP 9: Persistence Service Delegates to Repository

**File:** `ShiftScheduler/Redux/Services/PersistenceService.swift`

**Lines 184-187:** `saveUserProfile` method

```swift
func saveUserProfile(_ profile: UserProfile) async throws {
    logger.debug("Saving user profile: \(profile.displayName)")
    try await userProfileRepository.save(profile)
}
```

The service delegates to the `UserProfileRepository` to perform the actual persistence.

---

### STEP 10: Repository Writes to Disk

**File:** `ShiftScheduler/Persistence/UserProfileRepository.swift`

**Lines 38-46:** Repository's `save` method writes JSON to disk

```swift
func save(_ profile: UserProfile) async throws {
    try ensureDirectory()  // Ensure directory exists
    let fileURL = directoryURL.appendingPathComponent(fileName)
    let data = try await MainActor.run {
        try JSONEncoder().encode(profile)  // Encode to JSON
    }
    try data.write(to: fileURL, options: .atomic)  // Atomic write to disk
}
```

**Disk Location:**
- **Directory:** `Documents/ShiftSchedulerData/` (lines 5-8)
- **File Name:** `userProfile.json` (line 12)
- **Full Path:** `~/Documents/ShiftSchedulerData/userProfile.json`

**Atomic Write:** Line 45 uses `.atomic` option, which writes to a temporary file and then swaps it atomically to ensure data integrity.

---

### STEP 11: Success Result Dispatched Back

**File:** `ShiftScheduler/Redux/Middleware/SettingsMiddleware.swift`

**Line 47:** After successful save

```swift
await dispatch(.settings(.settingsSaved(.success(()))))
```

---

### STEP 12: Reducer Processes Success

**File:** `ShiftScheduler/Redux/Reducer/AppReducer.swift`

**Lines 692-695:** Settings reducer handles success

```swift
case .settingsSaved(.success):
    state.isLoading = false
    state.hasUnsavedChanges = false
    state.toastMessage = .success("Settings saved")
```

---

### STEP 13: UI Updates with Success

**File:** `ShiftScheduler/Views/SettingsView.swift`

**Lines 360-387:** The UI state reflects the save completion

```swift
saveStatus = .saved  // Shows green checkmark

// Auto-dismiss the "saved" indicator after 2 seconds
try await Task.sleep(nanoseconds: saveSuccessDuration)
if saveStatus == .saved {
    saveStatus = .idle
}
```

---

## Visual Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│ UI LAYER - SettingsView.swift                               │
├─────────────────────────────────────────────────────────────┤
│ User edits TextField (displayName)                           │
│   └─> onChange fires (Line 80)                              │
│       ├─> Immediate dispatch: .displayNameChanged (Line 83) │
│       └─> Schedule debounced save (Line 88-93)             │
│           └─> After 500ms: saveDisplayName() (Line 91)     │
│               └─> Dispatch: .settings(.saveSettings) (L365)│
└───────────┬─────────────────────────────────────────────────┘
            │ ASYNC DISPATCH
            v
┌─────────────────────────────────────────────────────────────┐
│ REDUX STORE - Core.swift                                    │
├─────────────────────────────────────────────────────────────┤
│ dispatch(action: Action) async (Line 45)                    │
│   ├─ PHASE 1: Apply Reducer (Synchronous) (Line 47)       │
│   ├─ PHASE 2: Yield for UI (Line 51)                       │
│   └─ PHASE 3: Run Middleware (Asynchronous) (Line 68)     │
└───────────┬─────────────────────────────────────────────────┘
            │
            v
┌─────────────────────────────────────────────────────────────┐
│ REDUCER - AppReducer.swift                                  │
├─────────────────────────────────────────────────────────────┤
│ appReducer() (Line 7)                                       │
│   └─> settingsReducer() (Line 30, AppReducer.swift)       │
│       └─> .saveSettings: state.isLoading = true (L690)    │
│                                                             │
│ ALSO: appLifecycleReducer() for initial change             │
│   └─> .displayNameChanged: state.userProfile.display… (L50)│
└───────────┬─────────────────────────────────────────────────┘
            │ STATE UPDATED → UI REACTS (@Observable)
            │
            v (AFTER Task.yield())
┌─────────────────────────────────────────────────────────────┐
│ MIDDLEWARE - SettingsMiddleware.swift                       │
├─────────────────────────────────────────────────────────────┤
│ settingsMiddleware() (Line 8)                               │
│   └─ .saveSettings case (Line 34)                          │
│      ├─ Create UserProfile with updated displayName (L38)  │
│      └─ services.persistenceService.saveUserProfile() (L46)│
└───────────┬─────────────────────────────────────────────────┘
            │ ASYNC CALL
            v
┌─────────────────────────────────────────────────────────────┐
│ PERSISTENCE SERVICE - PersistenceService.swift              │
├─────────────────────────────────────────────────────────────┤
│ saveUserProfile(_ profile) (Line 184)                       │
│   └─> userProfileRepository.save(profile) (Line 186)       │
└───────────┬─────────────────────────────────────────────────┘
            │ ASYNC CALL (actor-based)
            v
┌─────────────────────────────────────────────────────────────┐
│ REPOSITORY - UserProfileRepository.swift                    │
├─────────────────────────────────────────────────────────────┤
│ save(_ profile) async throws (Line 39)                      │
│   ├─ ensureDirectory() (Line 40)                            │
│   ├─ fileURL = directoryURL + "userProfile.json" (L41)     │
│   ├─ JSONEncoder().encode(profile) → Data (L43)            │
│   └─ data.write(to: fileURL, .atomic) (Line 45)            │
│                                                             │
│ DISK LOCATION:                                              │
│ ~/Documents/ShiftSchedulerData/userProfile.json             │
└───────────┬─────────────────────────────────────────────────┘
            │ WRITTEN TO DISK
            │
            v
┌─────────────────────────────────────────────────────────────┐
│ BACK TO MIDDLEWARE - SettingsMiddleware.swift               │
├─────────────────────────────────────────────────────────────┤
│ Dispatch success: .settings(.settingsSaved(.success())) (L47)│
└───────────┬─────────────────────────────────────────────────┘
            │
            v
┌─────────────────────────────────────────────────────────────┐
│ REDUCER - AppReducer.swift                                  │
├─────────────────────────────────────────────────────────────┤
│ settingsReducer() for .settingsSaved(.success) (Line 692)   │
│   ├─ state.isLoading = false                               │
│   ├─ state.hasUnsavedChanges = false                        │
│   └─ state.toastMessage = .success("Settings saved")        │
└───────────┬─────────────────────────────────────────────────┘
            │ STATE UPDATED
            │
            v
┌─────────────────────────────────────────────────────────────┐
│ UI LAYER - SettingsView.swift                               │
├─────────────────────────────────────────────────────────────┤
│ saveStatus = .saved (Line 371)                              │
│   └─> Shows green checkmark icon (Line 106-107)            │
│       └─> Auto-dismiss after 2 seconds (Line 374)          │
└─────────────────────────────────────────────────────────────┘
```

---

## Timing Summary

| Phase | Duration | Notes |
|-------|----------|-------|
| User Input | 0ms | TextField onChange fires |
| Debounce Wait | 500ms | Before save is triggered |
| Dispatch + Reducer | <1ms | Synchronous |
| UI Yield | <1ms | Task.yield() |
| Persistence | 10-50ms | JSON encoding + atomic file write |
| UI Update | <1ms | Reducer result dispatched and processed |
| **Total to Disk** | **~510-550ms** | Debounce (500ms) + persistence (~10-50ms) |
| UI Feedback Display | **~810-850ms** | Total + 300ms wait in saveDisplayName() |

---

## Key Architectural Points

### 1. Two-Phase Dispatch Pattern
- **Phase 1:** Reducer executes synchronously for immediate UI responsiveness
- **Phase 2:** Task.yield() allows UI to update
- **Phase 3:** Middleware executes asynchronously for side effects

### 2. Debouncing
- Prevents excessive saves while user is still typing
- Debounce delay: 500ms (configurable on line 17 of SettingsView.swift)
- Uses cancelable Task pattern

### 3. Atomic Write
- Uses FileManager's `.atomic` option to ensure data integrity
- Writes to temp file first, then swaps atomically
- Prevents partial writes during crashes or power loss

### 4. Error Handling
- Middleware catches errors and dispatches failure action
- Reducer updates state with error message for UI display
- User can retry save if failed

### 5. Sendable/Actor Isolation
- `UserProfileRepository` is an actor for thread-safe concurrent access
- All types are Sendable for Swift 6 strict concurrency compliance
- Prevents data races at compile time

### 6. Separation of Concerns
- **UI Layer:** User interaction and display logic
- **Redux Store:** State management and coordination
- **Reducer:** Pure state transformation (no side effects)
- **Middleware:** Asynchronous side effects (persistence, network, etc.)
- **Service Layer:** Business logic and external dependencies
- **Repository Layer:** Low-level data access

---

## Persistence Details

### File Location
- **Path:** `~/Documents/ShiftSchedulerData/userProfile.json`
- **Format:** JSON
- **Encoding:** UTF-8 via `JSONEncoder`

### Directory Structure
```
~/Documents/
  └── ShiftSchedulerData/
      ├── userProfile.json          (this file)
      ├── shiftTypes.json
      ├── locations.json
      ├── changelog.json
      └── undoredo_stacks.json
```

### UserProfile JSON Schema
```json
{
  "userId": "UUID string",
  "displayName": "string",
  "retentionPolicy": "forever | days30 | days60 | days90",
  "autoPurgeEnabled": true,
  "lastPurgeDate": "ISO8601 timestamp or null"
}
```

### Repository Configuration
- **Actor-based:** Thread-safe concurrent access
- **Directory creation:** Automatic with intermediate directories
- **Error handling:** Throws errors for file I/O failures
- **Testing support:** Accepts custom directory URL in initializer

---

## Redux Flow Summary

This complete flow demonstrates Redux unidirectional data flow:

**UI → Action → Reducer → State Update → Middleware → Persistence → Success Action → Reducer → State Update → UI**

The architecture ensures:
- **Predictable state updates** (single source of truth)
- **Testable logic** (pure reducers, injectable services)
- **Responsive UI** (synchronous reducer, debounced persistence)
- **Error resilience** (atomic writes, error actions)
- **Concurrent safety** (actors, Sendable types)

---

## Related Documentation

- [ARCHITECTURE_SOLUTION.md](../ARCHITECTURE_SOLUTION.md) - Overall Redux architecture
- [SERVICE_LAYER_ARCHITECTURE.md](../SERVICE_LAYER_ARCHITECTURE.md) - Service layer design
- [REDUX_MIGRATION_PLAN.md](../REDUX_MIGRATION_PLAN.md) - Migration from TCA to Redux
- [CLAUDE.md](../CLAUDE.md) - Project conventions and guidelines
