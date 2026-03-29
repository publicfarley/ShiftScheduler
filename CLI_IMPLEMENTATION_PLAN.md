# CLI Implementation Plan

A macOS command-line interface for ShiftScheduler that shares data with the iOS app via `~/Documents/ShiftSchedulerData/` and calendar via EventKit.

**Key decisions:**
- **Architecture**: Thin CLI layer over services (not Redux, not raw service calls)
- **Project structure**: Swift Package (Package.swift) with swift-argument-parser
- **Calendar**: Full EventKit integration (read + write)
- **Output**: Human-readable tables by default, `--json` flag for machine-readable output

---

## Project Structure

```
ShiftScheduler/
├── Package.swift                          # SPM manifest
├── Sources/
│   └── ShiftSchedulerCLI/                 # CLI executable
│       ├── ShiftSchedulerCLI.swift        # Entry point + root command
│       ├── CLIController.swift            # Thin orchestration layer over services
│       ├── OutputFormatter.swift          # Human-readable + JSON formatting
│       ├── Commands/
│       │   ├── TodayCommand.swift         # `shift today`
│       │   ├── ScheduleCommand.swift      # `shift schedule list|add|delete`
│       │   ├── ShiftTypesCommand.swift    # `shift types list|add|delete`
│       │   ├── LocationsCommand.swift     # `shift locations list|add|delete`
│       │   ├── ChangeLogCommand.swift     # `shift log list|purge`
│       │   └── ProfileCommand.swift       # `shift profile show|set`
│       └── Utilities/
│           └── DateParsing.swift          # CLI date argument parsing
├── ShiftScheduler/                        # Existing iOS app (unchanged)
├── ShiftScheduler.xcodeproj/              # Existing (unchanged)
```

### Package.swift

- `ShiftSchedulerCore` library target references existing iOS source files via `path: "ShiftScheduler"` with explicit `sources` subdirectories (Models, Domain, Persistence, Repositories, Protocols, Services, Redux/Services, Redux/Errors)
- `ShiftSchedulerCLI` executable target depends on `ShiftSchedulerCore` and `swift-argument-parser` (~> 1.3)
- Platform: macOS 14+

### Shared Code

**Domain Models** (no changes needed):
- `ShiftScheduler/Models/` — Location, ShiftType, ScheduledShift, ShiftDuration, ScheduledShiftData
- `ShiftScheduler/Domain/` — ChangeLogEntry, ChangeType, ShiftSnapshot, UserProfile, ChangeLogRetentionPolicy, UndoRedoStacks

**Persistence** (no changes needed):
- `ShiftScheduler/Persistence/` — ShiftTypeRepository, LocationRepository, ChangeLogRepository, UserProfileRepository, CloudKitManager
- `ShiftScheduler/Repositories/` — ChangeLogRepositoryProtocol

**Services** (no changes needed):
- `ShiftScheduler/Redux/Services/` — PersistenceService, CalendarService, CurrentDayService, ShiftSwitchService, ServiceContainer + all protocols

**Platform guards applied:**
- `ShiftScheduler/Services/TimeChangeService.swift` — `#if canImport(UIKit)` with no-op macOS fallback

**Not needed for CLI:**
- All SwiftUI views (`ShiftScheduler/Views/`)
- Redux State/Action/Reducer/Middleware files
- `ReduxStoreEnvironment.swift`, `ShiftSchedulerApp.swift`

---

## Command Hierarchy

```
shift-scheduler                              # Root command (shows help)
├── today                                    # Show today's shifts
│   └── --json                               # JSON output
├── schedule                                 # Schedule operations
│   ├── list [--from DATE] [--to DATE]       # List shifts in range (default: current month)
│   │   └── --json
│   ├── add --date DATE --type TYPE-ID [--notes "..."]   # Add shift to calendar
│   └── delete --event-id ID                 # Delete shift from calendar
├── types                                    # Shift type management
│   ├── list [--json]                        # List all shift types
│   ├── add --title "..." --symbol "..." --location LOC-ID [--start HH:MM --end HH:MM | --all-day]
│   ├── edit --id ID [--title "..."] [--symbol "..."]
│   └── delete --id ID
├── locations                                # Location management
│   ├── list [--json]
│   ├── add --name "..." --address "..."
│   ├── edit --id ID [--name "..."] [--address "..."]
│   └── delete --id ID
├── log                                      # Change log
│   ├── list [--limit N] [--json]
│   └── purge --older-than DAYS
├── profile                                  # User profile
│   ├── show [--json]
│   └── set --name "..."
└── auth                                     # Calendar authorization
    ├── status                               # Check EventKit authorization
    └── request                              # Request calendar access
```

