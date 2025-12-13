# Product Requirements Document: Shift Switch Feature

**Project:** ShiftScheduler
**Feature:** Shift Switch with Change Logging
**Version:** 1.1
**Date:** 2025-10-09
**Status:** Ready for Implementation Approval

---

## Executive Summary

The Shift Switch feature enables users to change scheduled shifts with complete historical tracking. This feature introduces multi-user support, comprehensive change logging with 1-year retention, and undo/redo capabilities—all implemented using SwiftData persistence integrated with the existing DDD architecture.

**Key Capabilities:**
- Switch any shift to any other shift type without constraints
- Track all changes with timestamp, user, reason, and old/new shift details
- Maintain historical record of deleted shifts in change log
- Undo/redo functionality for recent changes
- Configurable change log retention period (default: 1 year)
- Multi-user identification system

**Critical Architectural Principle:**
This feature strictly adheres to protocol-oriented programming for ALL external side-effecting dependencies. Every external dependency—including SwiftData ModelContext, calendar services, persistence layers, and system APIs—MUST be abstracted behind protocols to enable proper unit testing with mock implementations. This ensures testability, maintainability, and adherence to SOLID principles.

---

## 1. Product Vision

### 1.1 Problem Statement
Users need the ability to change their scheduled shifts while maintaining a complete historical record of all modifications. The system must support multiple users and provide transparency into shift changes over time.

### 1.2 Solution Overview
A comprehensive shift switching system with:
- Intuitive UI for changing shifts on Schedule and Today screens
- Separate Change Log aggregate with SwiftData persistence
- Immutable shift versioning to preserve historical accuracy
- Multi-user support with user identification
- Configurable retention policies
- **100% testable architecture through protocol-based dependency injection**

### 1.3 Success Metrics
- Users can successfully switch shifts in <5 seconds
- 100% of shift changes are logged with complete metadata
- Zero data loss during shift operations
- Change log maintains data integrity for configured retention period
- Undo/redo operations execute correctly 100% of the time
- **90%+ unit test coverage enabled by protocol-oriented architecture**

---

## 2. Functional Requirements

### 2.1 Shift Switching Core Functionality

#### FR-2.1.1: Switch Shift from Schedule Screen
**Priority:** P0 (Critical)

**Acceptance Criteria:**
- User taps on a selected shift displayed at bottom of Schedule screen
- Shift change sheet appears with Liquid Glass UI
- User selects new shift type from available options
- User optionally enters reason for change (text field)
- Confirmation popup appears: "Are you sure you want to switch this shift?"
- Upon confirmation, shift is immediately updated
- Success message appears: "Shift switched successfully"
- Schedule screen reflects new shift state
- Change is logged with all metadata

**Business Rules:**
- Any shift type can replace any other shift type (no constraints)
- No location matching requirements
- No time-based restrictions
- Switch operation is atomic (all-or-nothing)

#### FR-2.1.2: Switch Shift from Today Screen
**Priority:** P0 (Critical)

**Acceptance Criteria:**
- Quick Actions section displays "Switch Shift" CTA when today's shift exists
- Tapping "Switch Shift" opens same shift change sheet as Schedule screen
- Pre-selects today's shift as the shift to be switched
- Same workflow and validation as Schedule screen switch

**Business Rules:**
- Only available when a shift exists for today
- Uses same confirmation and success messaging

#### FR-2.1.3: Shift Switching Validation
**Priority:** P0 (Critical)

**Acceptance Criteria:**
- No validation constraints on shift type compatibility
- No validation constraints on location
- No validation constraints on time
- User cannot switch to the same shift type (no-op)
- Network connectivity validated before attempting switch
- Calendar service authorization validated

---

### 2.2 Change Log System

#### FR-2.2.1: Change Log Data Capture
**Priority:** P0 (Critical)

**Acceptance Criteria:**
- Every shift switch captures:
  - Timestamp (Date with millisecond precision)
  - User ID (UUID identifying the user)
  - Old shift type (full ShiftType details)
  - New shift type (full ShiftType details)
  - Shift date
  - Optional reason (user-provided text)
  - Change type: "SWITCH"
- Change log entry persisted via SwiftData
- Entry creation is transactional with shift update

**Data Model:**
```swift
@Model
class ChangeLogEntry {
    var id: UUID
    var timestamp: Date
    var userId: UUID
    var changeType: ChangeType // enum: switch, delete, create
    var shiftDate: Date
    var oldShiftTypeId: UUID?
    var newShiftTypeId: UUID?
    var reason: String?
    var oldShiftDetails: ShiftSnapshot? // embedded value object
    var newShiftDetails: ShiftSnapshot? // embedded value object
}

enum ChangeType: String, Codable {
    case switch
    case delete
    case create
}

struct ShiftSnapshot: Codable {
    let shiftTypeId: UUID
    let symbol: String
    let title: String
    let timeRange: String
    let location: String?
}
```

#### FR-2.2.2: Deleted Shift Logging
**Priority:** P0 (Critical)

**Acceptance Criteria:**
- When shift is deleted, change log entry created with:
  - Change type: "DELETE"
  - Old shift details captured
  - New shift details: nil
  - User ID captured
  - Timestamp captured
- Deleted shift remains visible in Change Log
- Change Log maintains record even after shift deletion from calendar

#### FR-2.2.3: Change Log Retention Policy
**Priority:** P1 (High)

**Acceptance Criteria:**
- Default retention period: 1 year (365 days)
- Retention period configurable in Settings screen
- Options: 30 days, 90 days, 6 months, 1 year, 2 years, Forever
- Background task automatically purges entries older than retention period
- Purge operation runs daily
- User notified of purge operation in Settings (last purged date)

#### FR-2.2.4: Change Log Screen
**Priority:** P0 (Critical)

**Acceptance Criteria:**
- New tab in main TabView: "Change Log"
- List view showing all change log entries
- Sorted by timestamp (most recent first)
- Each entry displays:
  - Date and time
  - Change type icon and label
  - Old shift → New shift (for switches)
  - Shift date
  - Reason (if provided)
  - User identifier
- Pull-to-refresh functionality
- Search/filter capabilities:
  - Filter by date range
  - Filter by change type
  - Filter by user
  - Search by reason text
- Empty state when no changes logged
- Loading state during data fetch
- Error state for load failures

**UI Design Principles:**
- Follow iOS industry best practices
- Use SF Symbols for icons
- Group changes by day with section headers
- Subtle animations for list updates
- Haptic feedback on interactions

---

### 2.3 Multi-User Support

#### FR-2.3.1: User Identification
**Priority:** P0 (Critical)

**Acceptance Criteria:**
- App generates unique User ID (UUID) on first launch
- User ID persisted in UserDefaults
- User ID included in all change log entries
- Settings screen displays current User ID
- Settings screen allows user to set display name
- Display name shown in Change Log instead of UUID when available

**Data Model:**
```swift
struct UserProfile {
    let userId: UUID
    var displayName: String?
}
```

#### FR-2.3.2: User Profile Management
**Priority:** P1 (High)

**Acceptance Criteria:**
- Settings screen section: "User Profile"
- Display User ID (read-only, copyable)
- Text field to edit display name
- "Reset User ID" option (with confirmation)
- Warning: Resetting User ID creates new identity for change tracking

---

### 2.4 Undo/Redo Functionality

#### FR-2.4.1: Undo Last Change
**Priority:** P1 (High)

**Acceptance Criteria:**
- Undo button available in Schedule and Today screens
- Only enabled when undo stack is not empty
- Undo reverts last shift switch
- Undo operation:
  - Restores previous shift state
  - Creates new change log entry marking the undo
  - Updates UI immediately
  - Adds operation to redo stack
- Undo stack maintains last 10 operations
- Undo stack persisted across app sessions

**Business Rules:**
- Only shift switches can be undone (not deletions or creations)
- Undo must validate shift date hasn't passed
- Undo validates calendar authorization

#### FR-2.4.2: Redo Last Undone Change
**Priority:** P1 (High)

