# Shift Import Facility — Implementation Plan

## Overview

Add an import facility that accepts shift schedule data as **pasted text from the pasteboard** or a **text file**, and creates scheduled shifts starting at the date indicated. This is the inverse of the existing Shift Export feature (Settings → Export Shifts), and deliberately round-trips with its output format.

### Input Format

```
2026-12-28 x d wd e x x h dh x x x
```

- **First token**: anchor date in ISO `yyyy-MM-dd` format.
- **Remaining tokens**: one shift-type symbol per consecutive calendar day, whitespace-separated. The first symbol applies to the anchor date itself, the second to the next day, and so on. The example above covers 2026-12-28 through 2027-01-07 (11 days).
- **`~` and `x` tokens**: skip the day, leave it unscheduled. `x` is treated exactly like `~` (case-insensitive, so `X` too). `~` matches the export format, which marks unscheduled days with `~`; `x` is the conventional day-off notation in hand-written rotations like the sample above.
- **Symbols**: all other tokens are matched case-insensitively against the `ShiftType.symbol` values in the user's shift type catalog. Unknown symbols are a validation error — the import never silently guesses.
- **Multiple lines**: each non-empty line is an independent `date symbols...` record, allowing several date ranges in one import. Blank lines and surrounding whitespace are ignored.

> **Note — `x` is reserved:** Because `x`/`X` always means "skip", a shift type whose catalog symbol is `x` cannot be referenced by import. Skip-token checking happens **before** catalog lookup. The preview makes this visible by labeling those days "Skipped".

---

## Architecture Fit

The app uses Redux (Action → Reducer → State → UI, middleware for side effects). The import feature lives in the **Settings** feature, directly beside the existing export feature, and reuses the shift-creation pipeline already proven in `ScheduleMiddleware.bulkAddDifferentShiftsConfirmed` (pre-validate → create calendar events via `CalendarService.createShiftEvent` → write `ChangeLogEntry` audit records → reload shifts).

```
ShiftImportView (sheet)
   │ dispatch .settings(.importTextChanged / .pasteImportFromClipboard / .validateImport / .confirmImport)
   ▼
AppReducer (sync state: sheet visibility, text, preview, errors)
   ▼
SettingsMiddleware (async: parse → resolve symbols → conflict check → create events + change log → reload)
   ▼
CalendarService / PersistenceService
```

---

## Implementation Steps

### Step 1 — Pure parser: `ShiftImportParser` (new file `ShiftScheduler/Domain/ShiftImportParser.swift`)

A pure, `Sendable`, fully unit-testable component with no service dependencies.

```swift
struct ShiftImportParser {
    struct ParsedEntry: Equatable, Sendable {
        let date: Date          // startOfDay
        let symbol: String      // raw symbol token ("~"/"x" skip tokens allowed)
    }

    /// Tokens (lowercased) that mean "leave this day unscheduled"
    static let skipTokens: Set<String> = ["~", "x"]

    enum ParseError: Error, Equatable {
        case emptyInput
        case invalidDate(line: Int, token: String)
        case noSymbols(line: Int)
        case overlappingRanges(date: Date)   // two lines assign the same day
    }

    static func parse(_ text: String) throws -> [ParsedEntry]
}
```

Rules:
- Split input into lines; ignore blank lines.
- Per line: first whitespace-separated token must parse as `yyyy-MM-dd` (fixed `en_US_POSIX` locale, current calendar/timezone at `startOfDay`); remaining tokens map to consecutive days.
- Reject a line with a valid date but zero symbols.
- Reject duplicate day assignments across lines.
- Skip-token entries (`~`, `x`, case-insensitive) are retained in the parse result (so the preview can show "Skipped") but produce no shift.

### Step 2 — Resolution & preview model (same file or `ShiftImportPreview.swift`)

A second pure stage resolves parsed entries against the catalog and existing schedule:

```swift
struct ShiftImportPreview: Equatable, Sendable {
    enum DayStatus: Equatable, Sendable {
        case willImport(ShiftType)
        case skipped                    // "~" or "x" (checked before catalog lookup)
        case unknownSymbol(String)      // blocks import
        case conflict(ShiftType, existing: ScheduledShiftData)  // day already scheduled
    }
    let days: [(date: Date, status: DayStatus)]
    var importableCount: Int { ... }
    var hasBlockingErrors: Bool { ... }   // any unknownSymbol
    var conflictCount: Int { ... }
}
```

