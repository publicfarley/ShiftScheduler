# Async Dispatch Testing Guide
**ShiftScheduler Redux Architecture**

**Last Updated:** November 6, 2025
**Related Changes:** Core.swift async dispatch implementation

---

## Overview

The Redux Store's `dispatch()` method is now **async** and awaits all middleware completion before returning. This provides:

✅ **Predictable behavior** - No race conditions in tests
✅ **Visible loading states** - `Task.yield()` ensures UI updates between phases
✅ **Clean tests** - No `Task.sleep()` hacks needed
✅ **Correctness** - Dispatch completing means "action + all side effects done"

---

## Architecture: Three-Phase Dispatch

```swift
public func dispatch(action: Action) async {
    // Phase 1: Apply reducer immediately (synchronous state update)
    state = reducer(state, action)

    // Phase 2: Yield to allow UI to update with reducer changes
    // This ensures loading states, optimistic updates, etc. are visible
    await Task.yield()

    // Phase 3: Execute middleware (async side effects)
    // Wait for all middleware to complete before returning
    await withTaskGroup(of: Void.self) { group in
        for middleware in middlewares {
            group.addTask {
                await middleware(...)
            }
        }
    }
}
```

**Key Insight:** The `await Task.yield()` between phases 1 and 2 allows SwiftUI's render loop to run, making loading states visible to the user.

---

## Testing Patterns

### Pattern 1: Test Reducers in Isolation (RECOMMENDED)

**Use Case:** Testing loading states, error states, any intermediate state transitions

**Why:** Fast, deterministic, tests the actual logic

```swift
@Test("loadShifts sets isLoading to true")
func testLoadShiftsStartsLoading() {
    // Given - Initial state
    var state = TodayState()
    state.isLoading = false

    // When - Reducer handles action
    let newState = todayReducer(state: state, action: .loadShifts)

    // Then - Loading state set immediately
    #expect(newState.isLoading == true)
}

@Test("shiftsLoaded success clears loading")
func testShiftsLoadedClearsLoading() {
    // Given - Loading state
    var state = TodayState()
    state.isLoading = true

    // When - Success action
    let newState = todayReducer(
        state: state,
        action: .shiftsLoaded(.success([]))
    )

    // Then - Loading cleared
    #expect(newState.isLoading == false)
}
```

**Philosophy:** If the reducer is correct, and middleware eventually completes, the loading state flow is guaranteed to work in production.

---

### Pattern 2: Integration Tests (Full Stack)

**Use Case:** Testing that middleware actually calls services and updates state

**Why:** Proves the full flow works end-to-end

```swift
@Test("Middleware loads shifts and updates state")
func testMiddlewareLoadsShifts() async {
    // Given - Mock service with test data
    let mockCalendar = MockCalendarService()
    mockCalendar.mockShifts = [testShift1, testShift2]

    let store = Store(
        state: AppState(),
        reducer: appReducer,
        services: ServiceContainer(calendarService: mockCalendar),
        middlewares: [todayMiddleware]
    )

    // When - Dispatch and await completion
    await store.dispatch(action: .today(.loadShifts))

    // Then - Middleware called service and state updated
    #expect(store.state.today.scheduledShifts.count == 2)
    #expect(mockCalendar.loadShiftsCallCount == 1)
}
```

**No Task.sleep needed!** The `await` guarantees middleware has completed.

---

### Pattern 3: Testing Complete State Transitions

**Use Case:** Verifying the full lifecycle of an operation

```swift
@Test("Complete loading cycle: start -> success")
func testCompleteLoadingCycle() {
    // Given - Initial state
    var state = TodayState()
    state.isLoading = false
    state.scheduledShifts = []

    // When - Start loading (reducer handles this)
    state = todayReducer(state: state, action: .loadShifts)

    // Then - Loading started
    #expect(state.isLoading == true)

    // When - Complete loading (middleware dispatches this)
    let testShifts = [testShift1, testShift2]
    state = todayReducer(
        state: state,
        action: .shiftsLoaded(.success(testShifts))
    )

    // Then - Loading complete
    #expect(state.isLoading == false)
    #expect(state.scheduledShifts.count == 2)
}
```

