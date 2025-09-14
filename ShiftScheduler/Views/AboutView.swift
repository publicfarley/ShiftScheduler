
import SwiftUI
import SwiftData

struct AlertItem: Identifiable {
    let id = UUID()
    let title: Text
    let message: Text
    let primaryButton: Alert.Button
    let secondaryButton: Alert.Button?
}

struct AboutView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var alertItem: AlertItem?

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer()

                Image(systemName: "calendar.badge.clock")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .foregroundColor(.primary)

                Text("WorkEvents")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                HStack {
                    Image(systemName: "sparkle")
                        .foregroundColor(.gray)
                    Text("Created by Farley Caesar")
                        .font(.title2)
                    Image(systemName: "sparkle")
                        .foregroundColor(.gray)
                }

                Text("Developer")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Text("Streamline your work schedule management")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer()

                Button(action: {
                    self.alertItem = AlertItem(
                        title: Text("Are you sure?"),
                        message: Text("This will permanently delete all data."),
                        primaryButton: .destructive(Text("Delete")) {
                            self.deleteAllData()
                        },
                        secondaryButton: .cancel()
                    )
                }) {
                    Text("Delete All Data")
                        .foregroundColor(.red)
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.red, lineWidth: 1)
                        )
                }
                .padding(.bottom, 50) // Add some padding to push it up from the bottom tab bar

                Spacer()
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.large)
            .alert(item: $alertItem) { alertItem in
                if let secondaryButton = alertItem.secondaryButton {
                    return Alert(title: alertItem.title, message: alertItem.message, primaryButton: alertItem.primaryButton, secondaryButton: secondaryButton)
                } else {
                    return Alert(title: alertItem.title, message: alertItem.message, dismissButton: alertItem.primaryButton)
                }
            }
        }
    }

    private func deleteAllData() {
        do {
            try modelContext.delete(model: ScheduledShift.self)
            try modelContext.delete(model: ShiftType.self)
            try modelContext.delete(model: Location.self)
            self.alertItem = AlertItem(title: Text("Success"), message: Text("All data has been deleted successfully."), primaryButton: .default(Text("OK")), secondaryButton: nil)
        } catch {
            self.alertItem = AlertItem(title: Text("Error"), message: Text("Failed to delete all data: \(error.localizedDescription)"), primaryButton: .default(Text("OK")), secondaryButton: nil)
        }
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
