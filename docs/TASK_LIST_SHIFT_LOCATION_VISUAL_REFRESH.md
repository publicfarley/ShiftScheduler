# Task List: Shift Types & Locations Visual Refresh

**Feature Branch:** `feature/shift-type-location-visual-refresh`
**Based on PRD:** `PRD_SHIFT_TYPE_LOCATION_VISUAL_REFRESH.md`
**Reference Implementation:** ShiftChangeSheet enhancements
**Target Completion:** TBD
**Estimated Time:** 12-17 hours

---

## Overview

Apply the premium Liquid Glass UI visual language from ShiftChangeSheet to the Shift Types and Locations management screens, matching the visual quality of the Today and Calendar tab shift cards.

**Key Visual Changes:**
- Dynamic color system using ShiftColorPalette
- Glassmorphic card styling with gradient borders
- Large gradient shift symbols (48pt)
- Staggered entrance animations
- Enhanced buttons with glass effects
- Multi-layer shadows and glows
- Full accessibility support

---

## Phase 1: Foundation Review & Setup

### Task 1.1: Review Current Implementation ✓ IN PROGRESS
**File:** `ShiftScheduler/Views/ShiftTypesView.swift`, `LocationsView.swift`
**Duration:** 30 minutes

**Current State Analysis:**
- [x] ShiftTypeRow uses gray gradients (not shift-specific)
- [x] Random header icons instead of shift symbols
- [x] Solid blue/red Edit/Delete buttons
- [x] Basic shadows (single layer, no glow)
- [x] No entrance animations
- [x] LocationRow has hardcoded placeholder date
- [x] No dynamic color system

**Action Items:**
- Document current component structure
- Identify reusable components from ShiftChangeSheet
- Note all dependencies and imports

---

## Phase 2: Component Creation

### Task 2.1: Create EnhancedShiftTypeCard Component
**File:** `ShiftScheduler/Views/Components/EnhancedShiftTypeCard.swift` (NEW)
**Duration:** 2-3 hours
**Priority:** HIGH

**Requirements:**
```swift
struct EnhancedShiftTypeCard: View {
    let shiftType: ShiftType
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var showingDeleteAlert = false

    var body: some View {
        // Implementation
    }
}
```

**Visual Specifications:**

**Header Section:**
- Background: Linear gradient using `ShiftColorPalette.gradientColorsForShift(shiftType)`
- Large symbol: 48pt, bold, white text with shadow
- Title: Semibold, white, 18pt
- Time badge: Capsule with gradient background (shift colors)
- Location: Caption with location icon, white 70% opacity
- Padding: 16pt
- Corner radius: 16pt (top corners only)

**Content Section:**
- Background: `.ultraThinMaterial`
- Description: Body text, 2 line limit with ellipsis
- Padding: 16pt
- Corner radius: 16pt (bottom corners only)

**Action Buttons:**
- Edit button:
  - Background: Shift color at 20% opacity + `.regularMaterial`
  - Border: 1pt stroke with shift color at 40%
  - Text: Shift color
  - Icon: `pencil` SF Symbol
  - Press effect: Scale to 0.96

- Delete button:
  - Background: Red at 20% opacity + `.regularMaterial`
  - Border: 1pt stroke with red at 40%
  - Text: Red
  - Icon: `trash` SF Symbol
  - Press effect: Scale to 0.96

**Card Container:**
- Shadow layer 1: `.black.opacity(0.1)`, radius 12, y: 6
- Shadow layer 2: `shiftColor.opacity(0.2)`, radius 8, y: 4
- Border: 1.5pt gradient stroke using shift color (40% → 20% opacity)
- Overall corner radius: 16pt

**Implementation Steps:**
1. Create new file with struct definition
2. Implement color system using `ShiftColorPalette.colorForShift(shiftType)`
3. Build header section with gradient background
4. Add large symbol with gradient circle background
5. Implement time badge as capsule with gradient
6. Build content section with description
7. Add glassmorphic Edit/Delete buttons
8. Apply multi-layer shadows and gradient border
9. Add press effects using `AnimationPresets.scalePress`
10. Test with various shift types

**Accessibility:**
- VoiceOver label: "\(symbol) \(title), \(timeRange), \(location)"
- Edit button hint: "Edit shift type"
- Delete button hint: "Delete shift type"
- Traits: `.button` for interactive elements

---

