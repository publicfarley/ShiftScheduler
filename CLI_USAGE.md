# shift-scheduler CLI — Usage Manual

A macOS command-line interface for ShiftScheduler. It reads and writes the
same data the iOS app uses — shift types, locations, profile, and change log
as JSON in `~/Documents/ShiftSchedulerData/` (override with `--data-dir`),
plus scheduled shifts in the shared `functioncraft.ShiftScheduler` EventKit
calendar, which syncs with the iOS app via iCloud when available.

This manual covers usage for **human operators** and for **LLM agents**
driving the tool programmatically. Read the "For LLM Agents" section before
scripting against this CLI — it documents the machine-readable contract
(`--json`, exit codes, error shape) you should rely on instead of parsing
human-readable text.

Binary name: `shift-scheduler`. Version: `0.1.0`.

---

## Table of Contents

1. [Installation & Build](#installation--build)
2. [Quick Start](#quick-start)
3. [Global Options](#global-options)
4. [Exit Codes](#exit-codes)
5. [Command Reference](#command-reference)
   - [today](#today)
   - [schedule](#schedule)
   - [types](#types)
   - [locations](#locations)
   - [log](#log)
   - [profile](#profile)
   - [auth](#auth)
   - [undo / redo](#undo--redo)
6. [Date & Time Formats](#date--time-formats)
7. [Referencing Objects (types & locations)](#referencing-objects-types--locations)
8. [For LLM Agents](#for-llm-agents)
9. [For Human Users](#for-human-users)
10. [Data Model Notes](#data-model-notes)
11. [Troubleshooting](#troubleshooting)

---

## Installation & Build

```bash
git clone <repo>
cd ShiftScheduler
swift build -c release
.build/release/shift-scheduler --help
```

For iterative development, `swift run shift-scheduler <args>` builds and runs
in one step (debug configuration).

There is no separate install step; copy the built binary onto your `PATH` if
you want a bare `shift-scheduler` command, e.g.:

```bash
cp .build/release/shift-scheduler /usr/local/bin/
```

---

## Quick Start

```bash
# One-time: grant Calendar access
shift-scheduler auth request

# Set up a location and a shift type
shift-scheduler locations add --name "Downtown" --address "123 Main St"
shift-scheduler types add --title "Day Shift" --symbol D \
  --location "Downtown" --start 07:00 --end 15:00

# Schedule and inspect
shift-scheduler schedule add --date tomorrow --type "Day Shift"
shift-scheduler today
shift-scheduler schedule list --from today --to +14d
```

---

## Global Options

Every leaf command (the actual executable subcommands, not `schedule`/`types`
group headers) accepts:

| Flag | Description |
|---|---|
| `--json` | Emit machine-readable JSON instead of a human-readable table/message. Applies to **both success and error** output (errors go to stderr; see [For LLM Agents](#for-llm-agents)). |
| `--data-dir <path>` | Override the data directory (default `~/Documents/ShiftSchedulerData`). Accepts `~` expansion. Useful for tests, multiple profiles, or sandboxing an agent's writes. |

Root-level flags (on `shift-scheduler` itself): `--version`, `--help` / `-h`.

---

## Exit Codes

Documented in `shift-scheduler --help` and stable across releases:

| Code | Meaning |
|---|---|
| `0` | Success. |
| `1` | Runtime failure — not found, not authorized, I/O error, validation error, user cancelled, confirmation required without a TTY. |
| `64` | Usage error — unknown command/subcommand, bad or missing arguments (standard `sysexits.h` `EX_USAGE`, provided by swift-argument-parser). |

Scripts and agents should branch on exit code first, then inspect stderr
(`--json` or plain text) for detail.

---

## Command Reference

### `today`

Show today's scheduled shifts.

```
shift-scheduler today [--json] [--data-dir <path>]
```

Requires calendar authorization (see [`auth`](#auth)). Prints a table of
today's shifts, or "No shifts scheduled for today (...)" if none.

---

### `schedule`

Manage scheduled shifts in the calendar. Default subcommand: `list`.

#### `schedule list`

```
shift-scheduler schedule list [--from <date>] [--to <date>] [--json]
```

- Defaults to the **current calendar month** if `--from`/`--to` are omitted.
- `--to` is **inclusive**.
- Dates accept the formats in [Date & Time Formats](#date--time-formats).
- Date arguments are validated *before* the calendar-authorization check, so
  a bad `--from`/`--to` value reports as a date error, not an auth error.

```bash
shift-scheduler schedule list
shift-scheduler schedule list --from today --to +14d
shift-scheduler schedule list --from 2026-07-01 --to 2026-07-31 --json
```

#### `schedule add`

```
shift-scheduler schedule add --date <date> --type <ref> [--notes <text>] [--json]
```

Creates a calendar event for the given shift type on the given date and
records a change-log entry (undoable). Prints the new event's EventKit
identifier — capture this for later `edit`/`delete`/`switch` calls.

```bash
shift-scheduler schedule add --date tomorrow --type "Day Shift"
shift-scheduler schedule add --date 2026-07-15 --type D --notes "Covering for Sam"
```

#### `schedule edit`

```
shift-scheduler schedule edit --event-id <id> --notes <text> [--json]
```

Replaces a shift's notes (pass `--notes ""` to clear them). To change the
shift *type* instead, use `schedule switch`.

```bash
shift-scheduler schedule edit --event-id <ID> --notes "Trade with Alex"
shift-scheduler schedule edit --event-id <ID> --notes ""
```

#### `schedule delete`

```
shift-scheduler schedule delete --event-id <id> [--reason <text>] [--force] [--json]
```

Deletes the shift and records a change-log entry (undoable). Prompts for
confirmation unless `--force` is given; without a TTY, omitting `--force`
fails fast with exit `1` rather than hanging (see [For LLM Agents](#for-llm-agents)).

```bash
shift-scheduler schedule delete --event-id <ID>
shift-scheduler schedule delete --event-id <ID> --force --reason "Shift cancelled"
```

#### `schedule switch`

```
shift-scheduler schedule switch --event-id <id> --to <ref> [--reason <text>] [--json]
```

Switches a scheduled shift to a different shift type, recording a
before/after snapshot in the change log so it can be undone.

```bash
shift-scheduler schedule switch --event-id <ID> --to "Night Shift"
shift-scheduler schedule switch --event-id <ID> --to N --reason "Traded with Alex"
```

---

### `types`

Manage shift type templates (title, symbol, time range or all-day, location).
Default subcommand: `list`.

#### `types list`

```
shift-scheduler types list [--json]
```

#### `types add`

```
shift-scheduler types add --title <text> --symbol <text> --location <ref> \
  [--description <text>] (--all-day | --start <HH:MM> --end <HH:MM>) [--json]
```

Provide either `--all-day` or **both** `--start` and `--end`. Overnight
shifts (end time before start time) are supported.

```bash
shift-scheduler types add --title "Day Shift" --symbol D --location "Downtown" --start 07:00 --end 15:00
shift-scheduler types add --title "On Call" --symbol OC --location "Downtown" --all-day
```

#### `types edit`

```
shift-scheduler types edit --id <ref> [--title <text>] [--symbol <text>] \
  [--description <text>] [--location <ref>] \
  (--all-day | --start <HH:MM> --end <HH:MM>) [--json]
```

Only the fields you provide change. Existing calendar events using this type
are updated in place when calendar access is authorized (reports how many
were cascaded).

```bash
shift-scheduler types edit --id "Day Shift" --symbol DS
shift-scheduler types edit --id <UUID> --start 08:00 --end 16:00
```

#### `types delete`

```
shift-scheduler types delete --id <ref> [--force] [--json]
```

Already-scheduled events using this type keep their event but display as
"(unknown type)" afterward — deletion does not cascade to the calendar.

```bash
shift-scheduler types delete --id "Day Shift"
shift-scheduler types delete --id <UUID> --force
```

---

### `locations`

Manage locations. Default subcommand: `list`.

#### `locations list`

```
shift-scheduler locations list [--json]
```

#### `locations add`

```
shift-scheduler locations add --name <text> --address <text> [--json]
```

#### `locations edit`

```
shift-scheduler locations edit --id <ref> [--name <text>] [--address <text>] [--json]
```

Cascades: shift types referencing this location are updated automatically,
and existing calendar events using those types are updated when calendar
access is authorized. Reports both cascade counts.

```bash
shift-scheduler locations edit --id "Downtown" --address "456 Oak Ave"
```

#### `locations delete`

```
shift-scheduler locations delete --id <ref> [--force] [--json]
```

**Fails with a `locationInUse` error if any shift type still references the
location** — delete/edit those shift types first, or point them elsewhere.

```bash
shift-scheduler locations delete --id "Downtown"
shift-scheduler locations delete --id <UUID> --force
```

---

### `log`

View or purge the shift change log (the audit trail behind `undo`/`redo`).
Default subcommand: `list`.

#### `log list`

```
shift-scheduler log list [--limit <n>] [--json]
```

Newest first. `--limit` defaults to 20 and must be positive.

```bash
shift-scheduler log list
shift-scheduler log list --limit 10 --json
```

#### `log purge`

```
shift-scheduler log purge --older-than <days> [--force] [--json]
```

Deletes change-log entries older than the given number of days. `--older-than`
must be a positive integer.

```bash
shift-scheduler log purge --older-than 90
shift-scheduler log purge --older-than 30 --force
```

---

### `profile`

View or update the local user profile (display name, change-log retention
policy, auto-purge). Default subcommand: `show`.

#### `profile show`

```
shift-scheduler profile show [--json]
```

#### `profile set`

```
shift-scheduler profile set [--name <text>] [--retention <policy>] [--auto-purge <true|false>] [--json]
```

At least one field must be provided. Valid `--retention` values:
`30_days`, `90_days`, `6_months`, `1_year`, `2_years`, `forever`.

```bash
shift-scheduler profile set --name "Alex"
shift-scheduler profile set --retention 90_days --auto-purge true
```

---

### `auth`

Check or request calendar (EventKit) authorization. Default subcommand:
`status`.

#### `auth status`

```
shift-scheduler auth status [--json]
```

Reports `{"authorized": true|false}` in JSON mode. Never prompts.

#### `auth request`

```
shift-scheduler auth request [--json]
```

Triggers the macOS system permission dialog (interactive; there is no
non-interactive way to grant Calendar access — see
[For LLM Agents](#for-llm-agents)). Exits `1` if access is denied.

---

### `undo` / `redo`

```
shift-scheduler undo [--json]
shift-scheduler redo [--json]
```

Undo/redo the most recent `schedule add` / `schedule delete` /
`schedule switch` operation, using snapshots recorded in the change log.
`undo` moves the operation onto the redo stack; `redo` re-applies it. Both
report `nothingToUndo` / `nothingToRedo` (exit `1`) when their stack is
empty — this check happens *before* the calendar-authorization check, so an
empty stack is reported accurately even without calendar access.

```bash
shift-scheduler undo
shift-scheduler redo --json
```

---

## Date & Time Formats

**Dates** (`--date`, `--from`, `--to`, `--older-than` is a day count, not a
date):

| Input | Meaning |
|---|---|
| `today` / `tomorrow` / `yesterday` | Relative to the current day. |
| `+Nd` / `-Nd` | N days from today, e.g. `+14d`, `-7d`. |
| `+Nw` / `-Nw` | N weeks from today, e.g. `+2w`. |
| `YYYY-MM-DD` | Absolute date, e.g. `2026-07-15`. |

All dates are normalized to start-of-day in the local calendar.

**Times** (`--start`, `--end`): 24-hour `HH:MM`, e.g. `07:00`, `22:30`.
Overnight ranges (end < start) are valid and represent a shift crossing
midnight.

Invalid input raises `invalidDate` / `invalidTime` with a suggestion listing
the accepted formats — see [CLIError](#for-llm-agents) below.

---

## Referencing Objects (types & locations)

Anywhere a command takes a shift-type or location reference (`--type`,
`--to`, `--location`, `--id` on `types`/`locations` commands), you may pass:

1. A **UUID** (unambiguous, preferred for scripts/agents).
2. A **title** (shift types) or **name** (locations), case-insensitive.
3. A **symbol** (shift types only), case-insensitive.

If a title/symbol matches more than one object, the command fails with an
`ambiguous` error listing the candidates — re-run with the UUID to
disambiguate. Scheduled shifts (`--event-id`) are always referenced by their
EventKit event identifier, obtained from `schedule list` or the output of
`schedule add`.

---

## For LLM Agents

This CLI is designed to be driven programmatically. Rely on the following
contract rather than parsing human-readable text:

1. **Always pass `--json`.** Every leaf command supports it, on both the
   success path and the error path. Human-readable table output is not a
   stable format and may change; JSON field names are stable.

2. **Error shape.** On failure, JSON mode writes to **stderr**:
   ```json
   {
     "error": {
       "message": "No shift type matches 'Nite Shift'",
       "suggestion": "Run 'shift-scheduler types list' to see available shift types. You can reference a type by UUID, title, or symbol."
     }
   }
   ```
   `suggestion` is present when there's an actionable next step (not always).
   Non-JSON mode writes `Error: <message>` and, if present, the suggestion
   on the next line, also to stderr. Check the exit code first — 0 always
   means stdout holds the result payload; nonzero always means stderr holds
   the error.

3. **Exit codes**: `0` success, `1` runtime failure, `64` usage error. See
   [Exit Codes](#exit-codes).

4. **Destructive commands never hang waiting for input.** `schedule delete`,
   `types delete`, `locations delete`, and `log purge` prompt for
   confirmation only when stdin is a TTY. In a non-interactive context
   (agent, script, CI), the confirmation prompt is skipped and the command
   **fails immediately** with a `confirmationRequired` error (exit `1`)
   unless `--force` is passed. Always pass `--force` when calling these from
   an agent, and gate the decision to do so in your own logic (the CLI will
   not ask twice).

5. **`auth request` requires a human at the keyboard.** It shows the native
   macOS permission dialog — there is no headless/non-interactive way to
   grant EventKit access. An agent should call `auth status --json` first
   and, if `authorized` is `false`, surface that to a human rather than
   attempting `auth request` unattended. All calendar-touching commands
   (`today`, `schedule *`, `undo`, `redo`) will fail with
   `calendarNotAuthorized` until access is granted.

6. **Object references**: prefer UUIDs over titles/names/symbols in
   generated commands to avoid `ambiguous` errors. Obtain UUIDs from the
   `id` field of `types list --json` / `locations list --json`, and event
   IDs from the `eventId` field of `schedule list --json` /
   `schedule add --json`.

7. **Idempotency / retries**: `schedule add` always creates a new event —
   retrying a successful `add` creates a duplicate shift. Check
   `schedule list --from <date> --to <date> --json` first if you're unsure
   whether a shift already exists before adding one.

8. **`--data-dir` for sandboxing**: point an agent's reference-data writes
   (`types`, `locations`, `profile`, `log`) at a scratch directory with
   `--data-dir` to avoid touching the user's real data while testing a
   workflow. Note this does **not** sandbox calendar writes — those always
   go to the shared `functioncraft.ShiftScheduler` EventKit calendar. There
   is currently no `--dry-run` flag for calendar-mutating commands
   (`schedule add/edit/delete/switch`); an agent that needs a rehearsal
   should call `auth status --json` to confirm authorization state and
   review `schedule list` before mutating.

9. **`undo`/`redo` are single-step and shared state.** They operate on one
   global stack, not scoped to a session or an agent — undoing after
   another actor (the iOS app, another script) has made changes may not
   produce the effect you expect. Prefer targeted `schedule edit`/`switch`/
   `delete` calls with explicit event IDs over relying on `undo` in
   multi-actor environments.

10. **Stable JSON field names to depend on**: see the DTOs below. These are
    hand-written output shapes, decoupled from internal model encodings, and
    are the recommended integration surface.

    - `LocationDTO`: `id, name, address`
    - `ShiftTypeDTO`: `id, symbol, title, description, allDay, startTime, endTime, location`
    - `ShiftDTO`: `eventId, date, endDate, shiftType, notes, sickDay, sickReason`
    - `ChangeLogEntryDTO`: `id, timestamp, user, changeType, shiftDate, from, to, reason`
    - `ProfileDTO`: `userId, displayName, retentionPolicy, autoPurgeEnabled, lastPurgeDate`

    Dates are `YYYY-MM-DD`; timestamps are ISO 8601.

**Minimal agent recipe:**

```bash
shift-scheduler auth status --json                      # confirm access first
shift-scheduler types list --json                       # get type UUIDs
shift-scheduler locations list --json                    # get location UUIDs
shift-scheduler schedule list --from today --to +7d --json   # check current state
shift-scheduler schedule add --date 2026-07-15 --type <UUID> --json   # mutate
```

Always check the process exit code before trusting stdout.

---

## For Human Users

- Run any command with `--help` to see its flags, an abstract, and worked
  examples — every leaf command has an `EXAMPLES:` section in its
  `discussion`, e.g. `shift-scheduler schedule switch --help`.
- Omit `--json` for readable, aligned tables.
- Destructive commands (`schedule delete`, `types delete`,
  `locations delete`, `log purge`) prompt `[y/N]` when run interactively —
  no need to remember `--force` unless you're scripting.
- Made a mistake? `shift-scheduler undo` reverts the last add/delete/switch;
  `shift-scheduler redo` re-applies it if you change your mind.
- The calendar this CLI writes to is named **functioncraft.ShiftScheduler**
  and is visible in Calendar.app / the iOS app once calendar access is
  granted (`shift-scheduler auth request`) and iCloud sync has caught up.
- `--data-dir` is mainly useful for testing; day-to-day use should leave it
  at the default (`~/Documents/ShiftSchedulerData`) so the CLI and iOS app
  see the same reference data.

---

## Data Model Notes

- **Reference data** (shift types, locations, profile, change log) is local
  JSON on the machine running the CLI, at `~/Documents/ShiftSchedulerData/`
  by default. It is *not* automatically shared with an iOS device's sandbox;
  it syncs through CloudKit only where entitlements allow (the iOS app).
  Running the CLI on a Mac without CloudKit entitlements (the normal case
  for an unbundled command-line binary) means CloudKit sync silently
  no-ops — treated internally as a benign "offline" condition — and
  reference data stays local to that machine's `--data-dir`.
- **Scheduled shifts** live in EventKit, in the shared
  `functioncraft.ShiftScheduler` calendar. This *does* sync across devices
  via iCloud, independent of the CloudKit reference-data path above — this
  is the actual mechanism by which CLI-created shifts appear in the iOS app.
- **Undo/redo** replays from `ChangeLogEntry` snapshots (no stored EventKit
  identifiers); shifts are re-located by date + shift-type ID when
  reverting/reapplying.

---

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `Calendar access is not authorized` | EventKit permission not granted | `shift-scheduler auth request` (interactive; grant it in the macOS dialog) |
| `Confirmation required: ...` on a delete/purge in a script | No TTY, `--force` omitted | Add `--force` |
| `'X' matches multiple shift types:` | Ambiguous title/symbol reference | Re-run using the UUID (`types list --json`) |
| `Location 'X' is used by shift type(s): ...` | Deleting a location still referenced by a type | Edit/delete those shift types first, or use a different location |
| `Cannot parse date 'X'` | Unsupported date format | Use `YYYY-MM-DD`, `today`/`tomorrow`/`yesterday`, or `+Nd`/`-Nw` |
| CLI and iOS app show different reference data | Different `--data-dir`, or CloudKit sync unavailable to the CLI | Confirm both are using the same data directory / calendar; remember reference-data CloudKit sync is iOS-only (see [Data Model Notes](#data-model-notes)) |
