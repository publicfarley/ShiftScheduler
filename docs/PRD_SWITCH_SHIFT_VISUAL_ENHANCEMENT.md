# Product Requirements Document: Switch Shift Sheet Visual Enhancement

**Document Version:** 1.0
**Created:** 2025-10-11
**Project:** ShiftScheduler iOS App
**Target iOS Version:** 26.0+
**Priority:** High
**Type:** Visual Enhancement / UI/UX Improvement

---

## Executive Summary

This PRD defines the comprehensive visual enhancement of the Switch Shift sheet (ShiftChangeSheet.swift) to elevate it from a basic functional interface to a premium, visually stunning experience that matches iOS 26 Liquid Glass UI patterns. The enhancement will maintain all existing functionality while dramatically improving visual hierarchy, color dynamics, animations, and overall aesthetic appeal.

---

## 1. Product Vision & Goals

### 1.1 Vision Statement
Transform the Switch Shift sheet into a visually compelling interface that clearly communicates the shift change workflow through dynamic colors, fluid animations, and premium iOS 26 design patterns, creating a delightful user experience that reinforces user confidence in their shift management decisions.

### 1.2 Primary Goals
1. **Visual Excellence**: Achieve premium iOS 26 Liquid Glass aesthetic throughout the sheet
2. **Clear Communication**: Enhance visual hierarchy to guide users through the shift switch workflow
3. **Dynamic Responsiveness**: Implement color systems that respond to user selections
4. **Fluid Interactions**: Add smooth, intentional animations that feel natural and premium
5. **Maintain Performance**: Ensure 60 FPS throughout all animations and interactions
6. **Zero Regression**: Maintain all existing functionality and accessibility

### 1.3 Success Metrics
- Users can instantly identify current vs. new shift through visual design
- All animations run at 60 FPS on target devices (iPhone 12 and newer)
- Accessibility scores maintain 100% VoiceOver compatibility
- User feedback indicates improved visual appeal (qualitative)
- No increase in sheet presentation/dismissal time

---

## 2. Current State Analysis

### 2.1 Existing Implementation
**File:** ShiftChangeSheet.swift

**Current Features:**
- Basic Liquid Glass UI with `.ultraThinMaterial` backgrounds
- Simple layout: Current Shift section, New Shift Type picker, Reason field, Action buttons
- Basic spring animations on shift selection
- Standard system colors (blue/gray)
- Simple rounded rectangles for card backgrounds
- Basic toast notification for success
- Keyboard dismissal functionality

**Current Deficiencies:**
- Lacks visual hierarchy - all elements have similar visual weight
- No dynamic color system tied to shift identity
- Minimal use of Liquid Glass patterns beyond basic material
- Static, non-responsive visual design
- Basic animations without polish or personality
- Poor visual differentiation between "before" and "after" states
- Underutilized space and depth opportunities

### 2.2 Reference Design System
**Sources:** TodayView.swift, GlassCard.swift, EnhancedTodayShiftCard, OptimizedTodayShiftCard

**Established Patterns:**
- GlassCard component with glassmorphic effects
- Dynamic shift-based color system (hash-based color generation)
- Gradient backgrounds with subtle shadows
- Border strokes with gradient effects
- Spring animations with specific parameters
- Scale effects on interactions
- Shimmer/glow effects for emphasis
- Capsule-shaped status badges
- Haptic feedback integration
- Material layering for depth

---

## 3. Detailed Requirements

## 3.1 Component-by-Component Enhancement Specifications

### 3.1.1 Sheet Container & Presentation

**Requirements:**
- Custom presentation detents for optimal content display
- Enhanced background dimming with subtle blur
- Smooth entry animation (slide up with spring physics)
- Drag indicator with glassmorphic styling
- Corner radius: 24pt (top corners)

**Visual Specifications:**
```swift
// Presentation
.presentationDetents([.height(680), .large])
.presentationDragIndicator(.visible)
.presentationCornerRadius(24)
.presentationBackground {
    Color.clear
        .background(.ultraThinMaterial)
}

// Entry Animation
.transition(.asymmetric(
    insertion: .move(edge: .bottom)
        .combined(with: .opacity)
        .animation(.spring(response: 0.5, dampingFraction: 0.8)),
    removal: .move(edge: .bottom)
        .combined(with: .opacity)
        .animation(.spring(response: 0.4, dampingFraction: 0.85))
))
```

**Background Specifications:**
- Material: `.ultraThinMaterial` with 95% opacity
- Dimming overlay: Black with 35% opacity
- Blur radius: 20pt

---

### 3.1.2 Current Shift Display Card

**Requirements:**
- Replace basic card with enhanced GlassCard component
- Display shift symbol with dynamic color-coded background
- Show date, time range, and location with clear hierarchy
- Add subtle pulsing glow to emphasize "current" status
- Include "Current Shift" badge with glassmorphic styling

**Visual Specifications:**

**Card Structure:**
```swift
GlassCard(
    cornerRadius: 20,
    borderWidth: 1.5,
    shadowRadius: 12,
    shadowOpacity: 0.2
) {
    HStack(spacing: 16) {
        // Shift Symbol
        ShiftSymbolView(
            symbol: currentShift.shiftType.symbol,
            color: shiftColor(for: currentShift.shiftType),
            size: .large // 64pt
        )
        .glowEffect(color: shiftColor, intensity: 0.4)
        .pulsing() // Subtle 2s pulse animation

        // Shift Details
        VStack(alignment: .leading, spacing: 6) {
            // Badge
            // Time & Location
            // Shift Name
        }
    }
    .padding(20)
}
.gradientBorder(
    colors: [shiftColor.opacity(0.6), shiftColor.opacity(0.2)],
    lineWidth: 1.5
)
```

**Symbol Specifications:**
- Size: 64pt × 64pt
- Background: Gradient derived from shift color
  - Start: shiftColor with 80% opacity
  - End: shiftColor.darker(by: 0.2) with 90% opacity
- Corner radius: 16pt
- Shadow: 0/4/12/0.25 (x/y/blur/opacity)
- Glow: shiftColor at 40% intensity, 8pt radius
- Animation: Subtle pulse (scale 1.0 to 1.02) over 2s, continuous

**Typography Hierarchy:**
- Badge: SF Pro Rounded Medium, 11pt, all caps, letter spacing +0.5pt
- Shift Name: SF Pro Display Semibold, 20pt, -0.5pt tracking
- Time Range: SF Pro Text Regular, 15pt, secondary color
- Location: SF Pro Text Regular, 13pt, tertiary color

**"Current Shift" Badge:**
- Background: `.regularMaterial` with shiftColor tint at 20%
- Padding: 6pt horizontal, 3pt vertical
- Corner radius: 8pt
- Border: 0.5pt solid shiftColor at 40% opacity

**Color Specifications:**
- Dynamic color based on shift symbol hash
- Use existing cardColor algorithm from TodayView
- Gradient angle: 135 degrees
- Glow color matches primary shift color at 40% opacity

---

### 3.1.3 Transition Indicator / Visual Arrow

**Requirements:**
- Prominent animated indicator between old and new shift
- Should animate when new shift is selected
- Uses dynamic colors from both shifts
- Provides clear directional flow

