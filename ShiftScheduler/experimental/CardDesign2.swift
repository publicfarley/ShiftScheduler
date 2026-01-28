import SwiftUI

/// Card Design 2: Timeline Card with Leading Edge Accent
/// Thick vertical accent bar (left edge), header row with status/title/location
/// Symbol inline with time, full address on separate line, expandable notes
struct CardDesign2: View {
    let shift: ScheduledShift?
    let onTap: (() -> Void)?
    let isSelected: Bool
    let onSelectionToggle: ((UUID) -> Void)?
    let isInSelectionMode: Bool

    @State private var isPressed = false
    @State private var notesExpanded = false

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
            if let shift = shift, shift.isSickDay {
                // Shift marked as sick day - Show sick day card
                SickDayCardView(shift: shift, onTap: onTap)
            } else if let shift = shift, let shiftType = shift.shiftType {
                HStack(spacing: 0) {
                    // Thick vertical accent bar (4-6pt)
                    Rectangle()
                        .fill(cardColor)
                        .frame(width: 5)

                    // Content area
                    VStack(alignment: .leading, spacing: 12) {
                        // Header row: Status badge + Title + Location name
                        HStack(alignment: .top, spacing: 12) {
                            StatusBadge(status: shiftStatus)

                            Text(shiftType.title)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .lineLimit(2)

                            Spacer(minLength: 0)

                            // Location name (right aligned)
                            HStack(spacing: 4) {
                                Image(systemName: "location.fill")
                                    .font(.caption2)
                                    .foregroundColor(cardColor)
                                Text(shiftType.location.name)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                            }
                        }

                        // Symbol inline with time range (prominent)
                        HStack(spacing: 8) {
                            Text(shiftType.symbol)
                                .font(.title2)

                            Text(shiftType.timeRangeString)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(cardColor)

                            Spacer(minLength: 0)
                        }

                        // Description
                        if !shiftType.shiftDescription.isEmpty {
                            Text(shiftType.shiftDescription)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        // Full address on separate line
                        if !shiftType.location.address.isEmpty {
                            HStack(alignment: .top, spacing: 4) {
                                Image(systemName: "mappin.and.ellipse")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)

                                Text(shiftType.location.address)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)

                                Spacer(minLength: 0)
                            }
                        }

                        // Expandable notes section
                        if let notes = shift.notes, !notes.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Button(action: {
                                    withAnimation(.spring(response: 0.3)) {
                                        notesExpanded.toggle()
                                    }
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "note.text")
                                            .font(.caption2)
                                            .foregroundColor(cardColor)

                                        Text("Notes")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(cardColor)

                                        Spacer()

                                        Image(systemName: notesExpanded ? "chevron.up" : "chevron.down")
                                            .font(.caption2)
                                            .foregroundColor(cardColor)
                                    }
                                }
                                .buttonStyle(.plain)

                                if notesExpanded {
                                    Text(notes)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .padding(.top, 4)
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                            .padding(.top, 4)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(cardColor.opacity(0.05))
                            )
                        }
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
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
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isSelected ? Color.blue : Color(.systemGray5),
                            lineWidth: isSelected ? 3 : 1
                        )
                )
                .shadow(
                    color: isSelected ? Color.blue.opacity(0.3) : Color.black.opacity(0.08),
                    radius: 6,
                    x: 0,
                    y: 3
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
    let sampleLocation = Location(id: UUID(), name: "Main Office", address: "123 Main St, Suite 100, Downtown")
    let sampleShiftType = ShiftType(
        id: UUID(),
        symbol: "🌙",
        duration: .scheduled(
            from: HourMinuteTime(hour: 22, minute: 0),
            to: HourMinuteTime(hour: 6, minute: 0)
        ),
        title: "Night Shift",
        description: "Overnight monitoring and security",
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
        notes: "Remember to bring flashlight and security badge. Check all doors at midnight."
    )

    return ScrollView {
        VStack(spacing: 20) {
            Text("Design 2: Timeline Card with Leading Edge Accent")
                .font(.title3)
                .fontWeight(.bold)

            CardDesign2(shift: sampleShift)

            CardDesign2(shift: sampleShiftWithNotes)

            CardDesign2(shift: sampleShiftWithNotes, isSelected: true, isInSelectionMode: true)

            CardDesign2(shift: nil)
        }
        .padding()
    }
}
