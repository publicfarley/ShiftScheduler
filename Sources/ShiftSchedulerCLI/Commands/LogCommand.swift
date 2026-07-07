import Foundation
import ArgumentParser

struct LogCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "log",
        abstract: "View or purge the shift change log.",
        subcommands: [List.self, Purge.self],
        defaultSubcommand: List.self
    )

    // MARK: - list

    struct List: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "list",
            abstract: "List change log entries, newest first.",
            discussion: """
                EXAMPLES:
                  shift-scheduler log list
                  shift-scheduler log list --limit 10 --json
                """
        )

        @Option(help: "Maximum number of entries to show.")
        var limit: Int = 20

        @OptionGroup var options: GlobalOptions

        func validate() throws {
            guard limit > 0 else {
                throw ValidationError("--limit must be a positive number.")
            }
        }

        func run() async throws {
            try await CLIRuntime.run(json: options.json) {
                let controller = options.makeController()
                let entries = try await controller.persistence.loadChangeLogEntries()
                    .sorted { $0.timestamp > $1.timestamp }
                    .prefix(limit)
                if options.json {
                    try OutputFormatter.printJSON(entries.map(ChangeLogEntryDTO.init))
                } else if entries.isEmpty {
                    print("Change log is empty.")
                } else {
                    print(OutputFormatter.changeLogTable(Array(entries)))
                }
            }
        }
    }

    // MARK: - purge

    struct Purge: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "purge",
            abstract: "Delete change log entries older than a number of days.",
            discussion: """
                EXAMPLES:
                  shift-scheduler log purge --older-than 90
                  shift-scheduler log purge --older-than 30 --force
                """
        )

        @Option(name: .customLong("older-than"), help: "Delete entries older than this many days.")
        var olderThan: Int

        @Flag(help: "Skip the confirmation prompt.")
        var force = false

        @OptionGroup var options: GlobalOptions

        func validate() throws {
            guard olderThan > 0 else {
                throw ValidationError("--older-than must be a positive number of days.")
            }
        }

        func run() async throws {
            try await CLIRuntime.run(json: options.json) {
                let controller = options.makeController()
                guard let cutoff = Calendar.current.date(byAdding: .day, value: -olderThan, to: Date()) else {
                    throw CLIError.invalidOperation("Could not compute the cutoff date")
                }
                try CLIRuntime.confirm(
                    "Delete all change log entries older than \(olderThan) day(s)?",
                    force: force
                )
                let deleted = try await controller.persistence.purgeOldChangeLogEntries(olderThan: cutoff)
                if options.json {
                    try OutputFormatter.printJSON(["deleted": deleted])
                } else {
                    print("Deleted \(deleted) change log entr\(deleted == 1 ? "y" : "ies").")
                }
            }
        }
    }
}
