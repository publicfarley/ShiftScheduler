# Multi-Day Shift Support Implementation Plan

## Overview
Add support for shifts spanning multiple dates (e.g., 11 PM - 7 AM overnight shifts) with the following constraints:
- **Detection**: Automatic when end time < start time
- **Max Duration**: 2 days maximum (no 24+ hour shifts)
- **Display**: Show on BOTH start and end dates
- **Migration**: Existing shifts default to same-day

## Branch Strategy
Create new feature branch: `feature/multi-day-shifts`

---

## Phase 1: Core Model Updates (Foundation)

### 1.1 Update ShiftDuration Model
**File**: `ShiftDuration.swift`
- Add computed property `spansNextDay: Bool` (true when endTime < startTime)
- Add validation to reject shifts ≥24 hours
- Update `timeRangeString` to indicate overnight (e.g., "11:00 PM - 7:00 AM +1")
- Add helper to calculate actual duration in hours

### 1.2 Update ScheduledShift Model
**File**: `ScheduledShift.swift`
- Add `endDate: Date` property
- Update initializers to calculate `endDate` based on `shiftType.duration.spansNextDay`
- Update `==` operator to include `endDate` comparison
- Add computed property `spansDays: Int`

### 1.3 Update ScheduledShiftData Model
**File**: `ScheduledShiftData.swift`
- Add `endDate: Date` property
- Update Codable implementation
- Update equality/hash implementations

### 1.4 Create Date Helper Extensions
**New File**: `ScheduledShift+DateHelpers.swift`
- `occursOn(date:) -> Bool` - Check if shift occurs on target date
- `affectedDates() -> [Date]` - Return all dates shift occupies
- `overlaps(with:) -> Bool` - Check date range intersection
- `actualStartDateTime() -> Date` - Combine date + startTime
- `actualEndDateTime() -> Date` - Combine endDate + endTime

---

## Phase 2: Service Layer Updates

### 2.1 Update CalendarService
**File**: `CalendarService.swift`
- Update `loadShifts(from:to:)`: Extract `endDate` from EKEvent
- Update `createShiftEvent`: Calculate and set proper endDate for overnight shifts
- Update `updateShiftEvent`: Handle switching between single/multi-day shifts
- Update `convertEventToShift`: Extract both start and end dates from EKEvent

### 2.2 Update MockCalendarService
**File**: `MockCalendarService.swift`
- Add test data with multi-day shifts
- Update mock implementations to include `endDate` logic
- Add validation for max 2-day constraint

---

## Phase 3: Redux State & Reducer Updates

### 3.1 Update AppState
**File**: `AppState.swift` (Lines 269, 300)
- Replace `isDate(_:inSameDayAs:)` with `shift.occursOn(date:)` helper
- Update `filteredShifts` computed property
- Update `shiftsForSelectedDate` computed property

### 3.2 Update AppReducer
**File**: `AppReducer.swift` (Lines 144-149)
- Update today/tomorrow shift filtering to use `occursOn(date:)` helper
- Ensure cached shifts include multi-day shifts that span target date

---

## Phase 4: Critical Overlap Detection Logic

### 4.1 Update ScheduleMiddleware
**File**: `ScheduleMiddleware.swift` (Lines 52-54, 112-114)
- **CRITICAL**: Rewrite overlap detection algorithm
- Current: Groups by single date (broken for multi-day)
- New: Check if shift's date range intersects with ANY existing shift
- Validate conflicts on ALL affected dates (not just start date)
- Add validation to reject shifts ≥24 hours

### 4.2 Update TodayMiddleware
**File**: `TodayMiddleware.swift` (Lines 252-295)
- Update `loadNext7DaysShifts` to include `endDate` in ScheduledShift creation
- Ensure multi-day shifts appear correctly in 7-day view

### 4.3 Update Error Handling
**File**: `ScheduleError.swift`
- Update overlap error messages to show ALL conflicting dates
- Add `conflictingDates: [Date]` parameter for multi-day conflicts

