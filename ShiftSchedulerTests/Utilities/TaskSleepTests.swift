import Testing
import Foundation
@testable import ShiftScheduler

@Suite("Task.sleepUnlessCancelled")
struct TaskSleepTests {

    @Test("A zero-second sleep completes and reports it was not cancelled")
    func zeroSecondsCompletes() async {
        let completed = await Task.sleepUnlessCancelled(seconds: 0)
        #expect(completed)
    }

    @Test("A negative duration is treated as zero instead of trapping")
    func negativeSecondsClampsToZero() async {
        let completed = await Task.sleepUnlessCancelled(seconds: -5)
        #expect(completed)
    }

    @Test("A cancelled task reports cancellation without waiting out the duration")
    func cancelledReturnsFalse() async {
        let task = Task {
            // Long enough that only cancellation can end it within the test.
            await Task.sleepUnlessCancelled(seconds: 3600)
        }
        task.cancel()
        let completed = await task.value
        #expect(!completed)
    }
}
