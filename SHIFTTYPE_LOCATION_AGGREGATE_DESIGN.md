# ShiftType-Location Aggregate Design

## Current State Analysis

**Problem**: ShiftType-Location relationship is a loose foreign key reference
- `ShiftType.locationId: UUID?` (optional foreign key)
- Location must be looked up separately from repository
- No type safety - no compiler guarantee Location exists
- Views must perform manual lookups: `locationRepository.fetch(shiftType.locationId)`
- Data inconsistency risk - ShiftType can reference non-existent Location

**Business Rules to Enforce**:
1. ✅ Location is **mandatory** on every ShiftType
2. ✅ When creating ShiftType, Location is selected/created in same form
3. ✅ Locations **cannot be deleted** if referenced by ShiftTypes
4. ✅ CRUD operations on Location still required

## Proposed Solution: Aggregate Pattern

**ShiftType becomes an Aggregate Root** that contains Location as a Value Object.

### Why This Works

```
┌─────────────────────────────────┐
│     ShiftType (Aggregate Root)  │
├─────────────────────────────────┤
│ - id: UUID                      │
│ - symbol: String                │
│ - duration: ShiftDuration       │
│ - title: String                 │
│ - description: String           │
│                                 │
│ ┌───────────────────────────┐   │
│ │ Location (Part)           │   │
│ ├───────────────────────────┤   │
│ │ - id: UUID                │   │
│ │ - name: String            │   │
│ │ - address: String         │   │
│ └───────────────────────────┘   │
└─────────────────────────────────┘
```

**Key Properties**:
- Location embedded directly (non-optional)
- No separate Location ID reference
- Type-safe access: `shiftType.location.name`
- When ShiftType exists, Location is guaranteed to exist
- Codec structure: ShiftType → Location (nested JSON)

---

## Implementation Plan

### Phase 1: Update Domain Models

#### 1.1 Update `ShiftType.swift`

```swift
import Foundation

/// Aggregate Root for shift type templates
/// Contains embedded Location as a part of the aggregate
struct ShiftType: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var symbol: String
    var duration: ShiftDuration
    var title: String
    var shiftDescription: String
    var location: Location  // ✅ Non-optional, embedded

    init(
        id: UUID = UUID(),
        symbol: String,
        duration: ShiftDuration,
        title: String,
        description: String,
        location: Location  // ✅ Required parameter
    ) {
        self.id = id
        self.symbol = symbol
        self.duration = duration
        self.title = title
        self.shiftDescription = description
        self.location = location
    }

    // Convenience method for updating location
    mutating func updateLocation(_ location: Location) {
        self.location = location
    }

    var startTimeString: String {
        duration.startTimeString
    }

    var endTimeString: String {
        duration.endTimeString
    }

    var timeRangeString: String {
        duration.timeRangeString
    }

    var isAllDay: Bool {
        duration.isAllDay
    }
}
```

#### 1.2 Add Referential Integrity Method to PersistenceClient

```swift
extension PersistenceClient {
    /// Check if a location is used by any shift type
    /// Returns true if location is referenced by one or more shift types
    var canDeleteLocation: @Sendable (Location) async throws -> Bool = { location in
        let shiftTypes = try await fetchShiftTypes()
        return !shiftTypes.contains { $0.location.id == location.id }
    }

    /// Delete location only if not referenced by any ShiftType
    /// Throws error if location is in use
    var safeDeleteLocation: @Sendable (Location) async throws -> Void = { location in
        let shiftTypes = try await fetchShiftTypes()
        let isReferenced = shiftTypes.contains { $0.location.id == location.id }

        guard !isReferenced else {
            throw LocationDeletionError.locationInUse(
                count: shiftTypes.filter { $0.location.id == location.id }.count
            )
        }

        try await deleteLocation(location)
    }
}

enum LocationDeletionError: LocalizedError {
    case locationInUse(count: Int)

    var errorDescription: String? {
        switch self {
        case .locationInUse(let count):
            return "Cannot delete location. It is used by \(count) shift type(s)."
        }
    }
}
```

### Phase 2: Update Data Access

#### 2.1 Update `ShiftTypeRepository.swift`

The repository will now serialize/deserialize ShiftType with embedded Location:

```swift
// Codable will automatically handle nested Location serialization
// JSON structure:
// {
//   "id": "abc123",
//   "symbol": "M",
//   "title": "Morning Shift",
//   "location": {
//     "id": "loc456",
//     "name": "Main Office",
//     "address": "123 Main St"
//   }
// }
```

