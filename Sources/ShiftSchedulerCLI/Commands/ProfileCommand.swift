import Foundation
import ArgumentParser

struct ProfileCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "profile",
        abstract: "View or update the user profile.",
        subcommands: [Show.self, Set.self],
        defaultSubcommand: Show.self
    )

    // MARK: - show

    struct Show: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "show",
            abstract: "Show the current user profile.",
            discussion: """
                EXAMPLES:
                  shift-scheduler profile show
                  shift-scheduler profile show --json
                """
        )

        @OptionGroup var options: GlobalOptions

        func run() async throws {
            try await CLIRuntime.run(json: options.json) {
                let controller = options.makeController()
                let profile = try await controller.persistence.loadUserProfile()
                if options.json {
                    try OutputFormatter.printJSON(ProfileDTO(profile))
                } else {
                    print("Display name:      \(profile.displayName.isEmpty ? "(not set)" : profile.displayName)")
                    print("Retention policy:  \(profile.retentionPolicy.displayName)")
                    print("Auto-purge:        \(profile.autoPurgeEnabled ? "enabled" : "disabled")")
                    if let lastPurge = profile.lastPurgeDate {
                        print("Last purge:        \(OutputFormatter.iso8601.string(from: lastPurge))")
                    }
                }
            }
        }
    }

    // MARK: - set

    struct Set: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "set",
            abstract: "Update profile fields.",
            discussion: """
                Retention policies: \(ChangeLogRetentionPolicy.allCases.map(\.rawValue).joined(separator: ", "))

                EXAMPLES:
                  shift-scheduler profile set --name "Alex"
                  shift-scheduler profile set --retention 90_days --auto-purge true
                """
        )

        @Option(help: "New display name.")
        var name: String?

        @Option(help: "Change log retention policy.")
        var retention: String?

        @Option(name: .customLong("auto-purge"), help: "Enable or disable automatic purging (true/false).")
        var autoPurge: Bool?

        @OptionGroup var options: GlobalOptions

        func validate() throws {
            guard name != nil || retention != nil || autoPurge != nil else {
                throw ValidationError("Nothing to change. Provide --name, --retention, and/or --auto-purge.")
            }
            if let retention, ChangeLogRetentionPolicy(rawValue: retention) == nil {
                let valid = ChangeLogRetentionPolicy.allCases.map(\.rawValue).joined(separator: ", ")
                throw ValidationError("Unknown retention policy '\(retention)'. Valid values: \(valid).")
            }
        }

        func run() async throws {
            try await CLIRuntime.run(json: options.json) {
                let controller = options.makeController()
                var profile = try await controller.persistence.loadUserProfile()
                if let name { profile.displayName = name }
                if let retention, let policy = ChangeLogRetentionPolicy(rawValue: retention) {
                    profile.retentionPolicy = policy
                }
                if let autoPurge { profile.autoPurgeEnabled = autoPurge }
                try await controller.persistence.saveUserProfile(profile)
                if options.json {
                    try OutputFormatter.printJSON(ProfileDTO(profile))
                } else {
                    print("Profile updated.")
                }
            }
        }
    }
}
