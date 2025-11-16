import SwiftUI

/// Card Design 1: Gradient Border with Floating Symbol
/// Large circular symbol with gradient background (left, floating with shadow)
/// Vertical stack (right): Title, Description, Time badge (colored capsule), Location
/// Status badge top-left, optional active indicator bar (bottom, animated gradient), notes section
struct CardDesign1: View {
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

    private var gradientColors: (Color, Color) {
        guard let shiftType = shift?.shiftType else {
            return (Color(red: 0.2, green: 0.35, blue: 0.5),
                    Color(red: 0.1, green: 0.25, blue: 0.4))
        }
        return ShiftColorPalette.gradientColorsForShift(shiftType)
    }

    var body: some View {
        VStack(spacing: 0) {
            if let shift = shift, let shiftType = shift.shiftType {
                HStack(alignment: .top, spacing: 16) {
                    // Large circular symbol with gradient background (floating with shadow)
                    Text(shiftType.symbol)
                        .font(.system(size: 42))
                        .foregroundColor(.white)
                        .frame(width: 80, height: 80)
                        .background(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [gradientColors.0, gradientColors.1],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .shadow(color: cardColor.opacity(0.4), radius: 8, x: 0, y: 4)

                    // Right side: Title, Description, Time badge, Location
                    VStack(alignment: .leading, spacing: 8) {
                        // Status badge
                        StatusBadge(status: shiftStatus)

                        // Title
                        Text(shiftType.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        // Description
                        if !shiftType.shiftDescription.isEmpty {
                            Text(shiftType.shiftDescription)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        // Time badge (colored capsule)
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.caption)
                                .foregroundColor(.white)

                            Text(shiftType.timeRangeString)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(cardColor)
                        )

                        // Location
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "location.fill")
                                    .font(.caption2)
                                    .foregroundColor(cardColor)
                                Text(shiftType.location.name)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                            }

                            if !shiftType.location.address.isEmpty {
                                Text(shiftType.location.address)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Spacer(minLength: 0)
                }
                .padding(16)

                // Notes section with icon
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
                    .padding(.vertical, 12)
                }

                // Active indicator bar (animated gradient)
                if shiftStatus == .active {
                    LinearGradient(
                        colors: [gradientColors.0, gradientColors.1, gradientColors.0],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 3)
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
                            LinearGradient(
                                colors: isSelected
                                    ? [Color.blue, Color.blue.opacity(0.6)]
                                    : [cardColor.opacity(0.3), cardColor.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: isSelected ? 3 : 2
                        )
                )
                .shadow(
                    color: isSelected ? Color.blue.opacity(0.3) : cardColor.opacity(0.15),
                    radius: 8,
                    x: 0,
                    y: 4
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
            Text("Design 1: Gradient Border with Floating Symbol")
                .font(.title3)
                .fontWeight(.bold)

            CardDesign1(shift: sampleShift)

            CardDesign1(shift: sampleShiftWithNotes)

            CardDesign1(shift: sampleShiftWithNotes, isSelected: true, isInSelectionMode: true)

            CardDesign1(shift: nil)
        }
        .padding()
    }
}
