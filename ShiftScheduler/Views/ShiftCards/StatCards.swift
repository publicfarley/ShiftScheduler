import SwiftUI

// MARK: - Week Stat View

struct WeekStatView: View {
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text("\(count)")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

// MARK: - Enhanced Week Stat View

struct EnhancedWeekStatView: View {
    let count: Int
    let label: String
    let color: Color
    let icon: String
    @State private var isPressed = false

    var body: some View {
        VStack(spacing: 8) {
            // Icon - simple professional design
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(color.opacity(0.08))
                )

            // Count and label
            VStack(spacing: 2) {
                Text("\(count)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Simple progress indicator
            if count > 0 {
                Rectangle()
                    .fill(color.opacity(0.3))
                    .frame(height: 2)
                    .cornerRadius(1)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray5), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onTapGesture {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()

            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                isPressed = true
            }

            Task {
                try await Task.sleep(nanoseconds: 100_000_000)
                withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                    isPressed = false
                }
            }
        }
    }
}

// MARK: - Optimized Week Stat View

struct OptimizedWeekStatView: View {
    let count: Int
    let label: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            // Icon
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(color.opacity(0.08))
                )

            // Count and label
            VStack(spacing: 2) {
                Text("\(count)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Simple progress indicator
            if count > 0 {
                Rectangle()
                    .fill(color.opacity(0.3))
                    .frame(height: 2)
                    .cornerRadius(1)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray5), lineWidth: 1)
                )
        )
    }
}

// MARK: - Compact Week Stat View

struct CompactWeekStatView: View {
    let count: Int
    let label: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundColor(color)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(color.opacity(0.08))
                )

            VStack(spacing: 1) {
                Text("\(count)")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if count > 0 {
                Rectangle()
                    .fill(color.opacity(0.3))
                    .frame(height: 2)
                    .cornerRadius(1)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(.systemGray5), lineWidth: 1)
                )
        )
    }
}