---

## Phase 5: View Layer Updates (8 files)

### 5.1 Update TodayView
**File**: `TodayView.swift`
- **Lines 132-134**: Replace today filter with `occursOn(date:)` helper
- **Lines 219-222**: Replace tomorrow filter with `occursOn(date:)` helper
- **Lines 268-270**: Update week filter for date range intersection
- **Lines 467, 1353**: Update status logic to use `actualEndDateTime()`

### 5.2 Update ScheduleView
**File**: `ScheduleView.swift`
- Update shift filtering to show multi-day shifts on all affected dates
- Add visual indicator for overnight shifts in list

### 5.3 Update CustomCalendarView
**File**: `CustomCalendarView.swift` (Lines 76-78)
- Replace `isDate(_:inSameDayAs:)` with multi-day aware check
- Show indicators on ALL dates a shift occupies

### 5.4 Update Shift Card Components (3 files)
**Files**: `UnifiedShiftCard.swift`, `EnhancedShiftCard.swift`, `CompactHalfHeightShiftCard.swift`
- Update status determination to check if `now` falls within `[actualStartDateTime, actualEndDateTime]`
- Add "+1" badge or indicator for overnight shifts
- Display both start and end dates for multi-day shifts

### 5.5 Update ShiftDetailsView
**File**: `ShiftDetailsView.swift`
- Display both start and end dates separately
- Add visual indicator for overnight/multi-day shifts
- Show "Next Day" label for end time

### 5.6 Update ShiftChangeSheet
**File**: `ShiftChangeSheet.swift`
- Handle switching from single-day to multi-day shift type
- Update validation logic

### 5.7 Update OverlapResolutionSheet
**File**: `OverlapResolutionSheet.swift`
- Display ALL dates affected by multi-day shift overlap
- Show date ranges in conflict list

---

## Phase 6: Data Migration

### 6.1 Create Migration Logic
**New approach**: No separate migration file needed
- Default `endDate = date` for all existing shifts (handled in model initializer)
- Add fallback logic in `ScheduledShift.init` for backward compatibility
- Add migration in CalendarService when loading old data

---

## Phase 7: Comprehensive Testing

### 7.1 Update Test Data Builders
**File**: `TestDataBuilders.swift`
- Add `endDate` parameter to `ScheduledShiftBuilder`
- Add helper methods for creating overnight shift test data
- Add overnight ShiftType test data

### 7.2 Update Service Tests (5 files)
- `CalendarServiceTests.swift`: Test loading/creating multi-day shifts
- `CalendarServiceUpdateTests.swift`: Test updating single↔multi-day
- `PersistenceServiceIntegrationTests.swift`: Test `endDate` persistence
- Add new tests for `endDate` extraction from EKEvent

### 7.3 Update Reducer Tests (4 files)
- Test multi-day shift filtering in today/tomorrow/week views
- Test overlap detection across date boundaries
- Test status determination for overnight shifts

### 7.4 Update Middleware Tests (3 files)
- Test multi-day shift creation and overlap validation
- Test error cases (≥24 hour shifts rejected)

### 7.5 Add Edge Case Tests
**File**: `EdgeCaseTests.swift`
- 11:59 PM - 12:01 AM (2-minute overnight)
- 11 PM - 7 AM (typical night shift)
- 10 PM - 10 PM next day (24-hour - should REJECT)
- Midnight boundary shifts (12 AM start/end)
- DST transition handling
- Conflict detection across date boundaries

### 7.6 Update Integration Tests (2 files)
- End-to-end flow with multi-day shifts
- Redux state updates with overnight shifts

---

## Phase 8: Build Verification

### 8.1 Compile Both Targets
- App target: `xcodebuild -project ShiftScheduler.xcodeproj -scheme ShiftScheduler -destination 'platform=iOS Simulator,id=490A490A-C97A-43EE-978E-148A74A72499' build`
- Test target: `xcodebuild ... -only-testing:ShiftSchedulerTests test`