**Acceptance Criteria:**
- Redo button available in Schedule and Today screens
- Only enabled when redo stack is not empty
- Redo re-applies previously undone change
- Redo operation:
  - Restores undone shift state
  - Creates new change log entry marking the redo
  - Updates UI immediately
  - Removes operation from redo stack
- Redo stack cleared when new change made
- Redo stack persisted across app sessions

---

### 2.5 Domain Model Changes

#### FR-2.5.1: Immutable ScheduledShift with Versioning
**Priority:** P0 (Critical)

**Current Model:**
```swift
struct ScheduledShift: Identifiable, Equatable {
    let id: UUID
    let eventIdentifier: String
    let shiftType: ShiftType?
    let date: Date
}
```

**New Model:**
```swift
struct ScheduledShift: Identifiable, Equatable, Sendable {
    let id: UUID
    let version: Int
    let eventIdentifier: String
    let shiftType: ShiftType?
    let date: Date
    let createdAt: Date
    let createdBy: UUID
    let lastModifiedAt: Date
    let lastModifiedBy: UUID

    func withNewShiftType(_ newShiftType: ShiftType, modifiedBy userId: UUID) -> ScheduledShift {
        // Returns new instance with incremented version
    }
}
```

**Acceptance Criteria:**
- ScheduledShift is immutable (all properties let)
- Version increments on each modification
- Tracks creation and modification metadata
- Factory method creates new version for modifications
- Sendable conformance for Swift 6 concurrency

#### FR-2.5.2: ChangeLog Aggregate
**Priority:** P0 (Critical)

**Acceptance Criteria:**
- ChangeLog is separate SwiftData aggregate
- Manages ChangeLogEntry lifecycle
- Enforces retention policies
- Provides query interface for UI
- Actor-based for Swift 6 concurrency safety

**Domain Model:**
```swift
actor ChangeLog {
    private let context: ModelContextProtocol  // Protocol abstraction!
    private let retentionPolicy: ChangeLogRetentionPolicy

    func recordShiftSwitch(
        oldShift: ScheduledShift,
        newShift: ScheduledShift,
        reason: String?,
        userId: UUID
    ) async throws

    func recordShiftDeletion(
        shift: ScheduledShift,
        userId: UUID
    ) async throws

    func fetchEntries(
        from startDate: Date,
        to endDate: Date,
        filteredBy: ChangeLogFilter?
    ) async throws -> [ChangeLogEntry]

    func purgeExpiredEntries() async throws
}
```

---

## 3. Non-Functional Requirements

### 3.1 Performance Requirements

**NFR-3.1.1: Shift Switch Performance**
- Shift switch operation completes in <2 seconds
- UI remains responsive during operation
- Background operations don't block main thread

**NFR-3.1.2: Change Log Query Performance**
- Change Log screen loads in <1 second for 1000 entries
- Filtering/searching returns results in <500ms
- Pagination for large datasets (100 entries per page)

### 3.2 Data Integrity Requirements

**NFR-3.2.1: Transactional Consistency**
- Shift switch and change log creation are atomic
- Failure in either operation rolls back both
- No orphaned change log entries
- No unlogged shift switches

**NFR-3.2.2: Data Persistence**
- Change log survives app termination
- Change log survives app deletion/reinstall (via iCloud sync if enabled)
- No data corruption under concurrent access

### 3.3 Concurrency Requirements

**NFR-3.3.1: Swift 6 Concurrency Compliance**
- All mutable state protected by actors
- No data races at compile time
- Sendable conformance for transferred types
- MainActor isolation for UI updates

**NFR-3.3.2: Concurrent Operation Safety**
- Multiple shift switches don't corrupt state
- Change log writes are serialized
- Undo/redo stack operations are thread-safe

### 3.4 Usability Requirements

**NFR-3.4.1: UI Responsiveness**
- All user interactions provide immediate feedback
- Loading states shown for operations >500ms
- Error states are clear and actionable
- Success states confirm operation completion

**NFR-3.4.2: Accessibility**
- Native SwiftUI satisfies WCAG 2.1 AA standards
- VoiceOver support for all UI elements
- Dynamic Type support
- Sufficient color contrast ratios

### 3.5 Integration Requirements

**NFR-3.5.1: SwiftData Integration**
- SwiftData schema integrated with existing app architecture
- ModelContainer configured for ChangeLogEntry
- Existing DDD patterns preserved
- Repository pattern abstracts SwiftData implementation

**NFR-3.5.2: Calendar Service Integration**
- Shift switches update EventKit calendar events
- Change log doesn't depend on calendar service
- Calendar service failures don't prevent change logging
- Retry logic for transient calendar failures

### 3.6 Testability Requirements (NEW)

**NFR-3.6.1: Protocol-Oriented Architecture**
- **ALL external side-effecting dependencies MUST be abstracted behind protocols**
- Every production implementation MUST have a corresponding protocol
- Every protocol MUST have a mock implementation for testing
- Mock implementations MUST be used in ALL unit tests

**NFR-3.6.2: Dependency Injection**
- All services MUST accept dependencies through constructor injection
- Default parameters MAY be provided for production usage
- Test code MUST inject mock dependencies explicitly
- No direct instantiation of external dependencies within business logic

**NFR-3.6.3: Unit Test Coverage**
- Minimum 90% code coverage for domain logic
- 100% coverage for critical business rules
- All error paths tested with mock failures
- All concurrent operations tested with mock delays

---

## 4. User Interface Specifications

### 4.1 Shift Change Sheet

**Design Pattern:** Liquid Glass UI (following existing app patterns)

**Components:**
- Semi-transparent background with blur effect
- Floating modal with rounded corners (20pt radius)
- Material background (.ultraThinMaterial)
- Smooth slide-up animation (0.4s spring animation)

**Content Structure:**
```
┌─────────────────────────────────────────┐
│  Switch Shift                     [X]   │
│                                          │
│  Current Shift                           │
│  ┌────────────────────────────────────┐ │
│  │  [Symbol] Title                    │ │
│  │  Time: 9:00 AM - 5:00 PM          │ │
│  │  Location: Office                  │ │
│  └────────────────────────────────────┘ │
│                                          │
│  ↓ Switch To                             │
│                                          │
│  New Shift                               │
│  ┌────────────────────────────────────┐ │
│  │  Select Shift Type                 │ │
│  │  [Dropdown Picker]                 │ │
│  └────────────────────────────────────┘ │
│                                          │
│  Reason (Optional)                       │
│  ┌────────────────────────────────────┐ │
│  │  Enter reason for switch...        │ │
│  └────────────────────────────────────┘ │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │         Switch Shift               │ │
│  └────────────────────────────────────┘ │
│                                          │
│  [Cancel]                                │
└─────────────────────────────────────────┘
```

**Interaction Flow:**
1. User taps shift → Sheet slides up with spring animation
2. Current shift displays with visual card (readonly)
3. Dropdown shows all available shift types
4. User selects new shift → Preview updates
5. User optionally enters reason
6. User taps "Switch Shift"
7. Confirmation alert: "Are you sure?"
8. User confirms → Loading state (spinner)
9. Success: Toast message "Shift switched successfully"
10. Sheet dismisses with spring animation
11. Schedule updates with new shift

**Visual Design:**
- Use existing card styling from EnhancedShiftCard
- Color-coded shift types (matching existing palette)
- Liquid glass effects on buttons
- Haptic feedback on all interactions
- Smooth transitions between states

### 4.2 Today Screen Quick Action

**Location:** Quick Actions section (after existing actions)

**Button Design:**
```
┌──────────────────────┐
│   [clock.arrow]      │
│   Switch Shift       │
└──────────────────────┘
```

**Properties:**
- Icon: "arrow.triangle.2.circlepath" (SF Symbol)
- Color: .orange
- Only visible when today's shift exists
- Same visual style as OptimizedQuickActionButton

### 4.3 Change Log Screen

**Navigation:** New tab in TabView

**Tab Icon:** "clock.arrow.circlepath" (SF Symbol)

