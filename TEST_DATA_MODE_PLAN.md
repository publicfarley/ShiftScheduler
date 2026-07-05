# Test Data Mode — Implementation Plan

**Branch:** `claude/test-data-mode-plan-oyruib`
**Status:** Planned — ready for implementation

## Goal

Add a **Test Data Mode** toggled from the Settings view. While enabled, the entire app
(Today, Schedule, Shift Types, Locations, Change Log, Settings) operates against an
isolated sandbox so every feature can be explored freely without touching real data.
Turning the mode off returns the app to the real data, untouched.

## Confirmed Design Decisions (from product owner)

1. **Storage:** Sandboxed JSON directory (`ShiftSchedulerData-Test`) that survives app
   restarts, with CloudKit sync disabled. A "Reset Test Data" button re-seeds from scratch.
2. **Seed data:** Rich sample dataset seeded on first enable (locations, shift types,
   scheduled shifts past + future, change log entries) so every screen has content.
3. **Calendar:** Fully simulated calendar service — no EventKit at all in test mode. The
   real device calendar is never read or written, and no calendar permission is required.

## Architecture Overview

The app's Redux architecture makes this clean: **all side effects flow through
`ServiceContainer`** (`ShiftScheduler/Redux/Services/ServiceContainer.swift`). Test Data
Mode is implemented as an alternate service container wired to sandboxed implementations,
plus a store swap at the app root when the mode toggles.

```
                       ┌───────────────────────────────┐
 UserDefaults flag ──► │ ShiftSchedulerApp             │
 "testDataModeEnabled" │  builds Store with either:    │
                       │  • ServiceContainer()   (real)│
                       │  • .testDataContainer() (test)│
                       └───────────────┬───────────────┘
                                       │
              ┌────────────────────────┴───────────────────────┐
              │ Real mode                    Test mode          │
              │ PersistenceService           PersistenceService │
              │  → Documents/                 → Documents/      │
              │    ShiftSchedulerData           ShiftSchedulerData-Test
              │  → CloudKit sync ON           → CloudKit sync OFF
              │ CalendarService (EventKit)   SimulatedCalendarService
              │                               → simulatedCalendar.json
              └─────────────────────────────────────────────────┘
```

Key enablers already present in the codebase:
- All four repositories (`ShiftTypeRepository`, `LocationRepository`,
  `ChangeLogRepository`, `UserProfileRepository`) accept an injectable `directoryURL`.
- `PersistenceService` accepts injected repositories.
- `ServiceContainer` has an all-services initializer.
- Undo/redo stacks and change-log purge write via `changeLogRepository.directoryURL`,
  so they sandbox automatically.
- The Xcode project uses file-system-synchronized groups — new files need no
  `project.pbxproj` edits.

## The Mode Flag

- Stored in `UserDefaults.standard` under key `"testDataModeEnabled"` (NOT in the
  sandboxed profile — the flag must be readable before any container is built, and must
  live outside the data it switches).
- Read once at store-construction time; mirrored into `AppState` as
  `settings.isTestDataModeActive` so views can render indicators.

## New Files

### 1. `ShiftScheduler/Redux/Services/TestData/TestDataMode.swift`
Small namespace enum:
- `TestDataMode.userDefaultsKey = "testDataModeEnabled"`
- `TestDataMode.isEnabled` (get/set via UserDefaults)
- `TestDataMode.testDataDirectory: URL` → `Documents/ShiftSchedulerData-Test`
- `TestDataMode.resetTestData()` → deletes the test directory (seeder re-creates it)

### 2. `ShiftScheduler/Redux/Services/TestData/SimulatedCalendarService.swift`
Implements the full `CalendarServiceProtocol` (see
`Redux/Services/CalendarServiceProtocol.swift` — 18 methods) with **zero EventKit**:

- Backing store: `simulatedCalendar.json` inside the test data directory, holding an
  array of a small Codable record type:
  ```swift
  struct SimulatedEvent: Codable, Sendable {
      let eventIdentifier: String   // UUID string, stands in for EKEvent identifier
      var shiftTypeId: UUID
      var date: Date                // start-of-day of shift
      var endDate: Date
      var notes: String?
      var isSickDay: Bool
      var reason: String?
  }
  ```