### Task 2.2: Create EnhancedLocationCard Component
**File:** `ShiftScheduler/Views/Components/EnhancedLocationCard.swift` (NEW)
**Duration:** 1.5-2 hours
**Priority:** HIGH

**Requirements:**
```swift
struct EnhancedLocationCard: View {
    let location: Location
    let shiftTypeCount: Int
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var showingDeleteAlert = false
    @State private var showingConstraintAlert = false

    var body: some View {
        // Implementation
    }
}
```

**Visual Specifications:**

**Color System:**
- Use location name hash for color generation (similar to shifts)
- Default color family: Teal/blue gradient
- Function: `ShiftColorPalette.colorForLocation(location.name)` (to be added)

**Header Section:**
- Background: Gradient using location color
- Large icon: 48pt building/location icon with white color
- Location name: Bold, white, 18pt
- Usage badge: "\(X) shift types" in capsule with gradient
- Padding: 16pt
- Corner radius: 16pt (top only)

**Content Section:**
- Background: `.ultraThinMaterial`
- Address: Body text, 2-3 line limit
- Map icon: Small location pin icon
- Padding: 16pt
- Corner radius: 16pt (bottom only)

**Action Buttons:**
- Same style as EnhancedShiftTypeCard
- Edit: Location color based
- Delete: Red, with constraint checking

**Implementation Steps:**
1. Create new file with struct definition
2. Add location color generation to ShiftColorPalette
3. Build header with location icon and name
4. Add shift type count badge
5. Implement address display with map icon
6. Add glassmorphic buttons
7. Apply shadows and borders
8. Add constraint checking for delete
9. Test with various locations

**Accessibility:**
- VoiceOver label: "\(name), \(address), used by \(count) shift types"
- Buttons: Clear action descriptions
- Dynamic Type: Full support

---

## Phase 3: Update ShiftTypesView

### Task 3.1: Update Search Bar Styling
**File:** `ShiftScheduler/Views/ShiftTypesView.swift`
**Duration:** 30 minutes
**Priority:** MEDIUM

**Current State:**
```swift
HStack {
    Image(systemName: "magnifyingglass")
        .foregroundColor(.secondary)
    TextField("Search shift types...", text: $searchText)
}
.padding(12)
.background(Color(UIColor.systemGray6))
.cornerRadius(10)
```

**Enhanced State:**
```swift
HStack {
    Image(systemName: "magnifyingglass")
        .foregroundStyle(.secondary)
    TextField("Search shift types...", text: $searchText)
}
.padding(16)
.background {
    RoundedRectangle(cornerRadius: 14, style: .continuous)
        .fill(.ultraThinMaterial)
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(.quaternary, lineWidth: 1)
        }
}
```

**Changes:**
- Replace system gray background with `.ultraThinMaterial`
- Increase padding from 12pt to 16pt
- Change corner radius from 10pt to 14pt (continuous style)
- Add 1pt quaternary border overlay
- Use `.foregroundStyle` instead of `.foregroundColor`

---

### Task 3.2: Replace ShiftTypeRow with EnhancedShiftTypeCard
**File:** `ShiftScheduler/Views/ShiftTypesView.swift`
**Duration:** 1 hour
**Priority:** HIGH

**Current Usage:**
```swift
ForEach(filteredShiftTypes) { shiftType in
    ShiftTypeRow(shiftType: shiftType)
}
```

**Enhanced Usage:**
```swift
ForEach(Array(filteredShiftTypes.enumerated()), id: \.element.id) { index, shiftType in
    EnhancedShiftTypeCard(
        shiftType: shiftType,
        onEdit: {
            shiftTypeToEdit = shiftType
        },
        onDelete: {
            shiftTypeToDelete = shiftType
            showingDeleteAlert = true
        }
    )
    .offset(y: cardAppeared[shiftType.id] ? 0 : 30)
    .opacity(cardAppeared[shiftType.id] ? 1 : 0)
    .animation(
        AnimationPresets.accessible(AnimationPresets.standardSpring)
            .delay(Double(index) * 0.05),
        value: cardAppeared[shiftType.id]
    )
}
.onAppear {
    for shiftType in filteredShiftTypes {
        cardAppeared[shiftType.id] = true
    }
}
```

