import SwiftUI

struct LocationsView: View {
    @Environment(\.reduxStore) var store
    @State private var searchText = ""
    @State private var showDeleteConfirmation = false
    @State private var locationToDelete: Location?

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
                        VStack(spacing: 16) {
                            Image(systemName: "location.slash")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            Text("No Locations")
                                .font(.headline)
                            Text(searchText.isEmpty ? "Add your first location to get started" : "No locations match your search")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxHeight: .infinity)
                        .padding()
                    } else {
                        // Locations list
                        ScrollView {
                            VStack(spacing: 12) {
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
                .sheet(isPresented: .constant(store.state.locations.showAddEditSheet)) {
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
                .onAppear {
                    store.dispatch(action: .locations(.task))
                }
            }
        }
    }
}

// MARK: - Location Card

struct LocationCard: View {
    let location: Location

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(location.name)
                        .font(.headline)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(location.address)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
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


#Preview {
    LocationsView()
}
