import SwiftUI

struct ChangeLogView: View {
    @Environment(\.reduxStore) var store

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 12) {
                    if store.state.changeLog.filteredEntries.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("No Changes")
                                .font(.headline)
                            Text("Your shift changes will appear here")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    } else {
                        ForEach(store.state.changeLog.filteredEntries.prefix(10)) { entry in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(entry.changeType.displayName)
                                        .font(.headline)
                                    Spacer()
                                    Text(entry.timestamp, style: .time)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Text(entry.userDisplayName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Change Log")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                store.dispatch(action: .changeLog(.task))
            }
        }
    }
}

#Preview {
    ChangeLogView()
}
