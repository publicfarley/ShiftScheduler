import SwiftUI

struct ShiftTypesView: View {
    @Environment(\.reduxStore) var store
    @State private var searchText = ""
    @State private var showDeleteConfirmation = false
    @State private var shiftTypeToDelete: ShiftType?

    var filteredShiftTypes: [ShiftType] {
        if searchText.isEmpty {
            return store.state.shiftTypes.shiftTypes
        }
        return store.state.shiftTypes.shiftTypes.filter { shiftType in
            shiftType.title.localizedCaseInsensitiveContains(searchText) ||
            shiftType.symbol.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    // Search bar
                    SearchBar(text: $searchText, placeholder: "Search shift types")
                        .padding()

                    if filteredShiftTypes.isEmpty && !store.state.shiftTypes.isLoading {
                        // Empty state
                        VStack(spacing: 16) {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            Text("No Shift Types")
                                .font(.headline)
                            Text(searchText.isEmpty ? "Add your first shift type to get started" : "No shift types match your search")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxHeight: .infinity)
                        .padding()
                    } else {
                        // Shift types list
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(filteredShiftTypes) { shiftType in
                                    ShiftTypeCard(shiftType: shiftType)
                                        .onTapGesture {
                                            store.dispatch(action: .shiftTypes(.editShiftType(shiftType)))
                                        }
                                        .contextMenu {
                                            Button(action: {
                                                store.dispatch(action: .shiftTypes(.editShiftType(shiftType)))
                                            }) {
                                                Label("Edit", systemImage: "pencil")
                                            }

                                            Button(role: .destructive, action: {
                                                shiftTypeToDelete = shiftType
                                                showDeleteConfirmation = true
                                            }) {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                            .padding()
                        }
                    }

                    // Loading indicator
                    if store.state.shiftTypes.isLoading {
                        ProgressView()
                            .padding()
                    }

                    // Error message
                    if let error = store.state.shiftTypes.errorMessage {
                        VStack {
                            HStack {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.red)
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .lineLimit(2)
                                Spacer()
                            }
                            .padding()
                            .background(Color(.systemRed).opacity(0.1))
                            .cornerRadius(8)
                            .padding()
                        }
                    }
                }
                .navigationTitle("Shift Types")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: {
                            store.dispatch(action: .shiftTypes(.addButtonTapped))
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                        }
                    }
                }
                .sheet(
                    isPresented: .constant(store.state.shiftTypes.showAddEditSheet),
                    onDismiss: {
                        store.dispatch(action: .shiftTypes(.addEditSheetDismissed))
                    }
                ) {
                    AddEditShiftTypeView(
                        isPresented: .constant(store.state.shiftTypes.showAddEditSheet),
                        shiftType: store.state.shiftTypes.editingShiftType
                    )
                }
                .alert("Delete Shift Type", isPresented: $showDeleteConfirmation) {
                    Button("Cancel", role: .cancel) { }
                    Button("Delete", role: .destructive) {
                        if let shiftType = shiftTypeToDelete {
                            store.dispatch(action: .shiftTypes(.deleteShiftType(shiftType)))
                            shiftTypeToDelete = nil
                        }
                    }
                } message: {
                    if let shiftType = shiftTypeToDelete {
                        Text("Are you sure you want to delete \"\(shiftType.title)\"? This action cannot be undone.")
                    }
                }
                .onAppear {
                    store.dispatch(action: .shiftTypes(.task))
                }
            }
        }
    }
}

// MARK: - Shift Type Card

struct ShiftTypeCard: View {
    let shiftType: ShiftType

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(shiftType.symbol)
                            .font(.title3)
                        Text(shiftType.title)
                            .font(.headline)
                            .lineLimit(1)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(shiftType.timeRangeString)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(shiftType.location.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Search Bar

struct SearchBar: View {
    @Binding var text: String
    let placeholder: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .dismissKeyboardOnTap()
    }
}

#Preview {
    ShiftTypesView()
}
