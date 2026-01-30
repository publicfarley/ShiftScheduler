import SwiftUI

// MARK: - Multi-Shift Featuring Algorithm

/// Result of featuring algorithm determining which shift should be primary
struct ShiftFeaturingResult {
    let featuredShift: ScheduledShift
    let nonFeaturedShift: ScheduledShift
    let featuredPosition: FeaturedPosition

    enum FeaturedPosition {
        case left   // Featured shift is on left, other is on right
        case right  // Featured shift is on right, other is on left
    }
}

/// Determines which shift should be featured based on current time
/// - Parameters:
///   - shifts: Array of shifts (should contain exactly 2 shifts)
///   - currentTime: The current time to evaluate against
/// - Returns: ShiftFeaturingResult indicating which shift is featured and positioning
func determineFeaturedShift(shifts: [ScheduledShift], currentTime: Date) -> ShiftFeaturingResult? {
    guard shifts.count == 2 else { return nil }

    let shift1 = shifts[0]
    let shift2 = shifts[1]

    // Get actual start/end times for both shifts
    let shift1Start = shift1.actualStartDateTime()
    let shift1End = shift1.actualEndDateTime()
    let shift2Start = shift2.actualStartDateTime()
    let shift2End = shift2.actualEndDateTime()

    // Check if current time falls within shift1's boundaries
    let isWithinShift1 = currentTime >= shift1Start && currentTime <= shift1End

    // Check if current time falls within shift2's boundaries
    let isWithinShift2 = currentTime >= shift2Start && currentTime <= shift2End

    // Case 1: Current time is within shift1
    if isWithinShift1 {
        // shift1 is featured
        // Determine if shift2 is before or after shift1
        let position: ShiftFeaturingResult.FeaturedPosition = shift2End <= shift1Start ? .right : .left
        return ShiftFeaturingResult(featuredShift: shift1, nonFeaturedShift: shift2, featuredPosition: position)
    }

    // Case 2: Current time is within shift2
    if isWithinShift2 {
        // shift2 is featured
        // Determine if shift1 is before or after shift2
        let position: ShiftFeaturingResult.FeaturedPosition = shift1End <= shift2Start ? .right : .left
        return ShiftFeaturingResult(featuredShift: shift2, nonFeaturedShift: shift1, featuredPosition: position)
    }

    // Case 3: Current time is outside all shifts
    // Feature the shift whose start time is upcoming first
    if shift1Start > currentTime && shift2Start > currentTime {
        // Both shifts are in the future - feature the earlier one
        if shift1Start < shift2Start {
            // shift1 starts first
            let position: ShiftFeaturingResult.FeaturedPosition = .left
            return ShiftFeaturingResult(featuredShift: shift1, nonFeaturedShift: shift2, featuredPosition: position)
        } else {
            // shift2 starts first
            let position: ShiftFeaturingResult.FeaturedPosition = .left
            return ShiftFeaturingResult(featuredShift: shift2, nonFeaturedShift: shift1, featuredPosition: position)
        }
    } else if shift1Start > currentTime {
        // Only shift1 is upcoming
        let position: ShiftFeaturingResult.FeaturedPosition = .left
        return ShiftFeaturingResult(featuredShift: shift1, nonFeaturedShift: shift2, featuredPosition: position)
    } else if shift2Start > currentTime {
        // Only shift2 is upcoming
        let position: ShiftFeaturingResult.FeaturedPosition = .left
        return ShiftFeaturingResult(featuredShift: shift2, nonFeaturedShift: shift1, featuredPosition: position)
    }

    // Case 4: Both shifts are in the past - feature the most recent one
    if shift1End > shift2End {
        let position: ShiftFeaturingResult.FeaturedPosition = .left
        return ShiftFeaturingResult(featuredShift: shift1, nonFeaturedShift: shift2, featuredPosition: position)
    } else {
        let position: ShiftFeaturingResult.FeaturedPosition = .left
        return ShiftFeaturingResult(featuredShift: shift2, nonFeaturedShift: shift1, featuredPosition: position)
    }
}

// MARK: - Multi-Shift Carousel Component

struct MultiShiftCarousel: View {
    @Environment(\.reduxStore) var store
    let shifts: [ScheduledShift]
    @State private var scrollPosition: CGFloat = 0
    @State private var currentFeaturedIndex: Int = 0

