import Foundation

/// Compares the app calendar against a user-chosen calendar, day by day.
///
/// The chosen calendar encodes a shift symbol in each event's description
/// (the text before the first `:`, e.g. `x: Off` → `x`). An empty day in the
/// app calendar is equivalent to `x`, `X` or `~` in the chosen calendar.
enum CalendarAudit {
    /// A raw event read from the chosen calendar
    struct ExternalEvent: Equatable, Sendable {
        let date: Date
        let description: String?
    }

    /// A calendar the user can pick to audit against
    struct AuditCalendar: Equatable, Sendable, Identifiable {
        let id: String
        let title: String
        let sourceTitle: String
    }

    /// The change that would bring the app calendar in line with the chosen calendar
    enum Fix: Equatable, Sendable {
        case create(ShiftType)
        case switchTo(ShiftType, from: ShiftType?, eventIdentifier: String)
        case remove(current: ShiftType?, eventIdentifier: String)
    }

    enum Outcome: Equatable, Sendable {
        case match
        case differs(Fix)
        /// App has a shift but the chosen calendar has no entry; no fix offered
        case notInExternal
        /// Chosen calendar uses a symbol with no matching shift type; no fix possible
        case unknownExternalSymbol(String)
    }

    struct Day: Equatable, Sendable, Identifiable {
        let date: Date
        /// nil when the app calendar has no shift on this day
        let appSymbol: String?
        /// nil when the chosen calendar has no entry on this day
        let externalSymbol: String?
        let outcome: Outcome

        var id: Date { date }

        var fix: Fix? {
            if case .differs(let fix) = outcome { return fix }
            return nil
        }
    }

    struct Report: Equatable, Sendable {
        /// Days where either calendar has an entry, in date order
        let days: [Day]
        /// Chosen-calendar events whose description has no readable symbol
        let skippedEventCount: Int

        var matchCount: Int {
            days.filter { $0.outcome == .match }.count
        }

        var discrepancyCount: Int {
            days.count - matchCount
        }

        var fixableDays: [Day] {
            days.filter { $0.fix != nil }
        }
    }

    /// Extracts the symbol from a description: the trimmed text before the first `:`
    ///
    /// Text containing whitespace (e.g. `Meeting with Bob: notes`) is not a symbol.
    static func symbol(fromDescription description: String?) -> String? {
        guard let description, let colon = description.firstIndex(of: ":") else {
            return nil
        }

        let symbol = description[..<colon].trimmingCharacters(in: .whitespacesAndNewlines)
        guard !symbol.isEmpty, !symbol.contains(where: \.isWhitespace) else {
            return nil
        }
        return symbol
    }

    /// Audits every day from `startDate` through `endDate` (both inclusive)
    static func audit(
        from startDate: Date,
        through endDate: Date,
        shifts: [ScheduledShift],
        externalEvents: [ExternalEvent],
        shiftTypes: [ShiftType]
    ) -> Report {
        let calendar = Calendar.current
        let first = calendar.startOfDay(for: startDate)
        let last = calendar.startOfDay(for: endDate)
        let inRange: (Date) -> Bool = { $0 >= first && $0 <= last }

        // First shift per start day; a shift is attributed to the day it starts on
        var shiftsByDay: [Date: (shift: ScheduledShift, type: ShiftType)] = [:]
        for shift in shifts.sorted(by: { $0.date < $1.date }) {
            let day = calendar.startOfDay(for: shift.date)
            guard inRange(day), let type = shift.shiftType, shiftsByDay[day] == nil else { continue }
            shiftsByDay[day] = (shift, type)
        }

        // First readable symbol per day
        var symbolsByDay: [Date: String] = [:]
        var skipped = 0
        for event in externalEvents {
            let day = calendar.startOfDay(for: event.date)
            guard inRange(day) else { continue }
            guard let symbol = symbol(fromDescription: event.description) else {
                skipped += 1
                continue
            }
            if symbolsByDay[day] == nil {
                symbolsByDay[day] = symbol
            }
        }

        let typesBySymbol = Dictionary(
            shiftTypes.map { ($0.symbol.lowercased(), $0) },
            uniquingKeysWith: { first, _ in first }
        )

        let days = Set(shiftsByDay.keys).union(symbolsByDay.keys).sorted().map { day -> Day in
            let app = shiftsByDay[day]
            let external = symbolsByDay[day]
            return Day(
                date: day,
                appSymbol: app?.type.symbol,
                externalSymbol: external,
                outcome: outcome(app: app, external: external, typesBySymbol: typesBySymbol)
            )
        }

        return Report(days: days, skippedEventCount: skipped)
    }

    private static func outcome(
        app: (shift: ScheduledShift, type: ShiftType)?,
        external: String?,
        typesBySymbol: [String: ShiftType]
    ) -> Outcome {
        guard let external else {
            return app == nil ? .match : .notInExternal
        }

        if let app, app.type.symbol.lowercased() == external.lowercased() {
            return .match
        }

        if ShiftImportParser.isSkipToken(external) {
            guard let app else { return .match }
            return .differs(.remove(current: app.type, eventIdentifier: app.shift.eventIdentifier))
        }

        guard let target = typesBySymbol[external.lowercased()] else {
            return .unknownExternalSymbol(external)
        }

        guard let app else {
            return .differs(.create(target))
        }
        return .differs(.switchTo(target, from: app.type, eventIdentifier: app.shift.eventIdentifier))
    }
}