**Screen Layout:**
```
┌─────────────────────────────────────────┐
│  Change Log                    [Filter] │
│                                          │
│  Today                                   │
│  ┌────────────────────────────────────┐ │
│  │  [↻] Switch  •  2:45 PM            │ │
│  │  Day → Night Shift                  │ │
│  │  Oct 9, 2025                        │ │
│  │  Reason: Schedule conflict          │ │
│  │  User: John Doe                     │ │
│  └────────────────────────────────────┘ │
│                                          │
│  Yesterday                               │
│  ┌────────────────────────────────────┐ │
│  │  [✕] Delete  •  8:15 AM            │ │
│  │  Morning Shift                      │ │
│  │  Oct 8, 2025                        │ │
│  │  User: Jane Smith                   │ │
│  └────────────────────────────────────┘ │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │  [↻] Switch  •  9:30 PM            │ │
│  │  Night → Evening Shift              │ │
│  │  Oct 8, 2025                        │ │
│  │  User: John Doe                     │ │
│  └────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

**Features:**
- Pull-to-refresh
- Grouped by relative date (Today, Yesterday, Oct 7, etc.)
- Each entry is tappable → Detail view
- Filter button opens filter sheet
- Empty state with helpful message
- Smooth list animations

**Change Entry Card Design:**
- Material background (.ultraThinMaterial)
- Rounded corners (12pt)
- Color-coded border based on change type
- Icon badge for change type
- Timestamp in relative format
- User display name or ID
- Tap to expand for full details

**Filter Sheet Options:**
- Date Range picker
- Change Type toggle (Switch, Delete, Create)
- User picker (multi-select)
- Reason text search
- Clear Filters button
- Apply button

### 4.4 Settings Screen Changes

**New Section: Change Log Settings**
```
┌─────────────────────────────────────────┐
│  Change Log Settings                    │
│                                          │
│  Retention Period                        │
│  └─ [1 year          ▼]                 │
│                                          │
│  Last Purged                             │
│  └─ Oct 8, 2025 at 3:00 AM              │
│                                          │
│  Total Entries                           │
│  └─ 247 changes logged                  │
│                                          │
└─────────────────────────────────────────┘
```

**New Section: User Profile**
```
┌─────────────────────────────────────────┐
│  User Profile                           │
│                                          │
│  User ID                                 │
│  └─ 550e8400-e29b-41d4-a716...          │
│     [Copy ID]                            │
│                                          │
│  Display Name                            │
│  └─ [John Doe                ]          │
│                                          │
│  [Reset User ID]                         │
│                                          │
└─────────────────────────────────────────┘
```

---

## 5. Technical Architecture

### 5.1 Protocol-Oriented Architecture Principles

**CRITICAL REQUIREMENT: ALL external side-effecting dependencies MUST be abstracted behind protocols.**

This architecture ensures:
- **Testability:** Mock implementations enable true unit testing without external dependencies
- **Maintainability:** Clear contracts between components
- **Flexibility:** Easy to swap implementations (e.g., in-memory for testing, production for release)
- **Isolation:** Business logic completely independent of infrastructure concerns

**Dependencies Requiring Protocol Abstraction:**

1. **SwiftData ModelContext** → `ModelContextProtocol`
2. **Calendar Service** → `CalendarServiceProtocol`
3. **User Defaults** → `UserDefaultsProtocol`
4. **Date/Time Services** → `DateProviderProtocol`
5. **Notification Services** → `NotificationServiceProtocol`
6. **All Repository Implementations** → Repository protocols

**Implementation Pattern:**

```swift
// 1. Define Protocol
protocol ServiceProtocol: Sendable {
    func performOperation() async throws -> Result
}

// 2. Production Conformance
final class ProductionService: ServiceProtocol {
    func performOperation() async throws -> Result {
        // Real implementation using external dependencies
    }
}

// 3. Mock for Testing
final class MockService: ServiceProtocol {
    var shouldFail = false
    var capturedCalls: [String] = []
    var mockResult: Result?

    func performOperation() async throws -> Result {
        capturedCalls.append("performOperation")
        if shouldFail {
            throw TestError.intentionalFailure
        }
        return mockResult ?? Result()
    }
}

// 4. Dependency Injection
actor BusinessLogic {
    private let service: ServiceProtocol

    init(service: ServiceProtocol) {
        self.service = service
    }
}

// 5. Production Usage
let production = BusinessLogic(service: ProductionService())

// 6. Test Usage
let mock = MockService()
let test = BusinessLogic(service: mock)
```

### 5.2 Domain Model Design

#### 5.2.1 Core Domain Objects

**ScheduledShift (Immutable with Versioning)**
```swift
struct ScheduledShift: Identifiable, Equatable, Sendable {
    let id: UUID
    let version: Int
    let eventIdentifier: String
    let shiftType: ShiftType?
    let date: Date
    let createdAt: Date
    let createdBy: UUID
    let lastModifiedAt: Date
    let lastModifiedBy: UUID

    init(
        id: UUID = UUID(),
        version: Int = 1,
        eventIdentifier: String,
        shiftType: ShiftType?,
        date: Date,
        createdBy: UUID
    ) {
        self.id = id
        self.version = version
        self.eventIdentifier = eventIdentifier
        self.shiftType = shiftType
        self.date = date
        let now = Date()
        self.createdAt = now
        self.createdBy = createdBy
        self.lastModifiedAt = now
        self.lastModifiedBy = createdBy
    }

    func withNewShiftType(
        _ newShiftType: ShiftType,
        modifiedBy userId: UUID
    ) -> ScheduledShift {
        ScheduledShift(
            id: self.id,
            version: self.version + 1,
            eventIdentifier: self.eventIdentifier,
            shiftType: newShiftType,
            date: self.date,
            createdAt: self.createdAt,
            createdBy: self.createdBy,
            lastModifiedAt: Date(),
            lastModifiedBy: userId
        )
    }
}
```

**ChangeLogEntry (SwiftData Model)**
```swift
@Model
final class ChangeLogEntry: Identifiable, Sendable {
    var id: UUID
    var timestamp: Date
    var userId: UUID
    var changeType: ChangeType
    var shiftDate: Date
    var oldShiftTypeId: UUID?
    var newShiftTypeId: UUID?
    var reason: String?
    var oldShiftSnapshot: ShiftSnapshot?
    var newShiftSnapshot: ShiftSnapshot?

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        userId: UUID,
        changeType: ChangeType,
        shiftDate: Date,
        oldShiftTypeId: UUID? = nil,
        newShiftTypeId: UUID? = nil,
        reason: String? = nil,
        oldShiftSnapshot: ShiftSnapshot? = nil,
        newShiftSnapshot: ShiftSnapshot? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.userId = userId
        self.changeType = changeType
        self.shiftDate = shiftDate
        self.oldShiftTypeId = oldShiftTypeId
        self.newShiftTypeId = newShiftTypeId
        self.reason = reason
        self.oldShiftSnapshot = oldShiftSnapshot
        self.newShiftSnapshot = newShiftSnapshot
    }
}

enum ChangeType: String, Codable {
    case switch
    case delete
    case create
    case undo
    case redo
}

struct ShiftSnapshot: Codable, Sendable {
    let shiftTypeId: UUID
    let symbol: String
    let title: String
    let description: String
    let timeRange: String
    let location: String?

    init(from shiftType: ShiftType) {
        self.shiftTypeId = shiftType.id
        self.symbol = shiftType.symbol
        self.title = shiftType.title
        self.description = shiftType.shiftDescription
        self.timeRange = shiftType.timeRangeString
        self.location = shiftType.location?.name
    }
}
```

**UserProfile (UserDefaults)**
```swift
struct UserProfile: Codable, Sendable {
    let userId: UUID
    var displayName: String?

    static func load(from storage: UserDefaultsProtocol) -> UserProfile {
        if let data = storage.data(forKey: "userProfile"),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            return profile
        }
        // Create new user on first launch
        let newProfile = UserProfile(userId: UUID(), displayName: nil)
        newProfile.save(to: storage)
        return newProfile
    }

    func save(to storage: UserDefaultsProtocol) {
        if let data = try? JSONEncoder().encode(self) {
            storage.set(data, forKey: "userProfile")
        }
    }
}
```

#### 5.2.2 Protocol Abstractions for External Dependencies

**ModelContext Protocol (CRITICAL)**
```swift
/// Protocol abstraction for SwiftData ModelContext
/// Enables unit testing with mock implementations
protocol ModelContextProtocol: Sendable {
    func insert<T>(_ model: T)
    func delete<T>(_ model: T)
    func fetch<T>(_ descriptor: FetchDescriptor<T>) throws -> [T]
    func save() throws
}

