import Testing
import Foundation
@testable import ShiftSchedulerCLI

@Suite("Resolution notices")
struct ResolutionNoticeTests {

    @Test("No rebuild and no skipped events gives no notices")
    func quiet() {
        #expect(OutputFormatter.resolutionNotices(rebuiltTypes: 0, skippedEvents: 0).isEmpty)
    }

    @Test("A rebuild gives one note that names the count and the local file")
    func rebuildNote() {
        let lines = OutputFormatter.resolutionNotices(rebuiltTypes: 3, skippedEvents: 0)
        #expect(lines == ["Note: rebuilt 3 shift types from calendar events (local file only)."])
    }

    @Test("One rebuilt shift type uses the singular noun")
    func rebuildSingular() {
        let lines = OutputFormatter.resolutionNotices(rebuiltTypes: 1, skippedEvents: 0)
        #expect(lines == ["Note: rebuilt 1 shift type from calendar events (local file only)."])
    }

    @Test("Skipped events give a warning that points at sync")
    func skippedWarning() {
        let lines = OutputFormatter.resolutionNotices(rebuiltTypes: 0, skippedEvents: 2)
        #expect(lines.count == 1)
        #expect(lines[0].hasPrefix("Warning: 2 calendar events were skipped"))
        #expect(lines[0].contains("shift-scheduler sync"))
    }

    @Test("One skipped event uses the singular verb")
    func skippedSingular() {
        let lines = OutputFormatter.resolutionNotices(rebuiltTypes: 0, skippedEvents: 1)
        #expect(lines[0].hasPrefix("Warning: 1 calendar event was skipped"))
    }

    @Test("A rebuild and skipped events give the note first, then the warning")
    func both() {
        let lines = OutputFormatter.resolutionNotices(rebuiltTypes: 2, skippedEvents: 1)
        #expect(lines.count == 2)
        #expect(lines[0].hasPrefix("Note:"))
        #expect(lines[1].hasPrefix("Warning:"))
    }
}