**Implementation Steps:**
1. Import EnhancedShiftTypeCard
2. Add `@State private var cardAppeared: [UUID: Bool] = [:]`
3. Replace ShiftTypeRow usage
4. Add staggered animation with 0.05s delay per card
5. Move edit/delete logic to callbacks
6. Test animations with 10+ shift types
7. Verify accessibility with VoiceOver

---

### Task 3.3: Enhance Empty State
**File:** `ShiftScheduler/Views/ShiftTypesView.swift`
**Duration:** 45 minutes
**Priority:** MEDIUM

**Current State:**
```swift
VStack(spacing: 20) {
    Image(systemName: "clock.badge.questionmark")
        .font(.system(size: 60))
        .foregroundColor(.secondary)

    Text("No Shift Types")
        .font(.title2)
        .fontWeight(.semibold)

    Text("Create your first shift type...")
        .font(.body)
        .foregroundColor(.secondary)

    Button("Create Shift Type") {
        showingAddShiftType = true
    }
    .buttonStyle(.borderedProminent)
}
```

**Enhanced State:**
```swift
VStack(spacing: 20) {
    // Icon with gradient
    Image(systemName: "clock.badge.plus")
        .font(.system(size: 80))
        .fontWeight(.bold)
        .foregroundStyle(
            LinearGradient(
                colors: [.blue, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .offset(y: iconAppeared ? 0 : 20)
        .opacity(iconAppeared ? 1 : 0)

    Text("No Shift Types")
        .font(.title2)
        .fontWeight(.semibold)
        .offset(y: titleAppeared ? 0 : 15)
        .opacity(titleAppeared ? 1 : 0)

    Text("Create your first shift type to get started\nwith scheduling")
        .font(.body)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
        .offset(y: subtitleAppeared ? 0 : 10)
        .opacity(subtitleAppeared ? 1 : 0)

    // Enhanced button with gradient
    Button {
        showingAddShiftType = true
    } label: {
        HStack(spacing: 8) {
            Image(systemName: "plus.circle.fill")
            Text("Create Shift Type")
        }
        .font(.headline)
        .fontWeight(.semibold)
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(
            LinearGradient(
                colors: [.blue, .blue.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .foregroundColor(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .blue.opacity(0.3), radius: 12, y: 6)
    }
    .offset(y: buttonAppeared ? 0 : 10)
    .opacity(buttonAppeared ? 1 : 0)
    .pressScale(isPressed: false)
}
.onAppear {
    withAnimation(AnimationPresets.standardSpring.delay(0.1)) {
        iconAppeared = true
    }
    withAnimation(AnimationPresets.standardSpring.delay(0.2)) {
        titleAppeared = true
    }
    withAnimation(AnimationPresets.standardSpring.delay(0.3)) {
        subtitleAppeared = true
    }
    withAnimation(AnimationPresets.standardSpring.delay(0.4)) {
        buttonAppeared = true
    }
}
```

**Changes:**
- Larger icon (80pt) with gradient foreground
- Staggered entrance animations (0.1s delays)
- Enhanced button with gradient background and shadow
- Add state variables for animation tracking
- Better icon choice (`clock.badge.plus`)

---

## Phase 4: Update LocationsView

### Task 4.1: Update LocationRow with EnhancedLocationCard
**File:** `ShiftScheduler/Views/LocationsView.swift`
**Duration:** 1 hour
**Priority:** HIGH

**Current Usage:**
```swift
ForEach(filteredLocations) { location in
    LocationRow(location: location) {
        locationToEdit = location
    }
}
```

**Enhanced Usage:**
```swift
ForEach(Array(filteredLocations.enumerated()), id: \.element.id) { index, location in
    let shiftTypeCount = shiftTypes.filter { $0.location?.id == location.id }.count

    EnhancedLocationCard(
        location: location,
        shiftTypeCount: shiftTypeCount,
        onEdit: {
            locationToEdit = location
        },
        onDelete: {
            if canDelete(location) {
                locationToDelete = location
                showingDeleteAlert = true
            } else {
                locationToDelete = location
                showingConstraintAlert = true
            }
        }
    )
    .offset(y: cardAppeared[location.id] ? 0 : 30)
    .opacity(cardAppeared[location.id] ? 1 : 0)
    .animation(
        AnimationPresets.accessible(AnimationPresets.standardSpring)
            .delay(Double(index) * 0.05),
        value: cardAppeared[location.id]
    )
}
```