- Skip tokens (`~`, `x`) are classified as `.skipped` first; only remaining tokens go through catalog lookup.
- Symbol lookup: case-insensitive exact match on `ShiftType.symbol` from `state.shiftTypes.shiftTypes`.
- Conflicts detected against shifts loaded via `calendarService.loadShifts(from:to:)` for the parsed date span (same `occursOn(date:)` check the bulk-add validation uses).

### Step 3 — Redux state (`AppState.swift`, `SettingsState`)

Mirror the export state block:

```swift
// MARK: - Shift Import State
var showImportSheet: Bool = false
var importText: String = ""
var importPreview: ShiftImportPreview? = nil
var importConflictPolicy: ImportConflictPolicy = .skipConflicts   // .skipConflicts | .abortOnConflict
var isImporting: Bool = false
var importErrorMessage: String? = nil
var importSuccessMessage: String? = nil   // e.g. "Imported 8 shifts (2 skipped, 1 conflict skipped)"
```

### Step 4 — Redux actions (`AppAction.swift`, `SettingsAction`)

```swift
// MARK: - Shift Import Actions
case importSheetToggled(Bool)
case importTextChanged(String)
case pasteImportFromClipboard            // middleware reads UIPasteboard
case importFileLoaded(Result<String, Error>)  // from .fileImporter
case validateImport                      // parse + resolve + conflict check → preview
case importPreviewGenerated(ShiftImportPreview)
case importConflictPolicyChanged(ImportConflictPolicy)
case confirmImport                       // create shifts from current preview
case importCompleted(Result<Int, Error>) // count of shifts created
case importFailed(String)
case resetImport
```

Extend `SettingsAction.==` for the new cases (the enum has a manual `Equatable` implementation).

### Step 5 — Reducer (`AppReducer.swift`, settings section)

Pure state transitions only:
- `importSheetToggled`: show/hide; hide also clears text/preview/errors (like `resetExport`).
- `importTextChanged`: update text, invalidate any existing preview.
- `importPreviewGenerated`: store preview, clear error.
- `confirmImport`: set `isImporting = true`.
- `importCompleted(.success(count))`: clear `isImporting`, set success message, dismiss preview.
- `importCompleted(.failure)` / `importFailed`: clear `isImporting`, set `importErrorMessage`.
- `resetImport`: back to initial import state.

### Step 6 — Middleware (`SettingsMiddleware.swift`)

**`.pasteImportFromClipboard`** — read `UIPasteboard.general.string` on the MainActor (mirror of `copyToClipboard`), dispatch `.importTextChanged(text)` then `.validateImport`.

**`.validateImport`** —
1. `ShiftImportParser.parse(state.settings.importText)`; on `ParseError`, dispatch `.importFailed(message)` with a line-numbered, human-readable message.
2. Load existing shifts for the parsed date span via `calendarService.loadShifts(from:to:)`.
3. Build `ShiftImportPreview` against `state.shiftTypes.shiftTypes`; dispatch `.importPreviewGenerated(preview)`.

**`.confirmImport`** — reuses the bulk-add creation pattern:
1. Guard: preview exists, `!hasBlockingErrors`; if `importConflictPolicy == .abortOnConflict` and conflicts exist, fail with a clear message.
2. For each `.willImport` day (sorted by date, skipping conflicts under `.skipConflicts`):
   - `try await calendarService.createShiftEvent(date:shiftType:notes:)` with notes like `"Imported"` (or nil).
   - Persist a `ChangeLogEntry` (`changeType: .created`, `newShiftSnapshot: ShiftSnapshot(from: shiftType)`, `reason: "Imported from text"`), exactly as `bulkAddConfirmed` does.
3. On any creation error, dispatch `.importCompleted(.failure(...))` reporting how many were created before the failure (same partial-failure messaging as bulk add).
4. On success, dispatch `.importCompleted(.success(count))` then `.schedule(.loadShifts))` to refresh the calendar (bulk add does this via `bulkAddCompleted`).

Add the reducer-only cases to the middleware's pass-through `case ... : break` list.

### Step 7 — UI: `ShiftImportView.swift` (new, modeled on `ShiftExportView.swift`)

Sheet presented from Settings with:
1. **Input section**:
   - `TextEditor` bound to `importText` (monospaced), with placeholder showing the format example.
   - **Paste from Clipboard** button → `.pasteImportFromClipboard`.
   - **Import from File…** button → SwiftUI `.fileImporter(allowedContentTypes: [.plainText, .text])`; read the file (security-scoped access), dispatch `.importFileLoaded(...)`.
