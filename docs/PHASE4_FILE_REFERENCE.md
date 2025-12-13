# ShiftScheduler Multi-Select Implementation - File Reference Guide

## Absolute File Paths

### Redux Infrastructure (Production Ready)

#### State Definition
- **File**: `/Users/farley/Documents/code/projects/swift/ShiftScheduler/ShiftScheduler/Redux/State/AppState.swift`
- **Lines**: 228-323 (Multi-select section)
- **Key Classes**: 
  - `ScheduleState` struct with multi-select properties
  - `SelectionMode` enum (delete/add)

#### Actions Definition
- **File**: `/Users/farley/Documents/code/projects/swift/ShiftScheduler/ShiftScheduler/Redux/Action/AppAction.swift`
- **Lines**: 378-402 (Multi-select section)
- **Key Enum**: `ScheduleAction` with 9 multi-select cases

#### Reducer Logic
- **File**: `/Users/farley/Documents/code/projects/swift/ShiftScheduler/ShiftScheduler/Redux/Reducer/AppReducer.swift`
- **Lines**: 517-571 (Multi-select section)
- **Function**: `scheduleReducer(state:action:)` switch cases

---

### UI Components (Requiring Enhancement)

#### Shift Card Component
- **File**: `/Users/farley/Documents/code/projects/swift/ShiftScheduler/ShiftScheduler/Views/Components/UnifiedShiftCard.swift`
- **Lines**: 286
- **Current Parameters**: `shift: ScheduledShift?`, `onTap: (() -> Void)?`
- **Status**: Ready for multi-select enhancement
- **Changes Needed**:
  - Add `isSelected: Bool` parameter
  - Add `onSelectionToggle: (UUID) -> Void` callback
  - Add long-press gesture handler
  - Add selection indicator (checkmark overlay)

#### Main Schedule View
- **File**: `/Users/farley/Documents/code/projects/swift/ShiftScheduler/ShiftScheduler/Views/ScheduleView.swift`
- **Lines**: 509
- **Current Structure**:
  - Header buttons section (lines 202-209)
  - Calendar view section (lines 211-237)
  - Shift list section (lines 240-285)
- **Integration Points**:
  - Replace header buttons with selection toolbar when in multi-select mode
  - Enhance shift card rendering with selection state
  - Add long-press gesture to shift cards
  - Add bulk delete confirmation dialog

---

### Reference Components (For Design Patterns)

#### Button Patterns
- **File**: `/Users/farley/Documents/code/projects/swift/ShiftScheduler/ShiftScheduler/Views/UndoRedoButtonsView.swift`
- **Lines**: 236
- **Useful Components**:
  - `UndoRedoButton` struct (lines 57-135) - Reusable button pattern
  - `CompactUndoRedoButtons` struct (lines 138-206) - Toolbar pattern
  - Demonstrates: enabled/disabled states, loading states, haptic feedback, animations

#### Action Button Pattern
- **File**: `/Users/farley/Documents/code/projects/swift/ShiftScheduler/ShiftScheduler/Views/Components/GradientActionButton.swift`
- **Lines**: 205
- **Components**:
  - `GradientActionButton` - Primary action button with gradient
  - `GlassActionButton` - Secondary action button with glass morphism
  - Features: shimmer effect, glow, state management

---

### Test Files (Comprehensive Coverage)

#### State Tests
- **File**: `/Users/farley/Documents/code/projects/swift/ShiftScheduler/ShiftSchedulerTests/Redux/State/ScheduleStateMultiSelectTests.swift`
- **Lines**: 272
- **Test Cases**: 14 comprehensive state tests
- **Coverage**:
  - Initial state validation
  - Selection ID management
  - Selection mode transitions
  - Computed property validation
  - Permission checks

#### Action Tests
- **File**: `/Users/farley/Documents/code/projects/swift/ShiftScheduler/ShiftSchedulerTests/Redux/Action/ScheduleActionMultiSelectTests.swift`
- **Lines**: 240
- **Test Cases**: 18 comprehensive action tests
- **Coverage**:
  - Action creation
  - Parameter validation
  - Equality comparisons
  - Success/failure case handling

---

### Documentation Files (Generated)

