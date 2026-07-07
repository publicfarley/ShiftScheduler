import Foundation
import ArgumentParser

struct TodayCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "today",
        abstract: "Show today's scheduled shifts.",
        discussion: """
            EXAMPLES:
              shift-scheduler today
              shift-scheduler today --json
            """
    )

    @OptionGroup var options: GlobalOptions

    func run() async throws {
        try await CLIRuntime.run(json: options.json) {
            let controller = options.makeController()
            try await controller.requireCalendarAuthorization()
            let today = controller.currentDay.getTodayDate()
            let tomorrow = controller.currentDay.getTomorrowDate()
            let shifts = try await controller.calendar.loadShifts(from: today, to: tomorrow)
            if options.json {
                try OutputFormatter.printJSON(shifts.map(ShiftDTO.init))
            } else if shifts.isEmpty {
                print("No shifts scheduled for today (\(OutputFormatter.dayString(today))).")
            } else {
                print(OutputFormatter.shiftTable(shifts))
            }
        }
    }
}
