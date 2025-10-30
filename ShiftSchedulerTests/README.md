# ShiftScheduler Test Suite Documentation

Comprehensive guide to the ShiftScheduler test suite, test organization, running tests, and best practices.

## Overview

The ShiftScheduler test suite uses Apple's **Swift Testing framework** (not XCTest) with the `@Test` macro and `#expect` assertions. Tests are organized by feature and test type, with a focus on behavioral validation and comprehensive coverage.

- **Test Framework**: Swift Testing (`@Test` macro, `#expect` assertions)
- **Target Platform**: iOS Simulator (iPhone 16)
- **Minimum Deployment Target**: iOS 26.0
- **Total Tests**: 200+ (across all phases)

## Test Organization

Tests are organized into logical directories reflecting the app architecture:

```
ShiftSchedulerTests/
├── Services/                  # Service layer unit tests
│   ├── CalendarServiceTests.swift
│   ├── CalendarServiceErrorTests.swift
│   ├── PersistenceServiceTests.swift
│   ├── PersistenceServiceErrorTests.swift
│   ├── CurrentDayServiceTests.swift
│   ├── CurrentDayServiceErrorTests.swift
│   └── MockPersistenceServiceTests.swift
├── Redux/                     # Redux pattern tests
│   ├── ReducerTests.swift
│   ├── ReducerIntegrationTests.swift
│   ├── ConcurrencyTests.swift
│   ├── Middleware/
│   │   ├── MiddlewareIntegrationTests.swift
│   │   └── MiddlewareErrorHandlingTests.swift
│   └── ReduxIntegrationTests.swift
├── Performance/               # Performance benchmarks
│   └── PerformanceTests.swift
├── Builders/                  # Test data factories
│   └── TestDataBuilders.swift
└── Helpers/                   # Utilities and mocks
    ├── Mocks/
    │   ├── MockCalendarService.swift
    │   ├── MockPersistenceService.swift
    │   └── MockCurrentDayService.swift
    └── EdgeCaseTests.swift
```

## Running Tests

### Run All Tests

```bash
xcodebuild -project ShiftScheduler.xcodeproj \
  -scheme ShiftScheduler \
  -destination 'platform=iOS Simulator,id=490A490A-C97A-43EE-978E-148A74A72499' \
  test
```

### Run Specific Test Suite

```bash
# Run only service tests
xcodebuild -project ShiftScheduler.xcodeproj \
  -scheme ShiftScheduler \
  -destination 'platform=iOS Simulator,id=490A490A-C97A-43EE-978E-148A74A72499' \
  test -testPlan ServiceTests

# Run only Redux tests
xcodebuild -project ShiftScheduler.xcodeproj \
  -scheme ShiftScheduler \
  -destination 'platform=iOS Simulator,id=490A490A-C97A-43EE-978E-148A74A72499' \
  test -testPlan ReduxTests
```

### Run Tests Without Performance Tests

Skip performance benchmarks (useful for quick CI runs):

```bash
SKIP_PERFORMANCE_TESTS=1 xcodebuild -project ShiftScheduler.xcodeproj \
  -scheme ShiftScheduler \
  -destination 'platform=iOS Simulator,id=490A490A-C97A-43EE-978E-148A74A72499' \
  test
```

### Run Only Performance Tests

```bash
xcodebuild -project ShiftScheduler.xcodeproj \
  -scheme ShiftScheduler \
  -destination 'platform=iOS Simulator,id=490A490A-C97A-43EE-978E-148A74A72499' \
  test -testPlan PerformanceTests
```

### Run Specific Test File

```bash
xcodebuild -project ShiftScheduler.xcodeproj \
  -scheme ShiftScheduler \
  -destination 'platform=iOS Simulator,id=490A490A-C97A-43EE-978E-148A74A72499' \
  test -testNamePattern "CalendarServiceTests"
```

### Run Specific Test

```bash
xcodebuild -project ShiftScheduler.xcodeproj \
  -scheme ShiftScheduler \
  -destination 'platform=iOS Simulator,id=490A490A-C97A-43EE-978E-148A74A72499' \
  test -testNamePattern "testCalendarAuthorizationThrowsWhenConfigured"
```

## Test Categories

### Service Layer Tests (75+ tests)

Test individual service implementations with unit tests and integration tests.

#### Calendar Service Tests
- `CalendarServiceTests.swift`: Happy path authorization and shift loading
- `CalendarServiceErrorTests.swift`: Error handling and permission denial scenarios
- 6+ tests covering EventKit integration and error states

#### Persistence Service Tests
- `PersistenceServiceTests.swift`: File I/O operations for all data types
- `PersistenceServiceErrorTests.swift`: Failure modes and error recovery
- 19+ tests covering shift types, locations, change logs, and undo/redo

