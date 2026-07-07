import Foundation
import ArgumentParser

struct AuthCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "auth",
        abstract: "Check or request calendar (EventKit) authorization.",
        subcommands: [Status.self, Request.self],
        defaultSubcommand: Status.self
    )

    struct Status: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "status",
            abstract: "Report whether calendar access is authorized."
        )

        @OptionGroup var options: GlobalOptions

        func run() async throws {
            try await CLIRuntime.run(json: options.json) {
                let controller = options.makeController()
                let authorized = try await controller.calendar.isCalendarAuthorized()
                if options.json {
                    try OutputFormatter.printJSON(["authorized": authorized])
                } else if authorized {
                    print("Calendar access: authorized")
                } else {
                    print("Calendar access: not authorized")
                    print("Run 'shift-scheduler auth request' to request access.")
                }
            }
        }
    }

    struct Request: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "request",
            abstract: "Request calendar access (shows the macOS permission dialog)."
        )

        @OptionGroup var options: GlobalOptions

        func run() async throws {
            try await CLIRuntime.run(json: options.json) {
                let controller = options.makeController()
                let granted = try await controller.calendar.requestCalendarAccess()
                if options.json {
                    try OutputFormatter.printJSON(["authorized": granted])
                } else {
                    print(granted ? "Calendar access granted." : "Calendar access denied.")
                }
                if !granted {
                    throw ExitCode.failure
                }
            }
        }
    }
}
