import SwiftUI

/// Card Design 3: Split-Panel Design
/// 40% left panel with large symbol and gradient background, status badge overlay
/// 60% right panel with all text details stacked
/// Clean vertical divider between panels
struct CardDesign3: View {
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
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        // Left panel (40%) - Large symbol with gradient background
                        ZStack(alignment: .topLeading) {
                            // Gradient background
                            LinearGradient(
                                colors: [gradientColors.0, gradientColors.1],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )

                            // Symbol centered
                            Text(shiftType.symbol)
                                .font(.system(size: 56))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)

                            // Status badge overlay (top-left)
                            StatusBadge(status: shiftStatus)
                                .padding(10)
                        }
                        .frame(width: geometry.size.width * 0.4)

                        // Vertical divider
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .frame(width: 1)

                        // Right panel (60%) - All text details
                        VStack(alignment: .leading, spacing: 10) {
                            // Title
                            Text(shiftType.title)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .fixedSize(horizontal: false, vertical: true)

                            // Time with icon
                            HStack(spacing: 6) {
                                Image(systemName: "clock.fill")
                                    .font(.caption)
                                    .foregroundColor(cardColor)

                                Text(shiftType.timeRangeString)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                            }

                            // Location name and address
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
                                        .fixedSize(horizontal: false, vertical: true)
                                        .padding(.leading, 20)
                                }
                            }

                            // Description
                            if !shiftType.shiftDescription.isEmpty {
                                Text(shiftType.shiftDescription)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.top, 2)
                            }

                            // Notes
                            if let notes = shift.notes, !notes.isEmpty {
                                Divider()
                                    .padding(.vertical, 4)

                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "note.text")
                                            .font(.caption2)
                                            .foregroundColor(cardColor)

                                        Text("Notes")
                                            .font(.caption2)
                                            .fontWeight(.semibold)
                                            .foregroundColor(cardColor)
                                    }

                                    Text(notes)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemBackground))
                    }
                }
                .frame(height: calculateCardHeight(shift: shift))
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
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            isSelected ? Color.blue : Color(.systemGray5),
                            lineWidth: isSelected ? 3 : 1
                        )
                )
                .shadow(
                    color: isSelected ? Color.blue.opacity(0.3) : Color.black.opacity(0.1),
                    radius: 8,
                    x: 0,
                    y: 4
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
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

    private func calculateCardHeight(shift: ScheduledShift) -> CGFloat {
        var height: CGFloat = 160

        if let shiftType = shift.shiftType {
            if !shiftType.shiftDescription.isEmpty {
                height += 20
            }

            if !shiftType.location.address.isEmpty {
                height += 20
            }
        }

        if let notes = shift.notes, !notes.isEmpty {
            height += 50
        }

        return height
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
    let sampleLocation = Location(id: UUID(), name: "North Campus", address: "456 University Ave, Building C")
    let sampleShiftType = ShiftType(
        id: UUID(),
        symbol: "☀️",
        duration: .scheduled(
            from: HourMinuteTime(hour: 8, minute: 0),
            to: HourMinuteTime(hour: 16, minute: 0)
        ),
        title: "Day Shift",
        description: "Standard daytime operations",
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
        notes: "Team meeting at 10 AM in conference room B. Prepare monthly reports."
    )

    return ScrollView {
        VStack(spacing: 20) {
            Text("Design 3: Split-Panel Design")
                .font(.title3)
                .fontWeight(.bold)

            CardDesign3(shift: sampleShift)

            CardDesign3(shift: sampleShiftWithNotes)

            CardDesign3(shift: sampleShiftWithNotes, isSelected: true, isInSelectionMode: true)

            CardDesign3(shift: nil)
        }
        .padding()
    }
}
