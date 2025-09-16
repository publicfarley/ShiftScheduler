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
                        LazyVStack(spacing: 0) {
                            ForEach(filteredShiftTypes) { shiftType in
                                ShiftTypeRow(shiftType: shiftType)
                            }
                        }
                    }
                }
            }
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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(shiftType.symbol)
                    .foregroundColor(.orange)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(shiftType.title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(shiftType.timeRangeString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                HStack(spacing: 16) {
                    Button(action: { showingEditView = true }) {
                        Image(systemName: "pencil")
                            .font(.body)
                            .foregroundColor(.blue)
                    }

                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        Image(systemName: "trash")
                            .font(.body)
                            .foregroundColor(.red)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(shiftType.shiftDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(3)

                // Only show location if it exists and is accessible
                if shiftType.location != nil {
                    LocationDisplayView(shiftType: shiftType)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
        .padding(.vertical, 4)
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