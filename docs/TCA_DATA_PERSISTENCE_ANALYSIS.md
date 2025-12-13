# TCA Data Persistence Solutions - Comprehensive Analysis

**Date:** 2025-10-21
**Project:** ShiftScheduler
**Current Status:** TCA migration in progress with SwiftData models causing compatibility issues

---

## Executive Summary

This document analyzes data persistence solutions compatible with The Composable Architecture (TCA) for the ShiftScheduler iOS app. The current implementation uses SwiftData models (`@Model` classes) which have fundamental incompatibilities with TCA's architecture requirements, particularly around Equatable conformance and value semantics.

**Key Recommendation:** Migrate to a value-type (struct) based domain model with a file-based JSON persistence layer or GRDB for more complex querying needs.

---

## 1. Current State Analysis

### Existing Architecture

The project currently uses:
- **SwiftData** models with `@Model` macro (`ShiftType`, `Location`)
- **TCA 1.23.0** for state management
- **Dependency injection** pattern with TCA's `@Dependency` system
- **Repository abstraction** layer (`SwiftDataClient`)

### Current Models

```swift
@Model
final class ShiftType: @unchecked Sendable {
    var id: UUID
    var symbol: String
    var duration: ShiftDuration
    var title: String
    var shiftDescription: String
    var location: Location?
    // ... with manual Equatable conformance
}

@Model
final class Location: @unchecked Sendable, Identifiable {
    var id: UUID
    var name: String
    var address: String
    // ... with manual Equatable conformance
}
```

### Identified Issues

1. **Reference Semantics vs Value Semantics**: SwiftData models are classes (reference types), while TCA strongly prefers structs (value types) in State
2. **Equatable Conformance Challenges**: Manual Equatable implementation on classes is error-prone and doesn't provide compile-time guarantees
3. **@unchecked Sendable**: Required to bypass Swift 6 concurrency checking - a code smell indicating architectural mismatch
4. **Testing Complexity**: Reference types are harder to test and mock in TCA's reducer testing framework
5. **Performance**: TCA performs frequent equality checks on State; class comparison is more expensive than struct comparison

---

## 2. Why SwiftData is Incompatible with TCA

### The Equatable Problem

**TCA Requirement:** All State types must conform to Equatable. TCA uses state equality checks to:
- Determine when views need to re-render
- Optimize reducer execution
- Enable time-travel debugging
- Support proper testing with state assertions

**SwiftData Issue:**
- SwiftData models are classes (reference types)
- Classes use reference equality by default (same memory address)
- Manual Equatable implementation must compare all properties
- SwiftData `@Model` macro generates properties that include internal state (persistence tracking, faults, relationships)
- This internal state makes true value equality nearly impossible to implement correctly

### Example of the Problem

```swift
@Model
final class ShiftType: @unchecked Sendable {
    var id: UUID
    var symbol: String
    // ... other properties
}

extension ShiftType: Equatable {
    static func == (lhs: ShiftType, rhs: ShiftType) -> Bool {
        // Problem 1: This compares ALL properties, but SwiftData adds hidden properties
        lhs.id == rhs.id &&
        lhs.symbol == rhs.symbol
        // Problem 2: What about SwiftData's internal persistence state?
        // Problem 3: Two instances with same data aren't "equal" by reference
    }
}

// In TCA State:
struct MyState: Equatable {
    var shiftType: ShiftType  // ❌ Breaks value semantics
    // State changes even when data doesn't change (different object instance)
}
```

### The Reference Type Problem

```swift
// With SwiftData (class):
let shiftType1 = ShiftType(...)
let shiftType2 = ShiftType(...)  // Different instance, same data
shiftType1 == shiftType2  // false (different references) even with manual Equatable

// TCA State thinks it changed when it didn't:
oldState.shiftType !== newState.shiftType  // Always true with classes
```

### Additional SwiftData Incompatibilities

1. **ModelContext Thread Binding**: SwiftData's ModelContext is bound to a specific thread, conflicting with TCA's functional approach
2. **Observable Macro Conflicts**: SwiftData's `@Model` and TCA's `@Observable` can conflict
3. **Lazy Loading**: SwiftData's fault/lazy loading breaks TCA's predictable state model
4. **Relationship Complexity**: SwiftData relationships add mutable reference graphs, antithetical to TCA's immutable state

