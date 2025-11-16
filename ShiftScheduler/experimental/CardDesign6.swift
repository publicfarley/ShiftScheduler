import SwiftUI

/// Card Design 6: Card with Header Banner
/// Colored gradient header banner (full width) with status badge left, title center/left, symbol right
/// White body section with large clock icon + time, description, location, and notes
/// Gradient background shifts between darker and lighter tones
struct CardDesign6: View {
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
                // Header Banner with Gradient Background
                HStack(alignment: .center, spacing: 12) {
                    // Status badge (left)
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 6, height: 6)

                        Text(shiftStatus.displayName)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.25))
                    )

                    // Title (center-left, white text)
                    Text(shiftType.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    // Symbol (right)
                    Text(shiftType.symbol)
                        .font(.title2)
                }
                .padding(16)
                .background(
                    LinearGradient(
                        colors: [gradientColors.0, gradientColors.1],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

                // White Body Section
                VStack(alignment: .leading, spacing: 16) {
                    // Large clock icon + time (prominent)
                    HStack(spacing: 12) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 32))
                            .foregroundColor(cardColor)
                            .frame(width: 48, height: 48)
                            .background(
                                Circle()
                                    .fill(cardColor.opacity(0.1))
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Shift Time")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text(shiftType.timeRangeString)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }

                        Spacer(minLength: 0)
                    }

                    // Description (full width)
                    if !shiftType.shiftDescription.isEmpty {
                        Text(shiftType.shiftDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Location section with icon, name, and address
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.body)
                                .foregroundColor(cardColor)

                            Text(shiftType.location.name)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }

                        if !shiftType.location.address.isEmpty {
                            Text(shiftType.location.address)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.leading, 26)
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )

                    // Notes with icon
                    if let notes = shift.notes, !notes.isEmpty {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "note.text")
                                .font(.caption)
                                .foregroundColor(cardColor)

                            Text(notes)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(cardColor.opacity(0.05))
                        )
                    }
                }
                .padding(16)
                .background(Color(.systemBackground))

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
                            isSelected ? Color.blue : cardColor.opacity(0.2),
                            lineWidth: isSelected ? 3 : 1
                        )
                )
                .shadow(
                    color: isSelected ? Color.blue.opacity(0.3) : Color.black.opacity(0.1),
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
            Text("Design 6: Card with Header Banner")
                .font(.title3)
                .fontWeight(.bold)

            CardDesign6(shift: sampleShift)

            CardDesign6(shift: sampleShiftWithNotes)

            CardDesign6(shift: sampleShiftWithNotes, isSelected: true, isInSelectionMode: true)

            CardDesign6(shift: nil)
        }
        .padding()
    }
}
