import Foundation
import ArgumentParser

struct ScheduleCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "schedule",
        abstract: "View and modify scheduled shifts in the calendar.",
        subcommands: [List.self, Add.self, Edit.self, Delete.self, Switch.self],
        defaultSubcommand: List.self
    )

    // MARK: - list

    struct List: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "list",
            abstract: "List scheduled shifts (defaults to the current month).",
            discussion: """
                Dates accept YYYY-MM-DD, today, tomorrow, yesterday, +3d, -1w.
                --to is inclusive.

                EXAMPLES:
                  shift-scheduler schedule list
                  shift-scheduler schedule list --from today --to +14d
                  shift-scheduler schedule list --from 2026-07-01 --to 2026-07-31 --json
                """
        )

        @Option(help: "Start date of the range.")
        var from: String?

        @Option(help: "End date of the range (inclusive).")
        var to: String?

        @OptionGroup var options: GlobalOptions

        func run() async throws {
            try await CLIRuntime.run(json: options.json) {
                let controller = options.makeController()

                let today = controller.currentDay.getTodayDate()
                let startDate = try from.map { try DateParsing.parseDate($0) }
                    ?? controller.currentDay.getStartOfMonth(for: today)
                let endInclusive = try to.map { try DateParsing.parseDate($0) }
                    ?? controller.currentDay.getEndOfMonth(for: today)
                guard endInclusive >= startDate else {
                    throw CLIError.invalidOperation("--to (\(OutputFormatter.dayString(endInclusive))) is before --from (\(OutputFormatter.dayString(startDate)))")
                }
                try await controller.requireCalendarAuthorization()
                let endExclusive = Calendar.current.date(byAdding: .day, value: 1, to: endInclusive) ?? endInclusive

                let shifts = try await controller.calendar.loadShifts(from: startDate, to: endExclusive)
                if options.json {
                    try OutputFormatter.printJSON(shifts.map(ShiftDTO.init))
                } else if shifts.isEmpty {
                    print("No shifts between \(OutputFormatter.dayString(startDate)) and \(OutputFormatter.dayString(endInclusive)).")
                } else {
                    print(OutputFormatter.shiftTable(shifts))
                }
            }
        }
    }

    // MARK: - add

    struct Add: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "add",
            abstract: "Add a shift to the calendar and record it in the change log.",
            discussion: """
                EXAMPLES:
                  shift-scheduler schedule add --date tomorrow --type "Day Shift"
                  shift-scheduler schedule add --date 2026-07-15 --type D --notes "Covering for Sam"
                """
        )

        @Option(help: "Date of the shift (YYYY-MM-DD, today, tomorrow, +3d, ...).")
        var date: String

        @Option(help: "Shift type to schedule (UUID, title, or symbol).")
        var type: String

        @Option(help: "Optional notes to attach to the shift.")
        var notes: String?

        @OptionGroup var options: GlobalOptions

        func run() async throws {
            try await CLIRuntime.run(json: options.json) {
                let controller = options.makeController()
                let shiftDate = try DateParsing.parseDate(date)
                let shift = try await controller.addShift(date: shiftDate, typeReference: type, notes: notes)
                if options.json {
                    try OutputFormatter.printJSON(ShiftDTO(shift))
                } else {
                    let title = shift.shiftType.map { "\($0.symbol): \($0.title)" } ?? "shift"
                    print("Added \(title) on \(OutputFormatter.dayString(shift.date)).")
                    print("Event ID: \(shift.eventIdentifier)")
                }
            }
        }
    }

    // MARK: - edit

    struct Edit: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "edit",
            abstract: "Edit a scheduled shift's notes.",
            discussion: """
                Replaces the shift's notes. Pass an empty string to clear them.
                To change the shift type, use 'schedule switch'.

                EXAMPLES:
                  shift-scheduler schedule edit --event-id <ID> --notes "Trade with Alex"
                  shift-scheduler schedule edit --event-id <ID> --notes ""
                """
        )

        @Option(name: .customLong("event-id"), help: "EventKit event identifier of the shift (see 'schedule list').")
        var eventId: String

        @Option(help: "New notes for the shift (replaces existing notes; empty string clears).")
        var notes: String

        @OptionGroup var options: GlobalOptions

        func run() async throws {
            try await CLIRuntime.run(json: options.json) {
                let controller = options.makeController()
                try await controller.updateShiftNotes(eventIdentifier: eventId, notes: notes)
                if options.json {
                    try OutputFormatter.printJSON(["eventId": eventId, "notes": notes])
                } else {
                    print(notes.isEmpty ? "Cleared notes." : "Updated notes.")
                }
            }
        }
    }

    // MARK: - delete

    struct Delete: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "delete",
            abstract: "Delete a shift from the calendar and record it in the change log.",
            discussion: """
                Prompts for confirmation; pass --force to skip (required when no
                interactive terminal is available).

                EXAMPLES:
                  shift-scheduler schedule delete --event-id <ID>
                  shift-scheduler schedule delete --event-id <ID> --force --reason "Shift cancelled"
                """
        )

        @Option(name: .customLong("event-id"), help: "EventKit event identifier of the shift (see 'schedule list').")
        var eventId: String

        @Option(help: "Optional reason recorded in the change log.")
        var reason: String?

        @Flag(help: "Skip the confirmation prompt.")
        var force = false

        @OptionGroup var options: GlobalOptions

        func run() async throws {
            try await CLIRuntime.run(json: options.json) {
                let controller = options.makeController()
                let shift = try await controller.findShift(eventIdentifier: eventId)
                let title = shift.shiftType.map { "\($0.symbol): \($0.title)" } ?? "shift"
                try CLIRuntime.confirm(
                    "Delete \(title) on \(OutputFormatter.dayString(shift.date))?",
                    force: force
                )
                let deleted = try await controller.deleteShift(eventIdentifier: eventId, reason: reason)
                if options.json {
                    try OutputFormatter.printJSON(ShiftDTO(deleted))
                } else {
                    print("Deleted \(title) on \(OutputFormatter.dayString(deleted.date)).")
                }
            }
        }
    }

    // MARK: - switch

    struct Switch: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "switch",
            abstract: "Switch a scheduled shift to a different shift type.",
            discussion: """
                Records the switch in the change log with before/after snapshots,
                so it can be undone with 'shift-scheduler undo'.

                EXAMPLES:
                  shift-scheduler schedule switch --event-id <ID> --to "Night Shift"
                  shift-scheduler schedule switch --event-id <ID> --to N --reason "Traded with Alex"
                """
        )

        @Option(name: .customLong("event-id"), help: "EventKit event identifier of the shift (see 'schedule list').")
        var eventId: String

        @Option(help: "New shift type (UUID, title, or symbol).")
        var to: String

        @Option(help: "Optional reason recorded in the change log.")
        var reason: String?

        @OptionGroup var options: GlobalOptions

        func run() async throws {
            try await CLIRuntime.run(json: options.json) {
                let controller = options.makeController()
                let (shift, newType) = try await controller.switchShift(
                    eventIdentifier: eventId,
                    toTypeReference: to,
                    reason: reason
                )
                if options.json {
                    let updated = try await controller.findShift(eventIdentifier: eventId)
                    try OutputFormatter.printJSON(ShiftDTO(updated))
                } else {
                    let fromTitle = shift.shiftType.map { "\($0.symbol): \($0.title)" } ?? "(unknown)"
                    print("Switched \(fromTitle) -> \(newType.symbol): \(newType.title) on \(OutputFormatter.dayString(shift.date)).")
                }
            }
        }
    }
}