---

## 3. Alternative Persistence Solutions

### Option 1: File-Based JSON Persistence with Codable (RECOMMENDED FOR THIS PROJECT)

**Overview:** Store domain models as value types (structs) and persist to JSON files in the Documents directory.

#### Architecture

```swift
// 1. Domain Models (Pure Value Types)
struct ShiftType: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    var symbol: String
    var duration: ShiftDuration
    var title: String
    var description: String
    var locationID: UUID?

    init(id: UUID = UUID(), symbol: String, duration: ShiftDuration,
         title: String, description: String, locationID: UUID?) {
        self.id = id
        self.symbol = symbol
        self.duration = duration
        self.title = title
        self.description = description
        self.locationID = locationID
    }
}

struct Location: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    var name: String
    var address: String
}

// 2. Repository Protocol
protocol PersistenceRepository: Sendable {
    func loadShiftTypes() async throws -> [ShiftType]
    func saveShiftTypes(_ types: [ShiftType]) async throws
    func loadLocations() async throws -> [Location]
    func saveLocations(_ locations: [Location]) async throws
}

// 3. JSON File Repository Implementation
actor JSONFilePersistenceRepository: PersistenceRepository {
    private let fileManager = FileManager.default

    private var shiftTypesURL: URL {
        documentsDirectory.appendingPathComponent("shift_types.json")
    }

    private var locationsURL: URL {
        documentsDirectory.appendingPathComponent("locations.json")
    }

    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    func loadShiftTypes() async throws -> [ShiftType] {
        try await load(from: shiftTypesURL)
    }

    func saveShiftTypes(_ types: [ShiftType]) async throws {
        try await save(types, to: shiftTypesURL)
    }

    func loadLocations() async throws -> [Location] {
        try await load(from: locationsURL)
    }

    func saveLocations(_ locations: [Location]) async throws {
        try await save(locations, to: locationsURL)
    }

    private func load<T: Codable>(from url: URL) async throws -> [T] {
        guard fileManager.fileExists(atPath: url.path) else {
            return []
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([T].self, from: data)
    }

    private func save<T: Codable>(_ items: [T], to url: URL) async throws {
        let data = try JSONEncoder().encode(items)
        try data.write(to: url, options: [.atomic])
    }
}

// 4. TCA Dependency Client
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

    static let testValue = PersistenceClient()
}

extension DependencyValues {
    var persistence: PersistenceClient {
        get { self[PersistenceClient.self] }
        set { self[PersistenceClient.self] = newValue }
    }
}

// 5. Usage in TCA Reducer
@Reducer
struct ShiftTypesFeature {
    struct State: Equatable {
        var shiftTypes: [ShiftType] = []  // ✅ Pure value types
        var isLoading = false
    }

    enum Action {
        case loadShiftTypes
        case shiftTypesLoaded([ShiftType])
        case saveShiftType(ShiftType)
    }

    @Dependency(\.persistence) var persistence

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .loadShiftTypes:
                state.isLoading = true
                return .run { send in
                    let types = try await persistence.loadShiftTypes()
                    await send(.shiftTypesLoaded(types))
                }

            case let .shiftTypesLoaded(types):
                state.shiftTypes = types
                state.isLoading = false
                return .none

            case let .saveShiftType(shiftType):
                var updatedTypes = state.shiftTypes
                if let index = updatedTypes.firstIndex(where: { $0.id == shiftType.id }) {
                    updatedTypes[index] = shiftType
                } else {
                    updatedTypes.append(shiftType)
                }
                state.shiftTypes = updatedTypes

                return .run { _ in
                    try await persistence.saveShiftTypes(updatedTypes)
                }
            }
        }
    }
}
```

#### Pros
- ✅ **Perfect TCA compatibility**: Structs with automatic Equatable conformance
- ✅ **Simple implementation**: No external dependencies beyond Foundation
- ✅ **Atomic writes**: File operations are atomic, preventing corruption
- ✅ **Easy backup/export**: JSON files are human-readable and portable
- ✅ **No migration issues**: Change schema by adding Codable properties with defaults
- ✅ **Thread-safe**: Actor-based repository ensures safe concurrent access
- ✅ **Testable**: Easy to create mock repositories returning test data
- ✅ **Swift 6 compatible**: Full Sendable compliance without @unchecked
- ✅ **Small app size**: No database framework overhead
- ✅ **Version control friendly**: Can commit sample data files

