
import SwiftUI

struct AboutView: View {
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

                Text("Version 1.0 (Build 1)")
                    .font(.footnote)
                    .foregroundColor(.gray)

                Text("© 2025 Farley Caesar")
                    .font(.footnote)
                    .foregroundColor(.gray)

                HStack(spacing: 30) {
                    Image(systemName: "star.fill")
                        .resizable()
                        .frame(width: 25, height: 25)
                        .foregroundColor(.blue)
                    Image(systemName: "heart.fill")
                        .resizable()
                        .frame(width: 25, height: 25)
                        .foregroundColor(.pink)
                    Image(systemName: "leaf.fill")
                        .resizable()
                        .frame(width: 25, height: 25)
                        .foregroundColor(.green)
                }
                .padding(.bottom, 50) // Add some padding to push it up from the bottom tab bar

                Spacer()
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
