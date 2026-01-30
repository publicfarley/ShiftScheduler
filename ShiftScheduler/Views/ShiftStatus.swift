import SwiftUI

// MARK: - Shift Status Enumeration

enum ShiftStatus {
    case upcoming
    case active
    case completed
    case cancelled

    var displayName: String {
        switch self {
        case .upcoming: return "Upcoming"
        case .active: return "Active"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }

    var color: Color {
        switch self {
        case .upcoming: return .blue
        case .active: return .green
        case .completed: return .gray
        case .cancelled: return .red
        }
    }

    var icon: String {
        switch self {
        case .upcoming: return "clock"
        case .active: return "play.circle.fill"
        case .completed: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle.fill"
        }
    }
}

// MARK: - Status Badge Component

struct StatusBadge: View {
    let status: ShiftStatus

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(status.color)
                .frame(width: 6, height: 6)

            Text(status.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(status.color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(status.color.opacity(0.08))
        )
    }
}

// MARK: - Enhanced Status Badge

struct EnhancedStatusBadge: View {
    let status: ShiftStatus
    @State private var glowOpacity = 0.3

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)
                .shadow(color: status.color.opacity(glowOpacity), radius: 4, x: 0, y: 0)
                .onAppear {
                    if status == .active {
                        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                            glowOpacity = 0.8
                        }
                    }
                }

            Text(status.displayName)
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundColor(status.color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(status.color.opacity(0.12))
                .overlay(
                    Capsule()
                        .stroke(status.color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}
