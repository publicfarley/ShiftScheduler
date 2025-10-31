# ShiftScheduler - iOS Shift Management App

A modern iOS shift scheduling application built with SwiftUI and Redux architecture for unidirectional data flow and predictable state management.

**Current Status:** Phase 4 In Progress (Redux Architecture Complete, Testing 75%)

---

## 📚 Documentation Index

### 🚀 Start Here
- **[QUICK_START.md](QUICK_START.md)** ← **Start here for each session**
  - Quick navigation to all documents
  - Current project status and next steps
  - Build and test commands
  - Session workflow guide

### 📅 Phase & Progress Tracking
- **[PROJECT_PHASE_SCHEDULE.md](PROJECT_PHASE_SCHEDULE.md)** ← **Master schedule**
  - Complete timeline for both development tracks
  - Phase status and upcoming work
  - Session history log
  - Time estimates for each phase

### 🏗️ Architecture & Design
- **[CLAUDE.md](CLAUDE.md)** - Project conventions, Redux architecture, and best practices
- **[Redux Architecture Guide](#redux-architecture)** - State management patterns and middleware
- **[Phase Documentation](#-phase-status)** - Redux phase progression (Phase 0-4)

### 🎨 Visual Design
- **[STATUS_REPORT.md](STATUS_REPORT.md)** - Visual UI enhancement project status
- **[SHIFTTYPE_LOCATION_AGGREGATE_DESIGN.md](SHIFTTYPE_LOCATION_AGGREGATE_DESIGN.md)** - Domain design

### 📖 Guides & References
- **[MIGRATION_QUICK_START.md](MIGRATION_QUICK_START.md)** - Detailed TCA migration guide
- **[KEYBOARD_DISMISSAL_GUIDE.md](KEYBOARD_DISMISSAL_GUIDE.md)** - Keyboard handling patterns

---

## 🎯 Current Project Status

### Redux Architecture (Main Track)
- ✅ **Phase 0** - Removed TCA, created Redux foundation (Store, AppState, AppAction)
- ✅ **Phase 1** - Redux foundation with logging middleware
- ✅ **Phase 2** - Service layer and 6 feature middlewares
- ✅ **Phase 3** - View layer with 6 feature views connected
- ✅ **Phase 4 Priority 1** - Full CRUD operations (Add/Edit/Delete for Locations & Shift Types)
- ✅ **Phase 4 Priority 2** - Calendar filtering, date range selection, search
- ✅ **Phase 4 Priority 3** - Shift switching with undo/redo middleware
- 🟡 **Phase 4 Priority 4** - Testing (Service unit tests 75+ implemented, Priority 4E in progress)

**Completion: 90%** (All Redux phases operational, testing in progress ✅)

### Test Coverage
- ✅ Service layer tests: 75+ tests implemented
- ✅ Integration tests: Shift switching, calendar operations, persistence
- 🟡 Reducer state tests: Foundation ready
- 🟡 Middleware integration tests: In progress
- 🟡 View interaction tests: Pending

**Test Completion: 75%**

### Overall Project: **88%**

---

## 🏃 Next Steps

### Priority: Complete Redux Phase 4 Testing
**Estimated Time:** 40+ hours (Phase 4E breakdown)
```
Phase 4E-1: Critical Test Quality Fixes (18 hours)
  • Fix/delete disabled test suites
  • Rename and rewrite MiddlewareIntegrationTests
  • Rewrite CalendarServiceTests for actual behavior

Phase 4E-2: Test Quality & Isolation (14 hours)
  • Separate unit/integration test files
  • Add proper teardown/cleanup
  • Fix date determinism issues

Phase 4E-3: Additional Test Coverage (36 hours)
  • Error scenario tests
  • Concurrency tests
  • Real middleware integration tests

Phase 4E-4: Infrastructure & Docs (6 hours)
  • Clean up test infrastructure
  • Separate performance tests
  • Add test documentation
```

See: [CLAUDE.md](CLAUDE.md) → Phase 4 Priority 4E section

### After Testing: Production Ready
- [ ] Final bug fixes from test coverage
- [ ] Performance optimization if needed
- [ ] Documentation review
- [ ] Release v1.0

---

## 🏗️ Project Structure

```
ShiftScheduler/
├── Redux/                  # Redux architecture (state management)
│   ├── Store.swift         # @Observable @MainActor single source of truth
│   ├── AppState.swift      # 7 feature states combined
│   ├── AppAction.swift     # 60+ action types across all features
│   ├── AppReducer.swift    # Pure state transformation logic
│   └── Middleware/         # Async side effects handlers
│       ├── LoggingMiddleware.swift
│       ├── ScheduleMiddleware.swift
│       ├── TodayMiddleware.swift
│       ├── LocationsMiddleware.swift
│       ├── ShiftTypesMiddleware.swift
│       ├── ChangeLogMiddleware.swift
│       └── SettingsMiddleware.swift
│
├── Domain/                 # Core domain models (DDD)
│   ├── Domain.swift        # Location, ShiftType, ScheduledShift
│   ├── Aggregates.swift    # ShiftCatalog, Schedule
│   └── ...
│
├── Services/               # Service protocols & implementations
│   ├── CalendarServiceProtocol
│   ├── PersistenceServiceProtocol
│   ├── ShiftSwitchServiceProtocol
│   ├── CurrentDayServiceProtocol
│   └── ServiceContainer.swift (dependency injection)
│
├── Views/                  # SwiftUI Views (Redux-connected)
│   ├── ContentView.swift
│   ├── TodayView.swift
│   ├── ScheduleView.swift
│   ├── ShiftTypesView.swift
│   ├── LocationsView.swift
│   ├── SettingsView.swift
│   ├── ChangeLogView.swift
│   ├── Components/         # Reusable UI components
│   └── Utilities/          # KeyboardDismissal, Modifiers
│
└── Utilities/              # Shared helpers
    ├── Redux environment
    ├── Error handling
    └── ...

ShiftSchedulerTests/
├── Services/              # Service unit & integration tests (75+ tests)
├── Redux/                 # Reducer and middleware tests
├── Domain/                # Domain model tests
├── Mocks/                 # Mock service implementations
└── Helpers/               # Test data builders
```

---

## 📋 Session Workflow

### At Session Start (5 minutes)
1. Open [QUICK_START.md](QUICK_START.md)
2. Check current completion % and next phase
3. Review time estimate for your session
4. Pull latest changes: `git pull origin main`

### During Session
- Work on phase tasks
- Run tests frequently: `xcodebuild ... test`
- Make regular commits

### At Session End (5 minutes)
1. Update [PROJECT_PHASE_SCHEDULE.md](PROJECT_PHASE_SCHEDULE.md)
   - Change status emoji (🟡 → ✅)
   - Update completion %
   - Add session history row
2. Commit: `git add PROJECT_PHASE_SCHEDULE.md && git commit -m "docs: update phase progress"`
3. Push: `git push origin <branch>`

---

## 🔧 Build & Test

### Build for iOS Simulator
```bash
xcodebuild -project ShiftScheduler.xcodeproj \
  -scheme ShiftScheduler \
  -destination 'platform=iOS Simulator,id=490A490A-C97A-43EE-978E-148A74A72499' \
  build
```

### Run All Tests
```bash
xcodebuild -project ShiftScheduler.xcodeproj \
  -scheme ShiftScheduler \
  -destination 'platform=iOS Simulator,id=490A490A-C97A-43EE-978E-148A74A72499' \
  test
```

---

## ✨ Key Architecture Decisions

### Redux Pattern
- **Single Source of Truth**: @Observable @MainActor Store holds all AppState
- **Unidirectional Data Flow**: Action → Reducer → Middleware → State → UI
- **Pure Reducers**: All state mutations are deterministic and testable
- **Middleware for Side Effects**: Calendar ops, persistence, async tasks
- **No Singletons**: All services injected via ServiceContainer

### Swift 6 Concurrency
- Strict concurrency checking enabled
- All async code uses Task/async/await (no DispatchQueue)
- No global mutable state (services are stateless)
- Data races eliminated at compile time
- @MainActor enforcement for UI updates

### Service Layer (Dependency Injection)
- All external operations through protocols
- Production implementations: Calendar, Persistence, ShiftSwitch, CurrentDay
- Mock implementations for testing
- ServiceContainer for centralized dependency injection
- Easily testable with mock services

### Testing Strategy
- Swift Testing framework (not XCTest)
- Service unit tests (75+ implemented)
- Integration tests for middleware & services
- Reducer state transition tests
- Mock services for isolation

---

## 📊 Metrics

| Metric | Value |
|--------|-------|
| Redux Architecture | 100% ✅ |
| Views Connected to Store | 6/6 (100%) ✅ |
| Middleware Features | 6 complete ✅ |
| Service Protocols | 4 complete ✅ |
| Service Tests | 75+ (Service layer) ✅ |
| Total Tests | 100+ (all frameworks) |
| Lines of Production Code | 12,000+ |
| Test Coverage | 75% (Phase 4 in progress) |
| Compilation Warnings | 0 |
| Swift Concurrency Warnings | 0 |
| Architecture Pattern | Redux (unidirectional) ✅ |
| Testing Framework | Swift Testing (not XCTest) ✅ |

---

## 🎯 Success Criteria

- ✅ Redux architecture implemented with Store, AppState, AppAction, AppReducer
- ✅ All 6 views connected to Redux store
- ✅ All 6 feature middlewares implementing side effects
- ✅ Full CRUD operations (Add/Edit/Delete) for Locations and Shift Types
- ✅ Calendar integration with filtering and search
- ✅ Shift switching with undo/redo capability
- ✅ 75+ service layer tests implemented
- ✅ No singletons in Redux/view layer
- ✅ Swift 6 concurrency throughout (Task/async/await)
- ✅ Compiles with zero warnings
- 🟡 Phase 4 testing completion (in progress)
- ⏳ Production ready (after testing complete)

---

## 📝 Recent Changes

| Commit | Date | Description |
|--------|------|-------------|
| `2a525a4` | Oct 29 | Phase 4A: Service unit tests (75+ tests) |
| `2b7c6ba` | Oct 24 | Phase 4 Priority 3: Shift switching with undo/redo |
| `d6ae0a3` | Oct 23 | Phase 4 Priority 1: Full CRUD operations |
| `474f043` | Oct 23 | Phase 3: View layer & navigation (6 views) |
| `45844ce` | Oct 23 | Phase 2: Service layer & 6 middlewares |
| `8a00c66` | Oct 23 | Phase 1: Redux foundation with logging |
| `8506de5` | Oct 22 | TCA: Quick Actions feature |
| `2c3f2f2` | Oct 22 | TCA: Merge shift all-day event fix |

See full history: `git log --oneline | head -20`

---

## 🤝 Contributing

Follow Redux patterns in [CLAUDE.md](CLAUDE.md):
- **Dispatch actions** for all user interactions: `store.dispatch(action: .feature(.action))`
- **Reducers** transform state deterministically
- **Middleware** handles side effects (calendar, persistence, async)
- **Services** injected via protocols (testable mocks)
- **No forced unwraps** (`!`) - use safe unwrapping
- **Swift 6 concurrency** - use Task/async/await, not DispatchQueue
- **Keyboard dismissal** for all text input views
- **@MainActor** for UI operations

---

## 📞 Questions?

Refer to:
1. **Redux Architecture:** See [CLAUDE.md](CLAUDE.md) → Redux Architecture section
2. **Middleware & Services:** See [CLAUDE.md](CLAUDE.md) → Phase 2 & Service Layer
3. **Phase Progress:** See [CLAUDE.md](CLAUDE.md) → Redux Architecture Migration
4. **Next Steps:** See [QUICK_START.md](QUICK_START.md)
5. **Swift 6 Concurrency:** See [CLAUDE.md](CLAUDE.md) → Swift 6 Concurrency & Async/Await

---

**Project Last Updated:** October 31, 2025
**Redux Architecture:** Phases 0-4 Complete (Testing in Progress) 🚀
**Documentation Status:** Current and Accurate ✅

Start with [QUICK_START.md](QUICK_START.md) →