#### Cons
- ❌ **No complex queries**: Must load all data and filter in memory
- ❌ **Performance at scale**: Reading/writing entire files for each change
- ❌ **No relationships**: Must manually maintain ID references
- ❌ **Limited search**: No indexed search capabilities
- ❌ **Memory usage**: All data loaded into memory

#### Best For
- Apps with < 1000 total records
- Simple data models with few relationships
- Apps where data fits comfortably in memory
- **ShiftScheduler fits this profile perfectly** (dozens of shift types, locations, hundreds of shifts)

---

### Option 2: GRDB (SQLite Wrapper)

**Overview:** Type-safe SQLite database with value types and reactive observations.

#### Architecture

```swift
// 1. Database Models (Value Types)
struct ShiftType: Codable, Equatable, Identifiable, Sendable {
    var id: UUID
    var symbol: String
    var duration: ShiftDuration
    var title: String
    var description: String
    var locationID: UUID?
}

// 2. GRDB Database Setup
import GRDB

extension ShiftType: FetchableRecord, PersistableRecord {
    static let databaseTableName = "shiftTypes"
}

extension Location: FetchableRecord, PersistableRecord {
    static let databaseTableName = "locations"
}

// 3. Database Manager
actor DatabaseManager {
    private let dbQueue: DatabaseQueue

    init() throws {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dbURL = documentsURL.appendingPathComponent("shifts.db")

        dbQueue = try DatabaseQueue(path: dbURL.path)
        try migrator.migrate(dbQueue)
    }

    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1") { db in
            try db.create(table: "shiftTypes") { t in
                t.primaryKey("id", .text)
                t.column("symbol", .text).notNull()
                t.column("duration", .blob).notNull()
                t.column("title", .text).notNull()
                t.column("description", .text).notNull()
                t.column("locationID", .text)
            }

            try db.create(table: "locations") { t in
                t.primaryKey("id", .text)
                t.column("name", .text).notNull()
                t.column("address", .text).notNull()
            }
        }

        return migrator
    }

    func fetchShiftTypes() async throws -> [ShiftType] {
        try await dbQueue.read { db in
            try ShiftType.fetchAll(db)
        }
    }

    func saveShiftType(_ shiftType: ShiftType) async throws {
        try await dbQueue.write { db in
            try shiftType.save(db)
        }
    }

    func deleteShiftType(id: UUID) async throws {
        try await dbQueue.write { db in
            try ShiftType.deleteOne(db, key: id)
        }
    }

    // Reactive observation using Combine
    func observeShiftTypes() -> AnyPublisher<[ShiftType], Error> {
        ValueObservation
            .tracking { db in try ShiftType.fetchAll(db) }
            .publisher(in: dbQueue, scheduling: .immediate)
            .eraseToAnyPublisher()
    }
}

// 4. TCA Integration
@DependencyClient
struct DatabaseClient: Sendable {
    var fetchShiftTypes: @Sendable () async throws -> [ShiftType] = { [] }
    var saveShiftType: @Sendable (ShiftType) async throws -> Void
    var deleteShiftType: @Sendable (UUID) async throws -> Void
    var observeShiftTypes: @Sendable () -> AnyPublisher<[ShiftType], Error>
}

extension DatabaseClient: DependencyKey {
    static let liveValue: DatabaseClient = {
        let manager = try! DatabaseManager()
        return DatabaseClient(
            fetchShiftTypes: { try await manager.fetchShiftTypes() },
            saveShiftType: { try await manager.saveShiftType($0) },
            deleteShiftType: { try await manager.deleteShiftType(id: $0) },
            observeShiftTypes: { manager.observeShiftTypes() }
        )
    }()
}

// 5. Usage in Reducer with Reactive Updates
@Reducer
struct ShiftTypesFeature {
    struct State: Equatable {
        var shiftTypes: [ShiftType] = []
    }

    enum Action {
        case startObservingShiftTypes
        case shiftTypesUpdated([ShiftType])
        case saveShiftType(ShiftType)
    }

    @Dependency(\.database) var database

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .startObservingShiftTypes:
                return .publisher {
                    database.observeShiftTypes()
                        .map(Action.shiftTypesUpdated)
                }

            case let .shiftTypesUpdated(types):
                state.shiftTypes = types
                return .none

            case let .saveShiftType(type):
                return .run { _ in
                    try await database.saveShiftType(type)
                }
            }
        }
    }
}
```

