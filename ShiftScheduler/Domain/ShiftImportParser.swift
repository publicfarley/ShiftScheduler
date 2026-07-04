import Foundation

/// Parses shift import text of the form:
/// ```
/// 2026-12-28 x d wd e x x h dh x x x
/// ```
/// The first token on each line is an anchor date (yyyy-MM-dd). Each following
/// whitespace-separated token is a shift type symbol applied to one consecutive
/// calendar day, starting at the anchor date. This is the inverse of the
/// shift export format, which emits one symbol per day for a date range.
enum ShiftImportParser {
    struct ParsedEntry: Equatable, Sendable {
        let date: Date
        let symbol: String
    }

    enum ParseError: Error, Equatable {
        case emptyInput
        case invalidDate(line: Int, token: String)
        case noSymbols(line: Int)
        case overlappingRanges(date: Date)
    }

    /// Tokens (case-insensitive) that mean "leave this day unscheduled"
    static let skipTokens: Set<String> = ["~", "x"]

    private static func makeDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = Calendar.current.timeZone
        return formatter
    }

    static func isSkipToken(_ symbol: String) -> Bool {
        skipTokens.contains(symbol.lowercased())
    }

    static func parse(_ text: String) throws -> [ParsedEntry] {
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard !lines.isEmpty else {
            throw ParseError.emptyInput
        }

        var entries: [ParsedEntry] = []
        var seenDays: Set<Date> = []
        let calendar = Calendar.current
        let dateFormatter = makeDateFormatter()

        for (index, line) in lines.enumerated() {
            let lineNumber = index + 1
            let tokens = line.split(whereSeparator: { $0.isWhitespace }).map(String.init)

            guard let dateToken = tokens.first,
                  let anchorDate = dateFormatter.date(from: dateToken) else {
                throw ParseError.invalidDate(line: lineNumber, token: tokens.first ?? "")
            }

            let symbolTokens = Array(tokens.dropFirst())
            guard !symbolTokens.isEmpty else {
                throw ParseError.noSymbols(line: lineNumber)
            }

            let startOfAnchor = calendar.startOfDay(for: anchorDate)

            for (offset, symbol) in symbolTokens.enumerated() {
                guard let day = calendar.date(byAdding: .day, value: offset, to: startOfAnchor) else {
                    continue
                }

                guard !seenDays.contains(day) else {
                    throw ParseError.overlappingRanges(date: day)
                }
                seenDays.insert(day)

                entries.append(ParsedEntry(date: day, symbol: symbol))
            }
        }

        return entries.sorted { $0.date < $1.date }
    }
}