**Implementation Steps:**
1. Import EnhancedLocationCard
2. Add animation state tracking
3. Calculate shift type count per location
4. Replace LocationRow usage
5. Add staggered animations
6. Move delete constraint logic to component
7. Test with various locations

---

### Task 4.2: Remove Hardcoded Date, Add Shift Count
**File:** `ShiftScheduler/Views/Components/EnhancedLocationCard.swift`
**Duration:** 30 minutes
**Priority:** MEDIUM

**Current LocationRow:**
```swift
Text("September 16, 2025")
    .font(.caption2)
    .foregroundColor(.secondary)
```

**Enhanced Version:**
```swift
HStack(spacing: 6) {
    Image(systemName: "building.2.fill")
        .font(.caption2)
        .foregroundStyle(.white.opacity(0.7))

    Text("\(shiftTypeCount) shift \(shiftTypeCount == 1 ? "type" : "types")")
        .font(.caption)
        .fontWeight(.medium)
        .foregroundStyle(.white.opacity(0.7))
}
.padding(.horizontal, 10)
.padding(.vertical, 5)
.background(
    Capsule()
        .fill(.white.opacity(0.2))
)
```

**Changes:**
- Remove placeholder date completely
- Add building icon
- Display actual shift type count
- Style as capsule badge
- Use white with opacity for on-gradient visibility

---

### Task 4.3: Update Location Empty State
**File:** `ShiftScheduler/Views/LocationsView.swift`
**Duration:** 30 minutes
**Priority:** MEDIUM

**Similar to Task 3.3:**
- Larger icon (80pt) with teal/blue gradient
- Icon: `mappin.and.ellipse` or `building.2.fill`
- Staggered animations
- Enhanced button with gradient
- Better copy and icon choice

---

## Phase 5: Utilities & Extensions

### Task 5.1: Add Location Color Generation to ShiftColorPalette
**File:** `ShiftScheduler/Utilities/ShiftColorPalette.swift`
**Duration:** 30 minutes
**Priority:** HIGH

**Add to ShiftColorPalette:**
```swift
/// Generate a color for a location based on its name
/// Uses hash-based selection with teal/blue color family
static func colorForLocation(_ locationName: String) -> Color {
    let hash = locationName.hashValue
    let colors = locationColorPalette
    return colors[abs(hash) % colors.count]
}

/// Gradient colors for a location
static func gradientColorsForLocation(_ locationName: String) -> (Color, Color) {
    let primaryColor = colorForLocation(locationName)
    let secondaryColor = primaryColor.opacity(0.7)
    return (primaryColor, secondaryColor)
}

/// Teal/blue color palette for locations
private static let locationColorPalette: [Color] = [
    Color(red: 0.2, green: 0.6, blue: 0.8),   // Ocean Blue
    Color(red: 0.2, green: 0.7, blue: 0.7),   // Teal
    Color(red: 0.3, green: 0.5, blue: 0.8),   // Sky Blue
    Color(red: 0.2, green: 0.8, blue: 0.7),   // Turquoise
    Color(red: 0.3, green: 0.6, blue: 0.9),   // Azure
    Color(red: 0.2, green: 0.7, blue: 0.6),   // Sea Green
]
```

**Implementation Steps:**
1. Open ShiftColorPalette.swift
2. Add location color palette array
3. Add colorForLocation function
4. Add gradientColorsForLocation function
5. Test with various location names
6. Verify colors are distinct and accessible

---

### Task 5.2: Create Reusable GlassButton Component
**File:** `ShiftScheduler/Views/Components/GlassButton.swift` (NEW)
**Duration:** 45 minutes
**Priority:** MEDIUM

**Purpose:** Reusable button style for Edit/Delete buttons

```swift
struct GlassButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
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
                            .fill(color.opacity(0.2))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(color.opacity(0.4), lineWidth: 1)
                    }
            }
            .foregroundStyle(color)
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .animation(AnimationPresets.quickSpring, value: isPressed)
    }
}
```

**Usage:**
```swift
HStack(spacing: 8) {
    GlassButton(
        title: "Edit",
        icon: "pencil",
        color: shiftColor,
        action: onEdit
    )

    GlassButton(
        title: "Delete",
        icon: "trash",
        color: .red,
        action: onDelete
    )
}
```

---

## Phase 6: Polish & Refinements

### Task 6.1: Fine-tune Animation Timings
**Duration:** 1 hour
**Priority:** MEDIUM

