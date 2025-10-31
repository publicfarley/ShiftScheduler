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
                        VStack(spacing: 20) {
                            Spacer()

                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.purple.opacity(0.2), Color.pink.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 100, height: 100)

                                Image(systemName: "calendar.badge.plus")
                                    .font(.system(size: 44))
                                    .foregroundColor(.purple)
                            }

                            VStack(spacing: 8) {
                                Text("No Shift Types")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)

                                Text(searchText.isEmpty ? "Add your first shift type to get started" : "No shift types match your search")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }

                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        // Shift types list
                        ScrollView {
                            VStack(spacing: 16) {
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

    private let accentColor = Color.purple

    var body: some View {
        VStack(spacing: 0) {
            // Card Content
            VStack(alignment: .leading, spacing: 14) {
                // Header with symbol and title
                HStack(alignment: .center, spacing: 12) {
                    // Shift symbol badge
                    Text(shiftType.symbol)
                        .font(.title2)
                        .frame(width: 50, height: 50)
                        .background(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [accentColor.opacity(0.15), accentColor.opacity(0.08)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    Circle()
                                        .stroke(
                                            LinearGradient(
                                                colors: [accentColor.opacity(0.4), accentColor.opacity(0.2)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 2
                                        )
                                )
                                .shadow(color: accentColor.opacity(0.2), radius: 4, x: 0, y: 2)
                        )

                    // Shift title
                    Text(shiftType.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Spacer()

                    // Edit indicator
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.title3)
                        .foregroundColor(accentColor.opacity(0.6))
                }

                // Shift details section
                VStack(alignment: .leading, spacing: 10) {
                    // Time range
                    HStack(spacing: 8) {
                        Image(systemName: "clock.fill")
                            .font(.subheadline)
                            .foregroundColor(accentColor)
                            .frame(width: 24)

                        Text(shiftType.timeRangeString)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }

                    // Location
                    HStack(spacing: 8) {
                        Image(systemName: "location.fill")
                            .font(.subheadline)
                            .foregroundColor(accentColor)
                            .frame(width: 24)

                        Text(shiftType.location.name)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    }

                    // Description (if present)
                    if !shiftType.shiftDescription.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: "text.alignleft")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Text("Description")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                            }

                            Text(shiftType.shiftDescription)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .lineLimit(2)
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(.systemGray6))
                                )
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(accentColor.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(accentColor.opacity(0.15), lineWidth: 1)
                        )
                )
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                LinearGradient(
                                    colors: [accentColor.opacity(0.3), accentColor.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: accentColor.opacity(0.1), radius: 8, x: 0, y: 4)
            )

            // Bottom accent bar
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [accentColor.opacity(0.6), accentColor.opacity(0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 3)
                .cornerRadius(1.5)
                .padding(.horizontal, 16)
        }
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
