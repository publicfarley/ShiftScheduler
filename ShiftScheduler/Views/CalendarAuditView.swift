import SwiftUI

/// Audits the app calendar against a chosen calendar and offers to bring them in line
struct CalendarAuditView: View {
    @Environment(\.reduxStore) var store
    @Environment(\.dismiss) var dismiss
    @State private var showApplyConfirmation = false

    private var audit: CalendarAuditState { store.state.settings.calendarAudit }

    private var selectedCalendar: CalendarAudit.AuditCalendar? {
        audit.availableCalendars.first { $0.id == audit.selectedCalendarId }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    calendarSection
                    dateRangeSection
                    runButton
                    messages

                    if let report = audit.report {
                        resultsSection(report)
                    }
                }
                .padding()
            }
            .navigationTitle("Calendar Audit")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .alert("Update App Calendar?", isPresented: $showApplyConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Update") {
                    send(.applyFixes)
                }
            } message: {
                Text("This changes \(audit.selectedFixDates.count) date\(audit.selectedFixDates.count == 1 ? "" : "s") in the app calendar to match \(selectedCalendar?.title ?? "the chosen calendar"). Each change is recorded in the change log.")
            }
        }
    }

    // MARK: - Calendar Selection

    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Compare Against")
                .font(.title2)
                .fontWeight(.bold)

            if audit.isLoadingCalendars {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if audit.availableCalendars.isEmpty {
                Text("No other calendars are available.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Picker("Calendar", selection: Binding(
                    get: { audit.selectedCalendarId },
                    set: { newValue in
                        if let newValue {
                            send(.calendarSelected(newValue))
                        }
                    }
                )) {
                    Text("Choose a calendar").tag(String?.none)
                    ForEach(audit.availableCalendars) { calendar in
                        Text(calendar.sourceTitle.isEmpty ? calendar.title : "\(calendar.title) (\(calendar.sourceTitle))")
                            .tag(Optional(calendar.id))
                    }
                }
                .pickerStyle(.menu)
                .tint(.primary)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }

            Text("The shift symbol is read from each event's title: the text before the first colon, such as \u{201C}x: Off\u{201D}. An empty app day matches x, X or ~.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Date Range

    private var dateRangeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Date Range")
                .font(.title2)
                .fontWeight(.bold)

            datePicker("From", selection: Binding(
                get: { audit.startDate },
                set: { send(.startDateChanged($0)) }
            ))

            datePicker("To", selection: Binding(
                get: { audit.endDate },
                set: { send(.endDateChanged($0)) }
            ))
        }
    }

    private func datePicker(_ title: String, selection: Binding<Date>) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            Spacer()
            DatePicker(title, selection: selection, displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }

    // MARK: - Run

    private var runButton: some View {
        Button(action: {
            send(.runAudit)
        }) {
            HStack {
                if audit.isRunning {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "checklist")
                }
                Text(audit.isRunning ? "Auditing..." : "Run Audit")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
        .tint(.blue)
        .disabled(audit.selectedCalendarId == nil || audit.isRunning || audit.isApplying)
    }

    // MARK: - Messages

    @ViewBuilder
    private var messages: some View {
        if let error = audit.errorMessage {
            Label(error, systemImage: "exclamationmark.triangle.fill")
                .font(.subheadline)
                .foregroundColor(.red)
        }
        if let success = audit.successMessage {
            Label(success, systemImage: "checkmark.circle.fill")
                .font(.subheadline)
                .foregroundColor(.green)
        }
    }

    // MARK: - Results

    private func resultsSection(_ report: CalendarAudit.Report) -> some View {
        let discrepancies = report.days.filter { $0.outcome != .match }
        let matches = report.days.filter { $0.outcome == .match }

        return VStack(alignment: .leading, spacing: 16) {
            Text("Results")
                .font(.title2)
                .fontWeight(.bold)

            HStack(spacing: 16) {
                Label("\(report.matchCount) match", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Label("\(report.discrepancyCount) differ", systemImage: "exclamationmark.circle.fill")
                    .foregroundColor(report.discrepancyCount > 0 ? .orange : .secondary)
            }
            .font(.subheadline)

            if report.skippedEventCount > 0 {
                Text("\(report.skippedEventCount) event\(report.skippedEventCount == 1 ? "" : "s") on the chosen calendar had no readable symbol and \(report.skippedEventCount == 1 ? "was" : "were") skipped.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if report.days.isEmpty {
                Text("Neither calendar has entries in this range.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if !discrepancies.isEmpty {
                VStack(spacing: 8) {
                    ForEach(discrepancies) { day in
                        discrepancyRow(day)
                    }
                }

                applyButton
            }

            if !matches.isEmpty {
                DisclosureGroup("Matching days (\(matches.count))") {
                    VStack(spacing: 8) {
                        ForEach(matches) { day in
                            dayRow(day, tinted: false)
                        }
                    }
                    .padding(.top, 8)
                }
                .font(.subheadline)
            }
        }
    }

    private func discrepancyRow(_ day: CalendarAudit.Day) -> some View {
        HStack(spacing: 12) {
            if day.fix != nil {
                Button(action: {
                    send(.fixToggled(day.date))
                }) {
                    Image(systemName: audit.selectedFixDates.contains(day.date) ? "checkmark.square.fill" : "square")
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Update \(day.date.formatted(date: .abbreviated, time: .omitted))")
                .accessibilityValue(audit.selectedFixDates.contains(day.date) ? "Selected" : "Not selected")
            }
            dayRow(day, tinted: true)
        }
    }

    private func dayRow(_ day: CalendarAudit.Day, tinted: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(day.date.formatted(date: .complete, time: .omitted))
                .font(.subheadline)
                .fontWeight(.semibold)

            HStack(spacing: 6) {
                Text("App: \(day.appSymbol ?? "\u{2014}")")
                Image(systemName: "arrow.left.arrow.right")
                    .font(.caption2)
                Text("Chosen: \(day.externalSymbol ?? "\u{2014}")")
            }
            .font(.caption)
            .foregroundColor(.secondary)

            if let detail = day.detail {
                Text(detail)
                    .font(.caption)
                    .foregroundColor(day.fix != nil ? .blue : .orange)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(tinted ? Color.orange.opacity(0.12) : Color(.systemGray6))
        .cornerRadius(8)
    }

    private var applyButton: some View {
        Button(action: {
            showApplyConfirmation = true
        }) {
            HStack {
                if audit.isApplying {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }
                Text(audit.isApplying ? "Updating..." : "Update App Calendar (\(audit.selectedFixDates.count))")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
        .tint(.orange)
        .disabled(audit.selectedFixDates.isEmpty || audit.isApplying || audit.isRunning)
    }

    // MARK: - Dispatch

    private func send(_ action: CalendarAuditAction) {
        Task {
            await store.dispatch(action: .settings(.calendarAudit(action)))
        }
    }
}
