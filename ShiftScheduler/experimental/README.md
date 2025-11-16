# Experimental Shift Card Designs

This directory contains 10 different visual designs for shift cards, created for comparison and evaluation.

**Target Platform:** iOS 26.0+
**Framework:** SwiftUI
**Created:** November 16, 2025

## Design Overview

All designs display the same data with different layouts and visual styles:
- Shift status (Upcoming/Active/Completed)
- Shift title
- Symbol (emoji)
- Time range
- Description
- Location (name + address)
- Notes (optional)

## The 10 Designs

### CardDesign1.swift - Gradient Border with Floating Symbol
**Philosophy:** Modern, depth-focused design with visual prominence

**Key Features:**
- 80pt circular symbol with gradient background (floating with shadow)
- Vertical info stack: Title, description, colored time badge, location
- Animated gradient active indicator bar at bottom
- Dynamic gradient colors based on shift type

**Best For:** Visual impact, modern aesthetic, color-coded organization

---

### CardDesign2.swift - Timeline Card with Leading Edge Accent
**Philosophy:** Information hierarchy inspired by timeline patterns

**Key Features:**
- 5pt thick vertical accent bar on left edge (shift type color)
- Header row: Status badge + Title + Location
- Symbol inline with time
- Expandable notes section
- Clean, professional layout

**Best For:** Maximum scannability, clear visual categorization by color bar

---

### CardDesign3.swift - Split-Panel Design
**Philosophy:** Separation of identity (visual) from details (textual)

**Key Features:**
- 40% left panel: Large symbol with gradient background
- 60% right panel: All text details stacked
- Clean vertical divider
- Premium magazine-style layout

**Best For:** Dramatic visual separation, iconic symbol branding

---

### CardDesign4.swift - Glassmorphic Floating Card
**Philosophy:** iOS-native liquid glass aesthetic with depth and blur

**Key Features:**
- `.ultraThinMaterial` background (frosted glass effect)
- 64pt symbol centered at top
- Horizontal icon row layout
- Minimal color usage with subtle tints
- Address bar at bottom with colored background

**Best For:** Premium iOS feel, sophisticated aesthetic, blends with any background

---

### CardDesign5.swift - Horizontal Compact Strip
**Philosophy:** Maximum information density for list views

**Key Features:**
- Compact ~70-80pt height when collapsed
- Single horizontal row layout
- Expandable to show full details on demand
- Fits 10-15 shifts per screen

**Best For:** Dense list views, quick scanning of many shifts

---

### CardDesign6.swift - Card with Header Banner
**Philosophy:** Clear sections with prominent colored header

**Key Features:**
- Colored gradient header banner (full width)
- White text on colored background for high contrast
- Large clock icon with time in body
- Full display of all text information

**Best For:** Strong visual segmentation, high readability, distinguishing shifts in lists

---

### CardDesign7.swift - Icon-First Minimal
**Philosophy:** Symbol is hero, everything else is support

**Key Features:**
- Huge 80-100pt symbol (absolutely dominant)
- Tiny status dot (6-8pt)
- Ultra-clean typography with generous whitespace
- Subtle background tint (barely noticeable)

**Best For:** Emoji-forward design, modern minimal aesthetic, instant visual recognition

---

### CardDesign8.swift - Metro/Tile Style
**Philosophy:** Windows Metro-inspired flat design with bold typography

**Key Features:**
- Flat colored background (entire card, no gradients)
- All text white or very light
- Huge bold title (can take 3-4 lines)
- Sharp, flat design (no shadows)
- Details shown on tap

**Best For:** Bold, unmissable color blocks, modern flat aesthetic, maximum visual distinction

---

### CardDesign9.swift - Card with Inline Status Timeline
**Philosophy:** Timeline-inspired with status progression visualization

**Key Features:**
- 3-dot horizontal timeline at top (Upcoming → Active → Completed)
- Current status filled, others hollow
- Duration calculation shown with time
- Clean, intuitive status progression

**Best For:** Understanding shift lifecycle at a glance, professional appearance