#### Pros
- ✅ **SQL power**: Complex queries, joins, indexes, full-text search
- ✅ **Performance**: Optimized SQLite for large datasets
- ✅ **Transactions**: ACID compliance, rollback support
- ✅ **Migrations**: Structured schema migration system
- ✅ **Value types**: Full struct-based models, perfect for TCA
- ✅ **Reactive**: ValueObservation + Combine for automatic UI updates
- ✅ **Type-safe**: Compile-time query validation
- ✅ **Mature**: Battle-tested in production apps
- ✅ **Swift 6 ready**: Full concurrency support
- ✅ **TCA compatible**: Designed for functional architectures

#### Cons
- ❌ **Learning curve**: SQL knowledge required
- ❌ **Boilerplate**: More setup than JSON files
- ❌ **Dependencies**: External package (though well-maintained)
- ❌ **Migration complexity**: Schema changes require migration code
- ❌ **Debugging**: Harder to inspect than JSON files

#### Best For
- Apps with > 1000 records
- Complex queries and relationships
- Apps requiring search/filtering
- Need for performance optimization
- Future growth expectations

---

### Option 3: Core Data with Value Type Wrappers

**Overview:** Use Core Data for persistence but wrap entities in value types for TCA State.

#### Architecture

```swift
// 1. Core Data Entity (NSManagedObject)
@objc(ShiftTypeEntity)
class ShiftTypeEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var symbol: String
    @NSManaged var title: String
    // ... other properties
}

// 2. Value Type Wrapper
struct ShiftType: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    var symbol: String
    var title: String
    var description: String

    init(id: UUID = UUID(), symbol: String, title: String, description: String) {
        self.id = id
        self.symbol = symbol
        self.title = title
        self.description = description
    }

    // Convert from Core Data entity
    init(entity: ShiftTypeEntity) {
        self.id = entity.id
        self.symbol = entity.symbol
        self.title = entity.title
        self.description = entity.description ?? ""
    }

    // Convert to Core Data entity
    func toEntity(context: NSManagedObjectContext) -> ShiftTypeEntity {
        let entity = ShiftTypeEntity(context: context)
        entity.id = id
        entity.symbol = symbol
        entity.title = title
        entity.description = description
        return entity
    }

    // Update existing entity
    func update(entity: ShiftTypeEntity) {
        entity.symbol = symbol
        entity.title = title
        entity.description = description
    }
}

// 3. Repository Layer
actor CoreDataRepository {
    private let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "ShiftScheduler")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Core Data failed to load: \(error.localizedDescription)")
            }
        }
    }

    func fetchShiftTypes() async throws -> [ShiftType] {
        let context = container.viewContext
        return await context.perform {
            let request = ShiftTypeEntity.fetchRequest()
            let entities = try? context.fetch(request)
            return entities?.map(ShiftType.init) ?? []
        }
    }

    func saveShiftType(_ shiftType: ShiftType) async throws {
        let context = container.viewContext
        await context.perform {
            let request = ShiftTypeEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", shiftType.id as CVarArg)

            if let existing = try? context.fetch(request).first {
                shiftType.update(entity: existing)
            } else {
                _ = shiftType.toEntity(context: context)
            }

            try? context.save()
        }
    }
}

// 4. TCA Integration
@DependencyClient
struct PersistenceClient: Sendable {
    var loadShiftTypes: @Sendable () async throws -> [ShiftType] = { [] }
    var saveShiftType: @Sendable (ShiftType) async throws -> Void
}

extension PersistenceClient: DependencyKey {
    static let liveValue: PersistenceClient = {
        let repository = CoreDataRepository()
        return PersistenceClient(
            loadShiftTypes: { try await repository.fetchShiftTypes() },
            saveShiftType: { try await repository.saveShiftType($0) }
        )
    }()
}
```

#### Pros
- ✅ **Apple native**: First-party framework, well-documented
- ✅ **iCloud sync**: Built-in CloudKit integration
- ✅ **Powerful**: Relationships, predicates, fetch controllers
- ✅ **Xcode tools**: Visual data model editor, migration assistant
- ✅ **TCA compatible**: With value type wrapper pattern
- ✅ **Mature**: Decades of development and bug fixes

