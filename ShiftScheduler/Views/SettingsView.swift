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
                        Picker("Retention Period", selection: Binding(
                            get: { store.state.settings.retentionPolicy },
                            set: { newValue in
                                store.dispatch(action: .settings(.retentionPolicyChanged(newValue)))
                            }
                        )) {
                            ForEach(ChangeLogRetentionPolicy.allCases) { policy in
                                Text(policy.displayName).tag(policy)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.primary)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
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
