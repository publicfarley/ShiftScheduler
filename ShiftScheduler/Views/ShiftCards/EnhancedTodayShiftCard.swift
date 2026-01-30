import SwiftUI

// MARK: - Enhanced Today Shift Card with Visual Prominence

struct EnhancedTodayShiftCard: View {
    let shift: ScheduledShift?
    @State private var isPressed = false
    @State private var pulseOpacity = 0.3

    private var shiftStatus: ShiftStatus {
        guard let shift = shift else { return .upcoming }

        let now = Date()

        // Use actual start/end date-times for multi-day shift support
        let shiftStart = shift.actualStartDateTime()
        let shiftEnd = shift.actualEndDateTime()

        // Determine status based on current time relative to shift date-time range
        if now < shiftStart {
            return .upcoming
        } else if now >= shiftStart && now <= shiftEnd {
            return .active
        } else {
            return .completed
        }
    }

    private var cardColor: Color {
        guard let shiftType = shift?.shiftType else { return Color(red: 0.2, green: 0.35, blue: 0.5) }

        let hash = shiftType.symbol.hashValue
        let vibrantColors: [Color] = [
            Color(red: 0.1, green: 0.5, blue: 0.8),   // Vibrant Blue
            Color(red: 0.2, green: 0.7, blue: 0.5),   // Emerald Green
            Color(red: 0.8, green: 0.4, blue: 0.2),   // Warm Orange
            Color(red: 0.6, green: 0.3, blue: 0.8),   // Purple
            Color(red: 0.8, green: 0.3, blue: 0.5),   // Magenta
            Color(red: 0.3, green: 0.7, blue: 0.7)    // Teal
        ]
        return vibrantColors[abs(hash) % vibrantColors.count]
    }

    var body: some View {
        VStack(spacing: 0) {
            if let shift = shift, let shiftType = shift.shiftType {
                // Enhanced design with gradients and prominence
                VStack(alignment: .leading, spacing: 16) {
                    // Status badge with enhanced styling
                    HStack {
                        EnhancedStatusBadge(status: shiftStatus)
                        Spacer()
                    }

                    // Main content with enhanced layout
                    HStack(spacing: 16) {
                        // Enhanced symbol with gradient background
                        Text(shiftType.symbol)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [cardColor, cardColor.opacity(0.7)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(.white.opacity(0.2), lineWidth: 2)
                                    )
                                    .shadow(color: cardColor.opacity(0.4), radius: 8, x: 0, y: 4)
                            )

                        // Enhanced shift details
                        VStack(alignment: .leading, spacing: 8) {
                            Text(shiftType.title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)

                            if !shiftType.shiftDescription.isEmpty {
                                Text(shiftType.shiftDescription)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }

                            // Enhanced time badge
                            HStack(spacing: 6) {
                                Image(systemName: "clock.fill")
                                    .font(.caption)
                                    .foregroundColor(.white)

                                Text(shiftType.timeRangeString)
                                    .font(.callout)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(cardColor)
                                    .shadow(color: cardColor.opacity(0.3), radius: 4, x: 0, y: 2)
                            )

                            // Enhanced location
                            let location = shiftType.location
                            HStack(spacing: 6) {
                                Image(systemName: "location.fill")
                                    .font(.caption)
                                    .foregroundColor(cardColor)
                                Text(location.name)
                                    .font(.callout)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()
                    }
                }
                .padding(20)

                // Enhanced active indicator with pulse animation
                if shiftStatus == .active {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [cardColor, cardColor.opacity(0.6)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 4)
                        .opacity(pulseOpacity)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                                pulseOpacity = 0.8
                            }
                        }
                }
            } else {
                // Enhanced empty state
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(.systemGray5), Color(.systemGray6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)

                        Image(systemName: "calendar.badge.plus")
                            .font(.title)
                            .foregroundColor(.secondary)
                    }

                    VStack(spacing: 6) {
                        Text("No shift scheduled")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        Text("Perfect day for rest or planning ahead")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .padding(.horizontal, 20)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: shift != nil ? [cardColor.opacity(0.3), cardColor.opacity(0.1)] : [Color(.systemGray4), Color(.systemGray5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: shift != nil ? cardColor.opacity(0.15) : .black.opacity(0.05), radius: 12, x: 0, y: 6)
        )
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isPressed)
        .onTapGesture {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()

            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isPressed = true
            }

            Task {
                try await Task.sleep(nanoseconds: 150_000_000)
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isPressed = false
                }
            }
        }
    }
}
