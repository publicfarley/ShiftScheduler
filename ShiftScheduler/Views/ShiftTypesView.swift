import SwiftUI
import ComposableArchitecture

struct ShiftTypesView: View {
    @Bindable var store: StoreOf<ShiftTypesFeature>

    @State private var cardAppeared: [UUID: Bool] = [:]
    @State private var emptyStateAppeared = false

    private var filteredShiftTypes: IdentifiedArrayOf<ShiftType> {
        store.filteredShiftTypes
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                SearchBar()

                if filteredShiftTypes.isEmpty {
                    EmptyStateView()
                } else {
                    ShiftTypesListView(
                        cardAppeared: $cardAppeared,
                        filteredShiftTypes: filteredShiftTypes,
                        onEdit: { shiftType in
                            store.send(.editShiftType(shiftType))
                        },
                        onDelete: { shiftType in
                            store.send(.deleteShiftType(shiftType))
                        },
                        onAppear: {
                            let shiftTypeArray = Array(filteredShiftTypes)
                            for (index, shiftType) in shiftTypeArray.enumerated() {
                                withAnimation(
                                    AnimationPresets.accessible(AnimationPresets.standardSpring)
                                        .delay(Double(index) * 0.05)
                                ) {
                                    cardAppeared[shiftType.id] = true
                                }
                            }
                        }
                    )
                }
            }
            .dismissKeyboardOnTap()
            .navigationTitle("Shift Types")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        store.send(.addButtonTapped)
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(item: $store.scope(state: \.addEditSheet, action: \.addEditSheet)) { addEditStore in
                AddEditShiftTypeView(store: addEditStore)
            }
            .task {
                store.send(.task)
            }
        }
    }

    // MARK: - Sub-views for type-checking

    private func SearchBar() -> some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search shift types...", text: Binding(
                    get: { store.searchText },
                    set: { newValue in
                        store.send(.searchTextChanged(newValue))
                    }
                ))
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
                Text("\(filteredShiftTypes.count) \(filteredShiftTypes.count == 1 ? "shift type" : "shift types")")
                    .foregroundColor(.secondary)
                    .font(.subheadline)

                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }

    private func EmptyStateView() -> some View {
        VStack {
            Spacer()

            VStack(spacing: 24) {
                Image(systemName: "clock.badge.plus")
                    .font(.system(size: 80, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .offset(y: emptyStateAppeared ? 0 : 20)
                    .opacity(emptyStateAppeared ? 1 : 0)
                    .shadow(color: .blue.opacity(0.3), radius: 12, y: 6)

                VStack(spacing: 12) {
                    Text("No Shift Types")
                        .font(.title2)
                        .fontWeight(.bold)
                        .offset(y: emptyStateAppeared ? 0 : 15)
                        .opacity(emptyStateAppeared ? 1 : 0)

                    Text("Create your first shift type to get started\nwith scheduling")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .offset(y: emptyStateAppeared ? 0 : 10)
                        .opacity(emptyStateAppeared ? 1 : 0)
                }

                Button {
                    store.send(.addButtonTapped)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text("Create Shift Type")
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .blue.opacity(0.3), radius: 12, y: 6)
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
        }
    }

    private func ShiftTypesListView(
        cardAppeared: Binding<[UUID: Bool]>,
        filteredShiftTypes: IdentifiedArrayOf<ShiftType>,
        onEdit: @escaping (ShiftType) -> Void,
        onDelete: @escaping (ShiftType) -> Void,
        onAppear: @escaping () -> Void
    ) -> some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(Array(filteredShiftTypes), id: \.id) { shiftType in
                    EnhancedShiftTypeCard(
                        shiftType: shiftType,
                        onEdit: {
                            onEdit(shiftType)
                        },
                        onDelete: {
                            onDelete(shiftType)
                        }
                    )
                    .padding(.horizontal)
                    .offset(y: cardAppeared.wrappedValue[shiftType.id] ?? false ? 0 : 30)
                    .opacity(cardAppeared.wrappedValue[shiftType.id] ?? false ? 1 : 0)
                }
            }
            .padding(.vertical, 8)
        }
        .scrollDismissesKeyboard(.immediately)
        .onAppear {
            onAppear()
        }
    }
}

struct ShiftTypeRow: View {
    let shiftType: ShiftType
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

                    Text("📍 \(shiftType.location.name)")
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
                // TODO: Implement deletion through ShiftTypesFeature (Task 7)
            }
        } message: {
            Text("Are you sure you want to delete \"\(shiftType.title)\"? This action cannot be undone.")
        }
    }
}

struct LocationDisplayView: View {
    let shiftType: ShiftType

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
            // Location is always available in the aggregate
            locationName = shiftType.location.name
            showLocation = true
        }
    }
}

#Preview {
    ShiftTypesView(
        store: Store(
            initialState: ShiftTypesFeature.State(),
            reducer: {
                ShiftTypesFeature()
            }
        )
    )
}