**Visual Specifications:**

**Component Structure:**
```swift
TransitionArrow(
    fromColor: currentShiftColor,
    toColor: newShiftColor,
    animated: newShiftSelected
)
.frame(height: 44)
```

**Arrow Design:**
- Style: Downward chevron (SF Symbol: chevron.down.circle.fill)
- Size: 32pt
- Background: Gradient from currentShiftColor to newShiftColor
- Animation: Bouncing effect (0.5s duration) when new shift selected
- Shimmer effect on gradient
- Shadow: 0/2/8/0.2

**Animation Sequence:**
1. Initial state: Static, showing currentShiftColor
2. On selection:
   - Scale from 1.0 to 1.2 to 1.0 (0.6s, spring)
   - Color gradient animates from single color to dual gradient (0.8s, easeInOut)
   - Rotation: 0° to 360° (1.2s, easeInOut) - single rotation
   - Haptic: .impact(.medium)

**Surrounding Visual:**
- Dotted vertical line above and below (2pt dots, 4pt spacing)
- Line color: `.tertiary` with 50% opacity
- Line gradient matches shift colors on selection

---

### 3.1.4 New Shift Type Picker Section

**Requirements:**
- Grid or list of available shift types
- Each shift type uses enhanced card design
- Selected state clearly differentiated
- Smooth transitions between selections
- Color-coded per shift type

**Visual Specifications:**

**Container:**
```swift
VStack(alignment: .leading, spacing: 12) {
    SectionHeader(title: "Select New Shift", icon: "arrow.triangle.2.circlepath")

    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 12) {
            ForEach(availableShiftTypes) { shiftType in
                ShiftTypePickerCard(
                    shiftType: shiftType,
                    isSelected: selectedShiftType?.id == shiftType.id,
                    onTap: { selectShiftType(shiftType) }
                )
            }
        }
        .padding(.horizontal, 20)
    }
}
```

**Picker Card Design:**

*Unselected State:*
- Size: 100pt width × 120pt height
- Background: `.ultraThinMaterial` with 80% opacity
- Border: 1pt solid `.quaternary`
- Corner radius: 16pt
- Shadow: 0/2/8/0.1
- Symbol size: 32pt
- Symbol background: Gradient (subtle)
- Opacity: 0.85

*Selected State:*
- Size: 100pt width × 120pt height (no size change)
- Background: `.regularMaterial` with shiftColor tint at 15%
- Border: 2pt gradient (shiftColor variants)
- Corner radius: 16pt
- Shadow: 0/8/24/0.3 with shiftColor tint
- Symbol size: 36pt (scaled up)
- Symbol background: Full vibrant gradient
- Glow: shiftColor at 50% intensity, 12pt radius
- Opacity: 1.0
- Scale: 1.05
- Checkmark badge: Top-right corner, 20pt, filled circle

**Card Layout:**
```
┌─────────────────┐
│     ✓  (badge)  │
│                 │
│    [SYMBOL]     │
│   64x64 with    │
│   gradient bg   │
│                 │
│  Shift Name     │
│  14pt Semibold  │
│                 │
│  Time Range     │
│  11pt Regular   │
└─────────────────┘
```

**Selection Animation:**
1. Scale: 1.0 → 1.08 → 1.05 (0.5s total)
2. Border grows from 1pt to 2pt (0.3s)
3. Shadow expands (0.4s)
4. Glow fades in (0.5s)
5. Symbol scales from 32pt to 36pt (0.4s)
6. Checkmark badge: Slide in from top-right with spring (0.6s)
7. Background tint fades in (0.5s)
8. Haptic: .impact(.medium)

**Deselection Animation:**
1. All properties animate back to unselected state
2. Duration: 0.4s
3. Easing: .spring(response: 0.4, dampingFraction: 0.75)
4. Haptic: .impact(.light)

---

### 3.1.5 Reason Text Field

**Requirements:**
- Optional text field for switch reason
- Glassmorphic styling consistent with design system
- Keyboard dismissal support
- Character count indicator (if max limit exists)
- Smooth focus/unfocus animations

**Visual Specifications:**

**Container:**
```swift
VStack(alignment: .leading, spacing: 8) {
    SectionHeader(title: "Reason (Optional)", icon: "text.alignleft")

    TextEditor(text: $reason)
        .frame(height: 80)
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(
                    isFocused ? newShiftColor.opacity(0.6) : Color.quaternary,
                    lineWidth: isFocused ? 2 : 1
                )
        )
        .shadow(color: isFocused ? newShiftColor.opacity(0.2) : .clear,
                radius: 8, y: 4)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isFocused)
}
.dismissKeyboardOnTap()
```

**Typography:**
- Font: SF Pro Text Regular
- Size: 15pt
- Line height: 20pt
- Color: `.primary`
- Placeholder color: `.tertiary`

**Focus State:**
- Border color: newShiftColor at 60% opacity
- Border width: 2pt
- Shadow: newShiftColor at 20% opacity, 8pt radius, 4pt y-offset
- Glow: Subtle 6pt glow in newShiftColor at 15%

**Unfocused State:**
- Border color: `.quaternary`
- Border width: 1pt
- Shadow: None
- Glow: None

**Transition:**
- Duration: 0.3s
- Spring: response 0.3, dampingFraction 0.8
- Haptic on focus: .selection

---

### 3.1.6 Action Buttons (Switch & Cancel)

**Requirements:**
- Primary button: "Switch Shift" with gradient fill
- Secondary button: "Cancel" with subtle styling
- Loading state with enhanced spinner
- Disabled state clearly differentiated
- Smooth state transitions

**Visual Specifications:**

**Layout:**
```swift
HStack(spacing: 12) {
    // Cancel Button (Secondary)
    CancelButton()
        .frame(maxWidth: .infinity)

    // Switch Button (Primary)
    SwitchButton(enabled: canSwitch, loading: isLoading)
        .frame(maxWidth: .infinity)
}
.padding(.horizontal, 20)
.padding(.bottom, 20)
```

**Primary Button (Switch Shift):**

*Enabled State:*
```swift
Button(action: performSwitch) {
    HStack(spacing: 8) {
        if isLoading {
            ProgressView()
                .tint(.white)
        }
        Text("Switch Shift")
            .font(.system(.headline, design: .rounded, weight: .semibold))
        Image(systemName: "arrow.triangle.2.circlepath")
            .font(.system(size: 14, weight: .semibold))
    }
    .frame(maxWidth: .infinity)
    .frame(height: 52)
    .background(
        LinearGradient(
            colors: [
                newShiftColor,
                newShiftColor.adjusted(brightness: -0.15)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
    .foregroundColor(.white)
    .clipShape(RoundedRectangle(cornerRadius: 16))
    .shadow(color: newShiftColor.opacity(0.4), radius: 12, y: 6)
    .overlay(
        RoundedRectangle(cornerRadius: 16)
            .strokeBorder(
                LinearGradient(
                    colors: [.white.opacity(0.3), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: 1
            )
    )
}
.pressEffect() // Scale to 0.96 on press
.glowEffect(color: newShiftColor, intensity: 0.3, radius: 16)
```

