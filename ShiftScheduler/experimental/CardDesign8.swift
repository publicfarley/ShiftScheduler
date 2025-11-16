import SwiftUI

/// Card Design 8: Metro/Tile Style
/// Flat colored background (entire card, shift color - no gradients), all text white or very light
/// Symbol large (top-left), title huge, bold, white (can take 3-4 lines)
/// Status badge (bottom-left, white border, transparent bg), time (bottom-right, white, bold)
/// Tap to show details in overlay/modal
struct CardDesign8: View {
    let shift: ScheduledShift?
    let onTap: (() -> Void)?
    let isSelected: Bool
    let onSelectionToggle: ((UUID) -> Void)?
    let isInSelectionMode: Bool

    @State private var isPressed = false
    @State private var showDetails = false

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
                    // Top section: Symbol
                    HStack {
                        Text(shiftType.symbol)
                            .font(.system(size: 52))
                            .padding(.leading, 20)
                            .padding(.top, 20)

                        Spacer()
                    }

                    // Middle section: Title (huge, bold, white)
                    HStack {
                        Text(shiftType.title)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(4)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)

                        Spacer()
                    }

                    Spacer()

                    // Bottom section: Status badge and time
                    HStack(alignment: .bottom) {
                        // Status badge (bottom-left, white border, transparent bg)
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 6, height: 6)

                            Text(shiftStatus.displayName)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .strokeBorder(Color.white, lineWidth: 1.5)
                                .background(Capsule().fill(Color.white.opacity(0.15)))
                        )

                        Spacer()

                        // Time (bottom-right, white, bold)
                        Text(shiftType.timeRangeString)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .padding(20)
                }
                .frame(minHeight: 200)
                .background(cardColor)

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
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    isSelected ? Color.white : Color.clear,
                    lineWidth: isSelected ? 4 : 0
                )
        )
        .shadow(
            color: isSelected ? Color.white.opacity(0.4) : Color.black.opacity(0.2),
            radius: isSelected ? 12 : 6,
            x: 0,
            y: 4
        )
        .overlay(alignment: .topTrailing) {
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(
                        Circle()
                            .fill(cardColor.opacity(0.9))
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.white, lineWidth: 2)
                            )
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
        .sheet(isPresented: $showDetails) {
            if let shift = shift, let shiftType = shift.shiftType {
                ShiftDetailsSheet(shift: shift, shiftType: shiftType)
            }
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

                    // Show details sheet
                    if shift != nil {
                        showDetails = true
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

// MARK: - Details Sheet

struct ShiftDetailsSheet: View {
    let shift: ScheduledShift
    let shiftType: ShiftType
    @Environment(\.dismiss) private var dismiss

    private var cardColor: Color {
        ShiftColorPalette.colorForShift(shiftType)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Symbol and Title
                    HStack(spacing: 16) {
                        Text(shiftType.symbol)
                            .font(.system(size: 60))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(shiftType.title)
                                .font(.title2)
                                .fontWeight(.bold)

                            Text(shiftType.timeRangeString)
                                .font(.subheadline)
                                .foregroundColor(cardColor)
                        }

                        Spacer()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(cardColor.opacity(0.1))
                    )

                    // Description
                    if !shiftType.shiftDescription.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.headline)
                                .foregroundColor(.secondary)

                            Text(shiftType.shiftDescription)
                                .font(.body)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                    }

                    // Location
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Location")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        HStack(spacing: 8) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title3)
                                .foregroundColor(cardColor)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(shiftType.location.name)
                                    .font(.body)
                                    .fontWeight(.semibold)

                                if !shiftType.location.address.isEmpty {
                                    Text(shiftType.location.address)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )

                    // Notes
                    if let notes = shift.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.headline)
                                .foregroundColor(.secondary)

                            Text(notes)
                                .font(.body)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(cardColor.opacity(0.08))
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Shift Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
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
            Text("Design 8: Metro/Tile Style")
                .font(.title3)
                .fontWeight(.bold)

            CardDesign8(shift: sampleShift)

            CardDesign8(shift: sampleShiftWithNotes)

            CardDesign8(shift: sampleShiftWithNotes, isSelected: true, isInSelectionMode: true)

            CardDesign8(shift: nil)
        }
        .padding()
    }
}