**Actions:**
1. Test all animations on device
2. Adjust spring parameters if too bouncy or sluggish
3. Verify stagger delays feel natural (0.05s is good baseline)
4. Ensure no animation jank during scrolling
5. Test rapid interactions (fast scrolling, quick taps)

**Target Feel:**
- Entrance: Smooth, confident (not slow)
- Press: Immediate feedback (<0.1s)
- Transitions: Fluid, natural
- Scrolling: Butter smooth, 60 FPS

---

### Task 6.2: Optimize Color Contrast
**Duration:** 45 minutes
**Priority:** HIGH

**Tools:**
- Accessibility Inspector in Xcode
- Color contrast analyzer (online tool)
- Test in both light and dark mode

**Requirements:**
- Text on gradients: Minimum 4.5:1 contrast
- White text on shift colors: Must be readable
- Button text: Minimum 3:1 contrast
- Borders: Visible in both modes

**Actions:**
1. Test all shift colors with white text
2. Verify location colors have good contrast
3. Check button text readability
4. Test with color blindness simulators
5. Adjust saturation/brightness if needed

---

### Task 6.3: Add Haptic Feedback
**Duration:** 30 minutes
**Priority:** LOW

**Haptic Points:**
- Card tap: `.selection` haptic
- Edit button: `.light` impact
- Delete button: `.medium` impact
- Delete confirmation: `.heavy` impact (on actual delete)

**Implementation:**
```swift
import UIKit

extension View {
    func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) -> some View {
        self.onTapGesture {
            UIImpactFeedbackGenerator(style: style).impactOccurred()
        }
    }
}
```

---

## Phase 7: Testing & Validation

### Task 7.1: VoiceOver Testing
**Duration:** 1 hour
**Priority:** HIGH

**Test Checklist:**
- [ ] All shift type cards have descriptive labels
- [ ] All location cards have descriptive labels
- [ ] Edit buttons announce "Edit [name]"
- [ ] Delete buttons announce "Delete [name]"
- [ ] Search field is properly labeled
- [ ] Empty states are announced correctly
- [ ] Focus order is logical (top to bottom)
- [ ] Selection states are announced

**Testing Process:**
1. Enable VoiceOver (Settings > Accessibility)
2. Navigate through Shift Types tab
3. Navigate through Locations tab
4. Test all interactive elements
5. Verify focus order makes sense
6. Test with Dynamic Type enabled
7. Document any issues

---

### Task 7.2: Dynamic Type Testing
**Duration:** 1 hour
**Priority:** HIGH

**Size Categories to Test:**
- xSmall
- Medium (default)
- xLarge
- xxxLarge
- AX3 (Accessibility Large)
- AX5 (Accessibility Largest)

**Test Checklist:**
- [ ] Text never truncates (uses lineLimit for wrapping)
- [ ] Layouts don't break at largest sizes
- [ ] Buttons remain accessible (44pt minimum)
- [ ] Cards expand vertically as needed
- [ ] Symbols scale appropriately
- [ ] Spacing adjusts proportionally

**Process:**
1. Open Settings > Accessibility > Display & Text Size
2. Adjust text size slider
3. Return to app and test each size
4. Take screenshots at each size
5. Verify no truncation or layout breaks
6. Fix any issues found

---

### Task 7.3: Reduced Motion Testing
**Duration:** 30 minutes
**Priority:** HIGH

**Test Checklist:**
- [ ] Staggered animations replaced with simple fades
- [ ] Spring animations become easeOut
- [ ] Scale effects replaced with opacity
- [ ] No continuous animations (pulse, shimmer)
- [ ] Entrance still feels polished

**Process:**
1. Enable Reduce Motion (Settings > Accessibility > Motion)
2. Navigate to Shift Types tab
3. Verify animations are simplified
4. Check empty state animations
5. Test with Locations tab
6. Ensure experience is still pleasant

**Implementation Check:**
```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

var animation: Animation {
    reduceMotion
        ? .easeOut(duration: 0.2)
        : AnimationPresets.standardSpring
}
```

---

### Task 7.4: Performance Testing
**Duration:** 1.5 hours
**Priority:** HIGH

**Metrics to Measure:**
| Metric | Target | Tool |
|--------|--------|------|
| List scroll FPS | 60 FPS | Xcode FPS gauge |
| Entrance animation FPS | 60 FPS | Instruments (Core Animation) |
| Memory usage | <5MB increase | Instruments (Allocations) |
| Initial render time | <100ms | Time Profiler |

