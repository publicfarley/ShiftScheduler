import SwiftUI
import SwiftData

struct LocationsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var locations: [Location]
    @State private var showingAddLocation = false
    @State private var searchText = ""
    @State private var activeOnly = true

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
                    }
                    .padding(12)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.top)

                    HStack {
                        Text("Active Only")
                            .font(.body)

                        Spacer()

                        Toggle("", isOn: $activeOnly)

                        Text("\(filteredLocations.count) locations")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
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
                        }
                        .onDelete(perform: deleteLocations)
                    }
                }
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
        }
    }

    private func deleteLocations(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(filteredLocations[index])
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
        .modelContainer(for: [Location.self, ShiftType.self, ScheduledShift.self], inMemory: true)
}