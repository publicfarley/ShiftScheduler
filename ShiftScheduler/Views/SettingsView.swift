import SwiftUI

struct SettingsView: View {
    @Environment(\.reduxStore) var store
    @State private var displayName: String = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    Text("User Profile")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Display Name")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Enter your name", text: $displayName)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: displayName) { _, newValue in
                                store.dispatch(action: .settings(.displayNameChanged(newValue)))
                            }
                    }

                    Divider()

                    Text("Change Log Settings")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Retention Period")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Forever")
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }

                    Spacer()
                }
                .padding()
            }
            .scrollDismissesKeyboard(.immediately)
            .dismissKeyboardOnTap()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                store.dispatch(action: .settings(.task))
                displayName = store.state.settings.displayName
            }
        }
    }
}

#Preview {
    SettingsView()
}
