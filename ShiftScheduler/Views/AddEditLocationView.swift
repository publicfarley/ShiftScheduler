import SwiftUI
import ComposableArchitecture

struct AddEditLocationView: View {
    @Bindable var store: StoreOf<AddEditLocationFeature>

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
                                        TextField("Location name", text: $store.name)
                                            .multilineTextAlignment(.leading)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 12)

                                    Divider()

                                    HStack(alignment: .top) {
                                        Text("Address")
                                            .foregroundColor(.primary)
                                        Spacer()
                                        TextField("Street address", text: $store.address, axis: .vertical)
                                            .multilineTextAlignment(.leading)
                                            .foregroundColor(.secondary)
                                            .lineLimit(4, reservesSpace: true)
                                    }
                                    .padding(.vertical, 12)
                                }
                                .padding(.horizontal, 16)
                                .background(Color(UIColor.systemBackground))
                                .cornerRadius(10)
                            }
                        }

                        if !store.validationErrors.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(store.validationErrors, id: \.self) { error in
                                    HStack(spacing: 12) {
                                        Image(systemName: "exclamationmark.circle.fill")
                                            .foregroundColor(.red)
                                        Text(error)
                                            .font(.subheadline)
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                            .padding(12)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                }
                .scrollDismissesKeyboard(.immediately)
            }
            .dismissKeyboardOnTap()
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        store.send(.cancelButtonTapped)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        store.send(.saveButtonTapped)
                    }
                    .disabled(store.isSaving)
                }
            }
        }
    }

    private var navigationTitle: String {
        switch store.mode {
        case .add:
            return "New Location"
        case .edit:
            return "Edit Location"
        }
    }
}

#Preview {
    AddEditLocationView(store: Store(
        initialState: AddEditLocationFeature.State(mode: .add),
        reducer: { AddEditLocationFeature() }
    ))
}