/// Production conformance - ModelContext already implements these methods
extension ModelContext: ModelContextProtocol {
    // ModelContext naturally conforms to the protocol
}

/// Mock implementation for unit testing
final class MockModelContext: ModelContextProtocol {
    var insertedModels: [Any] = []
    var deletedModels: [Any] = []
    var mockFetchResults: [Any] = []
    var saveCallCount = 0
    var shouldThrowOnSave = false

    func insert<T>(_ model: T) {
        insertedModels.append(model)
    }

    func delete<T>(_ model: T) {
        deletedModels.append(model)
    }

    func fetch<T>(_ descriptor: FetchDescriptor<T>) throws -> [T] {
        return mockFetchResults.compactMap { $0 as? T }
    }

    func save() throws {
        saveCallCount += 1
        if shouldThrowOnSave {
            throw MockError.saveFailed
        }
    }
}

enum MockError: Error {
    case saveFailed
}
```

**UserDefaults Protocol**
```swift
/// Protocol abstraction for UserDefaults
protocol UserDefaultsProtocol: Sendable {
    func data(forKey key: String) -> Data?
    func set(_ value: Any?, forKey key: String)
    func removeObject(forKey key: String)
}

/// Production conformance
extension UserDefaults: UserDefaultsProtocol, @unchecked Sendable {
    // UserDefaults already implements these methods
}

/// Mock implementation for testing
final class MockUserDefaults: UserDefaultsProtocol {
    private var storage: [String: Any] = [:]

    func data(forKey key: String) -> Data? {
        storage[key] as? Data
    }

    func set(_ value: Any?, forKey key: String) {
        storage[key] = value
    }

    func removeObject(forKey key: String) {
        storage.removeValue(forKey: key)
    }
}
```

**Calendar Service Protocol**
```swift
/// Protocol abstraction for calendar operations
protocol CalendarServiceProtocol: Sendable {
    func updateShift(
        eventIdentifier: String,
        newShiftType: ShiftType
    ) async throws

    func deleteShift(eventIdentifier: String) async throws

    func createShift(
        shiftType: ShiftType,
        date: Date
    ) async throws -> String
}

/// Mock implementation for testing
actor MockCalendarService: CalendarServiceProtocol {
    var updateCallCount = 0
    var deleteCallCount = 0
    var createCallCount = 0
    var shouldFailUpdate = false
    var capturedUpdates: [(String, ShiftType)] = []

    func updateShift(
        eventIdentifier: String,
        newShiftType: ShiftType
    ) async throws {
        updateCallCount += 1
        capturedUpdates.append((eventIdentifier, newShiftType))
        if shouldFailUpdate {
            throw CalendarError.updateFailed
        }
    }

    func deleteShift(eventIdentifier: String) async throws {
        deleteCallCount += 1
    }

    func createShift(
        shiftType: ShiftType,
        date: Date
    ) async throws -> String {
        createCallCount += 1
        return "mock-event-\(createCallCount)"
    }
}

enum CalendarError: Error {
    case updateFailed
}
```

**Date Provider Protocol**
```swift
/// Protocol abstraction for current date/time
/// Enables deterministic testing
protocol DateProviderProtocol: Sendable {
    func now() -> Date
}

/// Production implementation
struct SystemDateProvider: DateProviderProtocol {
    func now() -> Date {
        Date()
    }
}

/// Mock implementation with controllable time
struct MockDateProvider: DateProviderProtocol {
    var fixedDate: Date

    func now() -> Date {
        fixedDate
    }
}
```

#### 5.2.3 Repository Pattern

**ChangeLogRepository Protocol**
```swift
protocol ChangeLogRepositoryProtocol: Sendable {
    func save(_ entry: ChangeLogEntry) async throws
    func fetchAll() async throws -> [ChangeLogEntry]
    func fetchEntries(
        from startDate: Date,
        to endDate: Date,
        filter: ChangeLogFilter?
    ) async throws -> [ChangeLogEntry]
    func deleteEntriesOlderThan(_ date: Date) async throws
    func deleteAll() async throws
}

