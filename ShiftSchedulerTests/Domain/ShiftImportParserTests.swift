import Testing
import Foundation
@testable import ShiftScheduler

@MainActor
struct ShiftImportParserTests {

    private static func date(_ year: Int, _ month: Int, _ day: Int) throws -> Date {
        try #require(Calendar.current.date(from: DateComponents(year: year, month: month, day: day)))
    }

    @Test("Parses the sample line into 11 consecutive dates with year rollover")
    func testSampleLineParsesConsecutiveDates() async throws {
        let text = "2026-12-28 x d wd e x x h dh x x x"
        let entries = try ShiftImportParser.parse(text)

        #expect(entries.count == 11)
        #expect(entries.first?.date == (try Self.date(2026, 12, 28)))
        #expect(entries.last?.date == (try Self.date(2027, 1, 7)))

        let expectedSymbols = ["x", "d", "wd", "e", "x", "x", "h", "dh", "x", "x", "x"]
        #expect(entries.map { $0.symbol } == expectedSymbols)
    }

    @Test("Parses multiple lines as independent ranges")
    func testMultiLineInput() async throws {
        let text = """
        2026-01-01 a b
        2026-02-01 c d
        """
        let entries = try ShiftImportParser.parse(text)

        #expect(entries.count == 4)
        #expect(entries[0].date == (try Self.date(2026, 1, 1)))
        #expect(entries[1].date == (try Self.date(2026, 1, 2)))
        #expect(entries[2].date == (try Self.date(2026, 2, 1)))
        #expect(entries[3].date == (try Self.date(2026, 2, 2)))
    }

    @Test("Ignores blank lines and surrounding whitespace")
    func testBlankLinesIgnored() async throws {
        let text = "\n  2026-01-01 a b  \n\n\n  2026-02-01 c  \n"
        let entries = try ShiftImportParser.parse(text)

        #expect(entries.count == 3)
    }

    @Test("Skip tokens ~, x, and X are preserved but do not require catalog resolution")
    func testSkipTokensRecognized() async throws {
        #expect(ShiftImportParser.isSkipToken("~"))
        #expect(ShiftImportParser.isSkipToken("x"))
        #expect(ShiftImportParser.isSkipToken("X"))
        #expect(!ShiftImportParser.isSkipToken("wd"))

        let entries = try ShiftImportParser.parse("2026-01-01 ~ x X wd")
        #expect(entries.map { $0.symbol } == ["~", "x", "X", "wd"])
    }

    @Test("Throws for an invalid date token")
    func testInvalidDateToken() async throws {
        #expect(throws: ShiftImportParser.ParseError.invalidDate(line: 1, token: "not-a-date")) {
            try ShiftImportParser.parse("not-a-date a b")
        }
    }

    @Test("Throws when a line has a date but no symbols")
    func testMissingSymbols() async throws {
        #expect(throws: ShiftImportParser.ParseError.noSymbols(line: 1)) {
            try ShiftImportParser.parse("2026-01-01")
        }
    }

    @Test("Throws when two lines assign the same day")
    func testDuplicateDayAcrossLines() async throws {
        let text = """
        2026-01-01 a b
        2026-01-02 c d
        """
        #expect(throws: ShiftImportParser.ParseError.overlappingRanges(date: try Self.date(2026, 1, 2))) {
            try ShiftImportParser.parse(text)
        }
    }

    @Test("Throws for empty input")
    func testEmptyInput() async throws {
        #expect(throws: ShiftImportParser.ParseError.emptyInput) {
            try ShiftImportParser.parse("   \n  \n")
        }
    }

    @Test("Second line invalid date reports correct line number")
    func testInvalidDateReportsLineNumber() async throws {
        let text = """
        2026-01-01 a
        bad-date b
        """
        #expect(throws: ShiftImportParser.ParseError.invalidDate(line: 2, token: "bad-date")) {
            try ShiftImportParser.parse(text)
        }
    }
}
