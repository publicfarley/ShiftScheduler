# CLI Implementation Plan

**Status: Implemented** (July 2026). This document describes the shipped design;
deviations from the original plan are noted inline.

A macOS command-line interface for ShiftScheduler. Reference data (shift types,
locations, profile, change log) is stored as JSON in `~/Documents/ShiftSchedulerData/`
on the Mac running the CLI; scheduled shifts live in the shared
`functioncraft.ShiftScheduler` EventKit calendar, which syncs with the iOS app
when hosted on iCloud. Reference data additionally syncs through CloudKit where
entitlements allow (i.e., in the iOS app — see "CloudKit on macOS CLI" below).

**Key decisions:**
- **Architecture**: Thin CLI layer (`CLIController`) over the Redux service implementations (not Redux itself)
- **Project structure**: Swift Package (Package.swift) with swift-argument-parser
- **Single-module target** *(deviation)*: the app sources have no `public` API, so a
  separate `ShiftSchedulerCore` library module was unusable from a CLI module without
  publicizing dozens of types. The executable target compiles the app's domain,
  persistence, and service sources together with the CLI sources instead.
- **Calendar**: Full EventKit integration (read + write)
- **Output**: Human-readable tables by default, `--json` flag for machine-readable output
- **Agent-friendly**: `--force` on destructive commands, confirmation prompts fail fast
  (never hang) without a TTY, errors respect `--json` on stderr, exit codes documented
  in root help, usage examples in every command's help text

---

## Project Structure

```
ShiftScheduler/
├── Package.swift                          # SPM manifest (single executable target)
├── Sources/
│   └── ShiftSchedulerCLI/                 # CLI sources
│       ├── ShiftSchedulerCLI.swift        # Entry point + root command
│       ├── CLIController.swift            # Thin orchestration layer over services
│       ├── CLIError.swift                 # CLI error types with suggestions
│       ├── GlobalOptions.swift            # --json/--data-dir, error output, confirmations
│       ├── OutputFormatter.swift          # Table rendering + stable JSON DTOs
│       ├── DateParsing.swift              # CLI date/time argument parsing
│       └── Commands/
│           ├── TodayCommand.swift         # shift-scheduler today
│           ├── ScheduleCommand.swift      # schedule list|add|edit|delete|switch
│           ├── TypesCommand.swift         # types list|add|edit|delete
│           ├── LocationsCommand.swift     # locations list|add|edit|delete
│           ├── LogCommand.swift           # log list|purge
│           ├── ProfileCommand.swift       # profile show|set
│           ├── AuthCommand.swift          # auth status|request
│           └── UndoRedoCommands.swift     # undo, redo
├── ShiftScheduler/                        # Existing iOS app (sources shared with CLI)
├── ShiftScheduler.xcodeproj/              # Existing (unchanged)
```

### Package.swift

- Single `ShiftSchedulerCLI` executable target with `path: "."` and an explicit
  `sources:` list covering Models, Domain, Persistence, Repositories, Protocols,
  Services, Redux/Services, Redux/Errors, and Sources/ShiftSchedulerCLI
- Excludes `Redux/Services/Mocks` (test doubles) and `ServiceContainer.swift`
  (app-level DI container that references the mocks)
- `swift-argument-parser` (~> 1.3); platform macOS 14+

### Shared Code

Compiled directly into the executable, unchanged except where noted:
- `ShiftScheduler/Models/`, `ShiftScheduler/Domain/` — domain models
- `ShiftScheduler/Persistence/` — JSON repositories (+ CloudKitManager, gated; see below)
- `ShiftScheduler/Redux/Services/` — PersistenceService, CalendarService, CurrentDayService, ShiftSwitchService
- `ShiftScheduler/Services/TimeChangeService.swift` — `#if canImport(UIKit)` with no-op macOS fallback

---

## Command Hierarchy (as shipped)

```
shift-scheduler                              # Root command (help, exit codes, examples)
├── today                                    # Today's shifts
├── schedule
│   ├── list [--from DATE] [--to DATE]       # Default: current month; --to inclusive
│   ├── add --date DATE --type REF [--notes]
│   ├── edit --event-id ID --notes "..."     # Replace/clear shift notes
│   ├── delete --event-id ID [--force] [--reason]
│   └── switch --event-id ID --to REF [--reason]
├── types    list | add | edit | delete
├── locations list | add | edit | delete     # delete refuses while referenced by types
├── log      list [--limit N] | purge --older-than DAYS [--force]
├── profile  show | set [--name] [--retention] [--auto-purge]
├── auth     status | request
├── undo                                     # Reverts last add/delete/switch via snapshots
└── redo
```

- Every leaf command supports `--json` and `--data-dir PATH`.
- Type/location references (`REF`) accept UUID, title/name, or symbol; ambiguous
  matches fail with the candidate list.
- `schedule add|delete|switch` write ChangeLogEntry records and maintain the
  undo/redo stacks (`undoredo_stacks.json`), same files the iOS app uses.
- Undo/redo re-locates the calendar event by date + shift type from the change-log
  snapshots (ChangeLogEntry does not store event identifiers).

---

## CloudKit on macOS CLI

CloudKit requires a `com.apple.developer.icloud-services` entitlement. Unbundled
CLI processes don't have one, and `CKContainer` **traps** (uncatchable `brk`) when
used without it. `CloudKitManager` therefore:
- creates its `CKContainer` lazily, and
- exposes `isSyncAvailable` (false under `#if SWIFT_PACKAGE`), checked by
  `checkAccountStatus()`, which every operation calls first.

In CLI builds all CloudKit operations throw `accountNotAvailable`, which the
repositories already treat as a benign "offline" warning. iOS app behavior is
unchanged.

---

## EventKit on macOS

1. **Authorization**: `auth status` reports EventKit state; `auth request` shows the
   macOS permission dialog. Unauthorized calendar commands fail with a suggestion to
   run `auth request`.
2. **Shared Calendar**: The CLI uses the same `functioncraft.ShiftScheduler` calendar
   as the iOS app (created on iCloud when available), so shifts sync across devices.

---

## Implementation Phases — all complete

- **Phase 1 — Foundation**: Package.swift, shared sources compile, platform guards. ✅
- **Phase 2 — Skeleton**: CLIController, OutputFormatter, today command, all subcommands registered. ✅
- **Phase 3 — Data commands**: types/locations/profile/log CRUD with validation. ✅
- **Phase 4 — Calendar commands**: auth, schedule list/add/edit/delete/switch, undo/redo. ✅
- **Phase 5 — Polish**: date parsing (`today`, `tomorrow`, `+3d`, `-1w`), JSON errors,
  exit codes (0/1/64) in root help, examples in every command, `--force` +
  non-TTY-safe confirmations, `--data-dir`. ✅
  - *Not shipped*: ANSI color output (`--no-color`) — plain output was chosen for
    simplicity and clean piping; can be added later if wanted.

### Validation (run from the repo root)

```bash
swift build                                        # zero warnings
swift run shift-scheduler --help                   # full command tree
DIR=$(mktemp -d)
swift run shift-scheduler locations add --name "Test" --address "1 Test St" --data-dir $DIR
swift run shift-scheduler locations list --json --data-dir $DIR
swift run shift-scheduler types add --title "Day" --symbol D --location Test --start 07:00 --end 15:00 --data-dir $DIR
swift run shift-scheduler types delete --id Day --data-dir $DIR < /dev/null   # exits 1, no hang
swift run shift-scheduler types delete --id Day --force --data-dir $DIR
swift run shift-scheduler auth status --json
```
