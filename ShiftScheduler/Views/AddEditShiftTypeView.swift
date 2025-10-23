import SwiftUI

struct AddEditShiftTypeView: View {
    @Environment(\.reduxStore) var store
    @Binding var isPresented: Bool

    let shiftType: ShiftType?

    @State private var title: String = ""
    @State private var symbol: String = ""
    @State private var startTime: Date = Date()
    @State private var endTime: Date = Date()
    @State private var showError = false

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !symbol.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var formTitle: String {
        shiftType != nil ? "Edit Shift Type" : "Add Shift Type"
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Shift Details") {
                    TextField("Title", text: $title)
                        .textInputAutocapitalization(.words)

                    TextField("Symbol", text: $symbol)
                        .textInputAutocapitalization(.characters)
                }

                Section("Time Range") {
                    DatePicker(
                        "Start Time",
                        selection: $startTime,
                        displayedComponents: .hourAndMinute
                    )

                    DatePicker(
                        "End Time",
                        selection: $endTime,
                        displayedComponents: .hourAndMinute
                    )
                }

                if let error = store.state.shiftTypes.errorMessage {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.red)
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        .padding()
                        .background(Color(.systemRed).opacity(0.1))
                    }
                }
            }
            .navigationTitle(formTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        store.dispatch(action: .shiftTypes(.addEditSheetDismissed))
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveShiftType()
                    }
                    .disabled(!isValid || store.state.shiftTypes.isLoading)
                }
            }
            .onAppear {
                if let shiftType = shiftType {
                    title = shiftType.title
                    symbol = shiftType.symbol
                    // Parse times from the shift type
                    if case .scheduled(let from, let to) = shiftType.duration {
                        startTime = from.toDate()
                        endTime = to.toDate()
                    }
                }
            }
            .dismissKeyboardOnTap()
        }
    }

    private func saveShiftType() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        let trimmedSymbol = symbol.trimmingCharacters(in: .whitespaces)

        guard !trimmedTitle.isEmpty, !trimmedSymbol.isEmpty else {
            showError = true
            return
        }

        let startTime = HourMinuteTime(from: self.startTime)
        let endTime = HourMinuteTime(from: self.endTime)

        let newShiftType = ShiftType(
            id: shiftType?.id ?? UUID(),
            symbol: trimmedSymbol,
            duration: .scheduled(from: startTime, to: endTime),
            title: trimmedTitle,
            description: shiftType?.shiftDescription ?? "",
            location: shiftType?.location ?? Location(id: UUID(), name: "", address: "")
        )

        store.dispatch(action: .shiftTypes(.saveShiftType(newShiftType)))
    }
}

#Preview {
    AddEditShiftTypeView(isPresented: .constant(true), shiftType: nil)
}
