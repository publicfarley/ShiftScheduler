# ShiftScheduler - iOS Shift Management App

A modern iOS shift scheduling application built with SwiftUI and The Composable Architecture (TCA).

**Current Status:** Phase 2B Complete (TCA Migration 85%, Overall 65%)

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
- **[CLAUDE.md](CLAUDE.md)** - Project conventions and best practices
- **[TCA_PHASE2B_TASK_CHECKLIST.md](TCA_PHASE2B_TASK_CHECKLIST.md)** - Detailed task breakdown
- **[TCA_PHASE2_SUMMARY.md](TCA_PHASE2_SUMMARY.md)** - Phase 2 completion summary
- **[TCA_MIGRATION_PHASE1.md](TCA_MIGRATION_PHASE1.md)** - Phase 1 technical details

### 🎨 Visual Design
- **[STATUS_REPORT.md](STATUS_REPORT.md)** - Visual UI enhancement project status
- **[SHIFTTYPE_LOCATION_AGGREGATE_DESIGN.md](SHIFTTYPE_LOCATION_AGGREGATE_DESIGN.md)** - Domain design

### 📖 Guides & References
- **[MIGRATION_QUICK_START.md](MIGRATION_QUICK_START.md)** - Detailed TCA migration guide
- **[KEYBOARD_DISMISSAL_GUIDE.md](KEYBOARD_DISMISSAL_GUIDE.md)** - Keyboard handling patterns

---

## 🎯 Current Project Status

### TCA Migration (Main Track)
- ✅ **Phase 1** - Foundation complete
- ✅ **Phase 2A** - Initial views migrated
- ✅ **Phase 2B** - Complex views migrated + integration tests
- 🟡 **Phase 3** - Performance testing (pending, 2-3 hours)
- 🟡 **Phase 4** - Final verification (pending, 1 hour)

**Completion: 85%** (All 9 views using TCA stores ✅)

### Visual UI Enhancement (Secondary Track)
- ✅ **Phase 1** - Foundation review
- ✅ **Phase 2A** - ShiftTypeCard component
- ✅ **Phase 2B** - Location color system
- 🟡 **Phase 2C** - LocationCard component (pending, 1.5-2 hours)
- 🟡 **Phase 3-5** - View updates and refinements

**Completion: 43%**

### Overall Project: **65%**

---

## 🏃 Next Steps

### Recommended: TCA Performance Testing
**Estimated Time:** 2-3 hours
```
1. Create performance tests for 1000+ shifts
2. Profile scroll and search performance
3. Optimize bottlenecks if identified
4. Document performance baselines
```

See: [PROJECT_PHASE_SCHEDULE.md](PROJECT_PHASE_SCHEDULE.md) → Phase 3

### Alternative: Visual Enhancement
**Estimated Time:** 1.5-2 hours
```
1. Create EnhancedLocationCard component
2. Add to LocationsView
3. Test with multiple locations
```

See: [STATUS_REPORT.md](STATUS_REPORT.md) → Phase 2C

---

## 🏗️ Project Structure

```
ShiftScheduler/
├── Domain/                 # Core domain models
│   ├── Domain.swift       # Location, ShiftType, ScheduledShift
│   ├── Aggregates.swift   # ShiftCatalog, Schedule
│   └── ...
│
├── Features/              # TCA Reducers (state management)
│   ├── TodayFeature.swift
│   ├── ScheduleFeature.swift
│   ├── ShiftTypesFeature.swift
│   ├── LocationsFeature.swift
│   ├── SettingsFeature.swift
│   ├── ChangeLogFeature.swift
│   └── ...
│
├── Dependencies/          # TCA Dependency Clients
│   ├── CalendarClient.swift
│   ├── PersistenceClient.swift
│   ├── ShiftSwitchClient.swift
│   └── ...
│
├── Views/                 # SwiftUI Views (all TCA-based)
│   ├── TodayView.swift
│   ├── ScheduleView.swift
│   ├── ShiftTypesView.swift
│   ├── LocationsView.swift
│   ├── Components/       # Reusable components
│   └── ...
│
└── Services/             # Legacy services (being replaced)
    ├── CalendarService.swift
    ├── ShiftSwitchService.swift
    └── ...

ShiftSchedulerTests/
├── Features/            # Feature unit tests
├── Integration/         # Feature integration tests (NEW)
├── Domain/              # Domain model tests
├── Mocks/               # Mock implementations
└── ...
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

### TCA (The Composable Architecture)
- All views use `@Bindable var store: StoreOf<Feature>`
- No direct singleton access from views
- 100% of business logic in features
- Testable, composable, and predictable

### Swift 6 Concurrency
- Strict concurrency checking enabled
- All async code properly handles Sendable
- No global mutable state (only actors)
- Data races eliminated at compile time

### Dependency Injection
- All external services wrapped as TCA dependencies
- Mockable for testing
- Easily swappable implementations

### Testing Strategy
- Swift Testing framework (not XCTest)
- Feature unit tests for all reducers
- Integration tests for feature composition
- Performance tests for optimization

---

## 📊 Metrics

| Metric | Value |
|--------|-------|
| Views Using TCA | 9/9 (100%) ✅ |
| Features Implemented | 8+ |
| Unit Tests | 16+ |
| Integration Tests | 14+ |
| Lines of Production Code | 8,000+ |
| Test Coverage | >80% |
| Compilation Warnings | 0 |
| Swift Concurrency Warnings | 0 |

---

## 🎯 Success Criteria

- ✅ All views use TCA stores
- ✅ Zero singleton access from views
- ✅ 100% of business logic in features
- ✅ All features unit tested (>80% coverage)
- ✅ Integration tests passing
- ✅ Performance acceptable (<1s load time)
- ✅ Compiles with zero warnings
- ⏳ Visual refresh complete
- ⏳ Ready for production

---

## 📝 Recent Changes

| Commit | Date | Description |
|--------|------|-------------|
| `8a0d81f` | Oct 22 | Phase schedule & quick start docs |
| `15a7fad` | Oct 22 | Task 12: Integration tests |
| `b65ed7d` | Oct 22 | ChangeLogView TCA migration |
| `20f1c46` | Oct 21 | ScheduleFeature TCA reducer |
| `e4b9e61` | Oct 21 | ShiftTypesFeature TCA reducer |

See full history: `git log --oneline | head -20`

---

## 🤝 Contributing

Follow patterns in [CLAUDE.md](CLAUDE.md):
- Use `@Observable` macro for state management
- No forced unwraps (`!`)
- Protocol-oriented dependencies
- Comprehensive error handling
- Keyboard dismissal for input forms

---

## 📞 Questions?

Refer to:
1. **Architecture:** See [CLAUDE.md](CLAUDE.md)
2. **TCA Migration:** See [TCA_MIGRATION_PHASE1.md](TCA_MIGRATION_PHASE1.md)
3. **Current Status:** See [PROJECT_PHASE_SCHEDULE.md](PROJECT_PHASE_SCHEDULE.md)
4. **Next Steps:** See [QUICK_START.md](QUICK_START.md)

---

**Project Last Updated:** October 22, 2025
**Phase Schedule Last Updated:** October 22, 2025
**Documentation Status:** Complete and Persistent ✅

Start with [QUICK_START.md](QUICK_START.md) →
