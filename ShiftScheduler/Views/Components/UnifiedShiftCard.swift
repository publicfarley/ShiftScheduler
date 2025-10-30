import SwiftUI

/// A reusable shift card component used across multiple screens (Today, Schedule, etc.)
/// Displays detailed shift information in a professional card layout
struct UnifiedShiftCard: View {
    let shift: ScheduledShift?
    let onTap: (() -> Void)?

    @State private var isPressed = false

    private var shiftStatus: ShiftStatus {
        guard let shift = shift, let shiftType = shift.shiftType else { return .upcoming }

        let now = Date()
        let calendar = Calendar.current

        // Check if shift is today
        if calendar.isDate(shift.date, inSameDayAs: now) {
            switch shiftType.duration {
            case .allDay:
                return .active
            case .scheduled(let startTime, let endTime):
                let shiftStart = startTime.toDate(on: shift.date)
                let shiftEnd = endTime.toDate(on: shift.date)

                if now < shiftStart {
                    return .upcoming
                } else if now >= shiftStart && now <= shiftEnd {
                    return .active
                } else {
                    return .completed
                }
            }
        } else if shift.date < now {
            return .completed
        } else {
            return .upcoming
        }
    }

    private var cardColor: Color {
        guard let shiftType = shift?.shiftType else { return Color(red: 0.2, green: 0.35, blue: 0.5) }

        // Use professional, muted color palette
        let hash = shiftType.symbol.hashValue
        let professionalColors: [Color] = [
            Color(red: 0.2, green: 0.35, blue: 0.5),   // Professional Blue
            Color(red: 0.25, green: 0.4, blue: 0.35),  // Forest Green
            Color(red: 0.4, green: 0.35, blue: 0.3),   // Warm Brown
            Color(red: 0.35, green: 0.3, blue: 0.4),   // Slate Purple
            Color(red: 0.4, green: 0.3, blue: 0.35),   // Muted Burgundy
            Color(red: 0.3, green: 0.4, blue: 0.4)     // Teal
        ]
        return professionalColors[abs(hash) % professionalColors.count]
    }

    var body: some View {
        VStack(spacing: 0) {
            if let shift = shift, let shiftType = shift.shiftType {
                // Has shift scheduled - Enhanced design
                VStack(alignment: .leading, spacing: 12) {
                    // Status badge - simplified
                    HStack {
                        StatusBadge(status: shiftStatus)
                        Spacer()
                    }

                    // Main content - cleaner, more professional layout
                    HStack(spacing: 14) {
                        // Symbol - simple circle without gradient
                        Text(shiftType.symbol)
                            .font(.title2)
                            .foregroundColor(cardColor)
                            .frame(width: 48, height: 48)
                            .background(
                                Circle()
                                    .fill(cardColor.opacity(0.08))
                                    .overlay(
                                        Circle()
                                            .stroke(cardColor.opacity(0.15), lineWidth: 1)
                                    )
                            )

                        // Shift details
                        VStack(alignment: .leading, spacing: 6) {
                            Text(shiftType.title)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            // Add missing description
                            if !shiftType.shiftDescription.isEmpty {
                                Text(shiftType.shiftDescription)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }

                            // Time - simplified badge
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.caption)
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
                                    .fill(cardColor.opacity(0.08))
                            )

                            // Location name
                            let location = shiftType.location
                            HStack(spacing: 4) {
                                Image(systemName: "location")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(location.name)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            // Location address
                            if !location.address.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "mappin.and.ellipse")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text(location.address)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                            }

                            // User notes
                            if let notes = shift.notes, !notes.isEmpty {
                                HStack(alignment: .top, spacing: 4) {
                                    Image(systemName: "note.text")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text(notes)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(3)
                                }
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("Notes: \(notes)")
                            }
                        }

                        Spacer()
                    }
                }
                .padding(16)

                // Active shift indicator - subtle
                if shiftStatus == .active {
                    Rectangle()
                        .fill(cardColor.opacity(0.3))
                        .frame(height: 2)
                }
            } else {
                // No shift scheduled - Professional empty state
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                        .frame(width: 56, height: 56)
                        .background(
                            Circle()
                                .fill(Color(.systemGray6))
                        )

                    VStack(spacing: 4) {
                        Text("No shift scheduled")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text("Add shifts in the Schedule tab")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .padding(.horizontal, 16)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(cardColor, lineWidth: 2.5)
                )
                .shadow(color: cardColor.opacity(0.15), radius: 6, x: 0, y: 3)
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onTapGesture {
            // Add haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()

            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                isPressed = true
            }

            Task {
                try await Task.sleep(seconds: 0.1)
                withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                    isPressed = false
                }

                // Call the onTap handler if provided
                onTap?()
            }
        }
    }
}

#Preview {
    let sampleLocation = Location(id: UUID(), name: "Main Office", address: "123 Main St, Suite 100")
    let sampleShiftType = ShiftType(
        id: UUID(),
        symbol: "🌅",
        duration: .scheduled(
            from: HourMinuteTime(hour: 9, minute: 0),
            to: HourMinuteTime(hour: 17, minute: 0)
        ),
        title: "Morning Shift",
        description: "Regular morning shift with breaks",
        location: sampleLocation
    )

    // Shift without notes
    let sampleShift = ScheduledShift(
        id: UUID(),
        eventIdentifier: UUID().uuidString,
        shiftType: sampleShiftType,
        date: Date(),
        notes: nil
    )

    // Shift with notes - demonstrates the notes feature
    let sampleShiftWithNotes = ScheduledShift(
        id: UUID(),
        eventIdentifier: UUID().uuidString,
        shiftType: sampleShiftType,
        date: Date(),
        notes: "Remember to bring safety equipment and laptop. Client meeting at 2 PM."
    )

    VStack(spacing: 16) {
        Text("Shift without notes:")
            .font(.caption)
            .foregroundColor(.secondary)

        UnifiedShiftCard(shift: sampleShift, onTap: {
            print("Shift tapped!")
        })

        Text("Shift with notes:")
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.top, 8)

        UnifiedShiftCard(shift: sampleShiftWithNotes, onTap: {
            print("Shift with notes tapped!")
        })

        Text("Empty state:")
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.top, 8)

        UnifiedShiftCard(shift: nil, onTap: nil)
    }
    .padding()
}