#### Cons
- ❌ **Complexity**: One of the most complex iOS frameworks
- ❌ **Boilerplate**: Extensive wrapper code required
- ❌ **Performance overhead**: Converting between entities and value types
- ❌ **Thread safety**: NSManagedObjectContext threading rules
- ❌ **Verbose**: More code than alternatives
- ❌ **Testing difficulty**: Requires Core Data stack in tests

#### Best For
- Apps already using Core Data
- Need iCloud sync
- Team familiar with Core Data
- Complex data models with many relationships

---

### Option 4: TCA's @Shared with .fileStorage

**Overview:** Use TCA's built-in shared state persistence with file storage.

#### Architecture

```swift
// 1. Domain Model
struct ShiftType: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    var symbol: String
    var title: String
    var description: String
}

// 2. Persistence Key
extension PersistenceKey where Self == PersistenceKeyDefault<FileStorageKey<IdentifiedArrayOf<ShiftType>>> {
    static var shiftTypes: Self {
        PersistenceKeyDefault(
            .fileStorage(.documentsDirectory.appending(component: "shift-types.json")),
            []
        )
    }
}

// 3. Usage in Feature
@Reducer
struct ShiftTypesFeature {
    struct State: Equatable {
        @Shared(.shiftTypes) var shiftTypes: IdentifiedArrayOf<ShiftType> = []
    }

    enum Action {
        case addShiftType(ShiftType)
        case deleteShiftType(id: ShiftType.ID)
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .addShiftType(shiftType):
                state.shiftTypes.append(shiftType)  // Automatically persisted!
                return .none

            case let .deleteShiftType(id):
                state.shiftTypes.remove(id: id)  // Automatically persisted!
                return .none
            }
        }
    }
}
```

#### Pros
- ✅ **Minimal boilerplate**: Built into TCA
- ✅ **Automatic persistence**: Changes saved automatically
- ✅ **Shared state**: Automatically synced across features
- ✅ **Type-safe**: Full compiler support
- ✅ **Perfect TCA integration**: Designed specifically for TCA

#### Cons
- ❌ **Limited control**: Less control over when/how data is saved
- ❌ **All-or-nothing**: Entire collection saved on any change
- ❌ **No transactions**: Can't group multiple changes
- ❌ **No queries**: Must load and filter all data in memory
- ❌ **Young feature**: Relatively new, may evolve

#### Best For
- Simple persistence needs
- Apps fully committed to TCA
- Prototyping and MVPs
- Small to medium datasets

---

### Option 5: In-Memory with UserDefaults Sync (Not Recommended)

**Overview:** Keep data in memory and sync critical data to UserDefaults.

#### Pros
- ✅ Extremely simple
- ✅ No file management

#### Cons
- ❌ UserDefaults size limits (~1MB practical limit)
- ❌ Not suitable for collections
- ❌ Poor performance for frequent updates
- ❌ Data loss risk

**Verdict:** Only suitable for small preference data, not domain models.

---

## 4. Comparison Matrix

| Feature | JSON Files | GRDB | Core Data | @Shared | SwiftData |
|---------|-----------|------|-----------|---------|-----------|
| **TCA Compatibility** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐ |
| **Simplicity** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Performance (small)** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Performance (large)** | ⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐ |
| **Query Capabilities** | ⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐ | ⭐⭐⭐⭐ |
| **Testing** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐ |
| **Migration** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| **Swift 6** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| **Dependencies** | None | GRDB | None | None | None |
| **Learning Curve** | Minimal | Medium | Steep | Minimal | Low |

**Key:**
- ⭐⭐⭐⭐⭐ Excellent
- ⭐⭐⭐⭐ Good
- ⭐⭐⭐ Adequate
- ⭐⭐ Poor
- ⭐ Very Poor

---

## 5. Migration Path Recommendations

### Recommended Approach: JSON File Persistence

**Rationale for ShiftScheduler:**
1. **Small dataset**: Dozens of shift types, locations; hundreds of shifts max
2. **Simple queries**: No complex filtering or search needed
3. **Perfect TCA fit**: Structs with automatic Equatable
4. **Zero dependencies**: Pure Foundation/Swift
5. **Easy migration**: Convert classes to structs
6. **Testability**: Simple mock repositories

### Migration Steps