### 8.2 Run Full Test Suite
- Verify all existing tests still pass
- Verify new multi-day shift tests pass
- Zero compilation errors/warnings

---

## Implementation Order (Strict Dependencies)

1. **Phase 1** (Models) - Foundation for everything
2. **Phase 2** (Services) - Depends on Phase 1 models
3. **Phase 3** (Redux State) - Depends on Phase 1 models
4. **Phase 4** (Overlap Detection) - **MOST CRITICAL** - Depends on Phase 1 helpers
5. **Phase 5** (Views) - Depends on all previous phases
6. **Phase 6** (Migration) - Handled automatically via initializers
7. **Phase 7** (Tests) - Validate all previous phases
8. **Phase 8** (Verification) - Final validation

---

## Risk Areas (High Complexity)

1. **Overlap Detection**: Completely new algorithm needed for date range intersection
2. **Status Determination**: Must handle "active" state across midnight boundary
3. **Calendar Display**: Shifts appearing on multiple dates simultaneously
4. **Test Coverage**: 37+ files affected, comprehensive edge cases required

---

## Estimated File Changes
- **New files**: 1 (DateHelpers extension)
- **Modified files**: 37+ (3 models, 8 views, 2 state/reducer, 4 services, 2 middleware, 2 errors, 15+ tests)
- **Test files affected**: 15+ (with new edge cases added)

---

## Success Criteria
✅ Overnight shifts (11 PM - 7 AM) create successfully
✅ Shifts appear on BOTH start and end dates in Today/Tomorrow views
✅ Status shows "active" correctly during overnight shift
✅ Overlap detection prevents conflicts across date boundaries
✅ Shifts ≥24 hours are rejected with clear error
✅ All 100+ existing tests still pass
✅ Both app and test targets compile with zero errors
✅ Data migration preserves all existing shifts (as same-day)

---

## Design Decisions (From User Input)

### Detection Method
**Choice**: End time < Start time (e.g., 23:00-07:00)
- Automatically detect overnight shifts when end hour is earlier than start hour
- Simple and intuitive for users
- No explicit flag needed

### Multi-Day Support
**Choice**: No - limit to 2 days maximum
- Simpler implementation
- Overnight shifts only (max ~24 hours)
- Sufficient for most shift work scenarios
- Reject shifts ≥24 hours with validation error

### Display Behavior
**Choice**: Show on both start and end dates
- Shift appears on both days (11 PM-7 AM shows on both tonight and tomorrow morning)
- Provides better visibility in Today/Tomorrow views
- Users see the shift on whichever day they're looking at

### Migration Strategy
**Choice**: Assume all existing shifts are same-day
- Set endDate = startDate for all existing shifts
- Users must manually update overnight shifts after migration
- Safest approach - no automatic interpretation of ambiguous data

---

## Technical Implementation Details

### ShiftDuration.spansNextDay Logic
```swift
var spansNextDay: Bool {
    switch self {
    case .allDay:
        return false
    case .scheduled(let from, let to):
        // If end hour < start hour, it spans to next day
        if to.hour < from.hour {
            return true
        }
        // If hours equal, check minutes
        if to.hour == from.hour && to.minute < from.minute {
            return true
        }
        return false
    }
}
```

### ScheduledShift.endDate Calculation
```swift
init(id: UUID = UUID(), eventIdentifier: String, shiftType: ShiftType?, date: Date, notes: String? = nil) {
    self.id = id
    self.eventIdentifier = eventIdentifier
    self.shiftType = shiftType
    self.date = date
    self.notes = notes

    // Calculate endDate based on shift type
    if let shiftType = shiftType, shiftType.duration.spansNextDay {
        self.endDate = Calendar.current.date(byAdding: .day, value: 1, to: date) ?? date
    } else {
        self.endDate = date
    }
}
```

