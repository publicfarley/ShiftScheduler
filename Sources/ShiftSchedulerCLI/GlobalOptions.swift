import Foundation
import ArgumentParser

/// Options shared by every leaf command.
struct GlobalOptions: ParsableArguments {
    @Flag(help: "Output machine-readable JSON instead of human-readable text.")
    var json = false

    @Option(
        name: .customLong("data-dir"),
        help: "Override the data directory (default: ~/Documents/ShiftSchedulerData).",
        completion: .directory
    )
    var dataDir: String?

    var dataDirectoryURL: URL? {
        dataDir.map { URL(fileURLWithPath: ($0 as NSString).expandingTildeInPath, isDirectory: true) }
    }

    func makeController() -> CLIController {
        CLIController(dataDirectory: dataDirectoryURL)
    }
}

/// Shared runtime helpers: error reporting that respects --json, and
/// confirmation prompts that never hang in non-interactive contexts.
enum CLIRuntime {
    /// Runs a command body, converting thrown errors into JSON- or human-readable
    /// output on stderr and a non-zero exit code.
    static func run(json: Bool, _ body: () async throws -> Void) async throws {
        do {
            try await body()
        } catch let exit as ExitCode {
            throw exit
        } catch {
            emit(error, json: json)
            throw ExitCode.failure
        }
    }

    /// Asks for confirmation before a destructive operation.
    /// --force skips the prompt. Without a TTY the prompt cannot be shown, so the
    /// command fails with a clear message instead of hanging (important for
    /// scripts and agents).
    static func confirm(_ action: String, force: Bool) throws {
        if force { return }
        guard isatty(fileno(stdin)) != 0 else {
            throw CLIError.confirmationRequired(action)
        }
        print("\(action) [y/N]: ", terminator: "")
        let answer = readLine()?.trimmingCharacters(in: .whitespaces).lowercased() ?? ""
        guard answer == "y" || answer == "yes" else {
            throw CLIError.cancelled
        }
    }

    private static func emit(_ error: Error, json: Bool) {
        let (message, suggestion) = describe(error)
        var text: String
        if json {
            var payload: [String: String] = ["message": message]
            if let suggestion { payload["suggestion"] = suggestion }
            let object = ["error": payload]
            if let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]),
               let encoded = String(data: data, encoding: .utf8) {
                text = encoded + "\n"
            } else {
                text = "{\"error\":{\"message\":\"\(message)\"}}\n"
            }
        } else {
            text = "Error: \(message)\n"
            if let suggestion { text += "\(suggestion)\n" }
        }
        FileHandle.standardError.write(Data(text.utf8))
    }

    private static func describe(_ error: Error) -> (message: String, suggestion: String?) {
        if let cliError = error as? CLIError {
            return (cliError.message, cliError.suggestion)
        }
        if let localized = error as? LocalizedError, let description = localized.errorDescription {
            return (description, localized.recoverySuggestion)
        }
        return (String(describing: error), nil)
    }
}