struct ChangeLogFilter: Sendable {
    let changeTypes: [ChangeType]?
    let userIds: [UUID]?
    let reasonContains: String?
}
```

**SwiftDataChangeLogRepository (Production Implementation)**
```swift
actor SwiftDataChangeLogRepository: ChangeLogRepositoryProtocol {
    private let modelContext: ModelContextProtocol  // Protocol, not concrete type!

    init(modelContext: ModelContextProtocol) {
        self.modelContext = modelContext
    }

    func save(_ entry: ChangeLogEntry) async throws {
        modelContext.insert(entry)
        try modelContext.save()
    }

    func fetchAll() async throws -> [ChangeLogEntry] {
        let descriptor = FetchDescriptor<ChangeLogEntry>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchEntries(
        from startDate: Date,
        to endDate: Date,
        filter: ChangeLogFilter?
    ) async throws -> [ChangeLogEntry] {
        var predicate = #Predicate<ChangeLogEntry> { entry in
            entry.timestamp >= startDate && entry.timestamp <= endDate
        }

        if let filter = filter {
            // Apply additional filters
            // Implementation details...
        }

        let descriptor = FetchDescriptor<ChangeLogEntry>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func deleteEntriesOlderThan(_ date: Date) async throws {
        let descriptor = FetchDescriptor<ChangeLogEntry>(
            predicate: #Predicate { $0.timestamp < date }
        )
        let entries = try modelContext.fetch(descriptor)
        for entry in entries {
            modelContext.delete(entry)
        }
        try modelContext.save()
    }

    func deleteAll() async throws {
        let entries = try fetchAll()
        for entry in entries {
            modelContext.delete(entry)
        }
        try modelContext.save()
    }
}
```

**InMemoryChangeLogRepository (Test Implementation)**
```swift
actor InMemoryChangeLogRepository: ChangeLogRepositoryProtocol {
    private var entries: [ChangeLogEntry] = []
    var saveCallCount = 0
    var shouldFailSave = false

    func save(_ entry: ChangeLogEntry) async throws {
        saveCallCount += 1
        if shouldFailSave {
            throw RepositoryError.saveFailed
        }
        entries.append(entry)
    }

    func fetchAll() async throws -> [ChangeLogEntry] {
        entries.sorted { $0.timestamp > $1.timestamp }
    }

    func fetchEntries(
        from startDate: Date,
        to endDate: Date,
        filter: ChangeLogFilter?
    ) async throws -> [ChangeLogEntry] {
        var filtered = entries.filter { entry in
            entry.timestamp >= startDate && entry.timestamp <= endDate
        }

        if let filter = filter {
            if let changeTypes = filter.changeTypes {
                filtered = filtered.filter { changeTypes.contains($0.changeType) }
            }
            if let userIds = filter.userIds {
                filtered = filtered.filter { userIds.contains($0.userId) }
            }
            if let searchText = filter.reasonContains {
                filtered = filtered.filter {
                    $0.reason?.localizedCaseInsensitiveContains(searchText) ?? false
                }
            }
        }

        return filtered.sorted { $0.timestamp > $1.timestamp }
    }

    func deleteEntriesOlderThan(_ date: Date) async throws {
        entries.removeAll { $0.timestamp < date }
    }

    func deleteAll() async throws {
        entries.removeAll()
    }
}

enum RepositoryError: Error {
    case saveFailed
    case fetchFailed
}
```

#### 5.2.4 Shift Switch Service

**ShiftSwitchService Protocol**
```swift
protocol ShiftSwitchServiceProtocol: Sendable {
    func switchShift(
        _ shift: ScheduledShift,
        to newShiftType: ShiftType,
        reason: String?,
        userId: UUID
    ) async throws -> ScheduledShift

    func undoLastSwitch() async throws -> ScheduledShift
    func redoLastSwitch() async throws -> ScheduledShift
}
```

**ShiftSwitchService Implementation (with Protocol Injection)**
```swift
actor ShiftSwitchService: ShiftSwitchServiceProtocol {
    private let calendarService: CalendarServiceProtocol  // Protocol!
    private let changeLogRepository: ChangeLogRepositoryProtocol  // Protocol!
    private let scheduleDataManager: ScheduleDataManagerProtocol  // Protocol!
    private let dateProvider: DateProviderProtocol  // Protocol!

    private var undoStack: [ChangeLogEntry] = []
    private var redoStack: [ChangeLogEntry] = []
    private let maxStackSize = 10

    init(
        calendarService: CalendarServiceProtocol,
        changeLogRepository: ChangeLogRepositoryProtocol,
        scheduleDataManager: ScheduleDataManagerProtocol,
        dateProvider: DateProviderProtocol = SystemDateProvider()
    ) {
        self.calendarService = calendarService
        self.changeLogRepository = changeLogRepository
        self.scheduleDataManager = scheduleDataManager
        self.dateProvider = dateProvider
    }

    func switchShift(
        _ shift: ScheduledShift,
        to newShiftType: ShiftType,
        reason: String?,
        userId: UUID
    ) async throws -> ScheduledShift {
        // 1. Create new shift version
        let newShift = shift.withNewShiftType(newShiftType, modifiedBy: userId)

        // 2. Update calendar event
        try await calendarService.updateShift(
            eventIdentifier: shift.eventIdentifier,
            newShiftType: newShiftType
        )

        // 3. Create change log entry
        let changeLogEntry = ChangeLogEntry(
            timestamp: dateProvider.now(),
            userId: userId,
            changeType: .switch,
            shiftDate: shift.date,
            oldShiftTypeId: shift.shiftType?.id,
            newShiftTypeId: newShiftType.id,
            reason: reason,
            oldShiftSnapshot: shift.shiftType.map { ShiftSnapshot(from: $0) },
            newShiftSnapshot: ShiftSnapshot(from: newShiftType)
        )

        // 4. Save change log (must succeed for operation to complete)
        try await changeLogRepository.save(changeLogEntry)

        // 5. Update undo stack
        undoStack.append(changeLogEntry)
        if undoStack.count > maxStackSize {
            undoStack.removeFirst()
        }

        // 6. Clear redo stack
        redoStack.removeAll()

        // 7. Notify schedule data manager
        await scheduleDataManager.shiftWasModified(newShift)

        return newShift
    }

    func undoLastSwitch() async throws -> ScheduledShift {
        guard let lastChange = undoStack.popLast() else {
            throw ShiftSwitchError.nothingToUndo
        }

        // Validation: can only undo switches
        guard lastChange.changeType == .switch else {
            throw ShiftSwitchError.cannotUndoChangeType
        }

        // Implementation details...
        // Revert the change, log undo, add to redo stack
        fatalError("Implementation required")
    }

    func redoLastSwitch() async throws -> ScheduledShift {
        guard let lastUndo = redoStack.popLast() else {
            throw ShiftSwitchError.nothingToRedo
        }

        // Implementation details...
        // Re-apply the change, log redo, add to undo stack
        fatalError("Implementation required")
    }
}

enum ShiftSwitchError: LocalizedError {
    case nothingToUndo
    case nothingToRedo
    case cannotUndoChangeType
    case calendarUpdateFailed
    case changeLogFailed

    var errorDescription: String? {
        switch self {
        case .nothingToUndo: return "No changes to undo"
        case .nothingToRedo: return "No changes to redo"
        case .cannotUndoChangeType: return "This type of change cannot be undone"
        case .calendarUpdateFailed: return "Failed to update calendar"
        case .changeLogFailed: return "Failed to log change"
        }
    }
}
```

**Schedule Data Manager Protocol**
```swift
protocol ScheduleDataManagerProtocol: Sendable {
    func shiftWasModified(_ shift: ScheduledShift) async
    func refreshSchedule() async throws
}
```

### 5.3 SwiftData Integration

#### 5.3.1 ModelContainer Configuration

**Updated ShiftSchedulerApp.swift**
```swift
@main
struct ShiftSchedulerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Location.self,
            ShiftType.self,
            ChangeLogEntry.self  // New model
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
```

#### 5.3.2 Dependency Injection in App Setup

**Production Dependency Graph**
```swift
@main
struct ShiftSchedulerApp: App {
    var sharedModelContainer: ModelContainer = { /* ... */ }()

    // Create production dependencies
    private let calendarService: CalendarServiceProtocol
    private let changeLogRepository: ChangeLogRepositoryProtocol
    private let shiftSwitchService: ShiftSwitchServiceProtocol

    init() {
        // Calendar service (production)
        self.calendarService = ProductionCalendarService()

        // Change log repository with ModelContext protocol
        let modelContext = sharedModelContainer.mainContext
        self.changeLogRepository = SwiftDataChangeLogRepository(
            modelContext: modelContext  // ModelContext conforms to protocol
        )

        // Shift switch service with injected dependencies
        self.shiftSwitchService = ShiftSwitchService(
            calendarService: calendarService,
            changeLogRepository: changeLogRepository,
            scheduleDataManager: productionScheduleManager,
            dateProvider: SystemDateProvider()
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.shiftSwitchService, shiftSwitchService)
        }
        .modelContainer(sharedModelContainer)
    }
}
```

#### 5.3.3 Migration Strategy

Since ScheduledShift is currently a struct (not persisted), there's no migration needed. The new properties are added to the struct definition.

**Change Log Entries Migration:**
- Initial release: Create new SwiftData model
- Future versions: Use SwiftData's automatic migration when possible
- Complex migrations: Implement custom ModelMigrationPlan

### 5.4 Data Flow Architecture

```
User Action (Switch Shift)
    ↓
ShiftChangeSheet (SwiftUI View)
    ↓
ShiftSwitchService (Actor) [Protocol-based dependencies injected]
    ├→ CalendarServiceProtocol: Update event
    ├→ ChangeLogRepositoryProtocol: Log change
    └→ ScheduleDataManagerProtocol: Refresh cache
    ↓
UI Updates
    ├→ Success toast
    ├→ Schedule screen refresh
    └→ Change Log screen refresh (if visible)
```

### 5.5 Concurrency Model

**Actor Isolation:**
- `ShiftSwitchService`: Actor (serializes all switch operations)
- `ChangeLog`: Actor (serializes change log operations)
- `SwiftDataChangeLogRepository`: Actor (protects ModelContext)
- `ScheduleDataManager`: @Observable class (already exists, MainActor isolated for UI updates)

**Sendable Conformance:**
- `ScheduledShift`: Sendable (immutable struct)
- `ChangeLogEntry`: Sendable (@Model classes are Sendable by default in Swift 6)
- `ShiftSnapshot`: Sendable (immutable struct)
- `UserProfile`: Sendable (immutable struct)
- All protocols: Sendable

---

## 6. Implementation Plan

### Phase 1: Protocol Abstractions & Domain Model (Week 1)

**Stories:**
1. **Create protocol abstractions for all external dependencies**
   - Define `ModelContextProtocol` with mock implementation
   - Define `UserDefaultsProtocol` with mock implementation
   - Define `CalendarServiceProtocol` with mock implementation
   - Define `DateProviderProtocol` with mock implementation
   - Create extension for production conformance
   - Write protocol conformance tests

2. Create immutable ScheduledShift with versioning
3. Create ChangeLogEntry SwiftData model
4. Create ShiftSnapshot value object
5. Update UserProfile to use `UserDefaultsProtocol`
6. Update ModelContainer with ChangeLogEntry
7. Create ChangeLogRepository protocol and implementations
8. Write comprehensive unit tests for domain models

**Test Specifications:**
```swift
@Test("ModelContext protocol enables mock testing")
func testModelContextProtocol() async throws {
    let mock = MockModelContext()
    let repo = SwiftDataChangeLogRepository(modelContext: mock)

    let entry = ChangeLogEntry(/* ... */)
    try await repo.save(entry)

    #expect(mock.insertedModels.count == 1)
    #expect(mock.saveCallCount == 1)
}