*Disabled State:*
- Background: Solid gray gradient (`.quaternary` to `.quaternary.darker`)
- Text color: `.secondary`
- Shadow: None
- Glow: None
- Opacity: 0.6
- No press effect

*Loading State:*
- Background: Maintains enabled gradient but with 80% opacity
- ProgressView: White color, center-left positioned
- Text: "Switching..." with reduced opacity (0.8)
- Disable interaction
- Subtle pulsing animation on background

**Button Animations:**
- Press: Scale to 0.96, duration 0.1s
- Release: Scale to 1.0, spring response 0.3, dampingFraction 0.6
- Glow intensifies on press (0.3 to 0.5)
- Haptic: .impact(.medium) on tap

**Secondary Button (Cancel):**
```swift
Button(action: dismiss) {
    Text("Cancel")
        .font(.system(.body, design: .rounded, weight: .medium))
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .background(.ultraThinMaterial)
        .foregroundColor(.primary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.quaternary, lineWidth: 1)
        )
}
.pressEffect()
```

**Cancel Button State:**
- Background: `.ultraThinMaterial`
- Border: 1pt `.quaternary`
- Text: `.primary` color
- No shadow or glow
- Press effect: Scale to 0.96
- Haptic: .impact(.light)

---

### 3.1.7 Confirmation Dialog

**Requirements:**
- Custom styled confirmation alert
- Uses new shift color scheme
- Clear action hierarchy
- Smooth presentation

**Visual Specifications:**

**Dialog Style:**
```swift
.confirmationDialog("Confirm Shift Switch", isPresented: $showConfirmation) {
    Button("Switch to \(newShift.name)", role: .none) {
        performSwitch()
    }
    Button("Cancel", role: .cancel) {}
} message: {
    Text("Switch from \(currentShift.name) to \(newShift.name)?")
}
.dialogStyle(.automatic) // Uses system styling with custom tint
.tint(newShiftColor)
```

**Custom Tinting:**
- Primary action color: newShiftColor
- Destructive action color: System red
- Cancel action color: System default

**Animation:**
- Presentation: Scale and fade (0.4s, spring)
- Dismissal: Scale and fade (0.3s, spring)

---

### 3.1.8 Success Toast Notification

**Requirements:**
- Enhanced toast with Liquid Glass styling
- Uses new shift color
- Smooth entry/exit animations
- Auto-dismiss with progress indicator

**Visual Specifications:**

**Toast Structure:**
```swift
HStack(spacing: 12) {
    Image(systemName: "checkmark.circle.fill")
        .font(.system(size: 24))
        .foregroundStyle(
            LinearGradient(
                colors: [newShiftColor, newShiftColor.lighter(by: 0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .symbolEffect(.bounce, value: showToast)

    VStack(alignment: .leading, spacing: 2) {
        Text("Shift Switched")
            .font(.system(.subheadline, design: .rounded, weight: .semibold))
        Text("Changed to \(newShift.name)")
            .font(.system(.caption, design: .rounded))
            .foregroundColor(.secondary)
    }

    Spacer()
}
.padding(16)
.background(
    .regularMaterial,
    in: RoundedRectangle(cornerRadius: 16)
)
.overlay(
    RoundedRectangle(cornerRadius: 16)
        .strokeBorder(
            LinearGradient(
                colors: [newShiftColor.opacity(0.5), newShiftColor.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            lineWidth: 1.5
        )
)
.shadow(color: newShiftColor.opacity(0.3), radius: 20, y: 10)
.glowEffect(color: newShiftColor, intensity: 0.2, radius: 12)
```

**Position:**
- Top of screen (safe area + 16pt)
- Horizontal padding: 20pt from edges
- Full width minus padding

**Animation Sequence:**
1. Entry:
   - Slide down from top (-100pt offset)
   - Fade in from 0 to 1 opacity
   - Slight bounce on entry
   - Duration: 0.6s
   - Spring: response 0.5, dampingFraction 0.7
   - Haptic: .notification(.success)

2. Progress:
   - Subtle pulsing glow (0.8s cycle)
   - Minimal scale variation (1.0 to 1.01)

3. Exit (after 3s):
   - Slide up to top (-100pt offset)
   - Fade out to 0 opacity
   - Duration: 0.4s
   - Spring: response 0.4, dampingFraction 0.8

**Symbol Animation:**
- SF Symbol bounce effect on appearance
- Checkmark scales from 0.5 to 1.0 with spring
- Duration: 0.5s

---

### 3.1.9 Section Headers

**Requirements:**
- Consistent header style across sections
- Icon + label combination
- Subtle styling that doesn't compete with content

**Visual Specifications:**

**Header Component:**
```swift
HStack(spacing: 8) {
    Image(systemName: icon)
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(
            LinearGradient(
                colors: [.primary, .secondary],
                startPoint: .leading,
                endPoint: .trailing
            )
        )

    Text(title)
        .font(.system(.subheadline, design: .rounded, weight: .medium))
        .foregroundColor(.secondary)
        .textCase(.uppercase)
        .kerning(0.5)
}
.padding(.bottom, 4)
```

**Typography:**
- Font: SF Pro Rounded Medium
- Size: 12pt
- Case: Uppercase
- Letter spacing: +0.5pt
- Color: `.secondary`

**Icon:**
- Size: 13pt
- Weight: Medium
- Color: Gradient from `.primary` to `.secondary`

**Spacing:**
- Bottom padding: 4pt below header
- Top padding: 24pt above header (except first section: 20pt)

---

## 3.2 Color System Specifications

### 3.2.1 Dynamic Shift Color Generation

**Algorithm:**
Use existing `cardColor(for:)` function from TodayView that generates colors based on shift symbol hash.

**Color Requirements:**
- High contrast against white and black
- Vibrant and saturated (60-80% saturation)
- Avoid pure red (accessibility concern)
- Consistent per shift symbol

**Generated Color Variants:**

```swift
extension Color {
    // Primary shift color from hash
    static func shiftColor(for symbol: String) -> Color { /* existing algo */ }

    // Lighter variant (for gradients)
    func lighter(by percentage: Double = 0.2) -> Color {
        self.adjustBrightness(by: percentage)
    }

    // Darker variant (for gradients)
    func darker(by percentage: Double = 0.2) -> Color {
        self.adjustBrightness(by: -percentage)
    }

    // Adjusted brightness utility
    func adjustBrightness(by percentage: Double) -> Color { /* HSB adjustment */ }
}
```

**Color Usage Map:**
| Component | Primary Color | Secondary Color | Opacity |
|-----------|--------------|-----------------|---------|
| Current shift symbol bg | shiftColor | shiftColor.darker(0.2) | 80-90% |
| Current shift glow | shiftColor | - | 40% |
| Current shift border | shiftColor | shiftColor.lighter(0.1) | 60-20% |
| New shift symbol bg | newShiftColor | newShiftColor.darker(0.2) | 80-90% |
| New shift glow | newShiftColor | - | 50% |
| New shift border | newShiftColor | newShiftColor.lighter(0.1) | 60-20% |
| Transition arrow | currentShiftColor | newShiftColor | 100% |
| Primary button | newShiftColor | newShiftColor.darker(0.15) | 100% |
| Primary button shadow | newShiftColor | - | 40% |
| Primary button glow | newShiftColor | - | 30% |
| Focus border | newShiftColor | - | 60% |

