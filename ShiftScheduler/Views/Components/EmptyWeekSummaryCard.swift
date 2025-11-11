import SwiftUI

struct EmptyWeekSummaryCard: View {
    var onScheduleShifts: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
                .frame(width: 72, height: 72)
                .background(
                    Circle()
                        .fill(Color(.systemGray6))
                )

            VStack(spacing: 6) {
                Text("No shifts scheduled")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text("Plan your week ahead")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Button(action: onScheduleShifts) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.callout)

                    Text("Schedule Shifts")
                        .font(.callout)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .foregroundColor(.white)
                .background(
                    LinearGradient(
                        colors: [.blue, .indigo],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
                .shadow(
                    color: .black.opacity(0.05),
                    radius: 6,
                    x: 0,
                    y: 3
                )
        )
        .padding(.horizontal, 16)
    }
}

#Preview {
    EmptyWeekSummaryCard(onScheduleShifts: {})
}
