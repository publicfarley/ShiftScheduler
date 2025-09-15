import SwiftUI
import SwiftData

struct LocationsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var locations: [Location]
    @Query private var shiftTypes: [ShiftType]
    @State private var showingAddLocation = false
    @State private var showingEditLocation = false
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
                    List {
                        ForEach(filteredLocations) { location in
                            LocationRow(location: location)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    locationToEdit = location
                                    showingEditLocation = true
                                }
                        }
                        .onDelete(perform: deleteLocations)
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
            .sheet(isPresented: $showingEditLocation) {
                if let location = locationToEdit {
                    EditLocationView(location: location)
                }
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

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(location.name)
                .font(.headline)

            Text(location.address)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    LocationsView()
        .modelContainer(for: [Location.self, ShiftType.self], inMemory: true)
}