### 3.2.2 Gradient Specifications

**Standard Gradient Formula:**
```swift
LinearGradient(
    colors: [
        baseColor.opacity(startOpacity),
        baseColor.darker(by: 0.15).opacity(endOpacity)
    ],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)
```

**Gradient Angles:**
- Card backgrounds: 135° (topLeading to bottomTrailing)
- Button fills: 135° (topLeading to bottomTrailing)
- Border gradients: 180° (top to bottom)
- Symbol backgrounds: 135° (topLeading to bottomTrailing)

**Gradient Stops:**
- 2-stop gradients: [0.0, 1.0]
- 3-stop gradients: [0.0, 0.5, 1.0] (used for special effects)

---

## 3.3 Animation Specifications

### 3.3.1 Spring Animation Standards

**Presets:**

```swift
extension Animation {
    static let appSpringDefault = Animation.spring(
        response: 0.5,
        dampingFraction: 0.75
    )

    static let appSpringBouncy = Animation.spring(
        response: 0.5,
        dampingFraction: 0.6
    )

    static let appSpringSmooth = Animation.spring(
        response: 0.4,
        dampingFraction: 0.85
    )

    static let appSpringQuick = Animation.spring(
        response: 0.3,
        dampingFraction: 0.8
    )
}
```

**Usage Map:**
| Animation Type | Spring Preset | Duration | Delay |
|----------------|---------------|----------|-------|
| Sheet entry | appSpringDefault | 0.5s | 0s |
| Sheet exit | appSpringSmooth | 0.4s | 0s |
| Card selection | appSpringBouncy | 0.5s | 0s |
| Card deselection | appSpringQuick | 0.4s | 0s |
| Button press | easeOut | 0.1s | 0s |
| Button release | appSpringBouncy | 0.3s | 0s |
| Focus state change | appSpringQuick | 0.3s | 0s |
| Glow appearance | easeIn | 0.5s | 0.1s |
| Symbol pulse | easeInOut | 2.0s | 0s (repeat) |
| Transition arrow | appSpringBouncy | 0.6s | 0s |
| Toast entry | appSpringDefault | 0.6s | 0s |
| Toast exit | appSpringSmooth | 0.4s | 3.0s |

### 3.3.2 Scale Effects

**Press Effects:**
```swift
extension View {
    func pressEffect(scale: CGFloat = 0.96) -> some View {
        self.buttonStyle(PressEffectButtonStyle(scale: scale))
    }
}

struct PressEffectButtonStyle: ButtonStyle {
    let scale: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
```

**Scale Values:**
- Standard button press: 0.96
- Large card press: 0.98
- Small icon press: 0.94
- Selection emphasis: 1.05
- Hover emphasis: 1.02

### 3.3.3 Opacity Transitions

**Standard Fades:**
- Fade in: 0.0 → 1.0, easeIn, 0.3s
- Fade out: 1.0 → 0.0, easeOut, 0.3s
- Cross-fade: easeInOut, 0.4s

**Disabled State:**
- Active to disabled: 1.0 → 0.6, easeOut, 0.2s
- Disabled to active: 0.6 → 1.0, easeIn, 0.3s

### 3.3.4 Color Transitions

**Color Changes:**
```swift
.animation(.easeInOut(duration: 0.5), value: selectedColor)
```

**Gradient Animations:**
```swift
AnimatableGradient(
    from: oldGradient,
    to: newGradient,
    duration: 0.8,
    curve: .easeInOut
)
```

### 3.3.5 Rotation & Transform

**Rotation Values:**
- Full rotation: 0° → 360°, duration 1.2s, easeInOut
- Subtle rotation: 0° → 5° → 0°, duration 0.6s

**Transform Combinations:**
```swift
.scaleEffect(scale)
.rotationEffect(.degrees(rotation))
.offset(x: offsetX, y: offsetY)
.opacity(opacity)
```

### 3.3.6 Shimmer & Glow Effects

**Shimmer Implementation:**
```swift
struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.3),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(
                    .linear(duration: 2.0)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 400
                }
            }
    }
}
```

**Glow Implementation:**
```swift
extension View {
    func glowEffect(
        color: Color,
        intensity: Double,
        radius: CGFloat = 12
    ) -> some View {
        self
            .shadow(color: color.opacity(intensity), radius: radius, x: 0, y: 0)
            .shadow(color: color.opacity(intensity * 0.5), radius: radius * 0.5, x: 0, y: 0)
    }
}
```

**Pulse Animation:**
```swift
struct PulsingModifier: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.02 : 1.0)
            .opacity(isPulsing ? 0.9 : 1.0)
            .animation(
                .easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear { isPulsing = true }
    }
}
```

---

## 3.4 Typography Specifications

### 3.4.1 Font System

**Font Families:**
- Display: SF Pro Display (headlines, large text)
- Text: SF Pro Text (body, labels)
- Rounded: SF Pro Rounded (buttons, badges)

**Type Scale:**
| Style | Font | Size | Weight | Line Height | Usage |
|-------|------|------|--------|-------------|-------|
| Large Title | SF Pro Display | 28pt | Bold | 34pt | Sheet title |
| Title 1 | SF Pro Display | 24pt | Semibold | 30pt | Section titles |
| Title 2 | SF Pro Display | 20pt | Semibold | 26pt | Card titles |
| Headline | SF Pro Text | 15pt | Semibold | 20pt | Emphasis |
| Body | SF Pro Text | 15pt | Regular | 20pt | Main content |
| Subheadline | SF Pro Text | 13pt | Regular | 18pt | Secondary info |
| Caption 1 | SF Pro Text | 11pt | Regular | 14pt | Tertiary info |
| Caption 2 | SF Pro Text | 11pt | Medium | 14pt | Labels |

### 3.4.2 Text Hierarchy

**Color Values:**
- Primary: `.primary` (System adaptive)
- Secondary: `.secondary` (70% primary)
- Tertiary: `.tertiary` (50% primary)
- Quaternary: `.quaternary` (30% primary)

**Semantic Colors:**
- Success text: Green (system)
- Error text: Red (system)
- Warning text: Orange (system)
- Info text: Blue (system)

### 3.4.3 Dynamic Type Support

**All text must support Dynamic Type:**
```swift
Text("Content")
    .font(.system(.body, design: .default))
    .lineLimit(nil) // Allow expansion
```

**Size Categories to Support:**
- Extra Small (xSmall)
- Small
- Medium (default)
- Large
- Extra Large (xLarge)
- Extra Extra Large (xxLarge)
- Extra Extra Extra Large (xxxLarge)

**Accessibility Sizes:**
- Accessibility Medium (AX1)
- Accessibility Large (AX2)
- Accessibility Extra Large (AX3)
- Accessibility Extra Extra Large (AX4)
- Accessibility Extra Extra Extra Large (AX5)

---

