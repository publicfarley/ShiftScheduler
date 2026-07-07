import Foundation
import ArgumentParser

struct UndoCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "undo",
        abstract: "Undo the most recent schedule change (add, delete, or switch).",
        discussion: """
            EXAMPLES:
              shift-scheduler undo
              shift-scheduler undo --json
            """
    )

    @OptionGroup var options: GlobalOptions

    func run() async throws {
        try await CLIRuntime.run(json: options.json) {
            let controller = options.makeController()
            let entry = try await controller.undo()
            if options.json {
                try OutputFormatter.printJSON(ChangeLogEntryDTO(entry))
            } else {
                print("Undid '\(entry.changeType.rawValue)' on \(OutputFormatter.dayString(entry.scheduledShiftDate)).")
            }
        }
    }
}

struct RedoCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "redo",
        abstract: "Re-apply the most recently undone schedule change.",
        discussion: """
            EXAMPLES:
              shift-scheduler redo
              shift-scheduler redo --json
            """
    )

    @OptionGroup var options: GlobalOptions

    func run() async throws {
        try await CLIRuntime.run(json: options.json) {
            let controller = options.makeController()
            let entry = try await controller.redo()
            if options.json {
                try OutputFormatter.printJSON(ChangeLogEntryDTO(entry))
            } else {
                print("Redid '\(entry.changeType.rawValue)' on \(OutputFormatter.dayString(entry.scheduledShiftDate)).")
            }
        }
    }
}
