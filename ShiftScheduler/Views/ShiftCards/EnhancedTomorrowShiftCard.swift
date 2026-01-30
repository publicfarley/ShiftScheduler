import SwiftUI

// MARK: - Enhanced Tomorrow Shift Card with Visual Prominence

struct EnhancedTomorrowShiftCard: View {
    let shift: ScheduledShift?
    @State private var isPressed = false
    @State private var shimmerOffset: CGFloat = -200

    private var cardColor: Color {
        guard let shiftType = shift?.shiftType else { return Color(red: 0.3, green: 0.4, blue: 0.7) }

        let hash = shiftType.symbol.hashValue
        let elegantColors: [Color] = [
            Color(red: 0.3, green: 0.4, blue: 0.7),   // Elegant Blue
            Color(red: 0.3, green: 0.6, blue: 0.5),   // Sophisticated Green
            Color(red: 0.7, green: 0.5, blue: 0.3),   // Warm Amber
            Color(red: 0.5, green: 0.3, blue: 0.7),   // Rich Purple
            Color(red: 0.7, green: 0.3, blue: 0.5),   // Rose
            Color(red: 0.3, green: 0.6, blue: 0.6)    // Turquoise
        ]
        return elegantColors[abs(hash) % elegantColors.count]
    }

    var body: some View {
        VStack(spacing: 0) {
            if let shift = shift, let shiftType = shift.shiftType {
                // Enhanced design with modern visual effects
                VStack(alignment: .leading, spacing: 14) {
                    // Tomorrow badge with enhanced styling
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "moon.stars.fill")
                                .font(.caption)
                                .foregroundColor(.white)

                            Text("Tomorrow")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.indigo, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: .indigo.opacity(0.3), radius: 4, x: 0, y: 2)
                        )

                        Spacer()
                    }

                    // Main content with enhanced layout
                    HStack(spacing: 14) {
                        // Enhanced symbol with sophisticated design
                        Text(shiftType.symbol)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [cardColor, cardColor.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(.white.opacity(0.15), lineWidth: 1)
                                    )
                                    .shadow(color: cardColor.opacity(0.3), radius: 6, x: 0, y: 3)
                            )

                        // Enhanced shift details
                        VStack(alignment: .leading, spacing: 6) {
                            Text(shiftType.title)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                                .lineLimit(1)

                            if !shiftType.shiftDescription.isEmpty {
                                Text(shiftType.shiftDescription)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }

                            // Enhanced time display
                            HStack(spacing: 5) {
                                Image(systemName: "clock.fill")
                                    .font(.caption2)
                                    .foregroundColor(cardColor)

                                Text(shiftType.timeRangeString)
                                    .font(.callout)
                                    .fontWeight(.semibold)
                                    .foregroundColor(cardColor)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(cardColor.opacity(0.12))
                                    .overlay(
                                        Capsule()
                                            .stroke(cardColor.opacity(0.25), lineWidth: 1)
                                    )
                            )

                            // Enhanced location
                            let location = shiftType.location
                            HStack(spacing: 4) {
                                Image(systemName: "location.fill")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)

                                Text(location.name)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }

                        Spacer()
                    }
                }
                .padding(18)
            } else {
                // Enhanced empty state for tomorrow
                VStack(spacing: 14) {
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "moon.stars.fill")
                                .font(.caption)
                                .foregroundColor(.white)

                            Text("Tomorrow")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.indigo, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: .indigo.opacity(0.3), radius: 4, x: 0, y: 2)
                        )

                        Spacer()
                    }

                    HStack(spacing: 14) {
                        // Enhanced empty state icon
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(.systemGray5), Color(.systemGray6)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 50, height: 50)

                            Image(systemName: "bed.double.fill")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("No shift scheduled")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)

                            Text("A well-deserved day off awaits")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                }
                .padding(18)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            LinearGradient(
                                colors: shift != nil ? [cardColor.opacity(0.25), cardColor.opacity(0.1)] : [Color(.systemGray4), Color(.systemGray5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: shift != nil ? cardColor.opacity(0.1) : .black.opacity(0.04), radius: 8, x: 0, y: 4)
        )
        .overlay(
            // Subtle shimmer effect
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.1), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 60)
                .offset(x: shimmerOffset)
                .clipped()
                .onAppear {
                    withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: false)) {
                        shimmerOffset = 400
                    }
                }
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isPressed)
        .onTapGesture {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()

            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isPressed = true
            }

            Task {
                try await Task.sleep(nanoseconds: 120_000_000)
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isPressed = false
                }
            }
        }
    }
}