## 3.5 Spacing & Layout Specifications

### 3.5.1 Spacing System

**Base Unit:** 4pt

**Spacing Scale:**
```swift
enum Spacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 40
}
```

**Component Spacing:**
| Component | Internal Padding | External Spacing |
|-----------|-----------------|------------------|
| Sheet | 0pt | - |
| Sheet content | 20pt sides | - |
| Section | - | 24pt between |
| Card | 20pt | 12pt between |
| Header | 8pt horizontal | 4pt below |
| Text field | 12pt | 16pt below |
| Button | 16pt horizontal, 16pt vertical | 12pt between |
| Symbol | 12pt | 16pt from text |
| Badge | 6pt horizontal, 3pt vertical | 8pt |

### 3.5.2 Component Sizing

**Fixed Sizes:**
| Component | Width | Height |
|-----------|-------|--------|
| Sheet | Screen width | 680pt (medium detent) |
| Current shift card | Screen width - 40pt | Auto (min 120pt) |
| Shift picker card | 100pt | 120pt |
| Symbol (large) | 64pt | 64pt |
| Symbol (medium) | 36pt | 36pt |
| Symbol (small) | 24pt | 24pt |
| Primary button | Fill available | 52pt |
| Secondary button | Fill available | 52pt |
| Text field | Fill available | 80pt |
| Section header icon | 13pt | 13pt |

**Relative Sizes:**
- Card width: 100% of container minus horizontal padding
- Button width: 50% of container minus half gap (in HStack)

### 3.5.3 Corner Radius Standards

**Radius Scale:**
```swift
enum CornerRadius {
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 14
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
}
```

**Usage:**
- Sheet corners: 24pt (top only)
- Large cards: 20pt
- Medium cards: 16pt
- Buttons: 16pt
- Text fields: 14pt
- Badges: 8pt
- Symbols: 16pt (large), 12pt (medium), 8pt (small)

### 3.5.4 Shadow & Depth

**Shadow Levels:**

```swift
enum ShadowLevel {
    case none
    case light
    case medium
    case heavy
    case colored(Color)

    var properties: (radius: CGFloat, y: CGFloat, opacity: Double) {
        switch self {
        case .none: return (0, 0, 0)
        case .light: return (8, 2, 0.1)
        case .medium: return (12, 4, 0.2)
        case .heavy: return (20, 8, 0.3)
        case .colored: return (12, 6, 0.25)
        }
    }
}
```

**Shadow Application:**
| Component | Level | Color |
|-----------|-------|-------|
| Sheet | None | - |
| Current shift card | Medium | Black |
| Selected picker card | Heavy | shiftColor |
| Unselected picker card | Light | Black |
| Primary button | Colored | shiftColor |
| Secondary button | None | - |
| Toast | Heavy | shiftColor |
| Text field (focused) | Light | shiftColor |

---

## 4. Implementation Approach

### 4.1 Architecture Preservation

**Requirements:**
- No breaking changes to ShiftChangeSheet API
- Maintain existing protocol conformances
- Preserve SwiftData integration
- Keep repository pattern intact
- Respect Swift 6 concurrency model

**Interface Contract:**
```swift
// Existing interface must remain unchanged
struct ShiftChangeSheet: View {
    @Bindable var schedule: Schedule
    let shift: ScheduledShift
    let shiftCatalog: ShiftCatalog
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        // Enhanced implementation
    }
}
```

### 4.2 Component Extraction Strategy

**New Reusable Components to Create:**

1. **EnhancedShiftSymbolView.swift**
   - Replaces basic symbol rendering
   - Supports size variants (small, medium, large)
   - Includes gradient background, glow, pulse animation

2. **GlassCardV2.swift** (or enhance existing GlassCard)
   - Add gradient border support
   - Add shadow customization
   - Add glow effect option

3. **ShiftPickerCardView.swift**
   - Individual picker card component
   - Manages selection state animation
   - Reusable across app

4. **TransitionArrowView.swift**
   - Animated arrow between states
   - Color gradient support
   - Directional variant support

5. **EnhancedToast.swift**
   - Premium toast notification component
   - Color-themed styling
   - Auto-dismiss with progress

6. **PressEffectButtonStyle.swift**
   - Reusable button style with press animation
   - Configurable scale factor

7. **AnimationExtensions.swift**
   - Preset animation definitions
   - Reusable animation modifiers

8. **ColorExtensions.swift**
   - Color manipulation utilities
   - Gradient generation helpers

9. **ViewModifiers.swift**
   - Glow effect modifier
   - Shimmer effect modifier
   - Pulse animation modifier
   - Press effect modifier

### 4.3 Implementation Phases

**Phase 1: Foundation Components (2-3 hours)**
- Create color extension utilities
- Create animation preset extensions
- Create reusable view modifiers (glow, shimmer, pulse)
- Create press effect button style
- Update GlassCard component if needed

**Phase 2: Symbol & Card Components (2-3 hours)**
- Create EnhancedShiftSymbolView
- Create ShiftPickerCardView with selection animations
- Create TransitionArrowView
- Test in isolation

**Phase 3: Sheet Layout Restructure (2-3 hours)**
- Refactor ShiftChangeSheet layout structure
- Implement current shift card with enhanced styling
- Implement new shift picker section with scroll
- Implement section headers
- Add keyboard dismissal verification

**Phase 4: Interactive Elements (2 hours)**
- Enhance text field with focus animations
- Implement enhanced button styling with gradients
- Add loading state animations
- Implement haptic feedback

**Phase 5: Toast & Confirmation (1-2 hours)**
- Create EnhancedToast component
- Style confirmation dialog
- Implement toast animation sequence

**Phase 6: Polish & Refinement (2-3 hours)**
- Fine-tune all animation timings
- Optimize color contrast for accessibility
- Test with VoiceOver
- Test with Dynamic Type sizes
- Performance testing (60 FPS verification)

**Phase 7: Testing & Documentation (1-2 hours)**
- Unit tests for new components
- UI tests for interaction flows
- Code documentation
- Update CHANGELOG

**Total Estimated Time:** 12-18 hours

### 4.4 File Structure

```
ShiftScheduler/
├── Views/
│   ├── ShiftChangeSheet.swift (refactored)
│   └── Components/
│       ├── EnhancedShiftSymbolView.swift (new)
│       ├── ShiftPickerCardView.swift (new)
│       ├── TransitionArrowView.swift (new)
│       ├── EnhancedToast.swift (new)
│       └── SectionHeader.swift (new)
├── Styles/
│   ├── ButtonStyles.swift (updated)
│   └── ViewModifiers.swift (new/updated)
├── Extensions/
│   ├── Color+Extensions.swift (updated)
│   ├── Animation+Extensions.swift (new)
│   └── View+Extensions.swift (updated)
└── Tests/
    ├── ShiftChangeSheetTests.swift (updated)
    └── ComponentTests/
        ├── EnhancedShiftSymbolViewTests.swift (new)
        └── ShiftPickerCardViewTests.swift (new)
```

### 4.5 Swift 6 Concurrency Compliance

**Requirements:**
- All new components must use strict concurrency checking
- Use @MainActor for SwiftUI views
- Use nonisolated for protocol methods when needed
- No global mutable state
- Sendable conformance where required

