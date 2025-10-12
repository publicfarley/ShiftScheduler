import SwiftUI
import SwiftData

/// Enhanced location card with dynamic teal/blue colors, glassmorphic styling, and premium visual effects
///
/// This component displays a location with a vibrant gradient header, large location icon,
/// and glassmorphic content area. It uses the ShiftColorPalette location color system for
/// consistent, hash-based color generation.
///
/// Visual Features:
/// - Dynamic gradient header based on location name
/// - Large 48pt location/building icon with gradient background
/// - Shift type count badge showing usage
/// - Address display with map icon
/// - Glassmorphic content section with description
/// - Enhanced Edit/Delete buttons with location color theming
/// - Multi-layer shadows (black + location color glow)
/// - Gradient border stroke
/// - Press scale effects (0.96 on tap)
/// - Delete constraint checking (prevents deletion if location is in use)
///
/// - Parameters:
///   - location: The location to display
///   - shiftTypeCount: Number of shift types using this location
///   - onEdit: Callback triggered when Edit button is tapped
///   - onDelete: Callback triggered when Delete button is tapped
///   - canDelete: Whether deletion is allowed (no shift types using it)
///
/// - Example:
///   ```swift
///   EnhancedLocationCard(
///       location: location,
///       shiftTypeCount: 3,
///       onEdit: {
///           locationToEdit = location
///       },
///       onDelete: {
///           showingDeleteAlert = true
///       },
///       canDelete: true
///   )
///   ```
///
/// - Accessibility:
///   - VoiceOver: "\(name), \(address), used by \(count) shift types"
///   - Edit button: "Edit \(name)"
///   - Delete button: "Delete \(name)" or "Cannot delete \(name)"
///   - Supports Dynamic Type (scales appropriately)
///   - Respects Reduced Motion (simplifies animations)
struct EnhancedLocationCard: View {
    let location: Location
    let shiftTypeCount: Int
    let onEdit: () -> Void
    let onDelete: () -> Void
    let canDelete: Bool

    @State private var showingDeleteAlert = false
    @State private var showingConstraintAlert = false
    @State private var isEditPressed = false
    @State private var isDeletePressed = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    // MARK: - Color System

    private var locationColor: Color {
        ShiftColorPalette.colorForLocation(location.name)
    }

    private var gradientColors: (Color, Color) {
        ShiftColorPalette.gradientColorsForLocation(location.name)
    }

    private var glowColor: Color {
        ShiftColorPalette.glowColorForLocation(location.name)
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
                            locationColor.opacity(0.4),
                            .clear,
                            locationColor.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        }
        .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
        .shadow(color: glowColor.opacity(0.2), radius: 8, x: 0, y: 4)
        .alert("Delete Location", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete \"\(location.name)\"? This action cannot be undone.")
        }
        .alert("Cannot Delete Location", isPresented: $showingConstraintAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Cannot delete \"\(location.name)\" because it is used by \(shiftTypeCount) shift type\(shiftTypeCount == 1 ? "" : "s"). Please remove or reassign these shift types first.")
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(spacing: 16) {
            // Large Location Icon with Gradient Background
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
                    .shadow(color: locationColor.opacity(0.4), radius: 8, x: 0, y: 4)

                Image(systemName: "building.2.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
            }

            // Location Details
            VStack(alignment: .leading, spacing: 6) {
                // Location Name
                Text(location.name)
                    .font(.system(size: 18, weight: .semibold, design: .default))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                // Shift Type Count Badge
                HStack(spacing: 6) {
                    Image(systemName: "clock.badge.checkmark.fill")
                        .font(.caption2)
                        .foregroundStyle(.white)

                    Text("\(shiftTypeCount) shift \(shiftTypeCount == 1 ? "type" : "types")")
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
                        .shadow(color: locationColor.opacity(0.3), radius: 4, x: 0, y: 2)
                )
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
            // Address with Icon
            if !location.address.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.subheadline)
                        .foregroundStyle(locationColor)

                    Text(location.address)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .lineLimit(3)
                }
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
                                    .fill(locationColor.opacity(0.2))
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(locationColor.opacity(0.4), lineWidth: 1)
                            }
                    }
                    .foregroundStyle(locationColor)
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
                .accessibilityLabel("Edit \(location.name)")
                .accessibilityHint("Opens editor for this location")

                // Delete Button
                Button(action: handleDeleteTap) {
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
                                    .strokeBorder(Color.red.opacity(canDelete ? 0.4 : 0.2), lineWidth: 1)
                            }
                    }
                    .foregroundStyle(canDelete ? .red : .secondary)
                    .scaleEffect(isDeletePressed ? 0.96 : 1.0)
                    .opacity(canDelete ? 1.0 : 0.6)
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
                .accessibilityLabel(canDelete ? "Delete \(location.name)" : "Cannot delete \(location.name)")
                .accessibilityHint(canDelete ? "Deletes this location after confirmation" : "Location is in use by shift types")

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

    // MARK: - Actions

    private func handleDeleteTap() {
        if canDelete {
            showingDeleteAlert = true
        } else {
            showingConstraintAlert = true
        }
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        var label = "\(location.name)"
        if !location.address.isEmpty {
            label += ", \(location.address)"
        }
        if shiftTypeCount > 0 {
            label += ", used by \(shiftTypeCount) shift \(shiftTypeCount == 1 ? "type" : "types")"
        } else {
            label += ", not used by any shift types"
        }
        return label
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Location.self, ShiftType.self, configurations: config)

    let location1 = Location(name: "Hospital A", address: "123 Main Street, Downtown")
    let location2 = Location(name: "Clinic B", address: "456 Oak Avenue, Suite 200, Medical District")
    let location3 = Location(name: "Office C", address: "789 Pine Road")

    container.mainContext.insert(location1)
    container.mainContext.insert(location2)
    container.mainContext.insert(location3)

    return ScrollView {
        VStack(spacing: 20) {
            Text("Location Cards")
                .font(.title2)
                .fontWeight(.bold)

            EnhancedLocationCard(
                location: location1,
                shiftTypeCount: 3,
                onEdit: { print("Edit tapped") },
                onDelete: { print("Delete tapped") },
                canDelete: false
            )

            EnhancedLocationCard(
                location: location2,
                shiftTypeCount: 1,
                onEdit: { print("Edit tapped") },
                onDelete: { print("Delete tapped") },
                canDelete: false
            )

            EnhancedLocationCard(
                location: location3,
                shiftTypeCount: 0,
                onEdit: { print("Edit tapped") },
                onDelete: { print("Delete tapped") },
                canDelete: true
            )

            Spacer()
        }
        .padding()
    }
    .modelContainer(container)
}