#### Phase 1: Create Value Type Models (1-2 hours)

```swift
// File: ShiftScheduler/Domain/Models.swift

import Foundation

// 1. Location (replace SwiftData @Model)
struct Location: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    var name: String
    var address: String

    init(id: UUID = UUID(), name: String, address: String) {
        self.id = id
        self.name = name
        self.address = address
    }
}

// 2. ShiftType (replace SwiftData @Model)
struct ShiftType: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    var symbol: String
    var duration: ShiftDuration
    var title: String
    var description: String
    var locationID: UUID?  // ⬅️ Changed from Location? to UUID?

    init(
        id: UUID = UUID(),
        symbol: String,
        duration: ShiftDuration,
        title: String,
        description: String,
        locationID: UUID?
    ) {
        self.id = id
        self.symbol = symbol
        self.duration = duration
        self.title = title
        self.description = description
        self.locationID = locationID
    }

    // Computed property to get location from array
    func location(from locations: [Location]) -> Location? {
        guard let locationID else { return nil }
        return locations.first { $0.id == locationID }
    }
}

// 3. Ensure ShiftDuration is Codable
extension ShiftDuration: Codable {
    // Implement if not already done
}
```

#### Phase 2: Create Repository Layer (2-3 hours)

```swift
// File: ShiftScheduler/Persistence/PersistenceRepository.swift

import Foundation

protocol PersistenceRepository: Sendable {
    func loadShiftTypes() async throws -> [ShiftType]
    func saveShiftTypes(_ types: [ShiftType]) async throws
    func loadLocations() async throws -> [Location]
    func saveLocations(_ locations: [Location]) async throws
}

// File: ShiftScheduler/Persistence/JSONFilePersistence.swift

actor JSONFilePersistenceRepository: PersistenceRepository {
    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var shiftTypesURL: URL {
        documentsDirectory.appendingPathComponent("shift_types.json")
    }

    private var locationsURL: URL {
        documentsDirectory.appendingPathComponent("locations.json")
    }

    init() {
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func loadShiftTypes() async throws -> [ShiftType] {
        try await load(from: shiftTypesURL)
    }

    func saveShiftTypes(_ types: [ShiftType]) async throws {
        try await save(types, to: shiftTypesURL)
    }

    func loadLocations() async throws -> [Location] {
        try await load(from: locationsURL)
    }

    func saveLocations(_ locations: [Location]) async throws {
        try await save(locations, to: locationsURL)
    }

    private func load<T: Codable>(from url: URL) async throws -> [T] {
        guard fileManager.fileExists(atPath: url.path) else {
            return []
        }
        let data = try Data(contentsOf: url)
        return try decoder.decode([T].self, from: data)
    }

    private func save<T: Codable>(_ items: [T], to url: URL) async throws {
        let data = try encoder.encode(items)
        try data.write(to: url, options: [.atomic])
    }
}
```

#### Phase 3: Create TCA Dependency (1 hour)

```swift
// File: ShiftScheduler/Dependencies/PersistenceClient.swift

import ComposableArchitecture
import Foundation

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

    static let testValue = PersistenceClient()

    static let previewValue = PersistenceClient(
        loadShiftTypes: { PreviewData.shiftTypes },
        saveShiftTypes: { _ in },
        loadLocations: { PreviewData.locations },
        saveLocations: { _ in }
    )
}

extension DependencyValues {
    var persistence: PersistenceClient {
        get { self[PersistenceClient.self] }
        set { self[PersistenceClient.self] = newValue }
    }
}
```

#### Phase 4: Update Features (3-4 hours)

```swift
// File: ShiftScheduler/Features/LocationsFeature.swift

@Reducer
struct LocationsFeature {
    @ObservableState
    struct State: Equatable {
        var locations: [Location] = []
        var isLoading = false
        // ... other state
    }

    enum Action {
        case onAppear
        case locationsLoaded(TaskResult<[Location]>)
        case addLocation(Location)
        case updateLocation(Location)
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

            case let .locationsLoaded(.failure(error)):
                state.isLoading = false
                // Handle error
                return .none

            case let .addLocation(location):
                state.locations.append(location)
                return .run { [locations = state.locations] _ in
                    try await persistence.saveLocations(locations)
                }

            case let .updateLocation(location):
                if let index = state.locations.firstIndex(where: { $0.id == location.id }) {
                    state.locations[index] = location
                }
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

#### Phase 5: Data Migration Script (2-3 hours)

```swift
// File: ShiftScheduler/Migration/SwiftDataMigration.swift

