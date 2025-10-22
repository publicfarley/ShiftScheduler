import SwiftUI
import OSLog
import ComposableArchitecture

private let logger = Logger(subsystem: "com.workevents.ShiftScheduler", category: "SettingsView")

struct SettingsView: View {
    @Bindable var store: StoreOf<SettingsFeature>
    @State private var isPressed = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Spacer for top breathing room
                    Spacer()
                        .frame(height: 20)

                    // Settings header with glass effect
                    GlassCard(cornerRadius: 20, blurMaterial: .ultraThinMaterial) {
                        VStack(spacing: 12) {
                            HStack(spacing: 10) {
                                Image(systemName: "gearshape.fill")
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.cyan, .blue],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .font(.title2)

                                Text("App Settings")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }

                            Text("Manage your app preferences and data")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                    .padding(.horizontal, 24)
                    .offset(y: store.titleAppeared ? 0 : 30)
                    .opacity(store.titleAppeared ? 1 : 0)
                    .padding(.bottom, 32)

                    // User Profile section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("User Profile")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 24)

                        GlassCard(cornerRadius: 16, blurMaterial: .regularMaterial) {
                            VStack(spacing: 20) {
                                // Display Name
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "person.fill")
                                            .foregroundStyle(.blue)
                                            .font(.title3)

                                        Text("Display Name")
                                            .font(.headline)
                                            .foregroundStyle(.primary)

                                        Spacer()
                                    }

                                    TextField("Enter your name", text: Binding(
                                        get: { store.displayName },
                                        set: { store.send(.displayNameChanged($0)) }
                                    ))
                                    .textFieldStyle(.roundedBorder)
                                }

                                Divider()