**Test Scenarios:**
1. **List Scrolling**
   - Create 20+ shift types
   - Scroll rapidly up and down
   - Monitor FPS during scroll
   - Should maintain 60 FPS

2. **Entrance Animations**
   - Navigate to Shift Types tab
   - Measure FPS during card entrance
   - Should maintain 60 FPS
   - Check for dropped frames

3. **Memory Usage**
   - Note memory before opening tab
   - Open Shift Types with 20 items
   - Note memory after animations complete
   - Increase should be <5MB
   - Check for leaks

4. **Rapid Interactions**
   - Rapidly tap Edit buttons
   - Quick scroll while animating
   - Verify no crashes or jank

**Actions:**
1. Profile with Instruments (Time Profiler)
2. Profile with Instruments (Core Animation)
3. Profile with Instruments (Allocations)
4. Run on physical device (iPhone 12 minimum)
5. Fix any performance issues found
6. Re-test after optimizations

---

### Task 7.5: Visual Regression Testing
**Duration:** 1 hour
**Priority:** MEDIUM

**Screenshots Needed:**
- [ ] Shift Types tab with 5 shift types (light mode)
- [ ] Shift Types tab with 5 shift types (dark mode)
- [ ] Shift Types empty state
- [ ] Locations tab with 3 locations (light mode)
- [ ] Locations tab with 3 locations (dark mode)
- [ ] Locations empty state
- [ ] Dynamic Type at AX3 size
- [ ] Search bar with text entered

**Process:**
1. Take screenshots of all scenarios
2. Compare with design specifications
3. Verify colors match shift types
4. Check spacing and alignment
5. Ensure consistency with ShiftChangeSheet
6. Document any visual issues

---

## Phase 8: Documentation & Cleanup

### Task 8.1: Update Code Documentation
**Duration:** 45 minutes
**Priority:** MEDIUM

**Files to Document:**
- EnhancedShiftTypeCard.swift
- EnhancedLocationCard.swift
- GlassButton.swift (if created)
- ShiftColorPalette.swift (new functions)

**Documentation Template:**
```swift
/// Brief description of component
///
/// Detailed description explaining purpose, behavior, and visual style.
///
/// - Parameters:
///   - param1: Description
///   - param2: Description
///
/// - Example:
///   ```swift
///   EnhancedShiftTypeCard(
///       shiftType: shiftType,
///       onEdit: { },
///       onDelete: { }
///   )
///   ```
///
/// - Accessibility:
///   - VoiceOver: Description
///   - Dynamic Type: Supported
///   - Reduced Motion: Animations simplified
```

---

### Task 8.2: Clean Up Old Code
**Duration:** 30 minutes
**Priority:** LOW

**Actions:**
1. Remove unused ShiftTypeRow component (or mark as deprecated)
2. Remove unused LocationRow component (or mark as deprecated)
3. Remove any temporary test code
4. Clean up commented-out code
5. Verify no unused imports
6. Run SwiftLint (if configured)

---

### Task 8.3: Update CHANGELOG
**Duration:** 15 minutes
**Priority:** LOW

**Entry:**
```markdown
## [Version X.X.X] - 2025-10-XX

### Enhanced
- **Shift Types & Locations UI**: Complete visual refresh with Liquid Glass design
  - Dynamic color system for shift type cards
  - Teal/blue color system for location cards
  - Large gradient shift symbols (48pt)
  - Glassmorphic card styling with gradient borders
  - Multi-layer shadows with color-specific glows
  - Enhanced Edit/Delete buttons with glass effects
  - Staggered entrance animations (0.05s delay per card)
  - Updated search bars with .ultraThinMaterial
  - Enhanced empty states with gradients and animations
  - Full accessibility support (VoiceOver, Dynamic Type, Reduced Motion)

### Added
- `EnhancedShiftTypeCard`: Premium shift type card component
- `EnhancedLocationCard`: Premium location card component
- `GlassButton`: Reusable glassmorphic button component
- Location color generation in ShiftColorPalette
- Press scale effects on all interactive elements

### Removed
- Hardcoded date placeholder in LocationRow
- Gray gradient headers (replaced with shift-specific colors)
- Random header icons (replaced with shift symbols)
```

---

### Task 8.4: Write Unit Tests
**Duration:** 2 hours
**Priority:** MEDIUM

**Tests to Write:**

**Test File:** `EnhancedShiftTypeCardTests.swift`
```swift
import Testing
import SwiftUI
@testable import ShiftScheduler