import SwiftData
import Foundation

/// One-time migration from SwiftData to JSON files
actor SwiftDataMigration {
    func migrateToJSON(modelContext: ModelContext) async throws {
        // 1. Fetch all SwiftData entities
        let locationDescriptor = FetchDescriptor<Location>()
        let oldLocations = try modelContext.fetch(locationDescriptor)

        let shiftTypeDescriptor = FetchDescriptor<ShiftType>()
        let oldShiftTypes = try modelContext.fetch(shiftTypeDescriptor)

        // 2. Convert to value types
        let newLocations = oldLocations.map { old in
            Location(id: old.id, name: old.name, address: old.address)
        }

        let newShiftTypes = oldShiftTypes.map { old in
            ShiftType(
                id: old.id,
                symbol: old.symbol,
                duration: old.duration,
                title: old.title,
                description: old.shiftDescription,
                locationID: old.location?.id
            )
        }

        // 3. Save to JSON files
        let repository = JSONFilePersistenceRepository()
        try await repository.saveLocations(newLocations)
        try await repository.saveShiftTypes(newShiftTypes)

        print("✅ Migration complete: \(newLocations.count) locations, \(newShiftTypes.count) shift types")
    }
}

// Usage (one-time, in app):
// Task {
//     try await SwiftDataMigration().migrateToJSON(modelContext: modelContext)
// }
```

#### Phase 6: Remove SwiftData (1 hour)

1. Delete `@Model` macros from old files
2. Remove SwiftData import statements
3. Remove ModelContainer setup from app
4. Delete SwiftData files
5. Update tests to use new models
6. Run all tests to verify

#### Phase 7: Testing (2-3 hours)

```swift
// File: ShiftSchedulerTests/PersistenceTests.swift

import Testing
import Foundation
@testable import ShiftScheduler

struct PersistenceTests {
    @Test func testSaveAndLoadLocations() async throws {
        // Given
        let repo = JSONFilePersistenceRepository()
        let locations = [
            Location(name: "Office", address: "123 Main St"),
            Location(name: "Remote", address: "Home")
        ]

        // When
        try await repo.saveLocations(locations)
        let loaded = try await repo.loadLocations()

        // Then
        #expect(loaded.count == 2)
        #expect(loaded[0].name == "Office")
    }

    @Test func testShiftTypeWithLocationReference() async throws {
        let repo = JSONFilePersistenceRepository()

        // Create location
        let location = Location(name: "Office", address: "123 Main St")
        try await repo.saveLocations([location])

        // Create shift type referencing location
        let shiftType = ShiftType(
            symbol: "☀️",
            duration: ShiftDuration.standard,
            title: "Day Shift",
            description: "Morning shift",
            locationID: location.id
        )
        try await repo.saveShiftTypes([shiftType])

        // Verify relationship
        let loadedTypes = try await repo.loadShiftTypes()
        let loadedLocations = try await repo.loadLocations()

        let loadedType = loadedTypes[0]
        #expect(loadedType.locationID == location.id)

        let resolvedLocation = loadedType.location(from: loadedLocations)
        #expect(resolvedLocation?.name == "Office")
    }
}
```

### Estimated Total Migration Time

- **Phase 1-3 (Foundation)**: 4-6 hours
- **Phase 4 (Features)**: 3-4 hours per major feature (3-4 features)
- **Phase 5-6 (Migration & Cleanup)**: 3-4 hours
- **Phase 7 (Testing)**: 2-3 hours

**Total: 20-30 hours for complete migration**

---

## 6. Alternative: GRDB Migration Path

If you anticipate significant growth or need advanced queries, GRDB is recommended.

### When to Choose GRDB

- Expecting > 1000 total records
- Need full-text search
- Complex filtering/sorting requirements
- Performance is critical
- Want reactive UI updates

### Quick Start with GRDB

```bash
# Add to Package.swift dependencies
.package(url: "https://github.com/groue/GRDB.swift.git", from: "7.6.1")
```

Follow similar migration phases but use GRDB's FetchableRecord/PersistableRecord protocols instead of Codable.

---

## 7. Recommendations Summary

### For ShiftScheduler: Use JSON File Persistence

**Reasons:**
1. ✅ Small dataset (perfect fit)
2. ✅ Simple data model
3. ✅ Zero external dependencies
4. ✅ Perfect TCA compatibility
5. ✅ Easy to test and debug
6. ✅ Fast migration path
7. ✅ Swift 6 concurrency ready

### Future Consideration: GRDB

If any of these become true:
- Users have > 500 shifts scheduled
- Need to search/filter shifts by complex criteria
- Performance becomes an issue
- Want reactive database observations

Then migrate from JSON to GRDB. The value-type models will remain the same, only the repository implementation changes.

### Avoid

- ❌ **SwiftData with TCA**: Fundamental architectural mismatch
- ❌ **Core Data**: Too complex for this use case
- ❌ **UserDefaults**: Not designed for collections

---

## 8. Testing Strategy

### Mock Repository for Tests

```swift
// File: ShiftSchedulerTests/Mocks/MockPersistenceRepository.swift