**Example:**
```swift
@MainActor
struct EnhancedShiftSymbolView: View {
    let symbol: String
    let color: Color
    let size: SymbolSize

    nonisolated init(symbol: String, color: Color, size: SymbolSize = .medium) {
        self.symbol = symbol
        self.color = color
        self.size = size
    }

    var body: some View {
        // Implementation
    }
}
```

### 4.6 Protocol-Oriented Design

**Abstraction Points:**
- AnimationProvider protocol for testable animation timing
- ColorProvider protocol for testable color generation
- HapticProvider protocol for testable haptic feedback

**Example:**
```swift
protocol ColorProvider {
    func shiftColor(for symbol: String) -> Color
    func gradient(from color: Color, darkening: Double) -> [Color]
}

struct DefaultColorProvider: ColorProvider {
    func shiftColor(for symbol: String) -> Color {
        // Hash-based color generation
    }

    func gradient(from color: Color, darkening: Double) -> [Color] {
        [color, color.darker(by: darkening)]
    }
}

// View accepts protocol
struct ShiftPickerCardView: View {
    let colorProvider: ColorProvider
    // ...
}
```

---

## 5. Testing Strategy

### 5.1 Visual Regression Testing

**Snapshots Required:**
- Sheet in default state (no selection)
- Sheet with shift selected
- Sheet with text field focused
- Sheet with loading state
- Sheet with disabled button
- Toast appearance
- Various Dynamic Type sizes (Medium, xLarge, AX3)
- Light and dark mode

**Tools:**
- Manual visual inspection
- Screenshot comparisons
- Accessibility Inspector

### 5.2 Animation Performance Testing

**Metrics:**
- Frame rate during animations (target: 60 FPS)
- Sheet presentation time (target: <0.5s perceived)
- Button press responsiveness (target: <0.1s to feedback)

**Tools:**
- Xcode Instruments (Time Profiler, Core Animation)
- FPS overlay during development

**Test Scenarios:**
1. Sheet presentation from Today view
2. Rapid shift picker selection changes
3. Text field focus/unfocus cycles
4. Button press animations
5. Toast appearance/disappearance
6. Simultaneous animations (selection + glow + scale)

### 5.3 Accessibility Testing

**VoiceOver Testing:**
- All elements have descriptive labels
- Selection announces correctly
- Button states announced (enabled/disabled)
- Focus order is logical

**Dynamic Type Testing:**
- Test all size categories
- Verify no text truncation
- Verify layout doesn't break
- Verify buttons remain accessible

**Color Contrast Testing:**
- Minimum 4.5:1 contrast for text
- Minimum 3:1 contrast for UI elements
- Test with color blindness simulators

**Reduced Motion Testing:**
- Respect reduce motion setting
- Replace animations with simple fades/crossfades

### 5.4 Unit Testing

**Components to Test:**
```swift
@Test func testShiftSymbolViewRendersCorrectly() async throws {
    let symbol = EnhancedShiftSymbolView(
        symbol: "D",
        color: .blue,
        size: .large
    )
    #expect(symbol.symbol == "D")
    #expect(symbol.size == .large)
}

@Test func testColorProviderGeneratesConsistentColors() async throws {
    let provider = DefaultColorProvider()
    let color1 = provider.shiftColor(for: "D")
    let color2 = provider.shiftColor(for: "D")
    #expect(color1 == color2)
}

@Test func testShiftPickerCardSelectionState() async throws {
    let card = ShiftPickerCardView(
        shiftType: mockShiftType,
        isSelected: true
    )
    #expect(card.isSelected == true)
}

@Test func testButtonDisabledWhenNoSelection() async throws {
    let sheet = ShiftChangeSheet(
        schedule: mockSchedule,
        shift: mockShift,
        shiftCatalog: mockCatalog
    )
    // Verify button is disabled initially
    #expect(sheet.canSwitch == false)
}
```

### 5.5 Integration Testing

**Test Scenarios:**
1. Complete shift switch flow
   - Present sheet
   - Select new shift
   - Enter reason
   - Tap Switch button
   - Verify confirmation
   - Verify toast
   - Verify dismissal
   - Verify schedule updated

2. Cancel flow
   - Present sheet
   - Select new shift
   - Tap Cancel
   - Verify dismissal
   - Verify no changes

3. Error handling
   - Simulate save failure
   - Verify error state
   - Verify recovery

### 5.6 Performance Benchmarks

**Targets:**
| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| Sheet presentation time | <0.5s | Time from tap to visible |
| Animation frame rate | 60 FPS | Instruments Core Animation |
| Memory usage | <10MB increase | Instruments Allocations |
| Selection response time | <0.1s | Time from tap to visual feedback |
| Toast animation smoothness | 60 FPS | Instruments Core Animation |

---

## 6. Accessibility Requirements

### 6.1 VoiceOver Support

**Labels Required:**
- Sheet: "Switch shift for [date]"
- Current shift card: "Current shift: [name], [time], [location]"
- Shift picker cards: "[Shift name], [time range]. [Selected state]"
- Switch button: "Switch to [shift name]" or "Switch shift. Select a new shift first." (disabled)
- Cancel button: "Cancel shift switch"
- Text field: "Reason for shift switch, optional"
- Toast: "Shift switched successfully to [shift name]"

**Hints:**
- Disabled button: "Select a new shift to enable switching"
- Text field: "Enter an optional reason for switching shifts"

**Traits:**
- Buttons: `.button` trait
- Selected cards: `.selected` trait
- Headers: `.header` trait
- Text field: `.allowsDirectInteraction` trait

### 6.2 Dynamic Type Support

**Minimum Requirements:**
- Support all standard size categories
- Support accessibility size categories (AX1-AX5)
- Text never truncates - layout expands vertically
- Buttons remain minimum 44pt tap target
- Maintain readability at all sizes

**Layout Adjustments:**
| Size Category | Layout Changes |
|---------------|----------------|
| xSmall - Large | Default layout |
| xLarge - xxxLarge | Increase vertical spacing by 20% |
| AX1 - AX3 | Stack picker cards vertically |
| AX4 - AX5 | Increase card size, reduce elements per row |

### 6.3 Reduced Motion

**When reduce motion is enabled:**
```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

var animation: Animation {
    reduceMotion ? .easeInOut(duration: 0.2) : .appSpringDefault
}
```

**Changes:**
- Replace spring animations with simple easing
- Remove pulse animations
- Remove shimmer effects
- Replace scale effects with simple opacity
- Remove rotation animations
- Keep transitions but simplify to fade only

### 6.4 Color & Contrast

**Requirements:**
- WCAG 2.1 Level AA compliance minimum
- Text contrast ratio: Minimum 4.5:1 (large text: 3:1)
- UI element contrast: Minimum 3:1
- Test with color blindness simulators (protanopia, deuteranopia, tritanopia)

**High Contrast Mode:**
- Detect high contrast preference
- Increase border widths from 1-2pt to 3-4pt
- Remove subtle gradients in favor of solid colors
- Increase shadow opacity

---

