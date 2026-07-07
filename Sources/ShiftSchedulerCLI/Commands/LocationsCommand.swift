import Foundation
import ArgumentParser

struct LocationsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "locations",
        abstract: "Manage locations where shifts occur.",
        subcommands: [List.self, Add.self, Edit.self, Delete.self],
        defaultSubcommand: List.self
    )

    // MARK: - list

    struct List: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "list",
            abstract: "List all locations.",
            discussion: """
                EXAMPLES:
                  shift-scheduler locations list
                  shift-scheduler locations list --json
                """
        )

        @OptionGroup var options: GlobalOptions

        func run() async throws {
            try await CLIRuntime.run(json: options.json) {
                let controller = options.makeController()
                let locations = try await controller.persistence.loadLocations()
                if options.json {
                    try OutputFormatter.printJSON(locations.map(LocationDTO.init))
                } else if locations.isEmpty {
                    print("No locations defined. Add one with 'shift-scheduler locations add'.")
                } else {
                    print(OutputFormatter.locationTable(locations))
                }
            }
        }
    }

    // MARK: - add

    struct Add: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "add",
            abstract: "Create a new location.",
            discussion: """
                EXAMPLES:
                  shift-scheduler locations add --name "Downtown" --address "123 Main St"
                """
        )

        @Option(help: "Name of the location.")
        var name: String

        @Option(help: "Street address of the location.")
        var address: String

        @OptionGroup var options: GlobalOptions

        func run() async throws {
            try await CLIRuntime.run(json: options.json) {
                let controller = options.makeController()
                let location = Location(name: name, address: address)
                try await controller.persistence.saveLocation(location)
                if options.json {
                    try OutputFormatter.printJSON(LocationDTO(location))
                } else {
                    print("Added location '\(location.name)'.")
                    print("ID: \(location.id.uuidString)")
                }
            }
        }
    }

    // MARK: - edit

    struct Edit: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "edit",
            abstract: "Edit an existing location.",
            discussion: """
                Shift types referencing this location are updated automatically, and
                existing calendar events are updated when calendar access is authorized.

                EXAMPLES:
                  shift-scheduler locations edit --id "Downtown" --address "456 Oak Ave"
                """
        )

        @Option(help: "Location to edit (UUID or name).")
        var id: String

        @Option(help: "New name.")
        var name: String?

        @Option(help: "New address.")
        var address: String?

        @OptionGroup var options: GlobalOptions

        func validate() throws {
            guard name != nil || address != nil else {
                throw ValidationError("Nothing to change. Provide --name and/or --address.")
            }
        }

        func run() async throws {
            try await CLIRuntime.run(json: options.json) {
                let controller = options.makeController()
                let result = try await controller.editLocation(id, name: name, address: address)
                if options.json {
                    try OutputFormatter.printJSON(LocationDTO(result.location))
                } else {
                    print("Updated location '\(result.location.name)'.")
                    if result.cascadedTypes > 0 {
                        print("Updated \(result.cascadedTypes) shift type(s) referencing it.")
                    }
                    if result.cascadedEvents > 0 {
                        print("Updated \(result.cascadedEvents) calendar event(s) to match.")
                    }
                }
            }
        }
    }

    // MARK: - delete

    struct Delete: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "delete",
            abstract: "Delete a location.",
            discussion: """
                Fails if any shift type still references the location.

                EXAMPLES:
                  shift-scheduler locations delete --id "Downtown"
                  shift-scheduler locations delete --id <UUID> --force
                """
        )

        @Option(help: "Location to delete (UUID or name).")
        var id: String

        @Flag(help: "Skip the confirmation prompt.")
        var force = false

        @OptionGroup var options: GlobalOptions

        func run() async throws {
            try await CLIRuntime.run(json: options.json) {
                let controller = options.makeController()
                let location = try await controller.resolveLocation(id)
                try CLIRuntime.confirm("Delete location '\(location.name)'?", force: force)
                let deleted = try await controller.deleteLocation(id)
                if options.json {
                    try OutputFormatter.printJSON(LocationDTO(deleted))
                } else {
                    print("Deleted location '\(deleted.name)'.")
                }
            }
        }
    }
}