actor MockPersistenceRepository: PersistenceRepository {
    var shiftTypes: [ShiftType] = []
    var locations: [Location] = []

    var shouldThrowError = false

    func loadShiftTypes() async throws -> [ShiftType] {
        if shouldThrowError {
            throw MockError.loadFailed
        }
        return shiftTypes
    }

    func saveShiftTypes(_ types: [ShiftType]) async throws {
        if shouldThrowError {
            throw MockError.saveFailed
        }
        shiftTypes = types
    }

    func loadLocations() async throws -> [Location] {
        if shouldThrowError {
            throw MockError.loadFailed
        }
        return locations
    }

    func saveLocations(_ locations: [Location]) async throws {
        if shouldThrowError {
            throw MockError.saveFailed
        }
        self.locations = locations
    }

    enum MockError: Error {
        case loadFailed
        case saveFailed
    }
}

// Usage in tests:
extension PersistenceClient {
    static func mock(
        shiftTypes: [ShiftType] = [],
        locations: [Location] = []
    ) -> PersistenceClient {
        let repo = MockPersistenceRepository()
        repo.shiftTypes = shiftTypes
        repo.locations = locations

        return PersistenceClient(
            loadShiftTypes: { try await repo.loadShiftTypes() },
            saveShiftTypes: { try await repo.saveShiftTypes($0) },
            loadLocations: { try await repo.loadLocations() },
            saveLocations: { try await repo.saveLocations($0) }
        )
    }
}
```

### TCA Reducer Tests

```swift
@Test func testAddLocation() async {
    let mockPersistence = PersistenceClient.mock()
    let store = TestStore(initialState: LocationsFeature.State()) {
        LocationsFeature()
    } withDependencies: {
        $0.persistence = mockPersistence
    }

    let newLocation = Location(name: "Office", address: "123 Main")

    await store.send(.addLocation(newLocation)) {
        $0.locations = [newLocation]
    }
}
```

---

## 9. Additional Resources

### Documentation
- [TCA Documentation](https://pointfreeco.github.io/swift-composable-architecture/)
- [GRDB Documentation](https://github.com/groue/GRDB.swift)
- [Swift Concurrency](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)

### Community Examples
- [TCA Examples](https://github.com/pointfreeco/swift-composable-architecture/tree/main/Examples)
- [GRDB + TCA Integration](https://forums.swift.org/t/composablearchitecture-and-coredata-what-are-the-options/54935)

### Point-Free Episodes
- [Episode #249: Tour of TCA - Persistence](https://www.pointfree.co/collections/composable-architecture/composable-architecture-1-0/ep249-tour-of-the-composable-architecture-1-0-persistence)

---

## 10. Conclusion

SwiftData's reference-type models and internal persistence state make it fundamentally incompatible with TCA's value-type, functional architecture. The recommended solution for ShiftScheduler is **JSON file persistence with value-type models**, which provides:

- Perfect TCA compatibility
- Simple, testable code
- Zero dependencies
- Easy migration path
- Full Swift 6 concurrency support

This approach aligns with ShiftScheduler's current scale and complexity while leaving the door open for future migration to GRDB if advanced database features become necessary.

The migration can be completed in 20-30 hours with minimal risk, and the resulting architecture will be cleaner, more testable, and more maintainable than the current SwiftData implementation.