                                // User ID
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "key.fill")
                                            .foregroundStyle(.purple)
                                            .font(.title3)

                                        Text("User ID")
                                            .font(.headline)
                                            .foregroundStyle(.primary)

                                        Spacer()
                                    }

                                    HStack {
                                        Text(store.currentUserId.uuidString)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                            .truncationMode(.middle)

                                        Button {
                                            UIPasteboard.general.string = store.currentUserId.uuidString
                                        } label: {
                                            Image(systemName: "doc.on.doc")
                                                .font(.caption)
                                        }
                                        .buttonStyle(.borderless)
                                    }

                                    Text("This ID tracks your changes in the log")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }

                                Divider()

                                // Reset User ID button
                                Button(action: {
                                    store.send(.resetUserProfile)
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.clockwise")
                                        Text("Reset User ID")
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(
                                                LinearGradient(
                                                    colors: [.purple, .purple.opacity(0.8)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                                            .overlay {
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                                            }
                                    }
                                }
                            }
                            .padding(4)
                        }
                        .padding(.horizontal, 24)
                    }
                    .offset(y: store.userProfileSectionAppeared ? 0 : 30)
                    .opacity(store.userProfileSectionAppeared ? 1 : 0)
                    .padding(.bottom, 24)

                    // Change Log Settings section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Change Log Settings")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 24)

                        GlassCard(cornerRadius: 16, blurMaterial: .regularMaterial) {
                            VStack(spacing: 20) {
                                // Retention Policy
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "clock.arrow.circlepath")
                                            .foregroundStyle(.cyan)
                                            .font(.title3)

                                        Text("Retention Period")
                                            .font(.headline)
                                            .foregroundStyle(.primary)

                                        Spacer()
                                    }

                                    Picker("Retention Period", selection: Binding(
                                        get: { store.currentPolicy },
                                        set: { store.send(.policyChanged($0)) }
                                    )) {
                                        ForEach(ChangeLogRetentionPolicy.allCases) { policy in
                                            Text(policy.displayName).tag(policy)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .background(.ultraThinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))

                                    Text("How long to keep shift change history")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }

                                Divider()

                                // Last Purge Date
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "clock.badge.exclamationmark")
                                            .foregroundStyle(.orange)
                                            .font(.title3)

                                        Text("Last Purged")
                                            .font(.headline)
                                            .foregroundStyle(.primary)

                                        Spacer()
                                    }

                                    if let lastPurge = store.lastPurgeDate {
                                        Text(lastPurge, style: .relative) + Text(" ago")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)

                                        if store.lastPurgedCount > 0 {
                                            Text("\(store.lastPurgedCount) entries removed")
                                                .font(.caption2)
                                                .foregroundStyle(.tertiary)
                                        }
                                    } else {
                                        Text("Never")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Divider()

                                // Manual Purge Button
                                Button(action: {
                                    store.send(.purgeButtonTapped)
                                }) {
                                    HStack {
                                        Image(systemName: "trash.circle")
                                        Text("Purge Old Entries Now")
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(
                                                LinearGradient(
                                                    colors: [.orange, .orange.opacity(0.8)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
                                            .overlay {
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                                            }
                                    }
                                }
                                .disabled(store.currentPolicy == .forever)
                            }
                            .padding(4)
                        }
                        .padding(.horizontal, 24)
                    }
                    .offset(y: store.changeLogSectionAppeared ? 0 : 30)
                    .opacity(store.changeLogSectionAppeared ? 1 : 0)
                    .padding(.bottom, 24)

                    // Data Management section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Data Management")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 24)

                        GlassCard(cornerRadius: 16, blurMaterial: .regularMaterial) {
                            VStack(spacing: 20) {
                                HStack(spacing: 12) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.orange)
                                        .font(.title3)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Danger Zone")
                                            .font(.headline)
                                            .foregroundStyle(.primary)

                                        Text("Irreversible actions that affect your data")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()
                                }

                                Divider()

                                // Delete All Data button
                                Button(action: {
                                    store.send(.deleteAllDataButtonTapped)
                                }) {
                                    HStack {
                                        Image(systemName: "trash.fill")
                                        Text("Delete All Data")
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(
                                                LinearGradient(
                                                    colors: [.red, .red.opacity(0.8)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .shadow(color: .red.opacity(0.3), radius: 8, x: 0, y: 4)
                                            .overlay {
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                                            }
                                    }
                                }
                                .scaleEffect(isPressed ? 0.95 : 1.0)
                                .simultaneousGesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { _ in
                                            guard !UIAccessibility.isReduceMotionEnabled else { return }
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                                isPressed = true
                                            }
                                        }
                                        .onEnded { _ in
                                            guard !UIAccessibility.isReduceMotionEnabled else { return }
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                                isPressed = false
                                            }
                                        }
                                )
                            }
                            .padding(4)
                        }
                        .padding(.horizontal, 24)
                    }
                    .offset(y: store.dataManagementSectionAppeared ? 0 : 30)
                    .opacity(store.dataManagementSectionAppeared ? 1 : 0)

                    Spacer()
                        .frame(height: 40)
                }
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .presentationAlert(store: store)
            .onAppear {
                store.send(.onAppear)
            }
            .dismissKeyboardOnTap()
        }
    }
}

// MARK: - Alert Presentation Extension

extension View {
    @ViewBuilder
    func presentationAlert(store: StoreOf<SettingsFeature>) -> some View {
        self.alert(
            item: Binding(
                get: { store.alertItem },
                set: { _ in store.send(.alertDismissed) }
            )
        ) { alertItem in
            switch alertItem.actionStyle {
            case .default:
                Alert(
                    title: Text(alertItem.title),
                    message: Text(alertItem.message),
                    dismissButton: .default(Text(alertItem.actionTitle)) {
                        store.send(alertItem.action)
                    }
                )
            case .destructive:
                Alert(
                    title: Text(alertItem.title),
                    message: Text(alertItem.message),
                    primaryButton: .destructive(Text(alertItem.actionTitle)) {
                        store.send(alertItem.action)
                    },
                    secondaryButton: .cancel()
                )
            case .cancel:
                Alert(
                    title: Text(alertItem.title),
                    message: Text(alertItem.message),
                    dismissButton: .cancel()
                )
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(store: Store(initialState: SettingsFeature.State()) {
            SettingsFeature()
        })
    }
}

