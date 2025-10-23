import SwiftUI

struct ShiftTypesView: View {
    @Environment(\.reduxStore) var store

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(store.state.shiftTypes.shiftTypes) { shiftType in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(shiftType.symbol)
                                    .font(.title3)
                                Text(shiftType.title)
                                    .font(.headline)
                            }
                            Text(shiftType.timeRangeString)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
            .navigationTitle("Shift Types")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                store.dispatch(action: .shiftTypes(.task))
            }
        }
    }
}

#Preview {
    ShiftTypesView()
}
