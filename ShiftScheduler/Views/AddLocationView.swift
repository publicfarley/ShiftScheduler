import SwiftUI
import SwiftData

struct AddLocationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var address = ""

    private var isFormValid: Bool {
        !name.isEmpty && !address.isEmpty
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("LOCATION INFORMATION")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fontWeight(.medium)

                            VStack(spacing: 0) {
                                VStack(spacing: 0) {
                                    HStack {
                                        Text("Name")
                                            .foregroundColor(.primary)
                                        Spacer()
                                        TextField("Location name", text: $name)
                                            .multilineTextAlignment(.trailing)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 12)

                                    Divider()

                                    HStack(alignment: .top) {
                                        Text("Address")
                                            .foregroundColor(.primary)
                                        Spacer()
                                        TextField("Street address", text: $address, axis: .vertical)
                                            .multilineTextAlignment(.trailing)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1...3)
                                    }
                                    .padding(.vertical, 12)
                                }
                                .padding(.horizontal, 16)
                                .background(Color(UIColor.systemBackground))
                                .cornerRadius(10)
                            }
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("New Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        saveLocation()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }

    private func saveLocation() {
        let location = Location(name: name, address: address)
        modelContext.insert(location)
        dismiss()
    }
}

#Preview {
    AddLocationView()
        .modelContainer(for: [Location.self, ShiftType.self, ScheduledShift.self], inMemory: true)
}