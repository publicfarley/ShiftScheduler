import SwiftUI

/// A reusable shift card component used across multiple screens (Today, Schedule, etc.)
/// Displays detailed shift information in a professional card layout
/// Supports selection mode for multi-select operations with long-press gesture
struct UnifiedShiftCard: View {
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
        guard let shift = shift else {
            return .upcoming
        }

        let now = Date()

        // Use actual start/end date-times for multi-day shift support
        let shiftStart = shift.actualStartDateTime()
        let shiftEnd = shift.actualEndDateTime()

        // Determine status based on current time relative to shift date-time range
        if now < shiftStart {
            return .upcoming
        } else if now >= shiftStart && now <= shiftEnd {
            return .active
        } else {
            return .completed
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

                    // Main content - 2-column compact layout
                    HStack(spacing: 12) {
                        // Left column: Symbol + Title/Description
                        VStack(alignment: .leading, spacing: 4) {
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

                            // Title and description below symbol
                            VStack(alignment: .leading, spacing: 2) {
                                Text(shiftType.title)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)

                                // Compact description
                                if !shiftType.shiftDescription.isEmpty {
                                    Text(shiftType.shiftDescription)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                        }

                        // Right column: Time, Location, Address
                        VStack(alignment: .trailing, spacing: 4) {
                            // Time badge
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.caption)
                                    .foregroundColor(cardColor)

                                Text(shiftType.timeRangeString)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(cardColor)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(cardColor.opacity(0.08))
                            )

                            // Location details stacked
                            let location = shiftType.location
                            VStack(alignment: .trailing, spacing: 2) {
                                // Location name
                                HStack(spacing: 4) {
                                    Image(systemName: "location")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text(location.name)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }

                                // Location address - single line with truncation
                                if !location.address.isEmpty {
                                    HStack(spacing: 4) {
                                        Image(systemName: "mappin.and.ellipse")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        Text(location.address)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                            }
                        }

                        Spacer()
                    }

                    // User notes - full width if present
                    if let notes = shift.notes, !notes.isEmpty {
                        HStack(alignment: .top, spacing: 4) {
                            Image(systemName: "note.text")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(notes)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Notes: \(notes)")
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
                        .stroke(
                            isSelected ? Color.blue : cardColor,
                            lineWidth: isSelected ? 3 : 2.5
                        )
                )
                .shadow(color: isSelected ? Color.blue.opacity(0.3) : cardColor.opacity(0.15), radius: 6, x: 0, y: 3)
        )
        .overlay(alignment: .topTrailing) {
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.headline)
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

        // If in selection mode, toggle selection instead of calling onTap
        if isInSelectionMode, let shiftId = shift?.id {
            onSelectionToggle?(shiftId)
        } else {
            // Normal tap behavior
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

    private func handleLongPress() {
        // Long press to enter selection mode (if not already in it)
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

        UnifiedShiftCard(
            shift: sampleShift,
            onTap: { print("Shift tapped!") },
            isSelected: false,
            onSelectionToggle: nil,
            isInSelectionMode: false
        )

        Text("Shift with notes:")
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.top, 8)

        UnifiedShiftCard(
            shift: sampleShiftWithNotes,
            onTap: { print("Shift with notes tapped!") },
            isSelected: false,
            onSelectionToggle: nil,
            isInSelectionMode: false
        )

        Text("Selected state:")
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.top, 8)

        UnifiedShiftCard(
            shift: sampleShiftWithNotes,
            onTap: nil,
            isSelected: true,
            onSelectionToggle: { _ in print("Selection toggled") },
            isInSelectionMode: true
        )

        Text("Empty state:")
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.top, 8)

        UnifiedShiftCard(
            shift: nil,
            onTap: nil,
            isSelected: false,
            onSelectionToggle: nil,
            isInSelectionMode: false
        )
    }
    .padding()
}
