# Test Date Determinism Analysis & Implementation Plan

**Status:** Analysis Complete - Implementation Pending
**Date:** November 8, 2025
**Priority:** Medium (affects test reliability)

---

## Executive Summary

The test harness contains **non-deterministic date usage** that causes tests to behave differently on each run. This makes debugging difficult and can create flaky tests that pass on some days but fail on others.

**Finding:** 4 locations with problematic `Date()` usage that needs to be replaced with fixed dates or deterministic date calculations.

---

## Problem Analysis

### What's the Issue?

Using `Date()` (current date/time) as default parameter values or in test bodies causes tests to:
- ✗ Produce different results depending on when they run
- ✗ Be difficult to debug (test behavior changes daily)
- ✗ Potentially fail intermittently based on date boundaries
- ✗ Not be reproducible locally vs in CI

### Affected Locations

| File | Line(s) | Issue | Type | Severity |
|------|---------|-------|------|----------|
| TestDataBuilders.swift | 159 | `date: Date = Date()` | Default parameter | 🔴 High |
| TestDataBuilders.swift | 215, 219 | `timestamp: Date = Date()` `scheduledShiftDate: Date = Date()` | Default parameters | 🔴 High |
| QuickActionsMiddlewareTests.swift | 93, 125 | `makeTestShift(date: Date())` | Test body | 🟡 Medium |
| QuickActionsReducerTests.swift | 142 | `date: Date()` | Test body literal | 🟡 Medium |
| PerformanceTests.swift | 40, 48, 58, 65+ | `let startTime = Date()` `let elapsed = Date().timeIntervalSince()` | Time measurement | ✅ OK |

**Total Issues:** 4 problematic locations (Performance tests are legitimate)

---

## Current State vs Desired State

### Current (Non-Deterministic)

```swift
// TestDataBuilders.swift - Line 159
struct ScheduledShiftBuilder {
    init(
        id: UUID = UUID(),
        date: Date = Date(),  // ⚠️ Changes every test run
        shiftType: ShiftType? = nil,
        notes: String? = nil
    )
}

// QuickActionsMiddlewareTests.swift - Line 93
let testShift = makeTestShift(date: Date())  // ⚠️ Current date changes
```

### Desired (Deterministic)

```swift
// Option 1: Fixed reference date
let referenceDate = Calendar.current.date(from: DateComponents(year: 2025, month: 11, day: 8))!

// Option 2: Relative to test start
let today = Calendar.current.startOfDay(for: Date())

// Option 3: Builder pattern with explicit date
let testShift = ScheduledShiftBuilder(date: referenceDate).build()
```

---

## Implementation Plan

### Phase 1: Fix Test Data Builders (High Priority)

#### Task 1.1: Update ScheduledShiftBuilder
**File:** `TestDataBuilders.swift` (Line 159)

**Current:**
```swift
init(
    id: UUID = UUID(),
    date: Date = Date(),  // ⚠️ Non-deterministic
    shiftType: ShiftType? = nil,
    notes: String? = nil
)
```

**Change to:**
```swift
init(
    id: UUID = UUID(),
    date: Date = {
        let calendar = Calendar.current
        return calendar.startOfDay(for: Date())
    }(),
    shiftType: ShiftType? = nil,
    notes: String? = nil
)
```

**Alternative (if we want completely fixed date):**
```swift
init(
    id: UUID = UUID(),
    date: Date = {
        let calendar = Calendar.current
        return calendar.date(from: DateComponents(year: 2025, month: 11, day: 8)) ?? Date()
    }(),
    shiftType: ShiftType? = nil,
    notes: String? = nil
)
```

**Impact:** Fixes the most commonly used builder

---

#### Task 1.2: Update ChangeLogEntryBuilder
**File:** `TestDataBuilders.swift` (Lines 215, 219)