#### Comprehensive Analysis
- **File**: `/Users/farley/Documents/code/projects/swift/ShiftScheduler/PHASE4_MULTISELECT_CODEBASE_ANALYSIS.md`
- **Content**: 11-part analysis document with:
  - Current shift card component overview
  - Redux state structure documentation
  - Redux actions documentation
  - Redux reducer implementation details
  - Current ScheduleView structure
  - Reference design patterns
  - Test coverage summary
  - Architecture analysis with diagrams
  - Design system documentation
  - File inventory and line counts
  - Implementation requirements list

---

## Quick Reference: File Organization

```
ShiftScheduler/
├── ShiftScheduler/
│   ├── Redux/
│   │   ├── State/
│   │   │   └── AppState.swift (lines 228-323 multi-select)
│   │   ├── Action/
│   │   │   └── AppAction.swift (lines 378-402 multi-select)
│   │   ├── Reducer/
│   │   │   └── AppReducer.swift (lines 517-571 multi-select)
│   │   └── Logging/
│   │       └── ReduxLogger.swift
│   └── Views/
│       ├── Components/
│       │   ├── UnifiedShiftCard.swift (286 lines - TO ENHANCE)
│       │   ├── UndoRedoButtonsView.swift (236 lines - reference)
│       │   ├── GradientActionButton.swift (205 lines - reference)
│       │   └── [other components...]
│       ├── ScheduleView.swift (509 lines - TO ENHANCE)
│       └── [other views...]
├── ShiftSchedulerTests/
│   └── Redux/
│       ├── State/
│       │   └── ScheduleStateMultiSelectTests.swift (272 lines)
│       └── Action/
│           └── ScheduleActionMultiSelectTests.swift (240 lines)
└── PHASE4_MULTISELECT_CODEBASE_ANALYSIS.md (DOCUMENTATION)
```

---

## Implementation Checklist

### Components to Create
- [ ] `/Users/farley/Documents/code/projects/swift/ShiftScheduler/ShiftScheduler/Views/Components/SelectionToolbarView.swift`
- [ ] `/Users/farley/Documents/code/projects/swift/ShiftScheduler/ShiftScheduler/Views/BulkDeleteConfirmationDialog.swift`

### Components to Modify
- [ ] `/Users/farley/Documents/code/projects/swift/ShiftScheduler/ShiftScheduler/Views/Components/UnifiedShiftCard.swift`
- [ ] `/Users/farley/Documents/code/projects/swift/ShiftScheduler/ShiftScheduler/Views/ScheduleView.swift`

### Tests to Create
- [ ] Integration tests for selection toolbar
- [ ] Integration tests for shift card selection
- [ ] Integration tests for bulk delete flow

---

## Redux Connection Points

### From ScheduleView, access Redux state:
```swift
@Environment(\.reduxStore) var store

// Read state
store.state.schedule.selectedShiftIds      // Set<UUID>
store.state.schedule.isInSelectionMode     // Bool
store.state.schedule.selectionMode         // SelectionMode?
store.state.schedule.selectedShifts        // [ScheduledShift] (computed)
store.state.schedule.selectionCount        // Int (computed)
store.state.schedule.canDeleteSelectedShifts // Bool (computed)
store.state.schedule.showBulkDeleteConfirmation // Bool

// Dispatch actions
await store.dispatch(action: .schedule(.enterSelectionMode(mode: .delete, firstId: id)))
await store.dispatch(action: .schedule(.toggleShiftSelection(id)))
await store.dispatch(action: .schedule(.selectAllVisible))
await store.dispatch(action: .schedule(.clearSelection))
await store.dispatch(action: .schedule(.bulkDeleteRequested))
await store.dispatch(action: .schedule(.bulkDeleteConfirmed(ids)))
await store.dispatch(action: .schedule(.exitSelectionMode))
```

---

## Key Constants and Limits

- **Max Selection**: 100 items (enforced in reducer)
- **Selection Mode Enum**: `.delete` or `.add`
- **Color Palette**: 6 professional muted colors from `UnifiedShiftCard.cardColor`
- **Button Animation**: Spring(response: 0.3, dampingFraction: 0.6)
- **Haptic Style**: UIImpactFeedbackGenerator(style: .medium)

---

Generated: November 9, 2025
For: Phase 4 Multi-Select UI Implementation
Status: Ready for Development
