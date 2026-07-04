import SwiftUI
import UniformTypeIdentifiers

struct ShiftImportView: View {
    @Environment(\.reduxStore) var store
    @Environment(\.dismiss) var dismiss
    @State private var isShowingFileImporter = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    inputSection

                    if let preview = store.state.settings.importPreview {
                        previewSection(preview: preview)
                    }

                    if let successMessage = store.state.settings.importSuccessMessage {
                        successSection(message: successMessage)
                    }

                    if let errorMessage = store.state.settings.importErrorMessage {
                        errorSection(message: errorMessage)
                    }
                }
                .padding()
            }
            .scrollDismissesKeyboard(.immediately)
            .dismissKeyboardOnTap()
            .navigationTitle("Import Shifts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $isShowingFileImporter,
                allowedContentTypes: [.plainText, .text]
            ) { result in
                Task {
                    switch result {
                    case .success(let url):
                        let didStartAccessing = url.startAccessingSecurityScopedResource()
                        defer {
                            if didStartAccessing {
                                url.stopAccessingSecurityScopedResource()
                            }
                        }
                        do {
                            let data = try Data(contentsOf: url)
                            guard let text = String(data: data, encoding: .utf8) else {
                                throw CocoaError(.fileReadInapplicableStringEncoding)
                            }
                            await store.dispatch(action: .settings(.importFileLoaded(.success(text))))
                        } catch {
                            await store.dispatch(action: .settings(.importFileLoaded(.failure(error))))
                        }
                    case .failure(let error):
                        await store.dispatch(action: .settings(.importFileLoaded(.failure(error))))
                    }
                }
            }
        }
    }

    // MARK: - Input Section

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Paste or Load Shift Data")
                .font(.title2)
                .fontWeight(.bold)

            Text("Format: a start date (yyyy-MM-dd) followed by one shift symbol per day. Use ~ or x to leave a day unscheduled.")
                .font(.caption)
                .foregroundColor(.secondary)

            TextEditor(text: Binding(
                get: { store.state.settings.importText },
                set: { newValue in
                    Task {
                        await store.dispatch(action: .settings(.importTextChanged(newValue)))
                    }
                }
            ))
            .font(.system(.body, design: .monospaced))
            .frame(height: 140)
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .overlay(
                Group {
                    if store.state.settings.importText.isEmpty {
                        VStack {
                            HStack {
                                Text("2026-12-28 x d wd e x x h dh x x x")
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.secondary.opacity(0.6))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 16)
                                Spacer()
                            }
                            Spacer()
                        }
                        .allowsHitTesting(false)
                    }
                }
            )

            HStack(spacing: 12) {
                Button(action: {
                    Task {
                        await store.dispatch(action: .settings(.pasteImportFromClipboard))
                    }
                }) {
                    HStack {
                        Image(systemName: "doc.on.clipboard")
                        Text("Paste from Clipboard")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.bordered)

                Button(action: {
                    isShowingFileImporter = true
                }) {
                    HStack {
                        Image(systemName: "doc.badge.plus")
                        Text("Import from File")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.bordered)
            }

            Button(action: {
                Task {
                    await store.dispatch(action: .settings(.validateImport))
                }
            }) {
                HStack {
                    Image(systemName: "checklist")
                    Text("Preview Import")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .disabled(store.state.settings.importText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    // MARK: - Preview Section

    private func previewSection(preview: ShiftImportPreview) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: preview.hasBlockingErrors ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                    .foregroundColor(preview.hasBlockingErrors ? .orange : .green)
                Text("Preview")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }

            Text(summaryText(for: preview))
                .font(.subheadline)
                .foregroundColor(.secondary)

            if preview.conflictCount > 0 {
                conflictPolicyPicker
            }

            VStack(spacing: 0) {
                ForEach(Array(preview.days.enumerated()), id: \.offset) { _, day in
                    dayRow(day: day)
                    Divider()
                }
            }
            .background(Color(.systemGray6))
            .cornerRadius(8)

            Button(action: {
                Task {
                    await store.dispatch(action: .settings(.confirmImport))
                }
            }) {
                HStack {
                    if store.state.settings.isImporting {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "square.and.arrow.down")
                    }
                    Text(store.state.settings.isImporting ? "Importing..." : "Import \(preview.importableCount) Shift\(preview.importableCount == 1 ? "" : "s")")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .disabled(store.state.settings.isImporting || preview.hasBlockingErrors || preview.importableCount == 0)
        }
    }

    private var conflictPolicyPicker: some View {
        Picker("Conflict Handling", selection: Binding(
            get: { store.state.settings.importConflictPolicy },
            set: { newValue in
                Task {
                    await store.dispatch(action: .settings(.importConflictPolicyChanged(newValue)))
                }
            }
        )) {
            Text("Skip conflicting days").tag(ImportConflictPolicy.skipConflicts)
            Text("Cancel if conflicts").tag(ImportConflictPolicy.abortOnConflict)
        }
        .pickerStyle(.segmented)
    }

    private func summaryText(for preview: ShiftImportPreview) -> String {
        var parts: [String] = ["\(preview.importableCount) to import"]
        let skippedCount = preview.days.filter {
            if case .skipped = $0.status { return true }
            return false
        }.count
        if skippedCount > 0 {
            parts.append("\(skippedCount) skipped")
        }
        if preview.conflictCount > 0 {
            parts.append("\(preview.conflictCount) conflict\(preview.conflictCount == 1 ? "" : "s")")
        }
        let unknownCount = preview.days.filter {
            if case .unknownSymbol = $0.status { return true }
            return false
        }.count
        if unknownCount > 0 {
            parts.append("\(unknownCount) unknown symbol\(unknownCount == 1 ? "" : "s")")
        }
        return parts.joined(separator: " · ")
    }

    private func dayRow(day: ShiftImportPreview.Day) -> some View {
        HStack {
            Text(day.date.formatted(date: .abbreviated, time: .omitted))
                .font(.subheadline)
                .frame(width: 100, alignment: .leading)

            Text(day.symbol)
                .font(.system(.subheadline, design: .monospaced))
                .frame(width: 40, alignment: .leading)

            statusView(for: day.status)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private func statusView(for status: ShiftImportPreview.DayStatus) -> some View {
        switch status {
        case .willImport(let shiftType):
            Text(shiftType.title)
                .font(.subheadline)
                .foregroundColor(.primary)
        case .skipped:
            Text("Skipped")
                .font(.subheadline)
                .foregroundColor(.secondary)
        case .unknownSymbol(let symbol):
            Text("Unknown symbol \"\(symbol)\"")
                .font(.subheadline)
                .foregroundColor(.orange)
        case .conflict(let shiftType, _):
            Text("Conflict (would be \(shiftType.title))")
                .font(.subheadline)
                .foregroundColor(.red)
        }
    }

    // MARK: - Success Section

    private func successSection(message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGreen).opacity(0.1))
        )
    }

    // MARK: - Error Section

    private func errorSection(message: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Error")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }

            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemOrange).opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange, lineWidth: 1)
        )
    }
}

#Preview {
    ShiftImportView()
}
