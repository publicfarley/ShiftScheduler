import SwiftUI

/// Component for displaying a shift marked as sick day
/// Shows orange thermometer icon with "Out Sick" status
struct SickDayCardView: View {
    let shift: ScheduledShift
    let onTap: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .center, spacing: 12) {
                // Orange thermometer icon in circular background
                Image(systemName: "thermometer.medium")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.orange)
                    .frame(width: 56, height: 56)
                    .background(
                        Circle()
                            .fill(Color.orange.opacity(0.15))
                    )

                // Out Sick text
                VStack(spacing: 4) {
                    Text("Out Sick")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)

                    Text("Tap to see details & edit")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .padding(.horizontal, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            Color(.systemGray3).opacity(0.3),
                            lineWidth: 1
                        )
                )
        )
        .onTapGesture {
            onTap?()
        }
    }
}