---

### CardDesign10.swift - Layered Depth Card
**Philosophy:** Multiple elevation levels create physical depth

**Key Features:**
- Floating symbol container (8pt elevation with shadow)
- Elevated time pill (4pt elevation)
- Inset location area (recessed look)
- Separate elevated notes section
- Material Design 3 inspired

**Best For:** Tactile 3D feel, cross-platform aesthetic, physical depth through elevation

---

## Technical Details

### Common Features (All Designs)

- **Props Support:**
  - `shift: ScheduledShift?`
  - `onTap: (() -> Void)?`
  - `isSelected: Bool`
  - `onSelectionToggle: ((UUID) -> Void)?`
  - `isInSelectionMode: Bool`

- **Functionality:**
  - Tap and long-press gesture handlers
  - Selection state with blue border and checkmark
  - Haptic feedback on interactions
  - Empty state handling
  - Press animations (scale to 0.98)
  - Safe unwrapping throughout

- **SwiftUI Patterns:**
  - iOS 26.0+ compatible
  - Swift 6 concurrency patterns
  - Modern `@Observable` state management
  - Proper `@MainActor` usage
  - Dynamic Type support
  - Accessibility considerations

### Text Truncation Handling

Each design handles long text differently:

- **No Truncation:** CardDesign3, CardDesign4, CardDesign6, CardDesign7, CardDesign9, CardDesign10
- **Minimal Truncation:** CardDesign1, CardDesign2
- **Expandable Details:** CardDesign2, CardDesign5, CardDesign8

### Color System

All designs use `ShiftColorPalette` for consistent professional colors:
- Professional Blue
- Forest Green
- Warm Brown
- Slate Purple
- Muted Burgundy
- Teal

Colors are dynamically assigned based on shift symbol hash for consistency.

## Usage

### Previewing Designs

Each file includes comprehensive `#Preview` sections:
```swift
#Preview {
    VStack(spacing: 16) {
        Text("Shift without notes")
        CardDesign1(shift: sampleShift, onTap: {}, ...)

        Text("Shift with notes")
        CardDesign1(shift: sampleShiftWithNotes, onTap: {}, ...)

        Text("Selected state")
        CardDesign1(shift: sampleShift, isSelected: true, ...)

        Text("Empty state")
        CardDesign1(shift: nil, ...)
    }
    .padding()
}
```

### Integration

To use any design in your app:
```swift
import SwiftUI

struct MyView: View {
    let shift: ScheduledShift

    var body: some View {
        CardDesign1(
            shift: shift,
            onTap: { print("Tapped") },
            isSelected: false,
            onSelectionToggle: nil,
            isInSelectionMode: false
        )
    }
}
```

## Recommendations

**For Maximum Scannability:**
- CardDesign2 (Timeline with accent bar)
- CardDesign5 (Compact strip)

**For Visual Impact:**
- CardDesign1 (Gradient border)
- CardDesign6 (Header banner)
- CardDesign8 (Metro tile)

**For iOS-Native Feel:**
- CardDesign4 (Glassmorphic)
- CardDesign10 (Layered depth)

**For Information Density:**
- CardDesign5 (Compact strip - fits 10-15 per screen)

**For Accessibility:**
- CardDesign2 (High contrast accent bar)
- CardDesign6 (Clear header separation)
- CardDesign9 (Status timeline)

**For Modern/Trendy:**
- CardDesign4 (Liquid glass)
- CardDesign7 (Icon-first minimal)
- CardDesign8 (Metro flat)

## Build Status

✅ All 10 designs compile successfully
✅ Zero errors or warnings
✅ Ready for preview and testing

## Next Steps

1. Preview each design in Xcode Canvas
2. Compare visual styles and layouts
3. Test with various content lengths
4. Evaluate readability and scannability
5. Select preferred design(s) for production use
6. Optionally combine best elements from multiple designs

---

**Note:** These are experimental designs for evaluation purposes. They are not yet integrated into the main app navigation but can be previewed individually in Xcode.