---

### Pattern 4: Testing with Intentionally Slow Middleware (Optional)

**Use Case:** Proving loading state is actually visible during middleware execution

**When to use:** Integration tests that need to verify UI timing

```swift
@Test("Loading state visible during async middleware")
func testLoadingStateDuringMiddleware() async {
    // Given - Mock with artificial delay
    let mockCalendar = MockCalendarService()
    mockCalendar.artificialDelay = 0.1  // 100ms

    let store = Store(
        state: AppState(),
        reducer: appReducer,
        services: ServiceContainer(calendarService: mockCalendar),
        middlewares: [todayMiddleware]
    )

    // When - Start dispatch in background
    let task = Task {
        await store.dispatch(action: .today(.loadShifts))
    }

    // Small delay to let reducer run but middleware still executing
    try? await Task.sleep(nanoseconds: 10_000_000)  // 10ms

    // Then - Loading state visible
    #expect(store.state.today.isLoading == true)

    // Wait for completion
    await task.value

    // Then - Loading cleared
    #expect(store.state.today.isLoading == false)
}
```

**Note:** This is the **only** case where `Task.sleep` is acceptable in tests, and only for proving temporal behavior.

---

## View Layer: Dispatching Actions

### In Button Handlers

```swift
Button("Load Shifts") {
    Task {
        await store.dispatch(action: .today(.loadShifts))
    }
}
```

### In Task Modifiers (Preferred for Initial Loads)

```swift
TodayView()
    .task {
        await store.dispatch(action: .today(.loadShifts))
    }
```

### In onAppear (If You Need State Access)

```swift
.onAppear {
    Task {
        await store.dispatch(action: .appLifecycle(.onAppAppear))
    }
}
```

---

## Loading State Visibility: Why Task.yield() Matters

**Without Task.yield():**
```swift
public func dispatch(action: Action) async {
    state = reducer(state, action)  // isLoading = true

    // Immediately await middleware (blocks main thread)
    await withTaskGroup(...) {
        // ... 2 seconds of work ...
    }
    // UI updates here with both loading→loaded in same frame!
}
```

**Timeline:**
- T=0ms: Set `isLoading = true`
- T=0ms - T=2000ms: Middleware runs (UI never renders loading state)
- T=2000ms: UI updates showing data (no loading indicator ever visible!)

**With Task.yield():**
```swift
public func dispatch(action: Action) async {
    state = reducer(state, action)  // isLoading = true

    await Task.yield()  // ← Suspend and let UI render

    await withTaskGroup(...) {
        // ... 2 seconds of work ...
    }
}
```

**Timeline:**
- T=0ms: Set `isLoading = true`
- T=0ms: `Task.yield()` suspends execution
- T=16ms: UI renders `ProgressView("Loading...")` ✅
- T=16ms - T=2016ms: Middleware runs
- T=2016ms: UI renders data

---

## Common Pitfalls and Solutions

### ❌ Pitfall 1: Forgetting await

```swift
// ❌ BAD - Won't compile (dispatch is async)
Button("Load") {
    store.dispatch(action: .load)  // ERROR
}
```

```swift
// ✅ GOOD - Wrap in Task
Button("Load") {
    Task {
        await store.dispatch(action: .load)
    }
}
```

### ❌ Pitfall 2: Using Task.sleep in Tests

```swift
// ❌ BAD - Unnecessary and flaky
await store.dispatch(action: .load)
try? await Task.sleep(nanoseconds: 10_000_000)
#expect(store.state.loaded == true)
```

```swift
// ✅ GOOD - Dispatch completes when middleware finishes
await store.dispatch(action: .load)
#expect(store.state.loaded == true)
```

### ❌ Pitfall 3: Testing Loading State Through Store

```swift
// ❌ BAD - Complex, slow, unnecessary
func testLoadingState() async {
    let task = Task { await store.dispatch(...) }
    try? await Task.sleep(...)
    #expect(store.state.isLoading == true)
    await task.value
}
```

