import SwiftUI

/// Card Design 5: Horizontal Compact Strip
/// Single row layout ~70-80pt height when collapsed
/// Symbol left (small 40pt circle), title + time stacked, status badge center-right, location far right
/// Expandable to show full details including description, address, and notes
struct CardDesign5: View {
    let shift: ScheduledShift?
    let onTap: (() -> Void)?
    let isSelected: Bool
    let onSelectionToggle: ((UUID) -> Void)?
    let isInSelectionMode: Bool

    @State private var isPressed = false
    @State private var isExpanded = false

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
                VStack(spacing: 0) {
                    // Compact row (always visible)
                    HStack(spacing: 12) {
                        // Symbol left (small 40pt circle)
                        Text(shiftType.symbol)
                            .font(.title3)
                            .foregroundColor(cardColor)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(cardColor.opacity(0.12))
                                    .overlay(
                                        Circle()
                                            .stroke(cardColor.opacity(0.25), lineWidth: 1)
                                    )
                            )

                        // Vertical stack: Title + Time
                        VStack(alignment: .leading, spacing: 4) {
                            Text(shiftType.title)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .lineLimit(1)

                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)

                                Text(shiftType.timeRangeString)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer(minLength: 8)

                        // Status badge (center-right)
                        HStack(spacing: 4) {
                            Circle()
                                .fill(shiftStatus.color)
                                .frame(width: 6, height: 6)

                            Text(shiftStatus.displayName)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(shiftStatus.color)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(shiftStatus.color.opacity(0.1))
                        )

                        // Location (far right)
                        HStack(spacing: 4) {
                            Image(systemName: "location")
                                .font(.caption2)
                                .foregroundColor(cardColor)

                            Text(shiftType.location.name)
                                .font(.caption)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                        }
                        .frame(width: 80, alignment: .trailing)

                        // Expand/collapse chevron
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isExpanded.toggle()
                            }
                        }) {
                            Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle")
                                .font(.title3)
                                .foregroundColor(cardColor)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color(.systemBackground))

                    // Expanded details
                    if isExpanded {
                        VStack(alignment: .leading, spacing: 12) {
                            Divider()

                            // Description
                            if !shiftType.shiftDescription.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Description")
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(cardColor)

                                    Text(shiftType.shiftDescription)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }

                            // Full address
                            if !shiftType.location.address.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Address")
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(cardColor)

                                    HStack(alignment: .top, spacing: 6) {
                                        Image(systemName: "mappin.and.ellipse")
                                            .font(.caption)
                                            .foregroundColor(cardColor)

                                        Text(shiftType.location.address)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }

                            // Notes
                            if let notes = shift.notes, !notes.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Notes")
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(cardColor)

                                    HStack(alignment: .top, spacing: 6) {
                                        Image(systemName: "note.text")
                                            .font(.caption)
                                            .foregroundColor(cardColor)

                                        Text(notes)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }

                            // Shift duration info
                            HStack(spacing: 20) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Start Time")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)

                                    Text(shiftType.startTimeString)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("End Time")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)

                                    Text(shiftType.endTimeString)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                }

                                Spacer()
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                        .transition(.opacity.combined(with: .move(edge: .top)))
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
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isSelected ? Color.blue : cardColor.opacity(0.3),
                            lineWidth: isSelected ? 3 : 1.5
                        )
                )
                .shadow(
                    color: isSelected ? Color.blue.opacity(0.25) : Color.black.opacity(0.06),
                    radius: isExpanded ? 8 : 4,
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
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isExpanded)
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
    let sampleLocation = Location(id: UUID(), name: "HQ", address: "100 Corporate Blvd, Downtown District")
    let sampleShiftType = ShiftType(
        id: UUID(),
        symbol: "🏢",
        duration: .scheduled(
            from: HourMinuteTime(hour: 10, minute: 0),
            to: HourMinuteTime(hour: 18, minute: 0)
        ),
        title: "Office Shift",
        description: "Regular office hours with flexible lunch break",
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
        notes: "Department standup at 10:30 AM. Client presentation at 3 PM. Remember to update project timeline."
    )

    return ScrollView {
        VStack(spacing: 20) {
            Text("Design 5: Horizontal Compact Strip")
                .font(.title3)
                .fontWeight(.bold)

            Text("Tap chevron to expand")
                .font(.caption)
                .foregroundColor(.secondary)

            CardDesign5(shift: sampleShift)

            CardDesign5(shift: sampleShiftWithNotes)

            CardDesign5(shift: sampleShiftWithNotes, isSelected: true, isInSelectionMode: true)

            CardDesign5(shift: nil)
        }
        .padding()
    }
}