**Current:**
```swift
init(
    id: UUID = UUID(),
    timestamp: Date = Date(),                    // ⚠️ Non-deterministic
    userId: UUID = UUID(),
    userDisplayName: String = "Test User",
    changeType: ChangeType = .created,
    scheduledShiftDate: Date = Date(),          // ⚠️ Non-deterministic
    oldShiftSnapshot: ShiftSnapshot? = nil,
    newShiftSnapshot: ShiftSnapshot? = nil,
    reason: String = ""
)
```

**Change to:**
```swift
init(
    id: UUID = UUID(),
    timestamp: Date = {
        let calendar = Calendar.current
        return calendar.startOfDay(for: Date())
    }(),
    userId: UUID = UUID(),
    userDisplayName: String = "Test User",
    changeType: ChangeType = .created,
    scheduledShiftDate: Date = {
        let calendar = Calendar.current
        return calendar.startOfDay(for: Date())
    }(),
    oldShiftSnapshot: ShiftSnapshot? = nil,
    newShiftSnapshot: ShiftSnapshot? = nil,
    reason: String = ""
)
```

**Impact:** Fixes changelog entry builder used in history tests

---

### Phase 2: Fix Test Middleware Tests (Medium Priority)

#### Task 2.1: Update QuickActionsMiddlewareTests
**File:** `QuickActionsMiddlewareTests.swift` (Lines 93, 125)

**Current:**
```swift
@Test
func deleteCreatesChangeLogEntry() async {
    let testShift = makeTestShift(date: Date())  // ⚠️ Non-deterministic
    // ...
}

@Test
func notesPersistedOnSheetClose() async {
    let testShift = makeTestShift(date: Date())  // ⚠️ Non-deterministic
    // ...
}
```

**Change to:**
```swift
@Test
func deleteCreatesChangeLogEntry() async {
    let calendar = Calendar.current
    let testDate = calendar.startOfDay(for: Date())
    let testShift = makeTestShift(date: testDate)
    // ...
}

@Test
func notesPersistedOnSheetClose() async {
    let calendar = Calendar.current
    let testDate = calendar.startOfDay(for: Date())
    let testShift = makeTestShift(date: testDate)
    // ...
}
```

**Alternative (simpler):**
```swift
// Remove explicit date parameter since builder now has deterministic default
let testShift = makeTestShift()
```

**Impact:** Makes middleware tests deterministic

---

#### Task 2.2: Update QuickActionsReducerTests
**File:** `QuickActionsReducerTests.swift` (Line 142)

**Current:**
```swift
ScheduledShift(
    id: UUID(),
    eventIdentifier: "TestEvent",
    shiftType: ShiftType(
        id: UUID(),
        symbol: "sun.fill",
        duration: .scheduled(from: HourMinuteTime(hour: 9, minute: 0),
                           to: HourMinuteTime(hour: 17, minute: 0)),
        title: "Test Shift",
        location: Location(id: UUID(), name: "Test Office", address: "123 Main St")
    ),
    date: Date(),  // ⚠️ Non-deterministic
    notes: nil
)
```

**Change to:**
```swift
ScheduledShift(
    id: UUID(),
    eventIdentifier: "TestEvent",
    shiftType: ShiftType(
        id: UUID(),
        symbol: "sun.fill",
        duration: .scheduled(from: HourMinuteTime(hour: 9, minute: 0),
                           to: HourMinuteTime(hour: 17, minute: 0)),
        title: "Test Shift",
        location: Location(id: UUID(), name: "Test Office", address: "123 Main St")
    ),
    date: Calendar.current.startOfDay(for: Date()),
    notes: nil
)
```

**Better (use builder instead of manual construction):**
```swift
let testShift = ScheduledShiftBuilder(
    shiftType: ShiftType(
        id: UUID(),
        symbol: "sun.fill",
        duration: .scheduled(from: HourMinuteTime(hour: 9, minute: 0),
                           to: HourMinuteTime(hour: 17, minute: 0)),
        title: "Test Shift",
        location: Location(id: UUID(), name: "Test Office", address: "123 Main St")
    ),
    notes: nil
).build()
```

