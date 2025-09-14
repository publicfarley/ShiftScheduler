import SwiftUI
import SwiftData

struct ShiftTypesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var shiftTypes: [ShiftType]
    @State private var showingAddShiftType = false
    @State private var searchText = ""
    @State private var activeOnly = true

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
                        Text("Active Only")
                            .font(.body)

                        Spacer()

                        Toggle("", isOn: $activeOnly)

                        Text("\(filteredShiftTypes.count) shift types")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
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
                    List {
                        ForEach(filteredShiftTypes) { shiftType in
                            ShiftTypeRow(shiftType: shiftType)
                        }
                        .onDelete(perform: deleteShiftTypes)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(shiftType.symbol)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)

                Spacer()

                Text("\(shiftType.startTimeString) - \(shiftType.endTimeString)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Text(shiftType.title)
                .font(.headline)

            Text(shiftType.shiftDescription)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)

            if let location = shiftType.location {
                Text("📍 \(location.name)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    ShiftTypesView()
        .modelContainer(for: [Location.self, ShiftType.self, ScheduledShift.self], inMemory: true)
}