### Global Options
- `--json` — Output JSON instead of human-readable format
- `--data-dir PATH` — Override data directory (default: `~/Documents/ShiftSchedulerData/`)

---

## CLIController Architecture

```swift
/// Thin orchestration layer - not Redux, not raw services
/// Combines service calls with business logic for CLI operations
final class CLIController {
    let persistence: PersistenceServiceProtocol
    let calendar: CalendarServiceProtocol
    let currentDay: CurrentDayServiceProtocol

    init(dataDirectory: URL? = nil) {
        self.persistence = PersistenceService(directoryURL: dataDirectory)
        self.calendar = CalendarService()
        self.currentDay = CurrentDayService()
    }

    // Example: add shift with audit trail
    func addShift(date: Date, shiftTypeId: UUID, notes: String?) async throws -> ScheduledShift {
        let shiftTypes = try await persistence.loadShiftTypes()
        guard let shiftType = shiftTypes.first(where: { $0.id == shiftTypeId }) else {
            throw CLIError.shiftTypeNotFound(shiftTypeId)
        }
        let shift = try await calendar.createShiftEvent(date: date, shiftType: shiftType, notes: notes)
        let entry = ChangeLogEntry(/* ... */)
        try await persistence.addChangeLogEntry(entry)
        return shift
    }
}
```

---

## EventKit on macOS

1. **Authorization**: On macOS, `EKEventStore.requestFullAccessToEvents()` shows a system dialog. The CLI checks auth status first and provides clear terminal output if denied.
2. **Shared Calendar**: The iOS app creates a calendar named `"functioncraft.ShiftScheduler"`. The CLI looks for/creates the same calendar, enabling shared shift data.
3. **No UIKit dependency**: `CalendarService.swift` uses `EventKit` (not `EventKitUI`), so it works on macOS without changes.

---

## Implementation Phases

### Phase 1: Foundation (Package.swift + Core library) ✅ COMPLETE

**Work:**
1. Create `Package.swift` with target definitions
2. Set up `ShiftSchedulerCore` referencing existing files
3. Resolve platform-specific issues (`#if canImport` guards)

**Acceptance Criteria:**
- [x] `Package.swift` exists with `ShiftSchedulerCore` library and `ShiftSchedulerCLI` executable targets
- [x] `swift-argument-parser` declared as dependency
- [x] All domain models accessible from the library target
- [x] All persistence repositories compile in the library target
- [x] All service protocols and implementations compile in the library target
- [x] No unguarded `import SwiftUI` or `import UIKit` in `ShiftSchedulerCore`
- [x] Minimal `ShiftSchedulerCLI.swift` entry point created

**Validation:**
```bash
swift build --target ShiftSchedulerCore 2>&1 | tail -1
# Expected: "Build complete!"
```

---

### Phase 2: CLI Skeleton

**Work:**
1. Create `CLIController.swift` with service initialization
2. Create `OutputFormatter.swift` (table + JSON modes)
3. Implement `today` command as proof-of-concept
4. Register all subcommand stubs (types, locations, schedule, log, profile, auth)

**Acceptance Criteria:**
- [ ] `swift build` compiles the full CLI executable with zero errors
- [ ] `swift run shift-scheduler --help` prints root help with all subcommand names
- [ ] `swift run shift-scheduler today` executes without crashing
- [ ] `swift run shift-scheduler today --json` produces valid JSON output
- [ ] `CLIController` initializes `PersistenceService`, `CalendarService`, and `CurrentDayService`
- [ ] `OutputFormatter` has both table and JSON rendering paths
- [ ] All subcommands registered and show `--help` output

