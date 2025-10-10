import SwiftUI
import SwiftData

struct ShiftTypesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var shiftTypes: [ShiftType]
    @State private var showingAddShiftType = false
    @State private var searchText = ""

    private var filteredShiftTypes: [ShiftType] {
        var filtered = shiftTypes

        if !searchText.isEmpty {
            filtered = filtered.filter { shiftType in
                shiftType.title.localizedCaseInsensitiveContains(searchText) ||
                shiftType.symbol.localizedCaseInsensitiveContains(searchText) ||
                shiftType.shiftDescription.localizedCaseInsensitiveContains(searchText)
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

                        TextField("Search shift types...", text: $searchText)
                    }
                    .padding(12)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.top)

                    HStack {
                        Text("\(filteredShiftTypes.count) \(filteredShiftTypes.count == 1 ? "shift type" : "shift types")")
                            .foregroundColor(.secondary)
                            .font(.subheadline)

                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }

                if filteredShiftTypes.isEmpty {
                    Spacer()

                    VStack(spacing: 20) {
                        Image(systemName: "clock.badge.questionmark")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)

                        Text("No Shift Types")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Create your first shift type to get started\nwith scheduling")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        Button("Create Shift Type") {
                            showingAddShiftType = true
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    .padding()

                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredShiftTypes) { shiftType in
                                ShiftTypeRow(shiftType: shiftType)
                            }
                        }
                    }
                    .scrollDismissesKeyboard(.immediately)
                }
            }
            .dismissKeyboardOnTap()
            .navigationTitle("Shift Types")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddShiftType = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddShiftType) {
                AddShiftTypeView()
            }
        }
    }

    private func deleteShiftTypes(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(shiftTypes[index])
            }
        }
    }
}

struct ShiftTypeRow: View {
    let shiftType: ShiftType
    @Environment(\.modelContext) private var modelContext
    @State private var showingEditView = false
    @State private var showingDeleteAlert = false

    private let consistentGradient = LinearGradient(
        colors: [Color(.systemGray3), Color(.systemGray4)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    private let headerIcons = ["star.fill", "heart.fill", "bolt.fill", "leaf.fill", "flame.fill", "diamond.fill"]

    private var randomIcon: String {
        let hash = abs(shiftType.title.hashValue)
        return headerIcons[hash % headerIcons.count]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Gradient Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(shiftType.symbol) : \(shiftType.title)")
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text(shiftType.timeRangeString)
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    if let location = shiftType.location {
                        Text("📍 \(location.name)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Image(systemName: randomIcon)
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(consistentGradient)

            // Content Section
            VStack(alignment: .leading, spacing: 8) {
                Text(shiftType.shiftDescription)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Button(action: { showingEditView = true }) {
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
                        showingDeleteAlert = true
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
        .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 2)
        .padding(.horizontal)
        .padding(.vertical, 3)
        .sheet(isPresented: $showingEditView) {
            EditShiftTypeView(shiftType: shiftType)
        }
        .alert("Delete Shift Type", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                withAnimation {
                    modelContext.delete(shiftType)
                }
            }
        } message: {
            Text("Are you sure you want to delete \"\(shiftType.title)\"? This action cannot be undone.")
        }
    }
}

struct LocationDisplayView: View {
    let shiftType: ShiftType
    @Environment(\.modelContext) private var modelContext

    @State private var locationName: String?
    @State private var showLocation: Bool = false

    var body: some View {
        Group {
            if showLocation, let locationName = locationName {
                Text("📍 \(locationName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .task {
            await loadLocationSafely()
        }
    }

    private func loadLocationSafely() async {
        await MainActor.run {
            guard let location = shiftType.location else {
                showLocation = false
                return
            }

            // Simply access the location name
            // The cascade delete should have already cleaned up invalid references
            locationName = location.name
            showLocation = true
        }
    }
}

#Preview {
    ShiftTypesView()
        .modelContainer(for: [Location.self, ShiftType.self], inMemory: true)
}