#### Current Day Service Tests
- `CurrentDayServiceTests.swift`: Date calculations and edge cases
- 23+ tests covering leap years, month boundaries, DST handling
- Extreme ranges and performance validation

#### Mock Service Tests
- `MockPersistenceServiceTests.swift`: Verify mock service behavior
- Configuration validation for error simulation

### Redux Architecture Tests (80+ tests)

Test Redux store, reducers, middleware, and state management.

#### Reducer Tests
- `ReducerTests.swift`: Pure function state transformation validation
- Action dispatch verification
- State consistency checks

#### Integration Tests
- `ReducerIntegrationTests.swift`: Reducer + state transitions
- `ReduxIntegrationTests.swift`: Full Redux flow including services

#### Middleware Tests
- `MiddlewareIntegrationTests.swift`: Real middleware execution with services
- `MiddlewareErrorHandlingTests.swift`: Error propagation and recovery
- 7+ tests for service calls and state updates

#### Concurrency Tests
- `ConcurrencyTests.swift`: Thread-safety and actor isolation
- 16 tests covering parallel dispatches, race conditions, Sendable compliance

### Performance Tests (18 tests)

Performance benchmarks ensuring operations complete within time bounds.

#### Categories
- Store dispatch performance
- Reducer execution speed
- Data collection building
- Mock service efficiency
- Filtering and sorting
- Collection operations
- Date calculations
- String operations
- Set/dictionary operations

**Note**: Performance tests can be skipped with `SKIP_PERFORMANCE_TESTS=1`

### Edge Case Tests (16+ tests)

`EdgeCaseTests.swift`: Boundary conditions and unusual inputs.

### Test Data Builders

`TestDataBuilders.swift`: Factory methods for creating test objects with sensible defaults.

#### Available Builders
- `LocationBuilder` - Create Location test objects
- `ShiftTypeBuilder` - Create ShiftType test objects with presets (morning, afternoon, night)
- `ScheduledShiftBuilder` - Create ScheduledShift instances
- `ChangeLogEntryBuilder` - Create ChangeLogEntry objects
- `ShiftSnapshotBuilder` - Create shift snapshots for comparison
- `TestDataCollections` - Standard sets of test data

## Writing New Tests

### Test Structure

Follow this structure for all new tests:

```swift
@Test("Descriptive test name")
func testMyFeature() {
    // Given - Setup preconditions
    let service = MyService()

    // When - Perform action
    let result = service.doSomething()

    // Then - Assert expected behavior
    #expect(result == expectedValue)
}
```

### Naming Conventions

1. **File Names**: `[FeatureName]Tests.swift` or `[Feature]ErrorTests.swift`
2. **Test Method Names**: `test[Feature][Scenario]()` - descriptive what is tested
3. **Test Decorator Names**: Use sentence case describing the test scenario

Examples:
- ✅ `@Test("User authorization succeeds with valid credentials")`
- ✅ `func testCalendarAuthorizationWithValidPermissions()`
- ❌ `@Test("Test authorization")` - too vague
- ❌ `func testAuth()` - insufficient detail

### Assertions

**CRITICAL**: Use behavior-based assertions, not type-checking.

```swift
// ❌ WRONG - Type checking (doesn't test behavior)
#expect(result is Bool)
#expect(error is CalendarServiceError)

// ✅ RIGHT - Behavior validation
#expect(result == true)
if case .notAuthorized = error {
    #expect(true)
} else {
    #expect(Bool(false), "Expected .notAuthorized error")
}
```

### Mock Usage

Use protocol-based mocks for dependency injection:

```swift
// Create mock with configured behavior
let mockService = MockCalendarService()
mockService.shouldThrowError = true
mockService.throwError = CalendarServiceError.notAuthorized

// Inject into system under test
let store = Store(..., services: mockServices, ...)

// Verify behavior
do {
    _ = try await mockService.isCalendarAuthorized()
    #expect(false, "Should have thrown")
} catch let error as CalendarServiceError {
    if case .notAuthorized = error {
        #expect(true)
    } else {
        throw error
    }
}
```

### Error Testing

For error scenario tests:

1. Configure mock to throw specific error
2. Call operation in try/catch
3. Validate error type with pattern matching
4. Never silently catch and ignore errors

```swift
@Test("Service throws when unavailable")
func testServiceErrorHandling() async throws {
    let mockService = MockCalendarService()
    mockService.shouldThrowError = true
    mockService.throwError = CalendarServiceError.notAuthorized

    do {
        _ = try await mockService.isCalendarAuthorized()
        #expect(Bool(false), "Expected error to be thrown")
    } catch let error as CalendarServiceError {
        if case .notAuthorized = error {
            #expect(true)  // Expected error caught
        } else {
            throw error  // Unexpected error type
        }
    }
}
```

