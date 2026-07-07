import Foundation
import ArgumentParser

/// Root command for the shift-scheduler CLI tool.
/// Manages shifts, shift types, locations, and schedules from the terminal.
@main
struct ShiftSchedulerCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "shift-scheduler",
        abstract: "Manage work shifts from the command line.",
        discussion: """
            shift-scheduler is a CLI companion to the ShiftScheduler iOS app.

            Shift types, locations, profile, and the change log are stored as JSON
            in ~/Documents/ShiftSchedulerData/ on this Mac (override with --data-dir).
            Scheduled shifts live in the "functioncraft.ShiftScheduler" calendar via
            EventKit; when that calendar is on iCloud, shifts stay in sync with the
            iOS app. Reference data syncs through CloudKit when available.

            Most commands support --json for machine-readable output. Destructive
            commands prompt for confirmation; pass --force to skip the prompt
            (required when running non-interactively, e.g. from a script or agent).

            EXIT CODES:
              0   Success.
              1   Runtime failure (not found, not authorized, I/O error, cancelled).
              64  Usage error (unknown command, bad arguments).

            EXAMPLES:
              shift-scheduler auth request
              shift-scheduler locations add --name "Downtown" --address "123 Main St"
              shift-scheduler types list --json
              shift-scheduler schedule add --date tomorrow --type "Day Shift"
              shift-scheduler schedule list --from today --to +14d
              shift-scheduler schedule switch --event-id <ID> --to "Night Shift"
              shift-scheduler undo
            """,
        version: "0.1.0",
        subcommands: [
            TodayCommand.self,
            ScheduleCommand.self,
            TypesCommand.self,
            LocationsCommand.self,
            LogCommand.self,
            ProfileCommand.self,
            AuthCommand.self,
            UndoCommand.self,
            RedoCommand.self
        ]
    )
}