- Implemented as an `actor` (serializes file access, satisfies `Sendable`).
- `isCalendarAuthorized()` / `requestCalendarAccess()` → always `true`.
- `loadShifts(from:to:)` → filter events by range, resolve `ShiftType` via the
  **test** `ShiftTypeRepository` (injected), map to `ScheduledShift` (same shape as
  `CalendarService.convertEventToShift`).
- `createShiftEvent` → perform the same overlap check the real service does (reuse
  `ScheduledShift.findOverlap(in:)` and throw `ScheduleError.overlappingShifts`),
  then append + persist. Compute `endDate` from `shiftType.duration.spansNextDay`
  exactly like the real service.
- `updateShiftEvent`, `deleteShiftEvent`, `deleteMultipleShiftEvents`,
  `updateShiftNotes`, `markShiftAsSick`, `updateEventsWithShiftType`,
  `resyncAllCalendarEvents` → mutate matching records and persist. Resync returns
  counts; `updateEventsWithShiftType` returns number of affected events.
- `loadShiftData*` → map records to `ScheduledShiftData` directly.
- Derived range helpers (`loadShiftsForNext30Days`, `loadShiftsForCurrentMonth`,
  `loadShiftsForExtendedRange`, `loadShiftsAroundMonth`) mirror the real service's
  date math and delegate to `loadShifts(from:to:)`.

### 3. `ShiftScheduler/Redux/Services/TestData/TestDataSeeder.swift`
`enum TestDataSeeder` with `static func seedIfNeeded(...)` and
`static func reseed(...)`:

- Idempotence: seed only when the test directory has no `shiftTypes.json`
  (fresh or just-reset sandbox).
- **Locations (4):** e.g. "Downtown Hospital", "Westside Clinic", "Remote / Home
  Office", "Airport Branch" — realistic multi-line addresses.
- **Shift types (5–6):** Day 🌞 (07:00–15:00), Evening 🌆 (15:00–23:00),
  Night 🌙 (23:00–07:00, spans next day), On-Call 📱 (all-day), Half Day 🌤
  (09:00–13:00), spread across the seeded locations. Use fixed UUIDs (constants) so
  reseeding is deterministic.
- **Scheduled shifts:** a realistic rotation covering **-30 days … +45 days** relative
  to `Date()` (e.g. repeating pattern of Day/Day/Evening/Night/off/off), including one
  sick day in the past week (`isSickDay: true` with a reason) and a couple of shifts
  with user notes — so Today, Schedule (month navigation both directions), and the
  sick-day UI all have content.
- **Change log entries (~8):** a mix of `ChangeType` values referencing the seeded
  shifts, with timestamps spread over the past 60 days (exercises retention/purge UI).
- **User profile:** `displayName: "Test User"`, `.forever` retention, auto-purge on.
- Seeding writes via the injected test repositories/services (not raw file writes),
  so the data always matches current schemas.

