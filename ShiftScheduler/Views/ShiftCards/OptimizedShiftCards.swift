import SwiftUI

// MARK: - Optimized Today Shift Card

struct OptimizedTodayShiftCard: View {
    let shift: ScheduledShift?

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
        guard let shiftType = shift?.shiftType else { return .blue }

        // Create color based on shift symbol hash for consistency
        let hash = shiftType.symbol.hashValue
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .red, .indigo, .teal, .cyan, .mint]
        return colors[abs(hash) % colors.count]
    }

    var body: some View {
        VStack(spacing: 0) {
            if let shift = shift, let shiftType = shift.shiftType {
                VStack(alignment: .leading, spacing: 12) {
                    // Status badge
                    HStack {
                        StatusBadge(status: shiftStatus)
                        Spacer()
                    }

                    // Main content
                    HStack(spacing: 14) {
                        // Symbol with gradient background
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [cardColor.opacity(0.2), cardColor.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 50, height: 50)

                            Text(shiftType.symbol)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(cardColor)
                        }

                        // Shift details
                        VStack(alignment: .leading, spacing: 5) {
                            Text(shiftType.title)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            // Time range with enhanced styling
                            HStack(spacing: 5) {
                                Image(systemName: "clock")
                                    .font(.caption2)
                                    .foregroundColor(cardColor)

                                Text(shiftType.timeRangeString)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(cardColor)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(cardColor.opacity(0.1))
                                    .overlay(
                                        Capsule()
                                            .stroke(cardColor.opacity(0.3), lineWidth: 1)
                                    )
                            )

                            // Location with icon
                            let location = shiftType.location
                            HStack(spacing: 4) {
                                Image(systemName: "location.fill")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)

                                Text(location.name)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            if !shiftType.location.address.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "mappin.and.ellipse")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)

                                    Text(shiftType.location.address)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            // Shift description
                            if !shiftType.shiftDescription.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "text.alignleft")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)

                                    Text(shiftType.shiftDescription)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.leading)
                                }
                            }
                        }

                        Spacer()
                    }
                }
                .padding(16)

                // Active shift indicator
                if shiftStatus == .active {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [cardColor.opacity(0.3), cardColor.opacity(0.1)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 4)
                }
            } else {
                // Empty state
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
                            .frame(width: 72, height: 72)

                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary)
                    }

                    VStack(spacing: 6) {
                        Text("No shift scheduled")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        Text("Perfect day for rest or planning ahead")
                            .font(.subheadline)
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
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(cardColor.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Optimized Tomorrow Shift Card

struct OptimizedTomorrowShiftCard: View {
    let shift: ScheduledShift?

    private var cardColor: Color {
        guard let shiftType = shift?.shiftType else { return .blue }

        // Create color based on shift symbol hash for consistency
        let hash = shiftType.symbol.hashValue
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .red, .indigo, .teal, .cyan, .mint]
        return colors[abs(hash) % colors.count]
    }

    var body: some View {
        VStack(spacing: 0) {
            if let shift = shift, let shiftType = shift.shiftType {
                VStack(spacing: 12) {
                    // Tomorrow label
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "moon.stars.fill")
                                .font(.caption)
                                .foregroundColor(.indigo)

                            Text("Tomorrow")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.indigo)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(.indigo.opacity(0.1))
                        )

                        Spacer()
                    }

                    // Main content
                    HStack(spacing: 14) {
                        // Symbol with gradient background
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [cardColor.opacity(0.2), cardColor.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 50, height: 50)

                            Text(shiftType.symbol)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(cardColor)
                        }

                        // Shift details
                        VStack(alignment: .leading, spacing: 5) {
                            Text(shiftType.title)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            // Time range with enhanced styling
                            HStack(spacing: 5) {
                                Image(systemName: "clock")
                                    .font(.caption2)
                                    .foregroundColor(cardColor)

                                Text(shiftType.timeRangeString)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(cardColor)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(cardColor.opacity(0.1))
                                    .overlay(
                                        Capsule()
                                            .stroke(cardColor.opacity(0.3), lineWidth: 1)
                                    )
                            )

                            // Location with icon
                            let location = shiftType.location
                            HStack(spacing: 4) {
                                Image(systemName: "location.fill")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)

                                Text(location.name)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            if !shiftType.location.address.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "mappin.and.ellipse")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)

                                    Text(shiftType.location.address)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            // Shift description
                            if !shiftType.shiftDescription.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "text.alignleft")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)

                                    Text(shiftType.shiftDescription)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.leading)
                                }
                            }
                        }

                        Spacer()
                    }
                }
                .padding(16)
            } else {
                // Empty state
                VStack(spacing: 14) {
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "moon.stars.fill")
                                .font(.caption)
                                .foregroundColor(.indigo)

                            Text("Tomorrow")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.indigo)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(.indigo.opacity(0.1))
                        )

                        Spacer()
                    }

                    HStack(spacing: 14) {
                        // Empty state icon
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

                        VStack(alignment: .leading, spacing: 5) {
                            Text("No shift scheduled")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)

                            Text("A well-deserved day off awaits")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                }
                .padding(16)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(cardColor.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}