**Validation:**
```bash
swift run shift-scheduler --help
swift run shift-scheduler today
swift run shift-scheduler today --json | jq .
swift run shift-scheduler types --help
```

---

### Phase 3: Data Management Commands

**Work:**
1. `types list|add|edit|delete` — full CRUD for shift types
2. `locations list|add|edit|delete` — full CRUD for locations
3. `profile show|set` — user profile management
4. `log list|purge` — change log viewing and cleanup

**Acceptance Criteria:**
- [ ] **Shift Types CRUD:** list (table + JSON), add (with time or all-day), edit, delete (with confirmation). Persists to `shiftTypes.json`.
- [ ] **Locations CRUD:** list, add, edit, delete. Persists to `locations.json`.
- [ ] **Profile:** show (name, retention policy), set display name.
- [ ] **Change Log:** list with `--limit`, purge with `--older-than` days.
- [ ] All commands support `--json` flag
- [ ] Invalid arguments produce clear error messages

**Validation:**
```bash
# Round-trip test
swift run shift-scheduler locations add --name "Test" --address "123 Test St"
swift run shift-scheduler locations list --json | jq '.[].name'
swift run shift-scheduler locations delete --id <ID>
```

---

### Phase 4: Calendar Commands

**Work:**
1. `auth status|request` — check and request EventKit authorization
2. `schedule list` — list shifts with date range filtering
3. `schedule add` — create calendar events
4. `schedule delete` — remove calendar events

**Acceptance Criteria:**
- [ ] `auth status` reports EventKit authorization state
- [ ] `auth request` triggers macOS authorization dialog
- [ ] `schedule list` shows current month by default, supports `--from`/`--to` date range
- [ ] `schedule add` creates calendar event with optional notes, persists ChangeLogEntry
- [ ] `schedule delete` removes event with confirmation, persists ChangeLogEntry
- [ ] Date arguments accept `YYYY-MM-DD`, `today`, `tomorrow`
- [ ] All commands support `--json` flag

**Validation:**
```bash
swift run shift-scheduler auth status
swift run shift-scheduler schedule list --from 2026-03-01 --to 2026-03-31
swift run shift-scheduler schedule add --date 2026-04-15 --type <ID>
swift run shift-scheduler schedule delete --event-id <EVENT-ID>
swift run shift-scheduler log list --limit 2
```

---

### Phase 5: Polish

**Work:**
1. ANSI color output for shift symbols and status
2. Comprehensive error messages and help text
3. Date parsing utilities (relative dates: `+3d`, `-1w`)
4. `--data-dir` global option support
5. `--no-color` flag and auto-detection of non-TTY output

**Acceptance Criteria:**
- [ ] Terminal output uses colors; disabled when piped or `--no-color` set
- [ ] Clear error messages with actionable suggestions (e.g., "Run 'shift-scheduler types list'...")
- [ ] All error messages exit with non-zero status code
- [ ] Date parsing supports: `YYYY-MM-DD`, `today`, `tomorrow`, `+3d`, `-1w`
- [ ] `--data-dir` overrides default data directory
- [ ] Help text is well-formatted with usage examples

**Validation:**
```bash
swift run shift-scheduler types list          # Colored output
swift run shift-scheduler types list | cat    # No ANSI codes
swift run shift-scheduler schedule list --from today --to +7d
swift run shift-scheduler --data-dir /tmp/test types list
swift run shift-scheduler types delete --id "not-a-uuid"  # Clear error, exit 1
```

---

## Key Risks & Mitigations

| Risk | Mitigation |
|------|-----------|
| Existing files have `import SwiftUI` or UIKit | Add `#if canImport` guards (done in Phase 1) |
| CloudKitManager may not compile on macOS CLI | Make it optional or stub for CLI |
| `@Observable` on Store requires macOS 14+ | CLI doesn't use Store — only services and models |
| EventKit auth dialog in terminal context | `auth` subcommand handles explicitly |
| SPM path references to `ShiftScheduler/` sources | Use `path:` parameter in Package.swift targets |