    var body: some View {
        GeometryReader { geometry in
            // Make cards slightly narrower than screen width so next card peeks out (carousel effect)
            let cardWidth = geometry.size.width * 0.85  // 85% of screen width

            if shifts.isEmpty {
                EmptyShiftCard()
            } else if shifts.count == 1 {
                // Single shift - display centered with full width
                UnifiedShiftCard(
                    shift: shifts[0],
                    onTap: {
                        Task {
                            await store.dispatch(action: .schedule(.shiftTapped(shifts[0])))
                        }
                    }
                )
            } else if shifts.count == 2 {
                // Two shifts - use featuring algorithm with carousel
                let featuringResult = determineFeaturedShift(shifts: shifts, currentTime: Date())

                if let result = featuringResult {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            if result.featuredPosition == .right {
                                // Non-featured shift on left (slightly off-screen)
                                UnifiedShiftCard(
                                    shift: result.nonFeaturedShift,
                                    onTap: {
                                        Task {
                                            await store.dispatch(action: .schedule(.shiftTapped(result.nonFeaturedShift)))
                                        }
                                    }
                                )
                                    .frame(width: cardWidth)
                                    .opacity(0.6)
                                    .scaleEffect(0.95)

                                // Featured shift
                                UnifiedShiftCard(
                                    shift: result.featuredShift,
                                    onTap: {
                                        Task {
                                            await store.dispatch(action: .schedule(.shiftTapped(result.featuredShift)))
                                        }
                                    }
                                )
                                    .frame(width: cardWidth)
                            } else {
                                // Featured shift on left
                                UnifiedShiftCard(
                                    shift: result.featuredShift,
                                    onTap: {
                                        Task {
                                            await store.dispatch(action: .schedule(.shiftTapped(result.featuredShift)))
                                        }
                                    }
                                )
                                    .frame(width: cardWidth)

                                // Non-featured shift on right (slightly visible for peek effect)
                                UnifiedShiftCard(
                                    shift: result.nonFeaturedShift,
                                    onTap: {
                                        Task {
                                            await store.dispatch(action: .schedule(.shiftTapped(result.nonFeaturedShift)))
                                        }
                                    }
                                )
                                    .frame(width: cardWidth)
                                    .opacity(0.6)
                                    .scaleEffect(0.95)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .scrollTargetBehavior(.paging)
                } else {
                    // Fallback - show first shift
                    UnifiedShiftCard(
                        shift: shifts[0],
                        onTap: {
                            Task {
                                await store.dispatch(action: .schedule(.shiftTapped(shifts[0])))
                            }
                        }
                    )
                        .padding(.horizontal, 20)
                }
            } else {
                // More than 2 shifts - show in scrollable carousel
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(shifts) { shift in
                            UnifiedShiftCard(
                                shift: shift,
                                onTap: {
                                    Task {
                                        await store.dispatch(action: .schedule(.shiftTapped(shift)))
                                    }
                                }
                            )
                                .frame(width: cardWidth)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .scrollTargetBehavior(.paging)
            }
        }
    }
}

// MARK: - Compact Multi-Shift Carousel Component (for Tomorrow section)

struct CompactMultiShiftCarousel: View {
    let shifts: [ScheduledShift]

    var body: some View {
        if shifts.isEmpty {
            CompactHalfHeightShiftCard(shift: nil, onTap: nil)
        } else if shifts.count == 1 {
            // Single shift - display with full width
            CompactHalfHeightShiftCard(shift: shifts[0], onTap: nil)
        } else {
            // Multiple shifts - show in scrollable horizontal carousel
            GeometryReader { geometry in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(shifts) { shift in
                            CompactHalfHeightShiftCard(shift: shift, onTap: nil)
                                .frame(width: geometry.size.width * 0.85)  // 85% width for peek effect
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .scrollTargetBehavior(.paging)
            }
        }
    }
}

// MARK: - Empty Shift Card

struct EmptyShiftCard: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.largeTitle)
                .foregroundColor(.secondary)

            VStack(spacing: 4) {
                Text("No shift scheduled")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("Add today's shift or enjoy your day off")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        )
    }
}
