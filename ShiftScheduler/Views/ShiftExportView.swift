import SwiftUI

struct ShiftExportView: View {
    @Environment(\.reduxStore) var store
    @Environment(\.dismiss) var dismiss
    @State private var startDate = Date()
    @State private var endDate = Date()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Date Selection Section
                    dateSelectionSection

                    // MARK: - Generate Button
                    if store.state.settings.exportedSymbols == nil {
                        generateButton
                    }

                    // MARK: - Export Output Section
                    if let symbols = store.state.settings.exportedSymbols {
                        exportOutputSection(symbols: symbols)
                    }

                    // MARK: - Error Message
                    if let errorMessage = store.state.settings.exportErrorMessage {
                        errorSection(message: errorMessage)
                    }
                }
                .padding()
            }
            .scrollDismissesKeyboard(.immediately)
            .dismissKeyboardOnTap()
            .navigationTitle("Export Shifts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Initialize dates from state if available
                if let stateStartDate = store.state.settings.exportStartDate {
                    startDate = stateStartDate
                }
                if let stateEndDate = store.state.settings.exportEndDate {
                    endDate = stateEndDate
                }
            }
        }
    }

    // MARK: - Date Selection Section

    private var dateSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select Date Range")
                .font(.title2)
                .fontWeight(.bold)

            VStack(spacing: 16) {
                // Start Date Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Start Date")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    DatePicker(
                        "Start Date",
                        selection: $startDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .onChange(of: startDate) { _, newValue in
                        Task {
                            await store.dispatch(action: .settings(.exportStartDateChanged(newValue)))
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(8)

                // End Date Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("End Date")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    DatePicker(
                        "End Date",
                        selection: $endDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .onChange(of: endDate) { _, newValue in
                        Task {
                            await store.dispatch(action: .settings(.exportEndDateChanged(newValue)))
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }

            Text("Export will include shift type symbols for each day in the selected range, separated by spaces.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
        }
    }

    // MARK: - Generate Button

    private var generateButton: some View {
        Button(action: {
            Task {
                await store.dispatch(action: .settings(.generateExport))
            }
        }) {
            HStack {
                if store.state.settings.isExporting {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "square.and.arrow.down")
                }
                Text(store.state.settings.isExporting ? "Generating..." : "Generate Export")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
        .tint(.blue)
        .disabled(store.state.settings.isExporting)
    }

    // MARK: - Export Output Section

    private func exportOutputSection(symbols: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Export Generated")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }

            // Output Display
            VStack(alignment: .leading, spacing: 8) {
                Text("Shift Symbols")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                ScrollView(.horizontal, showsIndicators: true) {
                    Text(symbols)
                        .font(.system(.body, design: .monospaced))
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 100)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }

            // Copy Button
            Button(action: {
                Task {
                    await store.dispatch(action: .settings(.copyToClipboard))
                }
            }) {
                HStack {
                    Image(systemName: "doc.on.doc")
                    Text("Copy to Clipboard")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
            .tint(.blue)

            // New Export Button
            Button(action: {
                Task {
                    await store.dispatch(action: .settings(.resetExport))
                }
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("New Export")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
            .tint(.gray)
        }
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
    ShiftExportView()
}
