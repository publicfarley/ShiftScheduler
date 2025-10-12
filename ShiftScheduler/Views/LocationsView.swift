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
    @State private var cardAppeared: [UUID: Bool] = [:]
    @State private var emptyStateAppeared = false

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
                            .foregroundStyle(.secondary)

                        TextField("Search locations...", text: $searchText)
                    }
                    .padding(16)
                    .background {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(.quaternary, lineWidth: 1)
                            }
                    }
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

                if filteredLocations.isEmpty {
                    Spacer()

                    VStack(spacing: 24) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 80, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.2, green: 0.7, blue: 0.7),
                                        Color(red: 0.3, green: 0.6, blue: 0.9)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .offset(y: emptyStateAppeared ? 0 : 20)
                            .opacity(emptyStateAppeared ? 1 : 0)
                            .shadow(color: Color(red: 0.2, green: 0.7, blue: 0.7).opacity(0.3), radius: 12, y: 6)

                        VStack(spacing: 12) {
                            Text("No Locations")
                                .font(.title2)
                                .fontWeight(.bold)
                                .offset(y: emptyStateAppeared ? 0 : 15)
                                .opacity(emptyStateAppeared ? 1 : 0)

                            Text("Create your first location to assign to\nshift types")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .offset(y: emptyStateAppeared ? 0 : 10)
                                .opacity(emptyStateAppeared ? 1 : 0)
                        }

                        Button {
                            showingAddLocation = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                Text("Create Location")
                            }
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.2, green: 0.7, blue: 0.7),
                                        Color(red: 0.2, green: 0.7, blue: 0.7).opacity(0.8)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: Color(red: 0.2, green: 0.7, blue: 0.7).opacity(0.3), radius: 12, y: 6)
                        }
                        .buttonStyle(.plain)
                        .offset(y: emptyStateAppeared ? 0 : 10)
                        .opacity(emptyStateAppeared ? 1 : 0)
                    }
                    .padding()
                    .onAppear {
                        withAnimation(
                            AnimationPresets.accessible(AnimationPresets.standardSpring)
                                .delay(0.1)
                        ) {
                            emptyStateAppeared = true
                        }
                    }

                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(Array(filteredLocations.enumerated()), id: \.element.id) { index, location in
                                let shiftTypeCount = shiftTypes.filter { $0.location?.id == location.id }.count
                                let canDelete = shiftTypeCount == 0

                                EnhancedLocationCard(
                                    location: location,
                                    shiftTypeCount: shiftTypeCount,
                                    onEdit: {
                                        locationToEdit = location
                                    },
                                    onDelete: {
                                        withAnimation {
                                            modelContext.delete(location)
                                        }
                                    },
                                    canDelete: canDelete
                                )
                                .padding(.horizontal)
                                .offset(y: cardAppeared[location.id] ?? false ? 0 : 30)
                                .opacity(cardAppeared[location.id] ?? false ? 1 : 0)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .scrollDismissesKeyboard(.immediately)
                    .onAppear {
                        // Trigger staggered animations
                        for (index, location) in filteredLocations.enumerated() {
                            withAnimation(
                                AnimationPresets.accessible(AnimationPresets.standardSpring)
                                    .delay(Double(index) * 0.05)
                            ) {
                                cardAppeared[location.id] = true
                            }
                        }
                    }
                }
            }
            .dismissKeyboardOnTap()
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

    private let consistentGradient = LinearGradient(
        colors: [Color(.systemGray3), Color(.systemGray4)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    private let headerIcons = ["star.fill", "heart.fill", "bolt.fill", "leaf.fill", "flame.fill", "diamond.fill"]

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
                        .foregroundColor(.primary)

                    Text("September 16, 2025")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: randomIcon)
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(consistentGradient)

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