@Test("ScheduledShift creates new version with incremented version number")
func testScheduledShiftVersioning() async throws {
    let shift = ScheduledShift(/* ... */)
    let newShift = shift.withNewShiftType(newType, modifiedBy: userId)
    #expect(newShift.version == shift.version + 1)
    #expect(newShift.id == shift.id)
}

@Test("ChangeLogEntry captures all required metadata")
func testChangeLogEntryCreation() async throws {
    let entry = ChangeLogEntry(/* ... */)
    #expect(entry.timestamp != nil)
    #expect(entry.userId == expectedUserId)
    #expect(entry.oldShiftSnapshot != nil)
}

@Test("UserProfile persists using UserDefaultsProtocol")
func testUserProfilePersistence() async throws {
    let mockDefaults = MockUserDefaults()
    let profile = UserProfile(userId: UUID(), displayName: "Test")
    profile.save(to: mockDefaults)

    let loaded = UserProfile.load(from: mockDefaults)
    #expect(loaded.userId == profile.userId)
}

@Test("InMemoryChangeLogRepository works without external dependencies")
func testInMemoryRepository() async throws {
    let repo = InMemoryChangeLogRepository()
    let entry = ChangeLogEntry(/* ... */)

    try await repo.save(entry)
    let fetched = try await repo.fetchAll()

    #expect(fetched.count == 1)
    #expect(fetched[0].id == entry.id)
}
```

### Phase 2: Shift Switch Service with Protocol Injection (Week 2)

**Stories:**
1. Create ShiftSwitchService protocol
2. Implement ShiftSwitchService with protocol-based dependencies
3. Integrate with CalendarServiceProtocol
4. Integrate with ChangeLogRepositoryProtocol
5. Implement undo/redo stack logic
6. Implement transaction rollback on failure
7. Write comprehensive unit tests using mock implementations

**Test Specifications:**
```swift
@Test("Shift switch creates change log entry using mocks")
func testShiftSwitchLogging() async throws {
    let mockCalendar = MockCalendarService()
    let mockRepo = InMemoryChangeLogRepository()
    let mockManager = MockScheduleDataManager()
    let mockDate = MockDateProvider(fixedDate: Date())

    let service = ShiftSwitchService(
        calendarService: mockCalendar,
        changeLogRepository: mockRepo,
        scheduleDataManager: mockManager,
        dateProvider: mockDate
    )

    let newShift = try await service.switchShift(
        originalShift,
        to: newType,
        reason: "Test",
        userId: testUserId
    )

    let entries = try await mockRepo.fetchAll()
    #expect(entries.count == 1)
    #expect(entries[0].changeType == .switch)
    #expect(mockCalendar.updateCallCount == 1)
}

@Test("Shift switch rolls back on calendar failure")
func testShiftSwitchRollback() async throws {
    let mockCalendar = MockCalendarService()
    mockCalendar.shouldFailUpdate = true
    let mockRepo = InMemoryChangeLogRepository()

    let service = ShiftSwitchService(
        calendarService: mockCalendar,
        changeLogRepository: mockRepo,
        scheduleDataManager: MockScheduleDataManager(),
        dateProvider: MockDateProvider(fixedDate: Date())
    )

    await #expect(throws: CalendarError.self) {
        try await service.switchShift(
            originalShift,
            to: newType,
            reason: nil,
            userId: testUserId
        )
    }

    let entries = try await mockRepo.fetchAll()
    #expect(entries.isEmpty)  // No entry saved due to rollback
}

@Test("Undo restores previous shift state")
func testUndoShiftSwitch() async throws {
    let mockCalendar = MockCalendarService()
    let mockRepo = InMemoryChangeLogRepository()

    let service = ShiftSwitchService(
        calendarService: mockCalendar,
        changeLogRepository: mockRepo,
        scheduleDataManager: MockScheduleDataManager(),
        dateProvider: MockDateProvider(fixedDate: Date())
    )

    let newShift = try await service.switchShift(/* ... */)
    let restoredShift = try await service.undoLastSwitch()

    #expect(restoredShift.shiftType?.id == originalShift.shiftType?.id)

    let entries = try await mockRepo.fetchAll()
    #expect(entries.count == 2) // switch + undo
}

@Test("Mock calendar service captures update calls")
func testMockCalendarCapture() async throws {
    let mock = MockCalendarService()
    try await mock.updateShift(eventIdentifier: "test-123", newShiftType: mockShift)

    #expect(mock.capturedUpdates.count == 1)
    #expect(mock.capturedUpdates[0].0 == "test-123")
}
```

### Phase 3: UI Components (Week 3)

**Stories:**
1. Create ShiftChangeSheet SwiftUI view
2. Implement Liquid Glass UI effects
3. Add confirmation dialog
4. Add success/error toast messages
5. Integrate with ShiftSwitchServiceProtocol via environment
6. Add "Switch Shift" to Today screen Quick Actions
7. Update Schedule screen to trigger shift change sheet
8. Write UI tests

**Test Specifications:**
```swift
@Test("Shift change sheet displays current shift details")
func testShiftChangeSheetDisplay() async throws {
    let sheet = ShiftChangeSheet(shift: testShift)
    // Verify UI displays correct shift info
}

@Test("Shift change sheet validates new shift selection")
func testShiftChangeSheetValidation() async throws {
    // Test that user cannot select same shift type
    // Test that shift type picker shows all available types
}

@Test("Confirmation dialog appears before switch")
func testConfirmationDialog() async throws {
    // Test confirmation dialog is shown
    // Test cancel action
    // Test confirm action
}
```

### Phase 4: Change Log Screen (Week 4)

**Stories:**
1. Create ChangeLogView with list layout
2. Implement ChangeLogEntryCard component
3. Add pull-to-refresh
4. Add filter/search functionality
5. Add empty/loading/error states
6. Integrate with ChangeLogRepositoryProtocol
7. Add to main TabView
8. Write UI tests

**Test Specifications:**
```swift
@Test("Change Log displays entries grouped by date")
func testChangeLogGrouping() async throws {
    let mockRepo = InMemoryChangeLogRepository()
    // Add test entries
    let view = ChangeLogView(repository: mockRepo)
    // Verify entries are grouped correctly
}

@Test("Change Log filters work correctly")
func testChangeLogFiltering() async throws {
    let mockRepo = InMemoryChangeLogRepository()
    // Add varied test entries

    let filter = ChangeLogFilter(changeTypes: [.switch], userIds: nil, reasonContains: nil)
    let filtered = try await mockRepo.fetchEntries(
        from: Date.distantPast,
        to: Date(),
        filter: filter
    )

    #expect(filtered.allSatisfy { $0.changeType == .switch })
}

@Test("Change Log shows deleted shifts")
func testDeletedShiftsInChangeLog() async throws {
    let mockRepo = InMemoryChangeLogRepository()
    let deleteEntry = ChangeLogEntry(
        userId: UUID(),
        changeType: .delete,
        shiftDate: Date(),
        oldShiftSnapshot: ShiftSnapshot(from: testShift)
    )
    try await mockRepo.save(deleteEntry)

    let entries = try await mockRepo.fetchAll()
    #expect(entries.contains { $0.changeType == .delete })
}
```

### Phase 5: Settings Integration (Week 5)

**Stories:**
1. Add Change Log Settings section
2. Implement retention policy picker
3. Add purge background task
4. Add User Profile section
5. Implement display name editor
6. Implement User ID reset functionality
7. Add statistics display (total entries, last purge)
8. Write integration tests

**Test Specifications:**
```swift
@Test("Retention policy purges old entries")
func testRetentionPolicyPurge() async throws {
    let mockRepo = InMemoryChangeLogRepository()
    let oldDate = Calendar.current.date(byAdding: .year, value: -2, to: Date())!
    let oldEntry = ChangeLogEntry(
        timestamp: oldDate,
        userId: UUID(),
        changeType: .switch,
        shiftDate: oldDate
    )
    try await mockRepo.save(oldEntry)

    let cutoffDate = Calendar.current.date(byAdding: .year, value: -1, to: Date())!
    try await mockRepo.deleteEntriesOlderThan(cutoffDate)

    let remaining = try await mockRepo.fetchAll()
    #expect(remaining.isEmpty)
}