### 4. `ShiftScheduler/Views/Components/TestDataModeBanner.swift`
A slim, always-visible indicator when the mode is on: orange capsule/banner reading
"🧪 Test Data Mode" pinned at the top edge (overlay in `ContentView`'s outer `ZStack`),
non-interactive, respects safe area. Follow existing component styling conventions
(see `Views/Components/`).

## Modified Files

### 5. `ShiftScheduler/Persistence/CloudKitManager.swift`
Add `private let isEnabled: Bool` (init parameter, default `true`). When `false`,
every public operation returns immediately (fetches return `[]`/no-op saves/deletes)
without creating CKContainer traffic. Guard at method entry. This keeps the
repositories' CloudKit code untouched while making the test sandbox iCloud-silent.

> Note: `CKContainer(identifier:)` is created in `init`. Move container/database
> creation into lazy accessors or make them optional when `isEnabled == false`, so a
> disabled manager never touches CloudKit at all.

### 6. `ShiftScheduler/Redux/Services/ServiceContainer.swift`
Add:
```swift
static func createTestDataContainer() -> ServiceContainer
```
- Builds the test directory URL from `TestDataMode.testDataDirectory`.
- `CloudKitManager(isEnabled: false)` shared by both synced repositories.
- Test repositories: `ShiftTypeRepository(directoryURL: testDir, cloudKitManager: disabled)`,
  `LocationRepository(...)`, `ChangeLogRepository(directoryURL: testDir)`,
  `UserProfileRepository(directoryURL: testDir)`.
- `PersistenceService(shiftTypeRepository: ..., locationRepository: ..., ...)`.
- `SimulatedCalendarService(directoryURL: testDir, shiftTypeRepository: testShiftTypeRepo)`.
- Real `CurrentDayService` and `TimeChangeService` (they are read-only w.r.t. data).
- Also add a convenience `static func makeContainer(testDataMode: Bool)` used by the app.

### 7. `ShiftScheduler/Redux/Services/PersistenceService.swift`
Guard the UserDefaults→profile migration: add `let skipLegacyMigration: Bool = false`
init parameter, set `true` in the test container. **Without this, enabling test mode
would delete the real user's legacy UserDefaults keys** (`displayName`, etc.) during
test-profile load. In test mode, a missing profile just returns the default profile
(the seeder writes "Test User" anyway).

### 8. `ShiftScheduler/Redux/State/AppState.swift`
`SettingsState`: add `var isTestDataModeActive: Bool = false` and
`var isTestDataResetting: Bool = false`.

### 9. `ShiftScheduler/Redux/Action/AppAction.swift`
`SettingsAction`: add
- `testDataModeToggled(Bool)` — user flipped the switch
- `resetTestDataRequested` — user tapped Reset Test Data
- `testDataResetCompleted` — middleware finished reset

### 10. `ShiftScheduler/Redux/Reducer/AppReducer.swift`
Handle the three actions: set `isTestDataModeActive`, set/clear `isTestDataResetting`,
and surface a toast (`toastMessage`) on reset completion, mirroring how purge handles
toasts.

### 11. `ShiftScheduler/Redux/Middleware/SettingsMiddleware.swift`
- `testDataModeToggled(enabled)`: write `TestDataMode.isEnabled = enabled`. (The store
  swap itself happens at the app root — see #13.)
- `resetTestDataRequested`: only valid in test mode; call `TestDataMode.resetTestData()`,
  then `TestDataSeeder.reseed(...)` via the container's services, then dispatch
  `testDataResetCompleted` followed by the reload actions the startup middleware uses
  (locations, shift types, change log, settings) so the UI refreshes in place.

### 12. `ShiftScheduler/Redux/Configuration/StoreConfiguration.swift`
`createReduxStore(includeStartup:state:services:)`: default `services` becomes
`ServiceContainer.makeContainer(testDataMode: TestDataMode.isEnabled)`, and the initial
`AppState` gets `settings.isTestDataModeActive` pre-set from the flag.

### 13. `ShiftScheduler/ShiftSchedulerApp.swift` — the mode switch
The store is `@State` at the app root; swapping modes = rebuilding the store:

- On launch: `createReduxStore(includeStartup: true)` now auto-selects the container
  from the persisted flag (no change to call site).
- If launching **into** test mode, run `TestDataSeeder.seedIfNeeded` before/at store
  startup (call it from the app's startup `Task`, or from `AppStartupMiddleware` when
  `state.settings.isTestDataModeActive`).
- Add `.onChange(of: reduxStore.state.settings.isTestDataModeActive)` on the root view:
  when it flips, rebuild — `reduxStore = createReduxStore(includeStartup: true)` —
  and briefly re-show the splash (reuse existing `showSplash` flow) so initialization
  re-runs cleanly against the new container. This is a full, clean swap: no service
  state can leak across modes because every service lives in the discarded container.

### 14. `ShiftScheduler/Views/SettingsView.swift`
New section at the **top** of the settings stack (above User Profile) so the mode is
discoverable:

- Section header "Test Data Mode" with 🧪 icon.
- `Toggle` bound to `store.state.settings.isTestDataModeActive`, dispatching
  `.settings(.testDataModeToggled(newValue))` — same binding pattern as the
  auto-purge toggle.
- Caption text: explains that a sample sandbox replaces real data, real data and the
  device calendar are untouched, and toggling off returns to real data.
- When active: an orange "active" tint on the section and a "Reset Test Data" button
  (with confirmation alert, mirroring the purge confirmation pattern) dispatching
  `.settings(.resetTestDataRequested)`; shows progress while `isTestDataResetting`.

### 15. `ShiftScheduler/ContentView.swift`
Overlay `TestDataModeBanner()` at the top of the existing `ZStack` when
`reduxStore.state.settings.isTestDataModeActive` — visible on every tab.

## Behavior Summary

| Concern | Real mode | Test mode |
|---|---|---|
| Shift types / locations / change log / profile | `Documents/ShiftSchedulerData` | `Documents/ShiftSchedulerData-Test` |
| CloudKit sync | On | Off (disabled manager) |
| Scheduled shifts | Real EventKit calendar | `simulatedCalendar.json` (actor) |
| Calendar permission | Required | Never requested |
| Undo/redo stacks | Real dir | Test dir (follows changeLogRepository) |
| Change-log purge | Real entries | Test entries only |
| UserDefaults legacy migration | Runs | Skipped |
| Visual indicator | None | Banner on all tabs + Settings section highlight |
| Persistence across restarts | — | Yes; flag + sandbox survive relaunch |
| Reset | — | "Reset Test Data" wipes sandbox and re-seeds |

## Tests (Swift Testing framework — `@Test` / `#expect`)

New `ShiftSchedulerTests/TestDataModeTests.swift`:
1. `SimulatedCalendarService` CRUD: create → load returns it; overlap on same day
   throws `ScheduleError.overlappingShifts`; update/delete round-trip; sick-day
   mark/unmark; notes update; range filtering; all against a temporary directory
   (deterministic fixed dates, cleanup in teardown — per TEST_QUALITY_REVIEW rules).
2. `TestDataSeeder`: seeding a fresh temp dir produces >0 locations, shift types,
   simulated shifts spanning past and future, and change log entries; `seedIfNeeded`
   is idempotent (second call adds nothing); `reseed` after mutation restores baseline.
3. `ServiceContainer.createTestDataContainer()`: persistence writes land under the
   test directory, not the real one (verify via temp-dir injected variant or by
   checking repository `directoryURL`).
4. `PersistenceService` with `skipLegacyMigration: true` leaves UserDefaults keys
   untouched when loading a missing profile.

## Implementation Order

1. `TestDataMode.swift` + `CloudKitManager` disable flag.
2. `SimulatedCalendarService` (largest piece — implement full protocol).
3. `TestDataSeeder`.
4. `ServiceContainer.createTestDataContainer()` / `makeContainer(testDataMode:)` +
   `PersistenceService.skipLegacyMigration`.
5. Redux plumbing: state, actions, reducer, settings middleware, store configuration.
6. App root store swap (`ShiftSchedulerApp`).
7. UI: Settings section, banner, ContentView overlay.
8. Tests.

## Constraints & Notes for the Implementer

- **This environment is Linux — `xcodebuild` is unavailable.** Code cannot be compiled
  here; write conservatively, mirror existing patterns and API signatures exactly
  (copy date math and conversion logic from `CalendarService` rather than reinventing).
  Final build/test verification (both app and test targets, per CLAUDE.md) must be run
  by the developer on macOS.
- The Xcode project uses file-system-synchronized groups: adding files under
  `ShiftScheduler/` and `ShiftSchedulerTests/` requires **no** `project.pbxproj` edits.
- SwiftData is banned; everything is JSON persistence (this plan complies).
- No singletons: `TestDataMode` is a stateless namespace over `UserDefaults` (an
  external store), and all services remain container-injected.
- Use `Task`/`async-await` only — no `DispatchQueue` (per CLAUDE.md).
- Keyboard dismissal rules don't apply to the new Settings section (no new text
  inputs), but keep the existing modifiers intact.
- Swift 6 strict concurrency: new service must be `Sendable` (actor recommended);
  seeded model values are already `Sendable`.
