import SwiftUI
import SwiftData

struct LocationsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var locations: [Location]
    @Query private var shiftTypes: [ShiftType]
    @State private var showingAddLocation = false
    @State private var locationToEdit: Location?
    @State private var searchText = ""
    @State private var activeOnly = true
    @FocusState private var searchFieldIsFocused: Bool

    private var filteredLocations: [Location] {
        var filtered = locations

        if !searchText.isEmpty {
            filtered = filtered.filter { location in
                location.name.localizedCaseInsensitiveContains(searchText) ||
                location.address.localizedCaseInsensitiveContains(searchText)
            }
        }

        return filtered
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)

                        TextField("Search locations...", text: $searchText)
                            .focused($searchFieldIsFocused)
                    }
                    .padding(12)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.top)

                    HStack {
                        Text("\(filteredLocations.count) \(filteredLocations.count == 1 ? "location" : "locations")")
                            .foregroundColor(.secondary)
                            .font(.subheadline)

                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                .onTapGesture {
                    searchFieldIsFocused = false
                }

                if filteredLocations.isEmpty {
                    Spacer()

                    VStack(spacing: 20) {
                        Image(systemName: "location")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)

                        Text("No Locations")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Create your first location to assign to\nshift types")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        Button("Create Location") {
                            showingAddLocation = true
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    .padding()

                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredLocations) { location in
                                LocationRow(location: location) {
                                    locationToEdit = location
                                }
                            }
                        }
                    }
                }
            }
            .onTapGesture {
                searchFieldIsFocused = false
            }
            .navigationTitle("Locations")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddLocation = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddLocation) {
                AddLocationView()
            }
            .sheet(item: $locationToEdit) { location in
                EditLocationView(location: location)
            }
        }
    }

    private func deleteLocations(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let locationToDelete = filteredLocations[index]

                // First, set location to nil for all shift types that reference this location
                let affectedShiftTypes = shiftTypes.filter { shiftType in
                    guard let shiftTypeLocation = shiftType.location else { return false }
                    return shiftTypeLocation.persistentModelID == locationToDelete.persistentModelID
                }
                for shiftType in affectedShiftTypes {
                    shiftType.location = nil
                }

                // Then delete the location
                modelContext.delete(locationToDelete)
            }
        }
    }
}

struct LocationRow: View {
    let location: Location
    let onEdit: () -> Void
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.blue)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(location.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("Location")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                HStack(spacing: 16) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.body)
                            .foregroundColor(.blue)
                    }

                    Button(action: {
                        withAnimation {
                            modelContext.delete(location)
                        }
                    }) {
                        Image(systemName: "trash")
                            .font(.body)
                            .foregroundColor(.red)
                    }
                }
            }

            Text(location.address)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(3)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

#Preview {
    LocationsView()
        .modelContainer(for: [Location.self, ShiftType.self], inMemory: true)
}