**No changes needed** - Codable protocol handles nested encoding/decoding automatically.

#### 2.2 Update `PersistenceClient` initialization

```swift
extension PersistenceClient: DependencyKey {
    static let liveValue: PersistenceClient = {
        let shiftTypeRepo = ShiftTypeRepository()
        let locationRepo = LocationRepository()
        let changeLogRepo = ChangeLogRepository()

        return PersistenceClient(
            fetchShiftTypes: {
                try await shiftTypeRepo.fetchAll()  // ✅ Returns ShiftType with embedded Location
            },
            fetchShiftType: { id in
                try await shiftTypeRepo.fetch(id: id)
            },
            saveShiftType: { shiftType in
                try await shiftTypeRepo.save(shiftType)  // ✅ Saves with Location embedded
            },
            updateShiftType: { shiftType in
                try await shiftTypeRepo.save(shiftType)
            },
            deleteShiftType: { shiftType in
                try await shiftTypeRepo.delete(id: shiftType.id)
            },
            fetchLocations: {
                try await locationRepo.fetchAll()
            },
            fetchLocation: { id in
                try await locationRepo.fetch(id: id)
            },
            saveLocation: { location in
                try await locationRepo.save(location)  // ✅ Still independent CRUD
            },
            updateLocation: { location in
                try await locationRepo.save(location)
            },
            deleteLocation: { location in
                // ✅ Will be guarded by canDeleteLocation check
                try await locationRepo.delete(id: location.id)
            },
            canDeleteLocation: { location in
                let shiftTypes = try await shiftTypeRepo.fetchAll()
                return !shiftTypes.contains { $0.location.id == location.id }
            },
            safeDeleteLocation: { location in
                let shiftTypes = try await shiftTypeRepo.fetchAll()
                let isReferenced = shiftTypes.contains { $0.location.id == location.id }
                guard !isReferenced else {
                    throw LocationDeletionError.locationInUse(
                        count: shiftTypes.filter { $0.location.id == location.id }.count
                    )
                }
                try await locationRepo.delete(id: location.id)
            },
            // ... other operations
        )
    }()

    // ... testValue and previewValue
}
```

### Phase 3: Update Features & Views

#### 3.1 Update `AddEditLocationFeature.swift` Actions

When saving a ShiftType, pass the full Location object:

```swift
// Before
case .saveShiftType:
    let shiftType = ShiftType(
        symbol: state.symbol,
        duration: duration,
        title: state.title,
        description: state.shiftDescription,
        locationId: state.selectedLocation.id  // ❌ Old way
    )

// After
case .saveShiftType:
    guard let location = state.selectedLocation else {
        state.errorMessage = "Location is required"
        return .none
    }

    let shiftType = ShiftType(
        symbol: state.symbol,
        duration: duration,
        title: state.title,
        description: state.shiftDescription,
        location: location  // ✅ New way - full object
    )
```

#### 3.2 Update View Code - Direct Access

```swift
// Before: Manual lookup
VStack {
    Text(shiftType.title)
    if let location = locationRepository.fetch(shiftType.locationId) {
        Text("📍 \(location.name)")
    } else {
        Text("📍 Unknown Location")
    }
}

// After: Direct access
VStack {
    Text(shiftType.title)
    Text("📍 \(shiftType.location.name)")  // ✅ Always available, no unwrapping
}
```

#### 3.3 Update `LocationsView` - Deletion with Referential Integrity

```swift
// When user tries to delete a location
if store.state.locations.contains(location) {
    do {
        // ✅ Safe deletion - checks if location is in use
        try await persistenceClient.safeDeleteLocation(location)
        store.send(.locationDeleted)
    } catch let error as LocationDeletionError {
        // ✅ Show user-friendly error
        store.send(.showError("Cannot delete. Location is used by shift types."))
    }
}
```

---

## Benefits Summary

### 1. Type Safety ✅
```swift
// Compiler guarantees Location exists
let location = shiftType.location  // Never nil
let locationName = shiftType.location.name  // Always accessible
```

### 2. Referential Integrity ✅
```swift
// Can't create orphaned ShiftTypes
let shiftType = ShiftType(..., location: location)  // Required

// Can't delete Locations that are in use
try await persistenceClient.safeDeleteLocation(location)  // Throws if in use
```