@Test("User display name updates using mock storage")
func testUserDisplayNameUpdate() async throws {
    let mockDefaults = MockUserDefaults()
    var profile = UserProfile.load(from: mockDefaults)
    profile.displayName = "New Name"
    profile.save(to: mockDefaults)

    let updated = UserProfile.load(from: mockDefaults)
    #expect(updated.displayName == "New Name")
}

@Test("User ID reset creates new identity")
func testUserIdReset() async throws {
    let mockDefaults = MockUserDefaults()
    let oldProfile = UserProfile.load(from: mockDefaults)

    // Reset by creating new profile
    let newProfile = UserProfile(userId: UUID(), displayName: nil)
    newProfile.save(to: mockDefaults)

    let loaded = UserProfile.load(from: mockDefaults)
    #expect(loaded.userId != oldProfile.userId)
}
```

### Phase 6: Integration & Polish (Week 6)

**Stories:**
1. End-to-end integration testing
2. Performance optimization
3. Error handling refinement
4. Accessibility audit
5. UI polish and animations
6. Documentation
7. Code review
8. QA testing

**Test Specifications:**
```swift
@Test("End-to-end shift switch flow with production services")
func testEndToEndShiftSwitch() async throws {
    // Use production dependencies but in test environment
    // Test complete flow from UI to persistence
    // Verify all systems updated correctly
}

@Test("Concurrent shift switches handled correctly")
func testConcurrentShiftSwitches() async throws {
    let mockRepo = InMemoryChangeLogRepository()
    let service = ShiftSwitchService(
        calendarService: MockCalendarService(),
        changeLogRepository: mockRepo,
        scheduleDataManager: MockScheduleDataManager(),
        dateProvider: SystemDateProvider()
    )

    // Test multiple simultaneous switches
    async let switch1 = service.switchShift(shift1, to: type1, reason: nil, userId: user1)
    async let switch2 = service.switchShift(shift2, to: type2, reason: nil, userId: user2)

    let _ = try await [switch1, switch2]

    let entries = try await mockRepo.fetchAll()
    #expect(entries.count == 2)  // Both changes logged
}

@Test("App state restoration after termination")
func testAppStateRestoration() async throws {
    // Test persistence survives across repository instances
    let repo1 = SwiftDataChangeLogRepository(modelContext: testContext)
    try await repo1.save(testEntry)

    // Simulate app restart by creating new repository with same context
    let repo2 = SwiftDataChangeLogRepository(modelContext: testContext)
    let entries = try await repo2.fetchAll()

    #expect(entries.count == 1)
}
```

---

## 7. Testing Strategy

### 7.1 Unit Testing with Protocol-Oriented Architecture

**Coverage Target:** 90%+ for domain logic

**Key Test Areas:**
- Domain model immutability and versioning
- Change log entry creation and validation
- Repository operations (CRUD) using in-memory implementations
- Shift switch service logic with full mock dependencies
- Undo/redo stack management
- User profile persistence with mock UserDefaults
- Retention policy logic
- **Protocol conformance and mock implementations**
- **Error handling with mock failures**
- **Concurrency safety with actor isolation**

**Testing Framework:** Swift Testing (using @Test macro)

**Mocking Strategy:**
- **EVERY external dependency has a protocol abstraction**
- **EVERY test uses mock implementations, never production dependencies**
- In-memory repository for test isolation
- Mock calendar service that captures calls and can simulate failures
- Mock date provider for deterministic time-based tests
- Mock UserDefaults for preference testing

**Example Test Structure:**
```swift
@Test("Complete shift switch workflow with all mocks")
func testShiftSwitchWorkflow() async throws {
    // Arrange: Create all mocks
    let mockCalendar = MockCalendarService()
    let mockRepo = InMemoryChangeLogRepository()
    let mockManager = MockScheduleDataManager()
    let mockDate = MockDateProvider(fixedDate: Date())

    // Inject mocks into service
    let service = ShiftSwitchService(
        calendarService: mockCalendar,
        changeLogRepository: mockRepo,
        scheduleDataManager: mockManager,
        dateProvider: mockDate
    )

    // Act: Perform operation
    let result = try await service.switchShift(
        testShift,
        to: newShiftType,
        reason: "Testing",
        userId: testUserId
    )

    // Assert: Verify all interactions
    #expect(result.version == testShift.version + 1)
    #expect(mockCalendar.updateCallCount == 1)

    let entries = try await mockRepo.fetchAll()
    #expect(entries.count == 1)
    #expect(entries[0].changeType == .switch)

    #expect(mockManager.modifiedShifts.contains(result.id))
}
```

### 7.2 Integration Testing

**Key Test Scenarios:**
- SwiftData persistence across app launches
- Calendar service integration (use real EventKit in test environment)
- Transaction rollback on failures
- Concurrent operation safety
- Change log query performance
- **Protocol conformance of production implementations**
- **Transition from mock to production dependencies**

**Integration Test Pattern:**
```swift
@Test("Production ModelContext conforms to protocol")
func testProductionModelContextConformance() async throws {
    let container = try ModelContainer(for: ChangeLogEntry.self)
    let context: ModelContextProtocol = container.mainContext  // Type annotation ensures conformance

    let repo = SwiftDataChangeLogRepository(modelContext: context)
    try await repo.save(testEntry)

    let fetched = try await repo.fetchAll()
    #expect(fetched.count == 1)
}
```

### 7.3 UI Testing

**Key Test Scenarios:**
- Shift change sheet workflow
- Confirmation dialogs
- Success/error states
- Change log filtering
- Settings UI interactions
- **Mock service injection into SwiftUI views**

### 7.4 Performance Testing

**Benchmarks:**
- Shift switch completes in <2 seconds
- Change log loads 1000 entries in <1 second
- UI remains responsive (60 FPS) during operations
- Memory usage stays below 100 MB for typical workloads
- **Mock overhead is negligible in tests**

---

## 8. Risks and Mitigations

### 8.1 Technical Risks

**Risk:** Protocol abstraction overhead and complexity
- **Mitigation:** Clear documentation and examples in codebase
- **Mitigation:** Protocol abstractions follow consistent patterns
- **Mitigation:** Benefits (testability, maintainability) far outweigh complexity

**Risk:** SwiftData integration complexity with existing architecture
- **Mitigation:** Repository pattern with protocol abstraction isolates SwiftData
- **Mitigation:** ModelContextProtocol enables testing without SwiftData
- **Mitigation:** Comprehensive integration tests
- **Mitigation:** Incremental rollout with feature flag

**Risk:** Data corruption under concurrent access
- **Mitigation:** Actor-based concurrency model
- **Mitigation:** Swift 6 strict concurrency checking
- **Mitigation:** Transactional operations with rollback
- **Mitigation:** Concurrent access tests with mock delays

**Risk:** Performance degradation with large change logs
- **Mitigation:** Pagination for UI
- **Mitigation:** Indexed queries in SwiftData
- **Mitigation:** Retention policy limits data growth
- **Mitigation:** Background purge tasks
- **Mitigation:** Performance tests with large mock datasets

### 8.2 UX Risks

**Risk:** Confirmation dialogs slow down user workflow
- **Mitigation:** User preference to disable confirmations
- **Mitigation:** "Don't ask again" option
- **Mitigation:** Haptic feedback for instant confirmation

**Risk:** Change log screen overwhelming with data
- **Mitigation:** Smart filtering and search
- **Mitigation:** Grouped by date for context
- **Mitigation:** Detail view on tap for full info

### 8.3 Data Risks

**Risk:** Change log data loss
- **Mitigation:** SwiftData persistence with iCloud sync option
- **Mitigation:** Export functionality for backup
- **Mitigation:** Regular automated tests of persistence

**Risk:** User confusion with multi-user IDs
- **Mitigation:** Clear explanation in Settings
- **Mitigation:** Display names instead of UUIDs
- **Mitigation:** Help documentation

### 8.4 Testing Risks

**Risk:** Mock implementations diverge from production behavior
- **Mitigation:** Protocol contracts enforce consistency
- **Mitigation:** Integration tests verify production conformance
- **Mitigation:** Regular code review of mock implementations

**Risk:** Over-reliance on mocks masks integration issues
- **Mitigation:** Comprehensive integration test suite
- **Mitigation:** End-to-end tests with production dependencies
- **Mitigation:** Manual QA testing in staging environment

---

## 9. Success Criteria

### 9.1 Functional Success

- [ ] Users can switch any shift to any other shift type
- [ ] All shift switches are logged with complete metadata
- [ ] Change log persists across app launches
- [ ] Undo/redo operations work correctly
- [ ] Deleted shifts appear in change log
- [ ] Retention policy purges old entries
- [ ] Multi-user support functions correctly

### 9.2 Performance Success

- [ ] Shift switch completes in <2 seconds
- [ ] Change log loads in <1 second
- [ ] UI maintains 60 FPS during operations
- [ ] No memory leaks detected
- [ ] Battery impact is negligible

### 9.3 Quality Success

- [ ] 90%+ unit test coverage
- [ ] **100% of external dependencies abstracted behind protocols**
- [ ] **All unit tests use mock implementations**
- [ ] **Zero direct dependencies on SwiftData, UserDefaults, or Calendar in business logic**
- [ ] Zero crashes in QA testing
- [ ] All accessibility requirements met
- [ ] Zero data integrity issues
- [ ] Positive user feedback (if beta tested)

### 9.4 Architectural Success

- [ ] **Every service accepts protocol dependencies**
- [ ] **Every protocol has mock implementation**
- [ ] **ModelContextProtocol successfully abstracts SwiftData**
- [ ] **Tests run without requiring SwiftData ModelContainer**
- [ ] **Protocol abstractions enable fast, isolated unit tests**
- [ ] Clean separation of concerns maintained
- [ ] DDD principles preserved throughout

---

## 10. Dependencies

### 10.1 External Dependencies

- **SwiftData:** Built-in iOS framework (iOS 17+) - **Abstracted behind ModelContextProtocol**
- **EventKit:** Existing dependency for calendar integration - **Abstracted behind CalendarServiceProtocol**
- **SwiftUI:** Existing dependency for UI
- **UserDefaults:** System persistence - **Abstracted behind UserDefaultsProtocol**

### 10.2 Internal Dependencies

- **CalendarService:** Existing service for calendar operations - **MUST implement CalendarServiceProtocol**
- **ScheduleDataManager:** Existing manager for schedule caching - **MUST implement ScheduleDataManagerProtocol**
- **Existing Domain Models:** Location, ShiftType, ScheduledShift

### 10.3 Team Dependencies

- **Product Manager:** Requirements clarification and approval
- **Designer:** UI/UX design review and approval
- **iOS Engineer:** Implementation and testing
- **QA Engineer:** Test plan execution and bug reporting
- **Tech Lead:** Architecture review and code review

---

## 11. Rollout Plan

### 11.1 Development Phases

**Week 1:** Protocol abstractions and domain model
**Week 2:** Core shift switch functionality with full protocol injection
**Week 3-4:** UI implementation and integration
**Week 5-6:** Settings, polish, and comprehensive testing

### 11.2 Testing Phases

**Week 7:** Internal QA testing
**Week 8:** Beta testing (optional)
**Week 9:** Bug fixes and refinements

### 11.3 Release Strategy

**Approach:** Feature flag controlled rollout

**Phase 1:** Internal dogfooding (1 week)
**Phase 2:** Beta release to select users (2 weeks)
**Phase 3:** Public release (all users)

**Rollback Plan:**
- Feature flag can disable shift switch UI
- Change log remains read-only if feature disabled
- Data persisted even if feature disabled

---

## 12. Future Enhancements

### 12.1 Short-term (Next Release)

- Bulk shift switching (select multiple dates)
- Change log export (CSV, PDF)
- Advanced filtering (custom date ranges, complex queries)
- Statistics dashboard (most changed shifts, etc.)

### 12.2 Medium-term (3-6 months)

- Team collaboration features (share change logs)
- Shift swap requests (between users)
- Approval workflows for shift changes
- Integration with external scheduling systems

### 12.3 Long-term (6+ months)

- AI-powered shift suggestions
- Predictive analytics on shift patterns
- Automated conflict detection
- Calendar sync across platforms (Google Calendar, Outlook)

---

## 13. Appendices

### Appendix A: Glossary

- **Shift Switch:** The act of changing a scheduled shift from one shift type to another
- **Change Log:** Historical record of all shift modifications
- **Retention Policy:** Rules governing how long change log entries are kept
- **Undo Stack:** In-memory list of recent changes that can be undone
- **Redo Stack:** In-memory list of undone changes that can be reapplied
- **User Profile:** User identity and preferences stored locally
- **Shift Snapshot:** Point-in-time capture of shift details for historical record
- **Protocol-Oriented Programming:** Design pattern where external dependencies are abstracted behind protocols
- **Dependency Injection:** Pattern where dependencies are passed into objects rather than created internally
- **Mock Implementation:** Test double that simulates behavior of real dependencies

### Appendix B: API Reference

See Section 5 (Technical Architecture) for detailed API specifications, including all protocol definitions and implementations.

### Appendix C: Protocol Abstraction Checklist

**For Every External Dependency:**
- [ ] Protocol defined with clear method signatures
- [ ] Protocol marked as `Sendable` for concurrency
- [ ] Production type conforms to protocol (via extension if needed)
- [ ] Mock implementation created for testing
- [ ] Mock implementation captures method calls
- [ ] Mock implementation can simulate failures
- [ ] All services accept protocol, not concrete type
- [ ] Unit tests use mock implementation
- [ ] Integration tests verify production conformance

**Example Template:**
```swift
// 1. Protocol Definition
protocol ExternalServiceProtocol: Sendable {
    func performOperation() async throws -> Result
}