### Async/Await Testing

Use `async` function signature and `await` for async operations:

```swift
@Test("Async operation completes successfully")
func testAsyncOperation() async throws {
    let service = CalendarService()
    let shifts = try await service.loadShifts(from: Date(), to: Date())
    #expect(!shifts.isEmpty)
}
```

### Date Handling in Tests

**Always use fixed, deterministic dates** - never use `Date()` directly:

```swift
// ❌ WRONG - Non-deterministic
let today = Date()

// ✅ RIGHT - Deterministic
let today = Calendar.current.date(from: DateComponents(
    year: 2025, month: 10, day: 30
))!

// ✅ Also acceptable for relative dates
let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
```

### Performance Tests

Mark performance tests with their tolerance:

```swift
@Test("Large collection sorting is fast")
func testLargeSortingPerformance() {
    let startTime = Date()
    let sorted = items.sorted { $0.date < $1.date }
    let elapsed = Date().timeIntervalSince(startTime)

    #expect(elapsed < 0.1, "Sorting 1000 items should take < 0.1 seconds")
}
```

## Best Practices

### ✅ DO

- Write one assertion per test (or logically grouped related assertions)
- Use descriptive test names that document the behavior being tested
- Test both happy paths and error scenarios
- Use builders for complex test data setup
- Mock external dependencies (calendar, files, network)
- Use deterministic dates instead of `Date()`
- Test error types with pattern matching, not just error existence
- Keep tests fast and isolated
- Use `@MainActor` on test structs that need main thread
- Document non-obvious test setup in comments

### ❌ DON'T

- Use `try!` or force unwraps (`!`) in tests
- Use `print()` for debugging (use `Logger` instead)
- Create shared global test state
- Use `Date()` directly (use calendar arithmetic instead)
- Write tests that depend on other tests
- Test multiple features in one test
- Ignore errors in catch blocks
- Use generic test names like "test1", "test2"
- Check types instead of behavior
- Leave `@Test()` decorator empty or with vague descriptions

## Test Coverage Goals

| Category | Current | Target |
|----------|---------|--------|
| Service Layer | 75 tests | 100% coverage |
| Redux | 80 tests | 95% coverage |
| Performance | 18 tests | Core paths benchmarked |
| Edge Cases | 16+ tests | All identified cases |
| **Total** | **200+** | **250+** |

## CI/CD Integration

### Recommended CI Configuration

```bash
# Fast CI run (skip performance tests)
SKIP_PERFORMANCE_TESTS=1 xcodebuild test \
  -project ShiftScheduler.xcodeproj \
  -scheme ShiftScheduler \
  -destination 'platform=iOS Simulator,id=490A490A-C97A-43EE-978E-148A74A72499'

# Full test run (nightly)
xcodebuild test \
  -project ShiftScheduler.xcodeproj \
  -scheme ShiftScheduler \
  -destination 'platform=iOS Simulator,id=490A490A-C97A-43EE-978E-148A74A72499'
```

### Test Output

Tests are reported with:
- Test count
- Pass/fail status
- Execution time
- Performance results (if applicable)

## Troubleshooting

### Tests Won't Run

1. Verify simulator is available:
   ```bash
   xcrun simctl list devices | grep iPhone
   ```

2. Update simulator ID if needed:
   ```bash
   xcodebuild -project ShiftScheduler.xcodeproj -scheme ShiftScheduler -showdestinations
   ```

### Flaky Tests

- Ensure tests use deterministic dates
- Verify no global state is shared between tests
- Check that async operations complete fully
- Add appropriate sleep/wait for timing-sensitive code

### Performance Test Timeouts

Reduce iteration counts or disable for CI:
```bash
SKIP_PERFORMANCE_TESTS=1 xcodebuild test ...
```

## Resources

- [Swift Testing Framework](https://developer.apple.com/documentation/testing)
- [Test-Driven Development Best Practices](https://www.pointfree.co)
- Project CLAUDE.md for architecture and design patterns
- TEST_QUALITY_REVIEW.md for detailed quality metrics

## Recent Changes (Phase 4E)

- ✅ Service layer error handling tests (Phase 4E-3.1)
- ✅ Redux concurrency tests (Phase 4E-3.2)
- ✅ Middleware integration tests (Phase 4E-3.3)
- ✅ TestDataBuilders cleanup - removed dead code (Phase 4E-4.1)
- ✅ Performance tests separated into optional execution (Phase 4E-4.2)
- ✅ Comprehensive test documentation (Phase 4E-4.3)

**For detailed quality metrics, see TEST_QUALITY_REVIEW.md**
