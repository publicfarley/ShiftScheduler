import SwiftUI

/// Card Design 9: Card with Inline Status Timeline
/// Horizontal 3-dot status timeline at top (Upcoming → Active → Completed)
/// Current status filled, others hollow, connecting lines between dots
/// Symbol in circle (left, below timeline)
/// Vertical stack (center): Title, Time + duration, Location + address, Description
/// Notes at bottom (full width), clean, minimal design
struct CardDesign9: View {
    let shift: ScheduledShift?
    let onTap: (() -> Void)?
    let isSelected: Bool
    let onSelectionToggle: ((UUID) -> Void)?
    let isInSelectionMode: Bool

    @State private var isPressed = false

    init(
        shift: ScheduledShift?,
        onTap: (() -> Void)? = nil,
        isSelected: Bool = false,
        onSelectionToggle: ((UUID) -> Void)? = nil,
        isInSelectionMode: Bool = false
    ) {
        self.shift = shift
        self.onTap = onTap
        self.isSelected = isSelected
        self.onSelectionToggle = onSelectionToggle
        self.isInSelectionMode = isInSelectionMode
    }

    private var shiftStatus: ShiftStatus {
        guard let shift = shift else { return .upcoming }

        let now = Date()
        let shiftStart = shift.actualStartDateTime()
        let shiftEnd = shift.actualEndDateTime()

        if now < shiftStart {
            return .upcoming
        } else if now >= shiftStart && now <= shiftEnd {
            return .active
        } else {
            return .completed
        }
    }

    private var cardColor: Color {
        guard let shiftType = shift?.shiftType else {
            return Color(red: 0.2, green: 0.35, blue: 0.5)
        }
        return ShiftColorPalette.colorForShift(shiftType)
    }

    var body: some View {
        VStack(spacing: 0) {
            if let shift = shift, let shiftType = shift.shiftType {
                VStack(alignment: .leading, spacing: 16) {
                    // Horizontal 3-dot status timeline at top
                    StatusTimeline(currentStatus: shiftStatus, color: cardColor)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                    // Content section
                    HStack(alignment: .top, spacing: 16) {
                        // Symbol in circle (left)
                        Text(shiftType.symbol)
                            .font(.system(size: 36))
                            .frame(width: 64, height: 64)
                            .background(
                                Circle()
                                    .fill(cardColor.opacity(0.15))
                            )

                        // Vertical stack (center): Title, Time, Location, Description
                        VStack(alignment: .leading, spacing: 10) {
                            // Title
                            Text(shiftType.title)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            // Time + duration
                            HStack(spacing: 6) {
                                Image(systemName: "clock")
                                    .font(.caption)
                                    .foregroundColor(cardColor)

                                Text(shiftType.timeRangeString)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)

                                if let duration = shiftType.duration.durationInHours {
                                    Text("(\(String(format: "%.1f", duration))h)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            // Location + address
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Image(systemName: "location.fill")
                                        .font(.caption)
                                        .foregroundColor(cardColor)

                                    Text(shiftType.location.name)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                }

                                if !shiftType.location.address.isEmpty {
                                    Text(shiftType.location.address)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.leading, 18)
                                }
                            }

                            // Description
                            if !shiftType.shiftDescription.isEmpty {
                                Text(shiftType.shiftDescription)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 16)

                    // Notes at bottom (full width)
                    if let notes = shift.notes, !notes.isEmpty {
                        Divider()
                            .padding(.horizontal, 16)

                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "note.text")
                                .font(.caption)
                                .foregroundColor(cardColor)

                            Text(notes)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)

                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    } else {
                        Spacer()
                            .frame(height: 16)
                    }
                }

            } else {
                // Empty state
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
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            isSelected ? Color.blue : Color(.separator).opacity(0.3),
                            lineWidth: isSelected ? 3 : 1
                        )
                )
                .shadow(
                    color: isSelected ? Color.blue.opacity(0.2) : Color.black.opacity(0.05),
                    radius: isSelected ? 8 : 4,
                    x: 0,
                    y: 2
                )
        )
        .overlay(alignment: .topTrailing) {
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.blue)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(Color(.systemBackground))
                    )
                    .offset(x: 8, y: -8)
            }
        }
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .onTapGesture {
            handleTap()
        }
        .onLongPressGesture {
            handleLongPress()
        }
    }

    private func handleTap() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()

        if isInSelectionMode, let shiftId = shift?.id {
            onSelectionToggle?(shiftId)
        } else {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                isPressed = true
            }

            Task {
                try? await Task.sleep(seconds: 0.1)
                await MainActor.run {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                        isPressed = false
                    }
                    onTap?()
                }
            }
        }
    }

    private func handleLongPress() {
        guard !isInSelectionMode, let shiftId = shift?.id else { return }

        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        onSelectionToggle?(shiftId)
    }
}

// MARK: - Status Timeline Component

struct StatusTimeline: View {
    let currentStatus: ShiftStatus
    let color: Color

    var body: some View {
        HStack(spacing: 0) {
            // Upcoming
            TimelineNode(
                isActive: currentStatus == .upcoming,
                label: "Upcoming",
                color: color,
                showLeadingLine: false,
                showTrailingLine: true
            )

            // Active
            TimelineNode(
                isActive: currentStatus == .active,
                label: "Active",
                color: color,
                showLeadingLine: true,
                showTrailingLine: true
            )

            // Completed
            TimelineNode(
                isActive: currentStatus == .completed,
                label: "Completed",
                color: color,
                showLeadingLine: true,
                showTrailingLine: false
            )
        }
    }
}

struct TimelineNode: View {
    let isActive: Bool
    let label: String
    let color: Color
    let showLeadingLine: Bool
    let showTrailingLine: Bool

    var body: some View {
        HStack(spacing: 0) {
            // Leading line
            if showLeadingLine {
                Rectangle()
                    .fill(isActive ? color : Color(.separator))
                    .frame(height: 2)
                    .frame(maxWidth: .infinity)
            }

            // Node
            VStack(spacing: 4) {
                Circle()
                    .fill(isActive ? color : Color.clear)
                    .overlay(
                        Circle()
                            .strokeBorder(isActive ? color : Color(.separator), lineWidth: 2)
                    )
                    .frame(width: 12, height: 12)

                Text(label)
                    .font(.caption2)
                    .foregroundColor(isActive ? color : .secondary)
            }
            .padding(.horizontal, 8)

            // Trailing line
            if showTrailingLine {
                Rectangle()
                    .fill(isActive ? color : Color(.separator))
                    .frame(height: 2)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Preview

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
        description: "Regular morning shift with team meetings",
        location: sampleLocation
    )

    let sampleShift = ScheduledShift(
        id: UUID(),
        eventIdentifier: UUID().uuidString,
        shiftType: sampleShiftType,
        date: Date(),
        notes: nil
    )

    let sampleShiftWithNotes = ScheduledShift(
        id: UUID(),
        eventIdentifier: UUID().uuidString,
        shiftType: sampleShiftType,
        date: Date(),
        notes: "Remember to bring safety equipment and laptop for the client meeting."
    )

    return ScrollView {
        VStack(spacing: 20) {
            Text("Design 9: Card with Inline Status Timeline")
                .font(.title3)
                .fontWeight(.bold)

            CardDesign9(shift: sampleShift)

            CardDesign9(shift: sampleShiftWithNotes)

            CardDesign9(shift: sampleShiftWithNotes, isSelected: true, isInSelectionMode: true)

            CardDesign9(shift: nil)
        }
        .padding()
    }
}
