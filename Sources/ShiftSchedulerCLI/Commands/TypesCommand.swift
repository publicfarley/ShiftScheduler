import Foundation
import ArgumentParser

struct TypesCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "types",
        abstract: "Manage shift type templates.",
        subcommands: [List.self, Add.self, Edit.self, Delete.self],
        defaultSubcommand: List.self
    )

    // MARK: - list

    struct List: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "list",
            abstract: "List all shift types.",
            discussion: """
                EXAMPLES:
                  shift-scheduler types list
                  shift-scheduler types list --json
                """
        )

        @OptionGroup var options: GlobalOptions

        func run() async throws {
            try await CLIRuntime.run(json: options.json) {
                let controller = options.makeController()
                let types = try await controller.persistence.loadShiftTypes()
                if options.json {
                    try OutputFormatter.printJSON(types.map(ShiftTypeDTO.init))
                } else if types.isEmpty {
                    print("No shift types defined. Add one with 'shift-scheduler types add'.")
                } else {
                    print(OutputFormatter.shiftTypeTable(types))
                }
            }
        }
    }

    // MARK: - add

    struct Add: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "add",
            abstract: "Create a new shift type.",
            discussion: """
                Provide either --all-day or both --start and --end (24-hour HH:MM).
                Overnight shifts (end before start) are supported.

                EXAMPLES:
                  shift-scheduler types add --title "Day Shift" --symbol D --location "Downtown" --start 07:00 --end 15:00
                  shift-scheduler types add --title "On Call" --symbol OC --location "Downtown" --all-day
                """
        )

        @Option(help: "Title of the shift type.")
        var title: String

        @Option(help: "Short symbol shown in listings and calendar events (e.g. D, N, OC).")
        var symbol: String

        @Option(help: "Optional longer description.")
        var description: String = ""

        @Option(help: "Location for this shift type (UUID or name).")
        var location: String

        @Option(help: "Start time (24-hour HH:MM).")
        var start: String?

        @Option(help: "End time (24-hour HH:MM).")
        var end: String?

        @Flag(name: .customLong("all-day"), help: "Create an all-day shift type instead of a timed one.")
        var allDay = false

        @OptionGroup var options: GlobalOptions

        func validate() throws {
            if allDay {
                guard start == nil, end == nil else {
                    throw ValidationError("--all-day cannot be combined with --start/--end.")
                }
            } else {
                guard start != nil, end != nil else {
                    throw ValidationError("Provide both --start and --end, or use --all-day.")
                }
            }
        }

        func run() async throws {
            try await CLIRuntime.run(json: options.json) {
                let controller = options.makeController()
                let shiftLocation = try await controller.resolveLocation(location)
                let duration: ShiftDuration
                if allDay {
                    duration = .allDay
                } else {
                    duration = .scheduled(
                        from: try DateParsing.parseTime(start ?? ""),
                        to: try DateParsing.parseTime(end ?? "")
                    )
                }
                let type = ShiftType(
                    symbol: symbol,
                    duration: duration,
                    title: title,
                    description: description,
                    location: shiftLocation
                )
                try await controller.persistence.saveShiftType(type)
                if options.json {
                    try OutputFormatter.printJSON(ShiftTypeDTO(type))
                } else {
                    print("Added shift type '\(type.symbol): \(type.title)' (\(type.timeRangeString)).")
                    print("ID: \(type.id.uuidString)")
                }
            }
        }
    }

    // MARK: - edit

    struct Edit: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "edit",
            abstract: "Edit an existing shift type.",
            discussion: """
                Only the provided fields change. Changing times requires either
                --all-day or both --start and --end. Existing calendar events using
                this type are updated when calendar access is authorized.

                EXAMPLES:
                  shift-scheduler types edit --id "Day Shift" --symbol DS
                  shift-scheduler types edit --id <UUID> --start 08:00 --end 16:00
                """
        )

        @Option(help: "Shift type to edit (UUID, title, or symbol).")
        var id: String

        @Option(help: "New title.")
        var title: String?

        @Option(help: "New symbol.")
        var symbol: String?

        @Option(help: "New description.")
        var description: String?

        @Option(help: "New location (UUID or name).")
        var location: String?

        @Option(help: "New start time (24-hour HH:MM).")
        var start: String?

        @Option(help: "New end time (24-hour HH:MM).")
        var end: String?

        @Flag(name: .customLong("all-day"), help: "Make this an all-day shift type.")
        var allDay = false

        @OptionGroup var options: GlobalOptions

        func validate() throws {
            if allDay, start != nil || end != nil {
                throw ValidationError("--all-day cannot be combined with --start/--end.")
            }
            if (start == nil) != (end == nil) {
                throw ValidationError("Provide both --start and --end to change times.")
            }
            let anyChange = title != nil || symbol != nil || description != nil
                || location != nil || start != nil || allDay
            guard anyChange else {
                throw ValidationError("Nothing to change. Provide at least one field to edit.")
            }
        }

        func run() async throws {
            try await CLIRuntime.run(json: options.json) {
                let controller = options.makeController()
                var type = try await controller.resolveShiftType(id)
                if let title { type.title = title }
                if let symbol { type.symbol = symbol }
                if let description { type.shiftDescription = description }
                if let location {
                    type.location = try await controller.resolveLocation(location)
                }
                if allDay {
                    type.duration = .allDay
                } else if let start, let end {
                    type.duration = .scheduled(
                        from: try DateParsing.parseTime(start),
                        to: try DateParsing.parseTime(end)
                    )
                }
                let cascadedEvents = try await controller.saveShiftTypeCascading(type)
                if options.json {
                    try OutputFormatter.printJSON(ShiftTypeDTO(type))
                } else {
                    print("Updated shift type '\(type.symbol): \(type.title)'.")
                    if cascadedEvents > 0 {
                        print("Updated \(cascadedEvents) calendar event(s) to match.")
                    }
                }
            }
        }
    }

    // MARK: - delete

    struct Delete: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "delete",
            abstract: "Delete a shift type.",
            discussion: """
                Calendar events already scheduled with this type keep their event but
                will show as '(unknown type)' in listings.

                EXAMPLES:
                  shift-scheduler types delete --id "Day Shift"
                  shift-scheduler types delete --id <UUID> --force
                """
        )

        @Option(help: "Shift type to delete (UUID, title, or symbol).")
        var id: String

        @Flag(help: "Skip the confirmation prompt.")
        var force = false

        @OptionGroup var options: GlobalOptions

        func run() async throws {
            try await CLIRuntime.run(json: options.json) {
                let controller = options.makeController()
                let type = try await controller.resolveShiftType(id)
                try CLIRuntime.confirm("Delete shift type '\(type.symbol): \(type.title)'?", force: force)
                try await controller.persistence.deleteShiftType(id: type.id)
                if options.json {
                    try OutputFormatter.printJSON(ShiftTypeDTO(type))
                } else {
                    print("Deleted shift type '\(type.symbol): \(type.title)'.")
                }
            }
        }
    }
}
