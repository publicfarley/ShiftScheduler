import SwiftUI
/// Card Design 10: Layered Depth Card
/// Multiple elevation levels with shadows
/// Floating symbol container (8pt elevation, top-left) with large symbol in colored circle and heavy shadow
/// Main content (right of symbol): Title with inline status badge, elevated time pill,
/// location in subtle inset area (recessed look), description
/// Notes in separate elevated section at bottom
struct CardDesign10: View {
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
                VStack(alignment: .leading, spacing: 0) {
                    // Main content area
                    HStack(alignment: .top, spacing: 16) {
                        // Floating symbol container (8pt elevation, top-left)
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
                            .shadow(color: cardColor.opacity(0.5), radius: 12, x: 0, y: 8)
                            .shadow(color: cardColor.opacity(0.3), radius: 4, x: 0, y: 2)

                        // Main content (right of symbol)
                        VStack(alignment: .leading, spacing: 12) {
                            // Title with inline status badge
                            HStack(spacing: 8) {
                                Text(shiftType.title)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)

                                // Inline status badge
                                HStack(spacing: 3) {
                                    Circle()
                                        .fill(shiftStatus.color)
                                        .frame(width: 5, height: 5)

                                    Text(shiftStatus.displayName)
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundColor(shiftStatus.color)
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(shiftStatus.color.opacity(0.1))
                                )
                            }

                            // Elevated time pill (4pt elevation)
                            HStack(spacing: 6) {
                                Image(systemName: "clock.fill")
                                    .font(.caption)
                                    .foregroundColor(cardColor)

                                Text(shiftType.timeRangeString)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)

                                if let duration = shiftType.duration.durationInHours {
                                    Text("(\(String(format: "%.1f", duration))h)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                            )

                            // Location in subtle inset area (recessed look)
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(cardColor.opacity(0.7))

                                    Text(shiftType.location.name)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                }

                                if !shiftType.location.address.isEmpty {
                                    Text(shiftType.location.address)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.leading, 20)
                                }
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        Color(.systemGray6)
                                            .shadow(.inner(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1))
                                    )
                            )

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
                    .padding(20)

                    // Notes in separate elevated section at bottom
                    if let notes = shift.notes, !notes.isEmpty {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "note.text")
                                .font(.caption)
                                .foregroundColor(cardColor)

                            Text(notes)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)

                            Spacer(minLength: 0)
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(cardColor.opacity(0.06))
                                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: -1)
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
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
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(
                            isSelected ? Color.blue : Color.clear,
                            lineWidth: isSelected ? 3 : 0
                        )
                )
                .shadow(
                    color: isSelected ? Color.blue.opacity(0.3) : Color.black.opacity(0.08),
                    radius: isSelected ? 10 : 6,
                    x: 0,
                    y: isSelected ? 6 : 3
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
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    )
                    .offset(x: 8, y: -8)
            }
        }
        .scaleEffect(isPressed ? 0.97 : 1.0)
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
        description: "Regular morning shift with team meetings and client presentations",
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
        notes: "Remember to bring safety equipment and laptop for the client meeting. Review presentation slides beforehand."
    )

    return ScrollView {
        VStack(spacing: 20) {
            Text("Design 10: Layered Depth Card")
                .font(.title3)
                .fontWeight(.bold)

            CardDesign10(shift: sampleShift)

            CardDesign10(shift: sampleShiftWithNotes)

            CardDesign10(shift: sampleShiftWithNotes, isSelected: true, isInSelectionMode: true)

            CardDesign10(shift: nil)
        }
        .padding()
    }
}
