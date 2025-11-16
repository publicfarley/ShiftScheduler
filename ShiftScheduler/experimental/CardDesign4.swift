import SwiftUI

/// Card Design 4: Glassmorphic Floating Card
/// .ultraThinMaterial background with frosted effect
/// Symbol centered top (large, no background circle)
/// Title centered below, horizontal icon row for status/time/location
/// Description centered, address bar at bottom with darker background
struct CardDesign4: View {
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
                VStack(spacing: 16) {
                    // Symbol centered top (large, no background)
                    Text(shiftType.symbol)
                        .font(.system(size: 64))
                        .padding(.top, 20)

                    // Title centered
                    Text(shiftType.title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    // Horizontal icon row: Status | Time | Location
                    HStack(spacing: 20) {
                        // Status
                        VStack(spacing: 6) {
                            Image(systemName: shiftStatus.icon)
                                .font(.title3)
                                .foregroundColor(shiftStatus.color)

                            Text(shiftStatus.displayName)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(shiftStatus.color)
                        }
                        .frame(maxWidth: .infinity)

                        Divider()
                            .frame(height: 40)

                        // Time
                        VStack(spacing: 6) {
                            Image(systemName: "clock.fill")
                                .font(.title3)
                                .foregroundColor(cardColor)

                            Text(shiftType.timeRangeString)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)

                        Divider()
                            .frame(height: 40)

                        // Location
                        VStack(spacing: 6) {
                            Image(systemName: "location.fill")
                                .font(.title3)
                                .foregroundColor(cardColor)

                            Text(shiftType.location.name)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 16)

                    // Description centered
                    if !shiftType.shiftDescription.isEmpty {
                        Text(shiftType.shiftDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 20)
                    }

                    // Notes (if present)
                    if let notes = shift.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 4) {
                                Image(systemName: "note.text")
                                    .font(.caption2)
                                    .foregroundColor(cardColor)

                                Text("Notes")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(cardColor)

                                Spacer()
                            }

                            Text(notes)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(cardColor.opacity(0.08))
                        )
                        .padding(.horizontal, 16)
                    }

                    Spacer(minLength: 12)
                }

                // Address bar bottom (darker background)
                if !shiftType.location.address.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.caption)
                            .foregroundColor(.white)

                        Text(shiftType.location.address)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        Rectangle()
                            .fill(cardColor.opacity(0.9))
                    )
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
            ZStack {
                // Glassmorphic background with tint
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(cardColor.opacity(0.05))
                    )

                // Border overlay
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(
                        LinearGradient(
                            colors: isSelected
                                ? [Color.blue, Color.blue.opacity(0.6)]
                                : [cardColor.opacity(0.3), cardColor.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isSelected ? 3 : 1.5
                    )
            }
            .shadow(
                color: isSelected ? Color.blue.opacity(0.3) : cardColor.opacity(0.15),
                radius: 12,
                x: 0,
                y: 6
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
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
    let sampleLocation = Location(id: UUID(), name: "West Building", address: "789 Innovation Drive, Tech Park")
    let sampleShiftType = ShiftType(
        id: UUID(),
        symbol: "🌆",
        duration: .scheduled(
            from: HourMinuteTime(hour: 14, minute: 0),
            to: HourMinuteTime(hour: 22, minute: 0)
        ),
        title: "Evening Shift",
        description: "Evening operations and customer support",
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
        notes: "Handle customer inquiries and prepare end-of-day reports. Manager on call."
    )

    return ZStack {
        // Background gradient to show glassmorphic effect
        LinearGradient(
            colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        ScrollView {
            VStack(spacing: 20) {
                Text("Design 4: Glassmorphic Floating Card")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.ultraThinMaterial)
                    )

                CardDesign4(shift: sampleShift)

                CardDesign4(shift: sampleShiftWithNotes)

                CardDesign4(shift: sampleShiftWithNotes, isSelected: true, isInSelectionMode: true)

                CardDesign4(shift: nil)
            }
            .padding()
        }
    }
}
