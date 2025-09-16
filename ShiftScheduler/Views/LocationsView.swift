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
    @Query private var shiftTypes: [ShiftType]
    @State private var showingDeleteAlert = false
    @State private var showingConstraintAlert = false

    private var referencingShiftTypes: [ShiftType] {
        shiftTypes.filter { shiftType in
            guard let shiftTypeLocation = shiftType.location else { return false }
            return shiftTypeLocation.persistentModelID == location.persistentModelID
        }
    }

    private var canDelete: Bool {
        referencingShiftTypes.isEmpty
    }

    private let gradientColors: [LinearGradient] = [
        LinearGradient(colors: [Color.blue, Color.blue.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(colors: [Color.green, Color.green.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(colors: [Color.orange, Color.orange.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(colors: [Color.purple, Color.purple.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(colors: [Color.pink, Color.pink.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(colors: [Color.red, Color.red.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
    ]

    private let headerIcons = ["star.fill", "heart.fill", "bolt.fill", "leaf.fill", "flame.fill", "diamond.fill"]

    private var randomGradient: LinearGradient {
        let hash = abs(location.name.hashValue)
        return gradientColors[hash % gradientColors.count]
    }

    private var randomIcon: String {
        let hash = abs(location.name.hashValue)
        return headerIcons[hash % headerIcons.count]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Gradient Header - Compressed height
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(location.name)
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    Text("September 16, 2025")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                Image(systemName: randomIcon)
                    .font(.callout)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(randomGradient)

            // Content Section - Reduced spacing and padding
            VStack(alignment: .leading, spacing: 8) {
                Text(location.address)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Button(action: onEdit) {
                        HStack(spacing: 3) {
                            Image(systemName: "pencil")
                                .font(.caption2)
                            Text("Edit")
                                .font(.caption2)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }

                    Button(action: {
                        if canDelete {
                            showingDeleteAlert = true
                        } else {
                            showingConstraintAlert = true
                        }
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "trash")
                                .font(.caption2)
                            Text("Delete")
                                .font(.caption2)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }

                    Spacer()
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
        }
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 1)
        .padding(.horizontal)
        .padding(.vertical, 3)
        .alert("Delete Location", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                withAnimation {
                    modelContext.delete(location)
                }
            }
        } message: {
            Text("Are you sure you want to delete \"\(location.name)\"? This action cannot be undone.")
        }
        .alert("Cannot Delete Location", isPresented: $showingConstraintAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            let count = referencingShiftTypes.count
            let shiftTypeNames = referencingShiftTypes.map { $0.title }.joined(separator: ", ")
            return Text("Cannot delete \"\(location.name)\" because it is referenced by \(count) shift type\(count == 1 ? "" : "s"): \(shiftTypeNames). Please remove or reassign these shift types first.")
        }
    }
}

#Preview {
    LocationsView()
        .modelContainer(for: [Location.self, ShiftType.self], inMemory: true)
}