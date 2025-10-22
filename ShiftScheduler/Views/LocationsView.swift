import SwiftUI
import ComposableArchitecture

struct LocationsView: View {
    @Bindable var store: StoreOf<LocationsFeature>

    @State private var cardAppeared: [UUID: Bool] = [:]
    @State private var emptyStateAppeared = false

    private var filteredLocations: IdentifiedArrayOf<Location> {
        store.filteredLocations
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        
                        Text("Search locations temporarily disabled")

//                        TextField("Search locations...", text: $store.searchText)
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
                            store.send(.addButtonTapped)
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
                                let shiftTypeCount = 0
                                let canDelete = true

                                EnhancedLocationCard(
                                    location: location,
                                    shiftTypeCount: shiftTypeCount,
                                    onEdit: {
                                        store.send(.editLocation(location))
                                    },
                                    onDelete: {
                                        store.send(.deleteLocation(location))
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
                        store.send(.addButtonTapped)
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(item: $store.scope(state: \.addEditSheet, action: \.addEditSheet)) { addEditStore in
                AddEditLocationView(store: addEditStore)
            }
        }
        .task {
            store.send(.task)
        }
    }

}

#Preview {
    LocationsView(store: Store(initialState: LocationsFeature.State(), reducer: {
        LocationsFeature()
    }))
}
