import SwiftUI

struct AddEditLocationView: View {
    @Environment(\.reduxStore) var store
    @Binding var isPresented: Bool

    let location: Location?

    @State private var name: String = ""
    @State private var address: String = ""
    @State private var showError = false

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !address.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var title: String {
        location != nil ? "Edit Location" : "Add Location"
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Location Details") {
                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.words)
                }

                Section("Address") {
                    TextEditor(text: $address)
                        .frame(height: 90) // Approximately 3 lines of text
                        .textInputAutocapitalization(.sentences)
                        .lineLimit(3...)
                        .scrollContentBackground(.hidden)
                }

                if let error = store.state.locations.errorMessage {
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
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        Task {
                            await store.dispatch(action: .locations(.addEditSheetDismissed))
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveLocation()
                    }
                    .disabled(!isValid || store.state.locations.isLoading)
                }
            }
            .onAppear {
                if let location = location {
                    name = location.name
                    address = location.address
                }
            }
            .dismissKeyboardOnTap()
            .interactiveDismissDisabled(false)
        }
    }

    private func saveLocation() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedAddress = address.trimmingCharacters(in: .whitespaces)

        guard !trimmedName.isEmpty, !trimmedAddress.isEmpty else {
            showError = true
            return
        }

        let newLocation = Location(
            id: location?.id ?? UUID(),
            name: trimmedName,
            address: trimmedAddress
        )

        Task {
            await store.dispatch(action: .locations(.saveLocation(newLocation)))
        }
    }
}

#Preview {
    AddEditLocationView(isPresented: .constant(true), location: nil)
}
