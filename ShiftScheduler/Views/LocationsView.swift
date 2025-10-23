import SwiftUI

struct LocationsView: View {
    @Environment(\.reduxStore) var store

    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(store.state.locations.locations) { location in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(location.name)
                                    .font(.headline)
                                Text(location.address)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                }
                .navigationTitle("Locations")
                .navigationBarTitleDisplayMode(.large)
            }
            .onAppear {
                store.dispatch(action: .locations(.task))
            }
        }
    }
}

#Preview {
    LocationsView()
}
