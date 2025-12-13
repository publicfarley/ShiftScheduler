# SwiftData to JSON Persistence - Quick Start Guide

**Project:** ShiftScheduler
**Recommended Approach:** JSON File Persistence with Value Types

---

## Why Migrate?

SwiftData uses **reference types** (classes) which conflict with TCA's **value types** (structs) requirement:

```swift
// ❌ Current (SwiftData)
@Model
final class ShiftType { ... }  // Reference type, manual Equatable, @unchecked Sendable

// ✅ Target (Value Type)
struct ShiftType: Codable, Equatable, Sendable { ... }  // Automatic everything!
```

**Key Problems with SwiftData + TCA:**
- Reference equality vs value equality
- TCA can't detect state changes properly
- `@unchecked Sendable` bypasses Swift 6 safety
- Difficult to test with mocks
- Performance issues with frequent equality checks

---

## Quick Migration Checklist

### Step 1: Create Value Type Models (1-2 hrs)

**File:** `ShiftScheduler/Domain/Models.swift`

```swift
import Foundation

struct Location: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    var name: String
    var address: String
}

struct ShiftType: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    var symbol: String
    var duration: ShiftDuration
    var title: String
    var description: String
    var locationID: UUID?  // Changed from Location? to ID reference
}
```

### Step 2: Create Repository (2 hrs)

**File:** `ShiftScheduler/Persistence/JSONFilePersistence.swift`

```swift
import Foundation

protocol PersistenceRepository: Sendable {
    func loadShiftTypes() async throws -> [ShiftType]
    func saveShiftTypes(_ types: [ShiftType]) async throws
    func loadLocations() async throws -> [Location]
    func saveLocations(_ locations: [Location]) async throws
}

actor JSONFilePersistenceRepository: PersistenceRepository {
    private let fileManager = FileManager.default
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    func loadShiftTypes() async throws -> [ShiftType] {
        try await load(from: documentsDirectory.appendingPathComponent("shift_types.json"))
    }

    func saveShiftTypes(_ types: [ShiftType]) async throws {
        try await save(types, to: documentsDirectory.appendingPathComponent("shift_types.json"))
    }

    func loadLocations() async throws -> [Location] {
        try await load(from: documentsDirectory.appendingPathComponent("locations.json"))
    }

    func saveLocations(_ locations: [Location]) async throws {
        try await save(locations, to: documentsDirectory.appendingPathComponent("locations.json"))
    }

    private func load<T: Codable>(from url: URL) async throws -> [T] {
        guard fileManager.fileExists(atPath: url.path) else { return [] }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([T].self, from: data)
    }

    private func save<T: Codable>(_ items: [T], to url: URL) async throws {
        let data = try JSONEncoder().encode(items)
        try data.write(to: url, options: [.atomic])
    }
}
```

### Step 3: Create TCA Dependency (1 hr)

**File:** `ShiftScheduler/Dependencies/PersistenceClient.swift`

```swift
import ComposableArchitecture

@DependencyClient
struct PersistenceClient: Sendable {
    var loadShiftTypes: @Sendable () async throws -> [ShiftType] = { [] }
    var saveShiftTypes: @Sendable ([ShiftType]) async throws -> Void
    var loadLocations: @Sendable () async throws -> [Location] = { [] }
    var saveLocations: @Sendable ([Location]) async throws -> Void
}

extension PersistenceClient: DependencyKey {
    static let liveValue: PersistenceClient = {
        let repository = JSONFilePersistenceRepository()
        return PersistenceClient(
            loadShiftTypes: { try await repository.loadShiftTypes() },
            saveShiftTypes: { try await repository.saveShiftTypes($0) },
            loadLocations: { try await repository.loadLocations() },
            saveLocations: { try await repository.saveLocations($0) }
        )
    }()
}

extension DependencyValues {
    var persistence: PersistenceClient {
        get { self[PersistenceClient.self] }
        set { self[PersistenceClient.self] = newValue }
    }
}
```

### Step 4: Update Features (3-4 hrs)

**Example:** `ShiftScheduler/Features/LocationsFeature.swift`

```swift
@Reducer
struct LocationsFeature {
    @ObservableState
    struct State: Equatable {
        var locations: [Location] = []  // ✅ Value types!
        var isLoading = false
    }

    enum Action {
        case onAppear
        case locationsLoaded(TaskResult<[Location]>)
        case addLocation(Location)
        case deleteLocation(Location.ID)
    }

    @Dependency(\.persistence) var persistence

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                return .run { send in
                    await send(.locationsLoaded(
                        TaskResult { try await persistence.loadLocations() }
                    ))
                }

            case let .locationsLoaded(.success(locations)):
                state.locations = locations
                state.isLoading = false
                return .none

            case let .addLocation(location):
                state.locations.append(location)
                return .run { [locations = state.locations] _ in
                    try await persistence.saveLocations(locations)
                }

            case let .deleteLocation(id):
                state.locations.removeAll { $0.id == id }
                return .run { [locations = state.locations] _ in
                    try await persistence.saveLocations(locations)
                }
            }
        }
    }
}
```

