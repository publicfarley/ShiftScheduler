import Foundation
import ArgumentParser
import ShiftSchedulerCore

/// Root command for the shift-scheduler CLI tool.
/// Manages shifts, shift types, locations, and schedules from the terminal,
/// sharing data with the ShiftScheduler iOS app via ~/Documents/ShiftSchedulerData/.
@main
struct ShiftSchedulerCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "shift-scheduler",
        abstract: "Manage work shifts from the command line.",
        discussion: """
            shift-scheduler is a CLI interface for the ShiftScheduler iOS app.
            It reads and writes to the same data directory as the iOS app
            (~/ Documents/ShiftSchedulerData/) so changes are reflected in both.
            """,
        version: "1.0.0",
        subcommands: []
    )

    mutating func run() async throws {
        // Root command with no subcommands prints help
        print(ShiftSchedulerCLI.helpMessage())
    }
}
