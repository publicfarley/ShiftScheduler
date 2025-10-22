import SwiftUI
import ComposableArchitecture

struct AddEditShiftTypeView: View {
    @Bindable var store: StoreOf<AddEditShiftTypeFeature>

    @State private var locations: [Location] = []
    @State private var selectedLocation: Location?
    @State private var showingAddLocation = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if let errorMessage = store.validationErrors.first {
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .font(.subheadline)
                            Spacer()
                        }
                        .padding(12)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .padding()
                }

                ScrollView {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("BASIC INFORMATION")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fontWeight(.medium)

                            VStack(spacing: 0) {
                                // Symbol Field
                                VStack(spacing: 0) {
                                    HStack {
                                        Text("Symbol")
                                            .foregroundColor(.primary)
                                        Spacer()
                                        TextField("e.g., M, E, N", text: $store.symbol)
                                            .textInputAutocapitalization(.characters)
                                            .multilineTextAlignment(.trailing)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 12)

                                    Divider()

                                    // Title Field
                                    HStack {
                                        Text("Title")
                                            .foregroundColor(.primary)
                                        Spacer()
                                        TextField("Shift title", text: $store.title)
                                            .multilineTextAlignment(.trailing)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 12)

                                    Divider()

                                    // Description Field
                                    HStack {
                                        Text("Description")
                                            .foregroundColor(.primary)
                                        Spacer()
                                        TextField("Optional description", text: $store.shiftDescription)
                                            .multilineTextAlignment(.trailing)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 12)
                                }
                                .padding(.horizontal, 12)
                                .background(Color(.systemBackground))
                                .cornerRadius(10)
                            }
                        }

                        VStack(alignment: .leading, spacing: 16) {
                            Text("TIME SETTINGS")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fontWeight(.medium)

                            VStack(spacing: 0) {
                                // Start Time
                                HStack {
                                    Text("Start Time")
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text(store.startTime?.timeString ?? "Select time")
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 12)

                                Divider()
                                    .padding(.horizontal, 12)

                                // End Time
                                HStack {
                                    Text("End Time")
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text(store.endTime?.timeString ?? "Select time")
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 12)
                            }
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                        }

                        VStack(alignment: .leading, spacing: 16) {
                            Text("LOCATION")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fontWeight(.medium)

                            VStack(spacing: 0) {
                                HStack {
                                    Text("Location")
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text(store.location.name)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 12)
                            }
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                        }
                    }
                    .padding()
                }
                .scrollDismissesKeyboard(.immediately)

                // Action Buttons
                HStack(spacing: 12) {
                    Button("Cancel") {
                        store.send(.cancelButtonTapped)
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(10)

                    Button(action: {
                        store.send(.saveButtonTapped)
                    }) {
                        if store.isSaving {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Save")
                                .fontWeight(.semibold)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .disabled(store.isSaving)
                }
                .padding()
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .dismissKeyboardOnTap()
        }
    }

    private var navigationTitle: String {
        switch store.mode {
        case .add:
            return "New Shift Type"
        case .edit:
            return "Edit Shift Type"
        }
    }
}
#Preview {
    AddEditShiftTypeView(
        store: Store(
            initialState: AddEditShiftTypeFeature.State(
                mode: .add(Location(id: UUID(), name: "Main Office", address: "123 Main St"))
            ),
            reducer: {
                AddEditShiftTypeFeature()
            }
        )
    )
}