// 2. Production Conformance
extension ExternalService: ExternalServiceProtocol {
    // Already implements performOperation
}

// 3. Mock Implementation
final class MockExternalService: ExternalServiceProtocol {
    var callCount = 0
    var shouldFail = false
    var mockResult: Result?

    func performOperation() async throws -> Result {
        callCount += 1
        if shouldFail { throw MockError.failed }
        return mockResult ?? Result()
    }
}

// 4. Service Using Protocol
actor DomainService {
    private let external: ExternalServiceProtocol

    init(external: ExternalServiceProtocol) {
        self.external = external
    }
}

// 5. Tests
@Test func testWithMock() async throws {
    let mock = MockExternalService()
    let service = DomainService(external: mock)
    // Test...
    #expect(mock.callCount == 1)
}
```

### Appendix D: UI Design Assets

UI design follows existing app patterns:
- Liquid Glass effects from existing components
- Color palette from existing ShiftCard components
- Typography and spacing from iOS design guidelines
- SF Symbols for all icons

### Appendix E: Related Documents

- Architecture Decision Record: SwiftData Integration
- Architecture Decision Record: Immutable Domain Model
- Architecture Decision Record: Protocol-Oriented Architecture
- Technical Specification: Actor-Based Concurrency
- User Guide: Shift Switching Feature

---

## Document Approval

**Product Manager:** _____________________ Date: _____
**Tech Lead:** _____________________ Date: _____
**Design Lead:** _____________________ Date: _____

---

**Version History:**
- v1.0 (2025-10-09): Initial PRD with complete requirements
- v1.1 (2025-10-09): Added comprehensive protocol-oriented architecture requirements throughout document
  - Added NFR 3.6: Testability Requirements
  - Added Section 5.1: Protocol-Oriented Architecture Principles
  - Added Section 5.2.2: Protocol Abstractions for External Dependencies (ModelContextProtocol, UserDefaultsProtocol, CalendarServiceProtocol, DateProviderProtocol)
  - Updated all repository implementations to use protocols
  - Updated ShiftSwitchService to use protocol injection
  - Enhanced test specifications to demonstrate mock usage
  - Added Section 9.3: Quality Success with protocol-oriented criteria
  - Added Section 9.4: Architectural Success criteria
  - Added Appendix C: Protocol Abstraction Checklist
  - Updated all code examples to show protocol-based dependency injection