```swift
// ✅ GOOD - Test reducer directly
func testLoadingState() {
    let state = reducer(initialState, action: .startLoad)
    #expect(state.isLoading == true)
}
```

---

## Test Organization

### Recommended Structure

```
ShiftSchedulerTests/
├── Redux/
│   ├── Reducer/
│   │   ├── TodayReducerLoadingStateTests.swift  ← Unit tests (fast)
│   │   ├── ScheduleReducerTests.swift
│   │   └── ...
│   ├── MiddlewareIntegrationTests.swift  ← Integration tests (slower)
│   └── ReducerIntegrationTests.swift
└── Services/
    ├── CalendarServiceTests.swift
    └── ...
```

### Test Naming Convention

**Reducer Tests (Unit):**
- `test[Action]Sets[State]` - e.g., `testLoadShiftsSetsLoading()`
- `test[Action]Clears[State]` - e.g., `testShiftsLoadedClearsLoading()`
- `test[Action]Preserves[State]` - e.g., `testLoadShiftsPreservesOtherState()`

**Integration Tests:**
- `test[Feature]Calls[Service]` - e.g., `testMiddlewareCallsCalendarService()`
- `test[Feature]Updates[State]` - e.g., `testMiddlewareUpdatesShifts()`
- `test[Feature]Handles[Error]` - e.g., `testMiddlewareHandlesLoadError()`

---

## Performance Considerations

### Q: Won't awaiting middleware slow down the UI?

**A:** Only if middleware is genuinely slow - which is **valuable feedback!**

**Solutions:**
1. **Make middleware faster** (the right fix) - cache data, reduce network calls
2. **Optimistic updates** - dispatch instant feedback actions:
   ```swift
   await store.dispatch(action: .startSaving)  // Instant
   // Middleware saves in background and dispatches .saved
   ```
3. **Background prefetching** - load data before user needs it

### Q: What if I need fire-and-forget dispatch?

**A:** You probably don't! But if you really need it:

```swift
// Fire and forget (rare - usually wrong choice)
Task {
    await store.dispatch(action: .backgroundSync)
}
// Don't await this Task - continues immediately
```

**Warning:** This loses the guarantees of async dispatch. Only use for truly independent background operations.

---

## Migration Checklist

When updating existing code to async dispatch:

- [ ] Update `dispatch()` call sites to use `await`
- [ ] Wrap synchronous button handlers in `Task { await ... }`
- [ ] Remove all `Task.sleep()` from tests (except temporal behavior tests)
- [ ] Update middleware integration tests to `await store.dispatch()`
- [ ] Add reducer unit tests for loading states
- [ ] Verify loading states are visible in UI (use `Task.yield()`)

---

## Example: Complete Test Suite

See `TodayReducerLoadingStateTests.swift` for a comprehensive example showing:
- ✅ Unit tests for loading state transitions
- ✅ Tests preserving other state during operations
- ✅ Complete lifecycle tests (start → success → reset)
- ✅ Error handling tests
- ✅ Multiple operation tests

See `MiddlewareIntegrationTests.swift` for integration tests showing:
- ✅ Service call verification
- ✅ State updates from middleware
- ✅ Secondary dispatch chains
- ✅ Error handling in middleware
- ✅ No `Task.sleep()` hacks

---

## Summary

**Key Principles:**

1. **Test reducers in isolation** - Fast, deterministic, tests the logic
2. **Await dispatch in integration tests** - No Task.sleep needed
3. **Use Task.yield() for visible loading states** - UI renders between phases
4. **One dispatch implementation** - No test-only variants
5. **Trust the architecture** - If reducer is correct, flow is correct

**Benefits:**

- ✅ No race conditions in tests
- ✅ No flaky timing issues
- ✅ Loading states actually visible
- ✅ Clean, readable test code
- ✅ Matches production behavior

---

**Questions?** See:
- `ShiftScheduler/Redux/Core.swift` - Async dispatch implementation
- `ShiftSchedulerTests/Redux/Reducer/TodayReducerLoadingStateTests.swift` - Example unit tests
- `ShiftSchedulerTests/Redux/MiddlewareIntegrationTests.swift` - Example integration tests