## 7. Edge Cases & Error Handling

### 7.1 Data Edge Cases

**Scenarios to Handle:**
1. **No available shifts to switch to**
   - Hide or disable shift picker section
   - Display message: "No other shifts available"
   - Disable switch button

2. **Very long shift names**
   - Text should wrap, not truncate
   - Limit to 2-3 lines with lineLimit
   - Scale down font if necessary

3. **Very long reason text**
   - Enforce character limit (e.g., 200 chars)
   - Show character count near limit
   - Disable switch button if exceeds limit

4. **Shift with no location**
   - Display "No location" or hide location row
   - Don't break layout

5. **Shift with no symbol**
   - Use default symbol (e.g., "?" or "S")
   - Generate color from shift name instead

### 7.2 State Management

**Loading States:**
- Show spinner on button
- Disable all interactive elements
- Prevent dismissal during save

**Error States:**
- Display error alert with retry option
- Maintain form state (don't reset)
- Log error with OSLog

**Success States:**
- Show toast
- Dismiss sheet after 0.5s delay
- Clear form state
- Trigger haptic feedback

### 7.3 Concurrency Edge Cases

**Scenarios:**
1. **User dismisses sheet during save**
   - Allow task to complete
   - Don't show toast if dismissed
   - Ensure data consistency

2. **Rapid button tapping**
   - Disable button after first tap
   - Prevent duplicate save operations

3. **Schedule modified externally during switch**
   - Detect conflict
   - Show alert about conflict
   - Offer to refresh and retry

### 7.4 UI Edge Cases

**Small Screens (iPhone SE):**
- Reduce sheet height to fit
- Use smaller detent
- Scale down elements slightly
- Prioritize vertical scrolling

**Large Screens (iPad, iPhone Pro Max):**
- Center sheet with max width
- Don't stretch horizontally beyond 500pt
- Increase font sizes slightly

**Landscape Orientation:**
- Adjust layout to horizontal
- Stack sections side-by-side if space allows
- Reduce vertical padding

**Dark Mode:**
- All colors adapt automatically
- Test glow effects visibility
- Ensure borders remain visible
- Verify text readability

---

## 8. Performance Optimization

### 8.1 Rendering Optimization

**Strategies:**
- Use `.drawingGroup()` for complex animations
- Avoid opacity animations on large views (use `.transition` instead)
- Cache gradient calculations
- Use `GeometryReader` sparingly
- Minimize view re-renders with `@State` hygiene

**Example:**
```swift
// Cache color calculations
private var shiftColor: Color {
    Color.shiftColor(for: shiftType.symbol)
}

// Use drawingGroup for complex animations
.drawingGroup(opaque: false, colorMode: .nonLinear)
```

### 8.2 Memory Management

**Strategies:**
- No retained cycles in closures
- Release animation resources when view disappears
- Use weak/unowned references appropriately
- Clear cached values when sheet dismissed

**Example:**
```swift
.onDisappear {
    // Clean up animations
    animationWorkItem?.cancel()
    animationWorkItem = nil
}
```

### 8.3 Animation Performance

**Guidelines:**
- Limit simultaneous animations to 3-4 max
- Use `.animation(_:value:)` instead of implicit animations
- Prefer transform-based animations (scale, rotation) over layout animations
- Avoid animating `frame()` or `padding()`
- Use `transaction` for fine control

**Example:**
```swift
// Good: Transform-based
.scaleEffect(isSelected ? 1.05 : 1.0)
.animation(.appSpringDefault, value: isSelected)

// Avoid: Layout-based
.frame(width: isSelected ? 120 : 100) // Triggers layout
```

---

## 9. Documentation Requirements

### 9.1 Code Documentation

**All new components must include:**
- Summary description
- Parameter documentation
- Usage examples
- Animation behavior notes
- Accessibility notes

**Example:**
```swift
/// An enhanced shift symbol view with dynamic colors, gradients, and animations.
///
/// This view displays a shift symbol (e.g., "D" for Day shift) with a vibrant
/// gradient background, optional glow effect, and subtle pulse animation.
///
/// - Parameters:
///   - symbol: The single-character shift symbol to display
///   - color: The base color for the symbol (generates gradient automatically)
///   - size: The size variant (.small, .medium, .large)
///   - showGlow: Whether to display the glow effect (default: true)
///   - animatePulse: Whether to animate a subtle pulse (default: true)
///
/// - Example:
///   ```swift
///   EnhancedShiftSymbolView(
///       symbol: "D",
///       color: .blue,
///       size: .large
///   )
///   ```
///
/// - Accessibility:
///   - VoiceOver reads symbol and shift name
///   - Respects reduce motion preference (disables pulse)
///   - Supports Dynamic Type for symbol scaling
struct EnhancedShiftSymbolView: View {
    // ...
}
```

### 9.2 README Updates

**Add section to README:**
```markdown
## Switch Shift UI

The Switch Shift sheet provides a visually rich interface for changing scheduled shifts. Key features:

- **Dynamic color system**: Colors adapt based on shift identity
- **Liquid Glass design**: Premium iOS 26 glassmorphic styling
- **Smooth animations**: 60 FPS spring-based animations throughout
- **Full accessibility**: VoiceOver, Dynamic Type, Reduced Motion support

### Components

- `EnhancedShiftSymbolView`: Color-coded shift symbol with gradients
- `ShiftPickerCardView`: Interactive shift selection cards
- `TransitionArrowView`: Animated transition indicator
- `EnhancedToast`: Premium toast notifications
```

### 9.3 CHANGELOG Entry

```markdown
## [Version X.X.X] - 2025-10-XX

### Enhanced
- **Switch Shift UI**: Complete visual overhaul with iOS 26 Liquid Glass design
  - Dynamic color system based on shift identity
  - Smooth spring animations throughout interface
  - Enhanced shift symbol views with gradients and glow effects
  - Interactive shift picker cards with selection animations
  - Premium button styling with gradients and depth
  - Enhanced toast notifications with color theming
  - Improved visual hierarchy and spacing
  - Full accessibility support (VoiceOver, Dynamic Type, Reduced Motion)

### Added
- `EnhancedShiftSymbolView`: Reusable shift symbol component
- `ShiftPickerCardView`: Interactive shift selection cards
- `TransitionArrowView`: Animated state transition indicator
- `EnhancedToast`: Premium toast notification component
- Color extension utilities for gradient generation
- Animation preset extensions for consistent timing
- View modifiers for glow, shimmer, and pulse effects

### Performance
- Optimized animations to maintain 60 FPS
- Reduced view re-renders with state management improvements
- Cached color calculations for better performance
```

---

## 10. Risk Assessment & Mitigation

### 10.1 Technical Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Performance degradation on older devices | Medium | High | Performance testing on iPhone 12, optimize animations, provide reduced motion fallback |
| Animation timing conflicts | Low | Medium | Use explicit animation values, thorough testing |
| Accessibility regressions | Low | High | Comprehensive VoiceOver testing, automated accessibility tests |
| Color contrast failures | Low | Medium | WCAG testing tools, color contrast analyzer |
| Memory leaks from animations | Low | Medium | Proper cleanup in onDisappear, memory profiling |
| Layout breaks on edge cases | Medium | Medium | Test all device sizes, Dynamic Type sizes |

### 10.2 UX Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Animations too distracting | Low | Medium | User feedback, adjustable animation intensity |
| Colors too vibrant/harsh | Low | Medium | Color testing with diverse users, adjust saturation |
| Information overload | Low | Medium | Clear visual hierarchy, user testing |
| Increased cognitive load | Low | Low | Maintain familiar patterns, progressive disclosure |

### 10.3 Project Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Implementation time exceeds estimate | Medium | Low | Phase-based approach, can stop after any phase |
| Breaking changes to existing code | Low | High | Comprehensive testing, maintain API contract |
| Merge conflicts with other features | Low | Medium | Frequent commits, clear component boundaries |

---

## 11. Success Criteria & Acceptance

### 11.1 Functional Requirements

**Must Have:**
- [ ] All existing functionality preserved
- [ ] Switch shift workflow completes successfully
- [ ] Data saved correctly to SwiftData
- [ ] Keyboard dismissal works correctly
- [ ] Cancel flow works correctly
- [ ] Error handling maintained

### 11.2 Visual Requirements

**Must Have:**
- [ ] Dynamic color system implemented
- [ ] Gradient backgrounds on cards and buttons
- [ ] Glow effects on selected elements
- [ ] Border gradients on cards
- [ ] Enhanced shift symbol views
- [ ] Premium button styling
- [ ] Enhanced toast notification
- [ ] Smooth spring animations throughout

**Nice to Have:**
- [ ] Shimmer effects on selections
- [ ] Particle effects on success
- [ ] Advanced transition animations
- [ ] Confetti on successful switch

### 11.3 Performance Requirements

**Must Have:**
- [ ] 60 FPS during all animations (iPhone 12+)
- [ ] Sheet presentation <0.5s perceived time
- [ ] No memory leaks detected
- [ ] Memory increase <10MB during sheet lifecycle

### 11.4 Accessibility Requirements

**Must Have:**
- [ ] All elements have VoiceOver labels
- [ ] All Dynamic Type sizes supported
- [ ] Reduced motion respected
- [ ] Color contrast passes WCAG AA
- [ ] Keyboard navigation works (iPad)
- [ ] All buttons meet 44pt minimum tap target

### 11.5 Code Quality Requirements

**Must Have:**
- [ ] Swift 6 concurrency compliance
- [ ] No compiler warnings
- [ ] All new code documented
- [ ] Unit tests for new components
- [ ] Integration tests pass
- [ ] Code review approved

---

## 12. Future Enhancements

### 12.1 Phase 2 Features (Not in Scope)

**Advanced Animations:**
- Confetti effect on successful switch
- Particle systems for celebrations
- Advanced transition animations between states
- Micro-interactions on every element

**Enhanced Interactivity:**
- Drag-to-switch gesture
- Swipe between shift options
- Pinch to zoom shift details
- Long-press for shift info popover

**AI/Smart Features:**
- Suggested shifts based on history
- Conflict warnings before switching
- Shift pattern insights
- Optimal switch recommendations

### 12.2 Potential Improvements

**Color System:**
- User-customizable shift colors
- Color themes (pastel, vibrant, professional)
- Season-based color palettes
- Accessibility color presets

**Layout Options:**
- Compact vs. comfortable spacing modes
- Grid vs. list picker layouts
- Customizable section order
- Collapsible sections

**Haptics:**
- Custom haptic patterns per shift
- Haptic feedback customization
- Audio feedback option

---

## 13. Appendix

### 13.1 Color Algorithm Reference

**Existing cardColor Algorithm (from TodayView):**
```swift
private func cardColor(for shift: ScheduledShift) -> Color {
    let symbol = shift.shiftType.symbol
    let hash = symbol.hashValue
    let hue = Double(abs(hash) % 360) / 360.0
    return Color(hue: hue, saturation: 0.7, brightness: 0.85)
}
```

**Proposed Enhanced Algorithm:**
```swift
extension Color {
    static func shiftColor(for symbol: String, saturation: Double = 0.70, brightness: Double = 0.85) -> Color {
        let hash = symbol.hashValue
        let hue = Double(abs(hash) % 360) / 360.0
        return Color(hue: hue, saturation: saturation, brightness: brightness)
    }

    func adjusted(brightness delta: Double = 0, saturation deltaSat: Double = 0) -> Color {
        // Convert to HSB, adjust, return new color
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return Color(hue: Double(h),
                     saturation: max(0, min(1, Double(s) + deltaSat)),
                     brightness: max(0, min(1, Double(b) + delta)),
                     opacity: Double(a))
    }
}
```

### 13.2 Animation Timing Reference

**iOS System Animation Durations:**
- Quick: 0.2-0.3s
- Standard: 0.3-0.5s
- Slow: 0.5-0.8s
- Very slow: 0.8-1.2s

**Recommended Spring Parameters:**
- Snappy: response 0.3, damping 0.7
- Bouncy: response 0.5, damping 0.6
- Smooth: response 0.4, damping 0.85
- Gentle: response 0.6, damping 0.9

### 13.3 SF Symbol Reference

**Symbols Used:**
- `arrow.triangle.2.circlepath`: Shift switch icon
- `chevron.down.circle.fill`: Transition arrow
- `checkmark.circle.fill`: Success indicator
- `text.alignleft`: Reason section icon
- `xmark.circle.fill`: Error indicator
- `clock.fill`: Time indicator
- `location.fill`: Location indicator
- Custom shift symbols from ShiftType

### 13.4 Glossary

**Terms:**
- **Liquid Glass**: Design pattern using translucent materials, blurs, and depth
- **Glassmorphism**: UI design trend featuring frosted glass aesthetics
- **Spring Animation**: Physics-based animation with natural motion
- **Haptic Feedback**: Tactile responses to user interactions
- **Dynamic Type**: iOS system for scalable text sizes
- **VoiceOver**: iOS screen reader for accessibility
- **Reduced Motion**: Accessibility setting to minimize animations
- **WCAG**: Web Content Accessibility Guidelines
- **Sendable**: Swift concurrency protocol for thread-safe types

---

## 14. Sign-off & Approval

### 14.1 Stakeholder Review

**Product Manager:**
- [ ] Vision and goals approved
- [ ] Success metrics defined
- [ ] Scope appropriate

**Design Lead:**
- [ ] Visual specifications approved
- [ ] Accessibility requirements met
- [ ] Brand consistency maintained

**Engineering Lead:**
- [ ] Technical approach sound
- [ ] Risks identified and mitigated
- [ ] Timeline realistic

**QA Lead:**
- [ ] Testing strategy comprehensive
- [ ] Acceptance criteria clear
- [ ] Edge cases covered

### 14.2 Implementation Authorization

**Authorized by:** [To be filled]
**Date:** [To be filled]
**Target Release:** [To be filled]

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-10-11 | Product Manager | Initial PRD creation |

---

**End of Document**

Total Pages: 26
Total Sections: 14
Total Requirements: 150+
Estimated Reading Time: 45 minutes
Estimated Implementation Time: 12-18 hours
