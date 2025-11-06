import SwiftUI

struct LocationsView: View {
    @Environment(\.reduxStore) var store
    @State private var searchText = ""
    @State private var showDeleteConfirmation = false
    @State private var locationToDelete: Location?
    @State private var showDeletionPreventedAlert = false
    @State private var deletionPreventionMessage = ""

    var filteredLocations: [Location] {
        if searchText.isEmpty {
            return store.state.locations.locations
        }
        return store.state.locations.locations.filter { location in
            location.name.localizedCaseInsensitiveContains(searchText) ||
            location.address.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    // Search bar
                    SearchBar(text: $searchText, placeholder: "Search locations")
                        .padding()

                    if filteredLocations.isEmpty && !store.state.locations.isLoading {
                        // Empty state
                        VStack(spacing: 20) {
                            Spacer()

                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.blue.opacity(0.2), Color.cyan.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 100, height: 100)

                                Image(systemName: "location.slash")
                                    .font(.system(size: 44))
                                    .foregroundColor(.blue)
                            }

                            VStack(spacing: 8) {
                                Text("No Locations")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)

                                Text(searchText.isEmpty ? "Add your first location to get started" : "No locations match your search")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }

                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        // Locations list
                        ScrollView {
                            VStack(spacing: 16) {
                                ForEach(filteredLocations) { location in
                                    LocationCard(location: location)
                                        .onTapGesture {
                                            store.dispatch(action: .locations(.editLocation(location)))
                                        }
                                        .contextMenu {
                                            Button(action: {
                                                store.dispatch(action: .locations(.editLocation(location)))
                                            }) {
                                                Label("Edit", systemImage: "pencil")
                                            }

                                            Button(role: .destructive, action: {
                                                locationToDelete = location
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
                    if store.state.locations.isLoading {
                        ProgressView()
                            .padding()
                    }

                    // Error message
                    if let error = store.state.locations.errorMessage {
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
                .navigationTitle("Locations")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: {
                            store.dispatch(action: .locations(.addButtonTapped))
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                        }
                    }
                }
                .sheet(
                    isPresented: .constant(store.state.locations.showAddEditSheet),
                       
                    onDismiss: {
                        store.dispatch(action: .locations(.addEditSheetDismissed))
                    }
                ) {
                    AddEditLocationView(
                        isPresented: .constant(store.state.locations.showAddEditSheet),
                        location: store.state.locations.editingLocation
                    )
                }
                .alert("Delete Location", isPresented: $showDeleteConfirmation) {
                    Button("Cancel", role: .cancel) { }
                    Button("Delete", role: .destructive) {
                        if let location = locationToDelete {
                            store.dispatch(action: .locations(.deleteLocation(location)))
                            locationToDelete = nil
                        }
                    }
                } message: {
                    if let location = locationToDelete {
                        Text("Are you sure you want to delete \"\(location.name)\"? This action cannot be undone.")
                    }
                }
                .alert("Cannot Delete Location", isPresented: $showDeletionPreventedAlert) {
                    Button("OK", role: .cancel) {
                        showDeletionPreventedAlert = false
                        deletionPreventionMessage = ""
                    }
                } message: {
                    Text(deletionPreventionMessage)
                }
                .onChange(of: store.state.locations.errorMessage) { oldValue, newValue in
                    if let message = newValue, message.contains("is used by") {
                        deletionPreventionMessage = message
                        showDeletionPreventedAlert = true
                    }
                }
                .onAppear {
                    store.dispatch(action: .locations(.loadLocations))
                }
            }
        }
    }
}

// MARK: - Location Card

struct LocationCard: View {
    let location: Location

    private let accentColor = Color.blue

    var body: some View {
        VStack(spacing: 0) {
            // Card Content
            VStack(alignment: .leading, spacing: 14) {
                // Header with icon badge
                HStack(alignment: .center, spacing: 12) {
                    // Location icon badge
                    Image(systemName: "mappin.circle.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [accentColor, accentColor.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: accentColor.opacity(0.4), radius: 6, x: 0, y: 3)
                        )

                    // Location name
                    Text(location.name)
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

                // Address section
                HStack(spacing: 8) {
                    Image(systemName: "location.fill")
                        .font(.caption)
                        .foregroundColor(accentColor)

                    Text(location.address)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(accentColor.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(accentColor.opacity(0.2), lineWidth: 1)
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


#Preview {
    LocationsView()
}