2. **Preview button** → `.validateImport`.
3. **Preview section** (when `importPreview != nil`): per-day rows — date, symbol, resolved shift title/time or "Skipped" (for `~`/`x`) / "⚠ Unknown symbol" / "Conflict: already scheduled". Summary line with counts. Conflict policy picker (Skip conflicting days / Cancel if conflicts).
4. **Import N Shifts** button → `.confirmImport`; disabled while `isImporting` or when `hasBlockingErrors`.
5. Error and success sections styled like the export view's `errorSection`.
6. Per CLAUDE.md: `.scrollDismissesKeyboard(.immediately)` + `.dismissKeyboardOnTap()`.

### Step 8 — Settings entry point (`SettingsView.swift`)

Add a `shiftImportSection` beside the existing `shiftExportSection` ("Import shifts from a space-separated symbol list…"), plus a `.sheet` bound to `showImportSheet` — mirroring lines 75–82 and 437–464 of the current file. Consider grouping both under a "Transfer Shifts" section.

### Step 9 — Tests (Swift Testing, `@Test` / `#expect`)

| Suite | Coverage |
|---|---|
| `ShiftImportParserTests` (new) | valid single line (the sample input, verifying 11 consecutive dates); multi-line; blank lines; skip tokens `~`, `x`, `X` produce no shift; invalid date token; missing symbols; duplicate day across lines; leading/trailing whitespace; month/year rollover (2026-12-28 → 2027-01) |
| `SettingsReducerTests` (extend) | each new action's state transition; sheet dismissal clears state |
| `SettingsMiddlewareImportTests` (new, mirrors `SettingsMiddlewareExportTests`) | validate happy path via mocks; unknown symbol blocks; conflict detection; confirm creates N events + N change log entries via `MockCalendarService`/`MockPersistenceService`; skip-conflicts vs abort policies; partial-failure error message; `.schedule(.loadShifts)` dispatched after success |
| Round-trip test | export a known schedule → prepend the start date → import into empty schedule → same shifts |

### Step 10 — Build verification (per CLAUDE.md)

- Build app target and test target on the iOS simulator; run the full test suite. Never report complete without both targets compiling.

---

## Edge Cases & Decisions

| Case | Behavior |
|---|---|
| Symbol not in catalog | Validation error shown in preview; import blocked (no silent guessing) |
| `~` or `x`/`X` symbol | Day intentionally left unscheduled (skip tokens, checked before catalog lookup) |
| Catalog contains a shift type with symbol `x` | Unreachable via import — `x` is reserved as a skip token; preview shows "Skipped" so this is visible |
| Day already has a shift | Surfaced as conflict; user chooses skip-conflicting-days (default) or abort |
| Duplicate day across input lines | Parse error |
| Case differences (`WD` vs `wd`) | Case-insensitive symbol match |
| Extra whitespace / multiple spaces / trailing newline | Tolerated (whitespace-split, blank tokens dropped) |
| Date without symbols | Parse error with line number |
| Huge input (years of days) | No hard limit; creation loop is sequential and awaited, progress via `isImporting`; preview count warns the user |
| Calendar permission missing | `createShiftEvent` throws → surfaced via `importCompleted(.failure)` |

## File Inventory

| File | Change |
|---|---|
| `ShiftScheduler/Domain/ShiftImportParser.swift` | **New** — pure parser + preview builder |
| `ShiftScheduler/Views/ShiftImportView.swift` | **New** — import sheet UI |
| `ShiftScheduler/Redux/State/AppState.swift` | Add import fields to `SettingsState`, `ImportConflictPolicy` enum |
| `ShiftScheduler/Redux/Action/AppAction.swift` | Add import cases to `SettingsAction` (+ `Equatable`) |
| `ShiftScheduler/Redux/Reducer/AppReducer.swift` | Handle import actions |
| `ShiftScheduler/Redux/Middleware/SettingsMiddleware.swift` | Paste/validate/confirm side effects |
| `ShiftScheduler/Views/SettingsView.swift` | Import section + sheet |
| `ShiftSchedulerTests/…` | Parser, reducer, middleware, round-trip tests |

## Suggested Commit Sequence

1. `feat: add ShiftImportParser with unit tests` (pure logic, no UI)
2. `feat: add import state, actions, and reducer handling for shift import`
3. `feat: implement shift import middleware (validate, conflict check, create shifts)`
4. `feat: add ShiftImportView with paste, file import, and preview`
5. `test: add import middleware and round-trip export/import tests`