@Test func testShiftTypeCardRendersCorrectly() async throws {
    let shiftType = ShiftType(
        symbol: "D",
        duration: .scheduled(from: HourMinuteTime(hour: 9, minute: 0),
                           to: HourMinuteTime(hour: 17, minute: 0)),
        title: "Day Shift",
        description: "Standard day shift",
        location: nil
    )

    // Verify component initializes
    let card = EnhancedShiftTypeCard(
        shiftType: shiftType,
        onEdit: { },
        onDelete: { }
    )

    #expect(card.shiftType.symbol == "D")
    #expect(card.shiftType.title == "Day Shift")
}

@Test func testColorGenerationIsConsistent() async throws {
    let color1 = ShiftColorPalette.colorForShift(mockShiftType)
    let color2 = ShiftColorPalette.colorForShift(mockShiftType)

    #expect(color1 == color2)
}

@Test func testLocationColorGeneration() async throws {
    let color = ShiftColorPalette.colorForLocation("Hospital A")

    // Verify color is from location palette (teal/blue family)
    #expect(color != .clear)
}
```

**Test Coverage Goals:**
- Component initialization
- Color generation consistency
- Button callback triggering
- Animation state management
- Accessibility properties

---

## Summary Checklist

### Components Created
- [ ] EnhancedShiftTypeCard.swift
- [ ] EnhancedLocationCard.swift
- [ ] GlassButton.swift (optional, reusable)

### Views Updated
- [ ] ShiftTypesView.swift - search bar, card usage, empty state
- [ ] LocationsView.swift - card usage, empty state, shift count

### Utilities Updated
- [ ] ShiftColorPalette.swift - location colors added

### Testing Completed
- [ ] VoiceOver tested and verified
- [ ] Dynamic Type tested (xSmall to AX5)
- [ ] Reduced Motion tested and working
- [ ] Performance testing (60 FPS achieved)
- [ ] Visual regression testing complete
- [ ] Unit tests written and passing

### Documentation
- [ ] Code comments added
- [ ] CHANGELOG updated
- [ ] README updated (if needed)

### Cleanup
- [ ] Old components removed/deprecated
- [ ] Unused code removed
- [ ] No compiler warnings
- [ ] SwiftLint passing (if configured)

---

## Estimated Time Breakdown

| Phase | Tasks | Duration |
|-------|-------|----------|
| Phase 1: Foundation | 1 task | 0.5 hours |
| Phase 2: Components | 2 tasks | 3.5-5 hours |
| Phase 3: ShiftTypesView | 3 tasks | 2.25 hours |
| Phase 4: LocationsView | 3 tasks | 2 hours |
| Phase 5: Utilities | 2 tasks | 1.25 hours |
| Phase 6: Polish | 3 tasks | 2.25 hours |
| Phase 7: Testing | 5 tasks | 5 hours |
| Phase 8: Documentation | 4 tasks | 3.5 hours |
| **Total** | **23 tasks** | **20-22 hours** |

---

## Success Criteria

### Visual
- ✓ All shift type cards use dynamic colors from ShiftColorPalette
- ✓ All location cards use teal/blue color family
- ✓ Large 48pt gradient symbols on all cards
- ✓ Multi-layer shadows (black + color glow)
- ✓ Gradient borders on all cards
- ✓ Glassmorphic Edit/Delete buttons
- ✓ Enhanced empty states with gradients

### Animation
- ✓ Staggered entrance animations (0.05s delay)
- ✓ 60 FPS during all animations
- ✓ Smooth press effects on buttons
- ✓ Animations respect Reduced Motion

### Accessibility
- ✓ 100% VoiceOver compatibility
- ✓ All Dynamic Type sizes supported (xSmall to AX5)
- ✓ Color contrast passes WCAG AA
- ✓ 44pt minimum tap targets maintained

### Functionality
- ✓ All existing features work unchanged
- ✓ Edit/delete operations functional
- ✓ Search functionality maintained
- ✓ Location constraint checking works

---

**Ready to Begin Implementation!** 🚀

Start with Phase 1, Task 1.1 (currently in progress) and work through each phase systematically. Use the TodoWrite tool to track progress and mark tasks as completed.
