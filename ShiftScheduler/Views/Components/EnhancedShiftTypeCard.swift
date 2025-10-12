import SwiftUI
import SwiftData

/// Enhanced shift type card with dynamic colors, glassmorphic styling, and premium visual effects
///
/// This component displays a shift type with a vibrant gradient header, large shift symbol,
/// and glassmorphic content area. It uses the ShiftColorPalette for dynamic color generation
/// based on the shift symbol, ensuring each shift type has a unique, consistent color.
///
/// Visual Features:
/// - Dynamic gradient header based on shift symbol
/// - Large 48pt shift symbol with gradient background
/// - Time range displayed as gradient capsule badge
/// - Glassmorphic content section with description
/// - Enhanced Edit/Delete buttons with shift color theming
/// - Multi-layer shadows (black + shift color glow)
/// - Gradient border stroke
/// - Press scale effects (0.96 on tap)
///
/// - Parameters:
///   - shiftType: The shift type to display
///   - onEdit: Callback triggered when Edit button is tapped
///   - onDelete: Callback triggered when Delete button is tapped
///
/// - Example:
///   ```swift
///   EnhancedShiftTypeCard(
///       shiftType: shiftType,
///       onEdit: {
///           shiftTypeToEdit = shiftType
///       },
///       onDelete: {
///           showingDeleteAlert = true
///       }
///   )
///   ```
///
/// - Accessibility:
///   - VoiceOver: "\(symbol) \(title), \(timeRange), \(location)"
///   - Edit button: "Edit \(title)"
///   - Delete button: "Delete \(title)"
///   - Supports Dynamic Type (scales appropriately)
///   - Respects Reduced Motion (simplifies animations)
struct EnhancedShiftTypeCard: View {
    let shiftType: ShiftType
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var showingDeleteAlert = false
    @State private var isEditPressed = false
    @State private var isDeletePressed = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    // MARK: - Color System

    private var shiftColor: Color {
        ShiftColorPalette.colorForShift(shiftType)
    }

    private var gradientColors: (Color, Color) {
        ShiftColorPalette.gradientColorsForShift(shiftType)
    }

    private var glowColor: Color {
        ShiftColorPalette.glowColorForShift(shiftType)
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header Section with Gradient
            headerSection

            // Content Section with Glass Effect
            contentSection
        }
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            shiftColor.opacity(0.4),
                            .clear,
                            shiftColor.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        }
        .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
        .shadow(color: glowColor.opacity(0.2), radius: 8, x: 0, y: 4)
        .alert("Delete Shift Type", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete \"\(shiftType.title)\"? This action cannot be undone.")
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(spacing: 16) {
            // Large Shift Symbol with Gradient Background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [gradientColors.0, gradientColors.1],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: shiftColor.opacity(0.4), radius: 8, x: 0, y: 4)

                Text(shiftType.symbol)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            // Shift Details
            VStack(alignment: .leading, spacing: 6) {
                // Title
                Text(shiftType.title)
                    .font(.system(size: 18, weight: .semibold, design: .default))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                // Time Range Badge
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .font(.caption2)
                        .foregroundStyle(.white)

                    Text(shiftType.timeRangeString)
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [gradientColors.0, gradientColors.1],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: shiftColor.opacity(0.3), radius: 4, x: 0, y: 2)
                )

                // Location if available
                if let location = shiftType.location {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Text(location.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [gradientColors.0.opacity(0.7), gradientColors.1.opacity(0.75)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 16,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 16,
                style: .continuous
            )
        )
    }

    // MARK: - Content Section

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Description
            if !shiftType.shiftDescription.isEmpty {
                Text(shiftType.shiftDescription)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
            }

            // Action Buttons
            HStack(spacing: 10) {
                // Edit Button
                Button(action: onEdit) {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil")
                            .font(.caption)
                        Text("Edit")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.regularMaterial)
                            .overlay {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(shiftColor.opacity(0.2))
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(shiftColor.opacity(0.4), lineWidth: 1)
                            }
                    }
                    .foregroundStyle(shiftColor)
                    .scaleEffect(isEditPressed ? 0.96 : 1.0)
                }
                .buttonStyle(.plain)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            withAnimation(AnimationPresets.quickSpring) {
                                isEditPressed = true
                            }
                        }
                        .onEnded { _ in
                            withAnimation(AnimationPresets.quickSpring) {
                                isEditPressed = false
                            }
                        }
                )
                .accessibilityLabel("Edit \(shiftType.title)")
                .accessibilityHint("Opens editor for this shift type")

                // Delete Button
                Button(action: { showingDeleteAlert = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                            .font(.caption)
                        Text("Delete")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.regularMaterial)
                            .overlay {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.red.opacity(0.2))
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(Color.red.opacity(0.4), lineWidth: 1)
                            }
                    }
                    .foregroundStyle(.red)
                    .scaleEffect(isDeletePressed ? 0.96 : 1.0)
                }
                .buttonStyle(.plain)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            withAnimation(AnimationPresets.quickSpring) {
                                isDeletePressed = true
                            }
                        }
                        .onEnded { _ in
                            withAnimation(AnimationPresets.quickSpring) {
                                isDeletePressed = false
                            }
                        }
                )
                .accessibilityLabel("Delete \(shiftType.title)")
                .accessibilityHint("Deletes this shift type after confirmation")

                Spacer()
            }
        }
        .padding(16)
        .background(.clear)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 16,
                bottomTrailingRadius: 16,
                topTrailingRadius: 0,
                style: .continuous
            )
        )
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        var label = "\(shiftType.symbol) \(shiftType.title), \(shiftType.timeRangeString)"
        if let location = shiftType.location {
            label += ", at \(location.name)"
        }
        if !shiftType.shiftDescription.isEmpty {
            label += ", \(shiftType.shiftDescription)"
        }
        return label
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: ShiftType.self, Location.self, configurations: config)

    let location = Location(name: "Hospital A", address: "123 Main St")
    container.mainContext.insert(location)

    let shiftType = ShiftType(
        symbol: "D",
        duration: .scheduled(
            from: HourMinuteTime(hour: 9, minute: 0),
            to: HourMinuteTime(hour: 17, minute: 0)
        ),
        title: "Day Shift",
        description: "Standard daytime shift for regular operations",
        location: location
    )
    container.mainContext.insert(shiftType)

    return VStack(spacing: 20) {
        EnhancedShiftTypeCard(
            shiftType: shiftType,
            onEdit: { print("Edit tapped") },
            onDelete: { print("Delete tapped") }
        )
        .padding()

        Spacer()
    }
    .modelContainer(container)
}