### Step 5: Remove SwiftData (1 hr)

1. Delete `@Model` annotations
2. Remove `import SwiftData` statements
3. Remove `ModelContainer` setup from app
4. Delete old SwiftData model files
5. Remove `SwiftDataClient.swift`
6. Update all imports and references

### Step 6: Test (2 hrs)

```swift
import Testing
@testable import ShiftScheduler

struct LocationsFeatureTests {
    @Test func testAddLocation() async {
        let store = TestStore(initialState: LocationsFeature.State()) {
            LocationsFeature()
        } withDependencies: {
            $0.persistence = .mock()  // Easy mock!
        }

        let location = Location(name: "Office", address: "123 Main")
        await store.send(.addLocation(location)) {
            $0.locations = [location]
        }
    }
}

// Mock helper
extension PersistenceClient {
    static func mock() -> Self {
        PersistenceClient(
            loadShiftTypes: { [] },
            saveShiftTypes: { _ in },
            loadLocations: { [] },
            saveLocations: { _ in }
        )
    }
}
```

---

## Benefits After Migration

| Aspect | Before (SwiftData) | After (JSON) |
|--------|-------------------|--------------|
| **Type** | Reference (class) | Value (struct) |
| **Equatable** | Manual, error-prone | Automatic, compiler-checked |
| **Sendable** | `@unchecked` | Automatic, safe |
| **TCA Compatibility** | Poor | Perfect |
| **Testing** | Complex | Simple |
| **Performance** | Reference comparison overhead | Fast value comparison |
| **Dependencies** | SwiftData framework | None (Foundation only) |

---

## Common Patterns

### Handling Relationships

**Before (SwiftData):**
```swift
@Model
final class ShiftType {
    var location: Location?  // Direct reference
}
```

**After (Value Types):**
```swift
struct ShiftType: Codable, Equatable {
    var locationID: UUID?  // ID reference

    // Resolve in presentation layer
    func location(from locations: [Location]) -> Location? {
        guard let locationID else { return nil }
        return locations.first { $0.id == locationID }
    }
}
```

### Loading Related Data

```swift
@Reducer
struct ShiftTypesFeature {
    struct State: Equatable {
        var shiftTypes: [ShiftType] = []
        var locations: [Location] = []  // Keep both arrays in state
    }

    enum Action {
        case onAppear
        case dataLoaded(shiftTypes: [ShiftType], locations: [Location])
    }

    @Dependency(\.persistence) var persistence

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    async let types = persistence.loadShiftTypes()
                    async let locations = persistence.loadLocations()
                    await send(.dataLoaded(
                        shiftTypes: try types,
                        locations: try locations
                    ))
                }
            }
        }
    }
}
```

---

## File Structure After Migration

```
ShiftScheduler/
├── Domain/
│   └── Models.swift              # Value type models (ShiftType, Location, etc.)
├── Persistence/
│   ├── PersistenceRepository.swift      # Protocol
│   └── JSONFilePersistence.swift        # Implementation
├── Dependencies/
│   └── PersistenceClient.swift          # TCA dependency
└── Features/
    ├── LocationsFeature.swift           # Updated to use value types
    ├── ShiftTypesFeature.swift
    └── ...

ShiftSchedulerTests/
├── Mocks/
│   └── MockPersistenceRepository.swift
└── Features/
    ├── LocationsFeatureTests.swift
    └── ...
```

---

## Troubleshooting

### Issue: "Cannot find type 'Location' in scope"

**Solution:** Make sure you've created the new value-type models and imported them where needed.

### Issue: Compile errors about Equatable

**Solution:** Ensure all properties in your structs are themselves Equatable. For custom types like `ShiftDuration`, add `Equatable` conformance.

### Issue: Tests failing after migration

**Solution:** Update test dependencies to use the new `PersistenceClient` mock instead of SwiftData mocks.

---

## Performance Notes

For ShiftScheduler's expected data size (< 1000 total records):
- ✅ JSON file loading: ~1-5ms
- ✅ JSON file saving: ~5-10ms
- ✅ Memory usage: Minimal (few KB)

If you later need to handle 10,000+ records, consider migrating to GRDB while keeping the same value-type models.

---

## Next Steps

1. ✅ Read full analysis: `TCA_DATA_PERSISTENCE_ANALYSIS.md`
2. ✅ Create new value-type models
3. ✅ Implement JSON persistence repository
4. ✅ Create TCA dependency client
5. ✅ Update one feature as proof-of-concept
6. ✅ Migrate remaining features
7. ✅ Remove SwiftData dependencies
8. ✅ Run full test suite

**Estimated Time:** 20-30 hours total

---

## Questions?

Refer to the comprehensive analysis document for:
- Detailed comparison of all persistence options
- GRDB migration path (if needed later)
- Advanced testing strategies
- Performance optimization tips