### 3. Simpler Code ✅
```swift
// Before: 3 lines + error handling
if let location = locationRepository.fetch(shiftType.locationId) {
    Text(location.name)  // Might not exist
}

// After: 1 line, guaranteed to work
Text(shiftType.location.name)
```

### 4. DDD Aggregate Pattern ✅
- Clear ownership hierarchy
- Bounded context respected
- Implicit cascading semantics (delete ShiftType → Location cleaned up)

### 5. Location CRUD Still Works ✅
```swift
// Create locations independently
try await persistenceClient.saveLocation(newLocation)

// Update locations
try await persistenceClient.updateLocation(updatedLocation)

// Delete only when not in use
try await persistenceClient.safeDeleteLocation(location)

// Read locations
let allLocations = try await persistenceClient.fetchLocations()
```

---

## Migration Path

### Order of Changes
1. ✅ Update `ShiftType.swift` - change `locationId: UUID?` → `location: Location`
2. ✅ Add referential integrity methods to `PersistenceClient`
3. ✅ Update all ShiftType initializations throughout codebase
4. ✅ Update features (AddEditLocationFeature, ShiftTypesFeature when created)
5. ✅ Update views to access `shiftType.location` directly
6. ✅ Add deletion guard in LocationsFeature

### Files to Modify
- `ShiftScheduler/Models/ShiftType.swift` ← Primary change
- `ShiftScheduler/Dependencies/PersistenceClient.swift` ← Add methods
- `ShiftScheduler/Features/AddEditLocationFeature.swift` ← Pass full Location
- `ShiftScheduler/Features/LocationsFeature.swift` ← Add deletion guard
- `ShiftScheduler/Features/ShiftTypesFeature.swift` (Task 7) ← New feature
- All View files that reference ShiftType ← Direct location access
- `ShiftScheduler/Models/Location.swift` ← No changes needed

---

## Data Persistence Example

### JSON Storage Format (Nested)

```json
[
  {
    "id": "shift-001",
    "symbol": "M",
    "title": "Morning Shift",
    "shiftDescription": "9 AM - 5 PM",
    "duration": {
      "case": "scheduled",
      "from": { "hour": 9, "minute": 0 },
      "to": { "hour": 17, "minute": 0 }
    },
    "location": {
      "id": "loc-001",
      "name": "Main Office",
      "address": "123 Main Street"
    }
  }
]
```

**Advantages**:
- Location data is bundled with ShiftType
- No broken references possible
- Serialization/deserialization automatic via Codable
- Location data is immutable once ShiftType is created (unless updated)

---

## Testing Strategy

### Unit Tests for Referential Integrity

```swift
func testCannotDeleteLocationInUse() async throws {
    let location = Location(name: "Main Office", address: "123 Main")
    let shiftType = ShiftType(
        symbol: "M",
        duration: .allDay,
        title: "Morning",
        description: "Morning shift",
        location: location
    )

    // Save both
    try await persistenceClient.saveLocation(location)
    try await persistenceClient.saveShiftType(shiftType)

    // Attempt deletion should fail
    XCTAssertThrowsError(
        try await persistenceClient.safeDeleteLocation(location),
        "Should not allow deletion of location in use"
    )
}

func testCanDeleteUnusedLocation() async throws {
    let location = Location(name: "Unused Office", address: "456 Oak")
    try await persistenceClient.saveLocation(location)

    // Should succeed - no ShiftTypes use this location
    try await persistenceClient.safeDeleteLocation(location)
}

func testDirectLocationAccess() throws {
    let location = Location(name: "Main", address: "123 Main")
    let shiftType = ShiftType(
        symbol: "M",
        duration: .allDay,
        title: "Morning",
        description: "Morning shift",
        location: location
    )

    // Direct access - no unwrapping needed
    XCTAssertEqual(shiftType.location.name, "Main")
    XCTAssertEqual(shiftType.location.address, "123 Main")
}
```

---

## Summary

**This design**:
- ✅ Embeds Location directly in ShiftType (aggregate pattern)
- ✅ Makes Location mandatory (non-optional)
- ✅ Enables type-safe direct access
- ✅ Prevents orphaned ShiftTypes
- ✅ Prevents deletion of Locations in use
- ✅ Maintains full CRUD on Locations (with guard)
- ✅ Simplifies view code
- ✅ Follows Domain-Driven Design principles
- ✅ Keeps data consistent

**When ready to implement**, follow the "Migration Path" section in order.
