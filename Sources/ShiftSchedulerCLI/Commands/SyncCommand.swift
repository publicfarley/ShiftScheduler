import Foundation
import ArgumentParser

struct SyncCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "sync",
        abstract: "Pull shift types and locations from CloudKit.",
        discussion: """
            Fetches shift types and locations from the CloudKit public database and
            merges them into the local files. Local records are kept; CloudKit wins
            when both hold the same record. Needs a signed build and an iCloud account.

            EXAMPLES:
              shift-scheduler sync
              shift-scheduler sync --json
            """
    )

    @OptionGroup var options: GlobalOptions

    func run() async throws {
        try await CLIRuntime.run(json: options.json) {
            let controller = options.makeController()
            let counts = try await controller.syncFromCloudKit()
            if options.json {
                try OutputFormatter.printJSON(["shiftTypes": counts.shiftTypes, "locations": counts.locations])
            } else {
                print("Pulled \(counts.shiftTypes) shift types and \(counts.locations) locations from CloudKit.")
            }
        }
    }
}