**Impact:** Makes reducer tests deterministic and cleaner

---

### Phase 3: Verification

#### Task 3.1: Run Tests Multiple Times
```bash
# Run tests multiple times to ensure consistency
for i in {1..5}; do
  xcodebuild -project ShiftScheduler.xcodeproj \
    -scheme ShiftScheduler \
    -destination 'platform=iOS Simulator,id=490A490A-C97A-43EE-978E-148A74A72499' \
    test
done
```

#### Task 3.2: Verify Across Date Boundaries
- Run tests on the last day of month
- Run tests on first day of month
- Run tests on leap year (Feb 29) if applicable
- Verify tests pass consistently

#### Task 3.3: Documentation Update
Update code comments to explain deterministic date strategy:

```swift
/// Test date calculation strategy:
/// Use Calendar.startOfDay(for: Date()) to get deterministic "today"
/// This ensures tests behave the same regardless of execution time.
/// For fixed dates in the past, use:
/// Calendar.current.date(from: DateComponents(year: 2025, month: 11, day: 8))
```

---

## Implementation Checklist

### Phase 1: Test Data Builders
- [ ] Task 1.1: Update ScheduledShiftBuilder default date
- [ ] Task 1.2: Update ChangeLogEntryBuilder default dates
- [ ] Run TodayReducerTests to verify
- [ ] Run ChangeLogReducerTests to verify

### Phase 2: Test Middleware Tests
- [ ] Task 2.1: Update QuickActionsMiddlewareTests
- [ ] Task 2.2: Update QuickActionsReducerTests
- [ ] Run QuickActionsMiddlewareTests
- [ ] Run QuickActionsReducerTests

### Phase 3: Verification
- [ ] Task 3.1: Run tests multiple times for consistency
- [ ] Task 3.2: Test across date boundaries
- [ ] Task 3.3: Update documentation
- [ ] Full test suite passes

### Final Steps
- [ ] Create commit: "fix: replace non-deterministic Date() with deterministic dates in test harness"
- [ ] Update this document with completion date
- [ ] Push to main

---

## Rationale for Each Change

### Why `Calendar.startOfDay(for: Date())`?
- ✅ Deterministic - always gives today at 00:00:00
- ✅ Realistic - tests use actual dates
- ✅ Consistent - doesn't change throughout test run
- ✅ Timezone-aware - handles local calendar correctly

### Why Not Completely Fixed Dates?
While using a completely fixed date (e.g., 2025-11-08) would work, it has drawbacks:
- Tests become outdated/confusing ("why Nov 8?")
- May break on leap years or calendar changes
- Less realistic for actual usage patterns

**Best approach:** Use `Calendar.startOfDay(for: Date())` to always use "today" deterministically

---

## Risk Assessment

### Low Risk
- All changes are in test code only
- No production code changes
- Improves test reliability without changing test logic
- Existing tests will pass (just more consistently)

### Potential Issues & Mitigations
| Risk | Mitigation |
|------|-----------|
| Tests with hardcoded date expectations | Review test assertions for date comparisons |
| Timezone-dependent calculations | Use Calendar operations consistently |
| Tests that depend on current date | All affected tests are stateless builders |

---

## Resources & References

- **CLAUDE.md** - Project guidelines on dates and testing
- **TestDataBuilders.swift** - Primary test data factory
- **Swift Calendar Documentation** - Date calculation patterns
- **Current Issues in TEST_QUALITY_REVIEW.md** - Related test quality improvements

---

## Notes

- This analysis was identified during Store configuration refactoring session
- Part of larger test quality improvement initiative
- Should be completed before Phase 4 Priority 4E (Test Quality Improvements)
- Complements existing deterministic date usage in TestDataCollections presets

---

**Document Status:** Ready for Implementation
**Last Updated:** November 8, 2025
**Next Steps:** Execute Phase 1 tasks when ready