### Overlap Detection Algorithm
```swift
func checkOverlap(newShift: ScheduledShift, existingShifts: [ScheduledShift]) -> Bool {
    for existing in existingShifts {
        // Get actual start/end DateTimes for both shifts
        let newStart = newShift.actualStartDateTime()
        let newEnd = newShift.actualEndDateTime()
        let existingStart = existing.actualStartDateTime()
        let existingEnd = existing.actualEndDateTime()

        // Check if date ranges intersect
        // Ranges overlap if: newStart < existingEnd AND newEnd > existingStart
        if newStart < existingEnd && newEnd > existingStart {
            return true // Overlap detected
        }
    }
    return false // No overlap
}
```

---

## File Paths Reference

### Models (Phase 1)
- `/Users/farley/Documents/code/projects/swift/ShiftScheduler/ShiftScheduler/Models/ShiftDuration.swift`
- `/Users/farley/Documents/code/projects/swift/ShiftScheduler/ShiftScheduler/Models/ScheduledShift.swift`
- `/Users/farley/Documents/code/projects/swift/ShiftScheduler/ShiftScheduler/Models/ScheduledShiftData.swift`
- `/Users/farley/Documents/code/projects/swift/ShiftScheduler/ShiftScheduler/Models/ScheduledShift+DateHelpers.swift` (NEW)

### Services (Phase 2)
- `/Users/farley/Documents/code/projects/swift/ShiftScheduler/ShiftScheduler/Redux/Services/CalendarService.swift`
- `/Users/farley/Documents/code/projects/swift/ShiftScheduler/ShiftScheduler/Redux/Services/Mocks/MockCalendarService.swift`

### Redux (Phase 3)
- `/Users/farley/Documents/code/projects/swift/ShiftScheduler/ShiftScheduler/Redux/State/AppState.swift`
- `/Users/farley/Documents/code/projects/swift/ShiftScheduler/ShiftScheduler/Redux/Reducer/AppReducer.swift`

### Middleware (Phase 4)
- `/Users/farley/Documents/code/projects/swift/ShiftScheduler/ShiftScheduler/Redux/Middleware/ScheduleMiddleware.swift`
- `/Users/farley/Documents/code/projects/swift/ShiftScheduler/ShiftScheduler/Redux/Middleware/TodayMiddleware.swift`
- `/Users/farley/Documents/code/projects/swift/ShiftScheduler/ShiftScheduler/Redux/Errors/ScheduleError.swift`

### Views (Phase 5)
- `/Users/farley/Documents/code/projects/swift/ShiftScheduler/ShiftScheduler/Views/TodayView.swift`
- `/Users/farley/Documents/code/projects/swift/ShiftScheduler/ShiftScheduler/Views/ScheduleView.swift`
- `/Users/farley/Documents/code/projects/swift/ShiftScheduler/ShiftScheduler/Views/CustomCalendarView.swift`
- `/Users/farley/Documents/code/projects/swift/ShiftScheduler/ShiftScheduler/Views/Components/UnifiedShiftCard.swift`
- `/Users/farley/Documents/code/projects/swift/ShiftScheduler/ShiftScheduler/Views/EnhancedShiftCard.swift`
- `/Users/farley/Documents/code/projects/swift/ShiftScheduler/ShiftScheduler/Views/Components/CompactHalfHeightShiftCard.swift`
- `/Users/farley/Documents/code/projects/swift/ShiftScheduler/ShiftScheduler/Views/ShiftDetailsView.swift`
- `/Users/farley/Documents/code/projects/swift/ShiftScheduler/ShiftScheduler/Views/ShiftChangeSheet.swift`
- `/Users/farley/Documents/code/projects/swift/ShiftScheduler/ShiftScheduler/Views/OverlapResolutionSheet.swift`

### Tests (Phase 7)
- See comprehensive list in Phase 7 sections above

---

## Next Steps After Plan Approval

1. Create feature branch: `git checkout -b feature/multi-day-shifts`
2. Begin Phase 1: Core Model Updates
3. After each phase, run build verification
4. Commit frequently with descriptive messages
5. Run full test suite after Phase 7
6. Final verification in Phase 8
7. Create PR for review when complete
