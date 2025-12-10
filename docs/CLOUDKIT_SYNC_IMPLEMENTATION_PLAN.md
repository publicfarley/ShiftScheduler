# CloudKit Sync Implementation Plan
## Option 5: Hybrid iCloud + Local-First Architecture

**Created:** December 9, 2025
**Status:** Planning
**Estimated Total Effort:** 50-70 hours (4-5 weeks)
**Target iOS Version:** iOS 17+ (with iOS 16 fallback)

---

## Overview

This plan implements multi-device synchronization using CloudKit while maintaining local JSON files as the primary source of truth. The architecture ensures the app works perfectly offline while providing cloud sync when available.

**Key Principles:**
1. Local files remain authoritative (never blocked by network)
2. CloudKit runs in background (async, non-blocking)
3. UI shows immediate feedback (optimistic updates)
4. Conflicts resolved with three-way merge
5. Gradual rollout (can ship without CloudKit enabled)

---

## Phase 1: Foundation & Setup (Week 1)
**Goal:** Establish CloudKit infrastructure and basic service layer
**Estimated Effort:** 12-16 hours

### Task 1.1: Xcode Project Configuration (2 hours)
**File:** `ShiftScheduler.xcodeproj`

- [ ] Add iCloud capability to ShiftScheduler target
  - Open project settings → Signing & Capabilities
  - Click "+ Capability" → iCloud
  - Enable CloudKit
  - Create new CloudKit container: `iCloud.com.functioncraft.ShiftScheduler`

- [ ] Configure CloudKit entitlements
  - Verify `ShiftScheduler.entitlements` includes:
    ```xml
    <key>com.apple.developer.icloud-container-identifiers</key>
    <array>
        <string>iCloud.com.functioncraft.ShiftScheduler</string>
    </array>
    <key>com.apple.developer.icloud-services</key>
    <array>
        <string>CloudKit</string>
    </array>
    ```

- [ ] Configure development vs. production environments
  - CloudKit Dashboard: Create development schema
  - Plan for production schema migration

**Deliverable:** Xcode project builds with CloudKit entitlements

---

### Task 1.2: CloudKit Schema Design (3 hours)
**Location:** CloudKit Dashboard (developer.apple.com)

Create record types in CloudKit schema:

#### Record Type: `Location`
```
Fields:
- locationId: String (indexed, searchable)
- name: String
- address: String
- modificationDate: Date/Time (indexed)
- createdBy: String (user record name)
```

#### Record Type: `ShiftType`
```
Fields:
- shiftTypeId: String (indexed, searchable)
- symbol: String
- title: String
- description: String
- startTime: String (HH:mm format)
- endTime: String (HH:mm format)
- locationReference: Reference (to Location)
- modificationDate: Date/Time (indexed)
- createdBy: String (user record name)
```

#### Record Type: `ChangeLogEntry`
```
Fields:
- entryId: String (indexed, searchable)
- changeDate: Date/Time (indexed)
- userId: String
- userDisplayName: String
- changeType: String (enum: created, updated, deleted, switched)
- targetType: String (enum: shift, location, shiftType)
- targetId: String
- details: String (JSON serialized)
- modificationDate: Date/Time (indexed)
```

#### Record Type: `SyncMetadata`
```
Fields:
- deviceId: String (indexed)
- lastSyncDate: Date/Time
- pendingUploadCount: Int64
- lastConflictDate: Date/Time
```

**Deliverable:** CloudKit schema deployed to development environment

---

### Task 1.3: Create Sync Domain Models (4 hours)
**New File:** `ShiftScheduler/Services/Sync/SyncModels.swift`

```swift
import Foundation
import CloudKit

// MARK: - Sync Status

enum SyncStatus: Equatable, Sendable {
    case notConfigured  // CloudKit not set up
    case synced         // All changes uploaded and downloaded
    case syncing        // Sync in progress
    case error(String)  // Sync error occurred
    case offline        // No network connection
}

// MARK: - Sync Conflict

struct SyncConflict: Equatable, Sendable, Identifiable {
    let id: UUID
    let entityType: ConflictEntityType
    let localVersion: ConflictVersion
    let remoteVersion: ConflictVersion
    let commonAncestor: ConflictVersion?
    let detectedAt: Date

    enum ConflictEntityType: String, Codable, Sendable {
        case location
        case shiftType
        case changeLogEntry
    }

    struct ConflictVersion: Equatable, Sendable {
        let data: Data  // JSON-encoded entity
        let modificationDate: Date
        let modifiedBy: String
    }
}

// MARK: - Sync Operation

struct SyncOperation: Equatable, Sendable, Identifiable {
    let id: UUID
    let type: OperationType
    let entityType: EntityType
    let entityId: String
    let data: Data  // JSON-encoded entity
    let createdAt: Date

    enum OperationType: String, Codable, Sendable {
        case upload
        case download
        case delete
    }

    enum EntityType: String, Codable, Sendable {
        case location
        case shiftType
        case changeLogEntry
    }
}

// MARK: - CloudKit Conversion Protocols

protocol CloudKitConvertible {
    func toCKRecord(in zoneID: CKRecordZone.ID) -> CKRecord
    static func fromCKRecord(_ record: CKRecord) throws -> Self
}

// MARK: - Sync Error

enum SyncError: Error, Equatable {
    case notAuthenticated
    case networkUnavailable
    case quotaExceeded
    case serverRejected(String)
    case conflictDetected(SyncConflict)
    case invalidData(String)
    case unknownError(String)
}
```

**Deliverable:** Sync domain models compiled and ready for use

---

### Task 1.4: Create Sync Service Protocol (3 hours)
**New File:** `ShiftScheduler/Services/Sync/SyncServiceProtocol.swift`

```swift
import Foundation
import CloudKit

// MARK: - Sync Service Protocol

protocol SyncServiceProtocol: Sendable {
    /// Check if CloudKit is available and user is authenticated
    func isAvailable() async -> Bool

    /// Upload pending local changes to CloudKit
    func uploadPendingChanges() async throws

    /// Download remote changes from CloudKit
    func downloadRemoteChanges() async throws

    /// Resolve a specific conflict
    func resolveConflict(_ conflict: SyncConflict, resolution: ConflictResolution) async throws

    /// Get current sync status
    func getSyncStatus() async -> SyncStatus

    /// Manually trigger full sync
    func performFullSync() async throws
}

enum ConflictResolution: Sendable {
    case keepLocal
    case keepRemote
    case merge(Data)  // JSON-encoded merged entity
}

// MARK: - CloudKit Sync Service

actor CloudKitSyncService: SyncServiceProtocol {
    private let container: CKContainer
    private let database: CKDatabase
    private let zoneID: CKRecordZone.ID

    private var syncStatus: SyncStatus = .notConfigured

    init(containerIdentifier: String = "iCloud.com.functioncraft.ShiftScheduler") {
        self.container = CKContainer(identifier: containerIdentifier)
        self.database = container.privateCloudDatabase
        self.zoneID = CKRecordZone.ID(zoneName: "ShiftSchedulerZone", ownerName: CKCurrentUserDefaultName)
    }

    func isAvailable() async -> Bool {
        // Check CloudKit account status
        do {
            let status = try await container.accountStatus()
            return status == .available
        } catch {
            return false
        }
    }

    func uploadPendingChanges() async throws {
        // TODO: Implement in Phase 2
        throw SyncError.unknownError("Not implemented")
    }

    func downloadRemoteChanges() async throws {
        // TODO: Implement in Phase 2
        throw SyncError.unknownError("Not implemented")
    }

    func resolveConflict(_ conflict: SyncConflict, resolution: ConflictResolution) async throws {
        // TODO: Implement in Phase 3
        throw SyncError.unknownError("Not implemented")
    }

    func getSyncStatus() async -> SyncStatus {
        return syncStatus
    }

    func performFullSync() async throws {
        // TODO: Implement in Phase 2
        throw SyncError.unknownError("Not implemented")
    }
}
```

**Deliverable:** Sync service protocol and skeleton implementation

---

### Task 1.5: Integrate into Service Container (2 hours)
**File:** `ShiftScheduler/Redux/Services/ServiceContainer.swift`

Add sync service to dependency injection:

```swift
struct ServiceContainer: Sendable {
    let calendarService: CalendarServiceProtocol
    let persistenceService: PersistenceServiceProtocol
    let shiftSwitchService: ShiftSwitchServiceProtocol
    let currentDayService: CurrentDayServiceProtocol
    let syncService: SyncServiceProtocol  // NEW

    init(
        calendarService: CalendarServiceProtocol = CalendarService(),
        persistenceService: PersistenceServiceProtocol = PersistenceService(),
        shiftSwitchService: ShiftSwitchServiceProtocol = ShiftSwitchService(),
        currentDayService: CurrentDayServiceProtocol = CurrentDayService(),
        syncService: SyncServiceProtocol = CloudKitSyncService()  // NEW
    ) {
        self.calendarService = calendarService
        self.persistenceService = persistenceService
        self.shiftSwitchService = shiftSwitchService
        self.currentDayService = currentDayService
        self.syncService = syncService
    }
}
```

**Deliverable:** ServiceContainer builds with sync service

---

### Task 1.6: Add Sync State to Redux (2 hours)
**Files:**
- `ShiftScheduler/Redux/AppState.swift`
- `ShiftScheduler/Redux/AppAction.swift`
- `ShiftScheduler/Redux/AppReducer.swift`

#### AppState.swift
```swift
struct AppState: Equatable {
    // ... existing state ...
    var syncState: SyncState = SyncState()
}

struct SyncState: Equatable {
    var status: SyncStatus = .notConfigured
    var lastSyncDate: Date? = nil
    var pendingConflicts: [SyncConflict] = []
    var isAutoSyncEnabled: Bool = true
}
```

#### AppAction.swift
```swift
enum AppAction: Equatable {
    // ... existing actions ...
    case sync(SyncAction)
}

enum SyncAction: Equatable {
    case checkAvailability
    case availabilityChecked(Bool)
    case uploadPendingChanges
    case downloadRemoteChanges
    case syncCompleted
    case syncFailed(String)
    case conflictDetected(SyncConflict)
    case resolveConflict(SyncConflict.ID, ConflictResolution)
    case updateStatus(SyncStatus)
}
```

#### AppReducer.swift
```swift
func reduce(state: inout AppState, action: AppAction) {
    switch action {
    // ... existing cases ...

    case .sync(let syncAction):
        reduceSyncAction(state: &state, action: syncAction)
    }
}

private func reduceSyncAction(state: inout AppState, action: SyncAction) {
    switch action {
    case .checkAvailability:
        // Status will be updated by middleware
        break

    case .availabilityChecked(let isAvailable):
        state.syncState.status = isAvailable ? .synced : .notConfigured

    case .uploadPendingChanges, .downloadRemoteChanges:
        state.syncState.status = .syncing

    case .syncCompleted:
        state.syncState.status = .synced
        state.syncState.lastSyncDate = Date()

    case .syncFailed(let error):
        state.syncState.status = .error(error)

    case .conflictDetected(let conflict):
        state.syncState.pendingConflicts.append(conflict)

    case .resolveConflict(let conflictId, _):
        state.syncState.pendingConflicts.removeAll { $0.id == conflictId }

    case .updateStatus(let status):
        state.syncState.status = status
    }
}
```

**Deliverable:** Redux state management for sync ready

---

## Phase 2: Upload & Download (Week 2)
**Goal:** Implement bidirectional sync between local files and CloudKit
**Estimated Effort:** 16-20 hours

### Task 2.1: Implement CloudKit Zone Setup (3 hours)
**File:** `ShiftScheduler/Services/Sync/CloudKitSyncService.swift`

Add custom zone creation and management:

```swift
actor CloudKitSyncService: SyncServiceProtocol {
    // ... existing properties ...

    private func ensureCustomZoneExists() async throws {
        let zone = CKRecordZone(zoneID: zoneID)

        do {
            _ = try await database.modifyRecordZones(saving: [zone], deleting: [])
            Logger.debug("CloudKit zone created or verified")
        } catch let error as CKError {
            // Zone already exists is not an error
            if error.code != .serverRecordChanged {
                throw SyncError.serverRejected(error.localizedDescription)
            }
        }
    }

    private func fetchServerChangeToken() async throws -> CKServerChangeToken? {
        // Retrieve stored change token from UserDefaults or local storage
        guard let data = UserDefaults.standard.data(forKey: "cloudKitChangeToken") else {
            return nil
        }

        return try? NSKeyedUnarchiver.unarchivedObject(ofClass: CKServerChangeToken.self, from: data)
    }

    private func saveServerChangeToken(_ token: CKServerChangeToken?) async {
        guard let token = token else { return }

        if let data = try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true) {
            UserDefaults.standard.set(data, forKey: "cloudKitChangeToken")
        }
    }
}
```

**Deliverable:** CloudKit custom zone created on first launch

---

### Task 2.2: Implement Location Upload (4 hours)
**File:** `ShiftScheduler/Services/Sync/CloudKitSyncService.swift`

Add Location → CKRecord conversion and upload:

```swift
extension Location: CloudKitConvertible {
    func toCKRecord(in zoneID: CKRecordZone.ID) -> CKRecord {
        let recordID = CKRecord.ID(recordName: id.uuidString, zoneID: zoneID)
        let record = CKRecord(recordType: "Location", recordID: recordID)

        record["locationId"] = id.uuidString
        record["name"] = name
        record["address"] = address ?? ""
        record["modificationDate"] = Date()

        return record
    }

    static func fromCKRecord(_ record: CKRecord) throws -> Location {
        guard let locationId = record["locationId"] as? String,
              let id = UUID(uuidString: locationId),
              let name = record["name"] as? String else {
            throw SyncError.invalidData("Missing required Location fields")
        }

        let address = record["address"] as? String

        return Location(id: id, name: name, address: address)
    }
}

actor CloudKitSyncService: SyncServiceProtocol {
    // ... existing code ...

    func uploadLocations(_ locations: [Location]) async throws {
        try await ensureCustomZoneExists()

        let records = locations.map { $0.toCKRecord(in: zoneID) }

        do {
            let result = try await database.modifyRecords(saving: records, deleting: [])
            Logger.debug("Uploaded \(result.saveResults.count) locations to CloudKit")
        } catch {
            throw SyncError.serverRejected(error.localizedDescription)
        }
    }

    func downloadLocations() async throws -> [Location] {
        try await ensureCustomZoneExists()

        let query = CKQuery(recordType: "Location", predicate: NSPredicate(value: true))
        let (matchResults, _) = try await database.records(matching: query)

        var locations: [Location] = []

        for (_, result) in matchResults {
            switch result {
            case .success(let record):
                if let location = try? Location.fromCKRecord(record) {
                    locations.append(location)
                }
            case .failure(let error):
                Logger.debug("Failed to fetch location: \(error)")
            }
        }

        return locations
    }
}
```

**Deliverable:** Locations sync to/from CloudKit

---

### Task 2.3: Implement ShiftType Upload (4 hours)
**File:** `ShiftScheduler/Services/Sync/CloudKitSyncService.swift`

Add ShiftType → CKRecord conversion and upload:

```swift
extension ShiftType: CloudKitConvertible {
    func toCKRecord(in zoneID: CKRecordZone.ID) -> CKRecord {
        let recordID = CKRecord.ID(recordName: id.uuidString, zoneID: zoneID)
        let record = CKRecord(recordType: "ShiftType", recordID: recordID)

        record["shiftTypeId"] = id.uuidString
        record["symbol"] = symbol
        record["title"] = title
        record["description"] = description
        record["startTime"] = duration.start.formatted(date: .omitted, time: .shortened)
        record["endTime"] = duration.end.formatted(date: .omitted, time: .shortened)

        // Reference to Location
        let locationRecordID = CKRecord.ID(recordName: location.id.uuidString, zoneID: zoneID)
        record["locationReference"] = CKRecord.Reference(recordID: locationRecordID, action: .none)

        record["modificationDate"] = Date()

        return record
    }

    static func fromCKRecord(_ record: CKRecord) throws -> ShiftType {
        guard let shiftTypeId = record["shiftTypeId"] as? String,
              let id = UUID(uuidString: shiftTypeId),
              let symbol = record["symbol"] as? String,
              let title = record["title"] as? String,
              let description = record["description"] as? String,
              let startTimeStr = record["startTime"] as? String,
              let endTimeStr = record["endTime"] as? String else {
            throw SyncError.invalidData("Missing required ShiftType fields")
        }

        // Parse times (simplified - improve with proper DateFormatter)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"

        guard let startTime = dateFormatter.date(from: startTimeStr),
              let endTime = dateFormatter.date(from: endTimeStr) else {
            throw SyncError.invalidData("Invalid time format")
        }

        // Note: Location must be resolved separately from reference
        // This is a placeholder - proper implementation needs location lookup
        let location = Location(id: UUID(), name: "Unknown", address: nil)

        return ShiftType(
            id: id,
            symbol: symbol,
            duration: startTime..<endTime,
            title: title,
            description: description,
            location: location
        )
    }
}

actor CloudKitSyncService: SyncServiceProtocol {
    // ... existing code ...

    func uploadShiftTypes(_ shiftTypes: [ShiftType]) async throws {
        try await ensureCustomZoneExists()

        let records = shiftTypes.map { $0.toCKRecord(in: zoneID) }

        do {
            let result = try await database.modifyRecords(saving: records, deleting: [])
            Logger.debug("Uploaded \(result.saveResults.count) shift types to CloudKit")
        } catch {
            throw SyncError.serverRejected(error.localizedDescription)
        }
    }

    func downloadShiftTypes(locations: [Location]) async throws -> [ShiftType] {
        try await ensureCustomZoneExists()

        let query = CKQuery(recordType: "ShiftType", predicate: NSPredicate(value: true))
        let (matchResults, _) = try await database.records(matching: query)

        var shiftTypes: [ShiftType] = []

        for (_, result) in matchResults {
            switch result {
            case .success(let record):
                // Resolve location reference
                if var shiftType = try? ShiftType.fromCKRecord(record),
                   let locationRef = record["locationReference"] as? CKRecord.Reference {

                    let locationId = UUID(uuidString: locationRef.recordID.recordName)
                    if let location = locations.first(where: { $0.id == locationId }) {
                        // Update with actual location
                        shiftType = ShiftType(
                            id: shiftType.id,
                            symbol: shiftType.symbol,
                            duration: shiftType.duration,
                            title: shiftType.title,
                            description: shiftType.description,
                            location: location
                        )
                        shiftTypes.append(shiftType)
                    }
                }
            case .failure(let error):
                Logger.debug("Failed to fetch shift type: \(error)")
            }
        }

        return shiftTypes
    }
}
```

**Deliverable:** ShiftTypes sync to/from CloudKit with Location references

---

### Task 2.4: Create Sync Middleware (5 hours)
**New File:** `ShiftScheduler/Redux/Middleware/SyncMiddleware.swift`

Implement middleware to trigger sync on data changes:

```swift
import Foundation

func syncMiddleware(
    state: AppState,
    action: AppAction,
    services: ServiceContainer,
    dispatch: @escaping Dispatcher<AppAction>
) async {
    switch action {
    // Check availability on app launch
    case .app(.launched):
        await handleCheckAvailability(services: services, dispatch: dispatch)

    // Upload changes after local save
    case .locations(.saved):
        await handleUploadLocations(state: state, services: services, dispatch: dispatch)

    case .shiftTypes(.saved):
        await handleUploadShiftTypes(state: state, services: services, dispatch: dispatch)

    // Download on foreground
    case .app(.didEnterForeground):
        await handleDownloadRemoteChanges(services: services, dispatch: dispatch)

    // Manual sync triggers
    case .sync(.uploadPendingChanges):
        await handleUploadPendingChanges(state: state, services: services, dispatch: dispatch)

    case .sync(.downloadRemoteChanges):
        await handleDownloadRemoteChanges(services: services, dispatch: dispatch)

    default:
        break
    }
}

// MARK: - Helper Functions

private func handleCheckAvailability(
    services: ServiceContainer,
    dispatch: @escaping Dispatcher<AppAction>
) async {
    let isAvailable = await services.syncService.isAvailable()
    await dispatch(.sync(.availabilityChecked(isAvailable)))
}

private func handleUploadLocations(
    state: AppState,
    services: ServiceContainer,
    dispatch: @escaping Dispatcher<AppAction>
) async {
    guard state.syncState.status != .notConfigured else { return }

    do {
        // Upload locations from state
        if let syncService = services.syncService as? CloudKitSyncService {
            try await syncService.uploadLocations(state.locationsState.locations)
            await dispatch(.sync(.syncCompleted))
        }
    } catch {
        await dispatch(.sync(.syncFailed(error.localizedDescription)))
    }
}

private func handleUploadShiftTypes(
    state: AppState,
    services: ServiceContainer,
    dispatch: @escaping Dispatcher<AppAction>
) async {
    guard state.syncState.status != .notConfigured else { return }

    do {
        if let syncService = services.syncService as? CloudKitSyncService {
            try await syncService.uploadShiftTypes(state.shiftTypesState.shiftTypes)
            await dispatch(.sync(.syncCompleted))
        }
    } catch {
        await dispatch(.sync(.syncFailed(error.localizedDescription)))
    }
}

private func handleUploadPendingChanges(
    state: AppState,
    services: ServiceContainer,
    dispatch: @escaping Dispatcher<AppAction>
) async {
    await handleUploadLocations(state: state, services: services, dispatch: dispatch)
    await handleUploadShiftTypes(state: state, services: services, dispatch: dispatch)
}

private func handleDownloadRemoteChanges(
    services: ServiceContainer,
    dispatch: @escaping Dispatcher<AppAction>
) async {
    guard let syncService = services.syncService as? CloudKitSyncService else { return }

    do {
        // Download locations first (needed for shift type references)
        let locations = try await syncService.downloadLocations()

        // Merge with local state (TODO: implement conflict detection)
        for location in locations {
            await dispatch(.locations(.add(location)))
        }

        // Download shift types
        let shiftTypes = try await syncService.downloadShiftTypes(locations: locations)

        for shiftType in shiftTypes {
            await dispatch(.shiftTypes(.add(shiftType)))
        }

        await dispatch(.sync(.syncCompleted))
    } catch {
        await dispatch(.sync(.syncFailed(error.localizedDescription)))
    }
}
```

**Deliverable:** Middleware automatically syncs on data changes

---

### Task 2.5: Wire Sync Middleware into Store (2 hours)
**File:** `ShiftScheduler/Redux/Store.swift`

Add sync middleware to middleware chain:

```swift
@Observable
@MainActor
final class Store {
    private(set) var state: AppState
    private let services: ServiceContainer
    private let middlewares: [Middleware<AppState, AppAction>]

    init(
        initialState: AppState = AppState(),
        services: ServiceContainer = ServiceContainer()
    ) {
        self.state = initialState
        self.services = services
        self.middlewares = [
            scheduleMiddleware,
            todayMiddleware,
            locationsMiddleware,
            shiftTypesMiddleware,
            changeLogMiddleware,
            settingsMiddleware,
            syncMiddleware,  // NEW - runs after data changes
            loggingMiddleware
        ]
    }

    // ... rest of store implementation ...
}
```

**Deliverable:** Sync middleware integrated into Redux flow

---

### Task 2.6: Test Two-Device Sync (2 hours)

**Setup:**
1. Build app on iPhone simulator (Device A)
2. Build app on physical iPhone (Device B)
3. Sign in to same iCloud account on both devices

**Test Cases:**
- [ ] Create Location on Device A → appears on Device B
- [ ] Create ShiftType on Device A → appears on Device B
- [ ] Edit Location on Device A → updates on Device B
- [ ] Delete Location on Device A → removes on Device B
- [ ] Test offline/online transitions
- [ ] Test app kill/restart (data persists)

**Deliverable:** Two-device sync working for locations and shift types

---

## Phase 3: Conflict Resolution (Week 3)
**Goal:** Handle simultaneous edits with three-way merge
**Estimated Effort:** 14-18 hours

### Task 3.1: Implement Change Tracking (4 hours)
**New File:** `ShiftScheduler/Services/Sync/ChangeTracker.swift`

Track local changes for conflict detection:

```swift
import Foundation

struct EntitySnapshot: Codable, Equatable, Sendable {
    let entityId: String
    let entityType: String
    let data: Data  // JSON-encoded entity
    let modificationDate: Date
    let modifiedBy: String
}

actor ChangeTracker {
    private var snapshots: [String: EntitySnapshot] = [:]

    func recordSnapshot(_ snapshot: EntitySnapshot) {
        snapshots[snapshot.entityId] = snapshot
    }

    func getSnapshot(for entityId: String) -> EntitySnapshot? {
        return snapshots[entityId]
    }

    func detectConflict(
        localEntity: EntitySnapshot,
        remoteEntity: EntitySnapshot
    ) -> SyncConflict? {
        let commonAncestor = snapshots[localEntity.entityId]

        // No conflict if modification dates match
        guard localEntity.modificationDate != remoteEntity.modificationDate else {
            return nil
        }

        // Conflict detected
        return SyncConflict(
            id: UUID(),
            entityType: parseEntityType(localEntity.entityType),
            localVersion: SyncConflict.ConflictVersion(
                data: localEntity.data,
                modificationDate: localEntity.modificationDate,
                modifiedBy: localEntity.modifiedBy
            ),
            remoteVersion: SyncConflict.ConflictVersion(
                data: remoteEntity.data,
                modificationDate: remoteEntity.modificationDate,
                modifiedBy: remoteEntity.modifiedBy
            ),
            commonAncestor: commonAncestor.map {
                SyncConflict.ConflictVersion(
                    data: $0.data,
                    modificationDate: $0.modificationDate,
                    modifiedBy: $0.modifiedBy
                )
            },
            detectedAt: Date()
        )
    }

    private func parseEntityType(_ typeString: String) -> SyncConflict.ConflictEntityType {
        switch typeString {
        case "Location": return .location
        case "ShiftType": return .shiftType
        case "ChangeLogEntry": return .changeLogEntry
        default: return .location
        }
    }
}
```

**Deliverable:** Change tracking for conflict detection

---

### Task 3.2: Implement Three-Way Merge (5 hours)
**New File:** `ShiftScheduler/Services/Sync/ConflictResolver.swift`

Implement merge algorithm:

```swift
import Foundation

struct ConflictResolver {
    /// Performs three-way merge of conflicting entities
    static func merge<T: Codable & Equatable>(
        base: T?,
        local: T,
        remote: T
    ) throws -> T {
        // If no base, use last-write-wins
        guard let base = base else {
            return local  // Prefer local in absence of common ancestor
        }

        // Compare fields and merge non-conflicting changes
        let baseData = try JSONEncoder().encode(base)
        let localData = try JSONEncoder().encode(local)
        let remoteData = try JSONEncoder().encode(remote)

        // If local and remote are identical, no conflict
        if localData == remoteData {
            return local
        }

        // If only local changed, use local
        if localData != baseData && remoteData == baseData {
            return local
        }

        // If only remote changed, use remote
        if remoteData != baseData && localData == baseData {
            return remote
        }

        // Both changed - need user resolution
        throw SyncError.conflictDetected(
            SyncConflict(
                id: UUID(),
                entityType: .location,  // Determine dynamically
                localVersion: SyncConflict.ConflictVersion(
                    data: localData,
                    modificationDate: Date(),
                    modifiedBy: "local"
                ),
                remoteVersion: SyncConflict.ConflictVersion(
                    data: remoteData,
                    modificationDate: Date(),
                    modifiedBy: "remote"
                ),
                commonAncestor: SyncConflict.ConflictVersion(
                    data: baseData,
                    modificationDate: Date(),
                    modifiedBy: "base"
                ),
                detectedAt: Date()
            )
        )
    }

    /// Field-level merge for Location
    static func mergeLocation(
        base: Location?,
        local: Location,
        remote: Location
    ) -> Location {
        guard let base = base else {
            return local  // Last-write-wins without base
        }

        // Merge individual fields
        let mergedName = local.name != base.name ? local.name : remote.name
        let mergedAddress = local.address != base.address ? local.address : remote.address

        return Location(
            id: local.id,
            name: mergedName,
            address: mergedAddress
        )
    }

    /// Field-level merge for ShiftType
    static func mergeShiftType(
        base: ShiftType?,
        local: ShiftType,
        remote: ShiftType
    ) -> ShiftType {
        guard let base = base else {
            return local
        }

        let mergedSymbol = local.symbol != base.symbol ? local.symbol : remote.symbol
        let mergedTitle = local.title != base.title ? local.title : remote.title
        let mergedDescription = local.description != base.description ? local.description : remote.description
        let mergedDuration = local.duration != base.duration ? local.duration : remote.duration
        let mergedLocation = local.location != base.location ? local.location : remote.location

        return ShiftType(
            id: local.id,
            symbol: mergedSymbol,
            duration: mergedDuration,
            title: mergedTitle,
            description: mergedDescription,
            location: mergedLocation
        )
    }
}
```

**Deliverable:** Three-way merge algorithm for automatic conflict resolution

---

### Task 3.3: Create Conflict Resolution UI (5 hours)
**New File:** `ShiftScheduler/Views/Sync/ConflictResolutionView.swift`

UI for user to resolve conflicts manually:

```swift
import SwiftUI

struct ConflictResolutionView: View {
    @Environment(\.reduxStore) var store
    let conflict: SyncConflict

    @State private var selectedResolution: ConflictResolution?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.orange)

                    Text("Sync Conflict Detected")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("The same \(conflict.entityType.rawValue) was edited on multiple devices")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)

                // Conflict versions
                ScrollView {
                    VStack(spacing: 16) {
                        ConflictVersionCard(
                            title: "Your Changes",
                            version: conflict.localVersion,
                            isSelected: selectedResolution == .keepLocal
                        )
                        .onTapGesture {
                            selectedResolution = .keepLocal
                        }

                        ConflictVersionCard(
                            title: "Remote Changes",
                            version: conflict.remoteVersion,
                            isSelected: selectedResolution == .keepRemote
                        )
                        .onTapGesture {
                            selectedResolution = .keepRemote
                        }

                        if let ancestor = conflict.commonAncestor {
                            ConflictVersionCard(
                                title: "Original Version",
                                version: ancestor,
                                isSelected: false
                            )
                        }
                    }
                    .padding()
                }

                // Action buttons
                HStack(spacing: 16) {
                    Button("Keep Both") {
                        // TODO: Implement merge UI
                    }
                    .buttonStyle(.bordered)

                    Button("Resolve") {
                        if let resolution = selectedResolution {
                            store.dispatch(action: .sync(.resolveConflict(conflict.id, resolution)))
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedResolution == nil)
                }
                .padding()
            }
            .navigationTitle("Resolve Conflict")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ConflictVersionCard: View {
    let title: String
    let version: SyncConflict.ConflictVersion
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }

            Text("Modified: \(version.modificationDate.formatted())")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("By: \(version.modifiedBy)")
                .font(.caption)
                .foregroundStyle(.secondary)

            // Show preview of data
            if let preview = decodePreview(version.data) {
                Text(preview)
                    .font(.body)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }

    private func decodePreview(_ data: Data) -> String? {
        // Decode and format preview text
        // TODO: Implement based on entity type
        return "Preview of changes..."
    }
}
```

**Deliverable:** Conflict resolution UI for manual resolution

---

### Task 3.4: Integrate Conflict Detection into Sync Flow (4 hours)
**File:** `ShiftScheduler/Services/Sync/CloudKitSyncService.swift`

Add conflict detection to download:

```swift
actor CloudKitSyncService: SyncServiceProtocol {
    private let changeTracker = ChangeTracker()

    // ... existing code ...

    func downloadRemoteChanges() async throws {
        try await ensureCustomZoneExists()

        // Download locations
        let remoteLocations = try await downloadLocations()

        // Detect conflicts
        var conflicts: [SyncConflict] = []

        for remoteLocation in remoteLocations {
            if let localSnapshot = await changeTracker.getSnapshot(for: remoteLocation.id.uuidString) {
                let remoteSnapshot = EntitySnapshot(
                    entityId: remoteLocation.id.uuidString,
                    entityType: "Location",
                    data: try JSONEncoder().encode(remoteLocation),
                    modificationDate: Date(),
                    modifiedBy: "remote"
                )

                if let conflict = await changeTracker.detectConflict(
                    localEntity: localSnapshot,
                    remoteEntity: remoteSnapshot
                ) {
                    conflicts.append(conflict)
                }
            }
        }

        // Throw if conflicts detected (will be caught by middleware)
        if !conflicts.isEmpty {
            throw SyncError.conflictDetected(conflicts[0])
        }

        // No conflicts - proceed with merge
        // (Handled by middleware)
    }

    func resolveConflict(_ conflict: SyncConflict, resolution: ConflictResolution) async throws {
        switch resolution {
        case .keepLocal:
            // Upload local version to CloudKit
            break

        case .keepRemote:
            // Overwrite local with remote version
            break

        case .merge(let mergedData):
            // Upload merged version to CloudKit
            break
        }
    }
}
```

**Deliverable:** Conflict detection integrated into sync pipeline

---

## Phase 4: User Experience & Testing (Week 4)
**Goal:** Polish UX and comprehensive testing
**Estimated Effort:** 12-16 hours

### Task 4.1: Add Sync Status Indicator (3 hours)
**New File:** `ShiftScheduler/Views/Sync/SyncStatusIndicator.swift`

Visual indicator of sync state:

```swift
import SwiftUI

struct SyncStatusIndicator: View {
    @Environment(\.reduxStore) var store

    var body: some View {
        HStack(spacing: 6) {
            syncIcon

            if store.state.syncState.status == .syncing {
                Text("Syncing...")
                    .font(.caption)
            }
        }
        .foregroundStyle(syncColor)
    }

    @ViewBuilder
    private var syncIcon: some View {
        switch store.state.syncState.status {
        case .notConfigured:
            Image(systemName: "icloud.slash")
        case .synced:
            Image(systemName: "icloud.and.arrow.up")
        case .syncing:
            ProgressView()
                .controlSize(.small)
        case .error:
            Image(systemName: "exclamationmark.icloud")
        case .offline:
            Image(systemName: "wifi.slash")
        }
    }

    private var syncColor: Color {
        switch store.state.syncState.status {
        case .notConfigured, .offline:
            return .secondary
        case .synced:
            return .green
        case .syncing:
            return .blue
        case .error:
            return .red
        }
    }
}

// Add to ContentView navigation bar
struct ContentView: View {
    @Environment(\.reduxStore) var store

    var body: some View {
        TabView(selection: Binding(
            get: { store.state.selectedTab },
            set: { store.dispatch(action: .app(.tabSelected($0))) }
        )) {
            // ... tabs ...
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                SyncStatusIndicator()
            }
        }
    }
}
```

**Deliverable:** Sync status visible in navigation bar

---

### Task 4.2: Add Sync Settings (2 hours)
**File:** `ShiftScheduler/Views/Settings/SettingsView.swift`

User controls for sync:

```swift
struct SettingsView: View {
    @Environment(\.reduxStore) var store

    var body: some View {
        Form {
            // ... existing settings ...

            Section("Sync") {
                Toggle("Auto-sync", isOn: Binding(
                    get: { store.state.syncState.isAutoSyncEnabled },
                    set: { enabled in
                        // TODO: Add Redux action for toggling auto-sync
                    }
                ))

                if let lastSync = store.state.syncState.lastSyncDate {
                    HStack {
                        Text("Last synced")
                        Spacer()
                        Text(lastSync.formatted(.relative(presentation: .named)))
                            .foregroundStyle(.secondary)
                    }
                }

                Button("Sync Now") {
                    store.dispatch(action: .sync(.uploadPendingChanges))
                    store.dispatch(action: .sync(.downloadRemoteChanges))
                }
                .disabled(store.state.syncState.status == .syncing)
            }
        }
    }
}
```

**Deliverable:** User-accessible sync controls in Settings

---

### Task 4.3: Handle Network Transitions (3 hours)
**New File:** `ShiftScheduler/Services/Sync/NetworkMonitor.swift`

Monitor network availability:

```swift
import Network
import Foundation

actor NetworkMonitor {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    private(set) var isConnected = false

    func startMonitoring(onUpdate: @escaping (Bool) -> Void) {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { [weak self] in
                guard let self = self else { return }
                let connected = path.status == .satisfied
                await self.updateConnectionStatus(connected)
                onUpdate(connected)
            }
        }
        monitor.start(queue: queue)
    }

    func stopMonitoring() {
        monitor.cancel()
    }

    private func updateConnectionStatus(_ connected: Bool) {
        isConnected = connected
    }
}

// Integrate into Store
@Observable
@MainActor
final class Store {
    private let networkMonitor = NetworkMonitor()

    init(initialState: AppState = AppState(), services: ServiceContainer = ServiceContainer()) {
        // ... existing init ...

        Task {
            await networkMonitor.startMonitoring { [weak self] isConnected in
                guard let self = self else { return }

                if isConnected {
                    self.dispatch(action: .sync(.downloadRemoteChanges))
                } else {
                    self.dispatch(action: .sync(.updateStatus(.offline)))
                }
            }
        }
    }
}
```

**Deliverable:** Automatic sync when network becomes available

---

### Task 4.4: Write Sync Unit Tests (4 hours)
**New File:** `ShiftSchedulerTests/Services/Sync/CloudKitSyncServiceTests.swift`

Comprehensive test coverage:

```swift
import Testing
import Foundation
@testable import ShiftScheduler

@Suite("CloudKit Sync Service Tests")
struct CloudKitSyncServiceTests {

    @Test("Sync service initializes correctly")
    func testInitialization() async throws {
        let service = CloudKitSyncService()
        let status = await service.getSyncStatus()

        #expect(status == .notConfigured)
    }

    @Test("Upload locations converts to CKRecord correctly")
    func testLocationUpload() async throws {
        let location = Location(id: UUID(), name: "Test Hospital", address: "123 Main St")

        let service = CloudKitSyncService()

        // Mock CloudKit container for testing
        // TODO: Implement mock CloudKit database

        // Verify conversion
        let record = location.toCKRecord(in: CKRecordZone.ID(zoneName: "Test", ownerName: "Test"))

        #expect(record["name"] as? String == "Test Hospital")
        #expect(record["address"] as? String == "123 Main St")
    }

    @Test("Conflict detection identifies simultaneous edits")
    func testConflictDetection() async throws {
        let changeTracker = ChangeTracker()

        let originalLocation = Location(id: UUID(), name: "Original", address: nil)
        let localLocation = Location(id: originalLocation.id, name: "Local Edit", address: nil)
        let remoteLocation = Location(id: originalLocation.id, name: "Remote Edit", address: nil)

        let localSnapshot = EntitySnapshot(
            entityId: originalLocation.id.uuidString,
            entityType: "Location",
            data: try JSONEncoder().encode(localLocation),
            modificationDate: Date(),
            modifiedBy: "user1"
        )

        let remoteSnapshot = EntitySnapshot(
            entityId: originalLocation.id.uuidString,
            entityType: "Location",
            data: try JSONEncoder().encode(remoteLocation),
            modificationDate: Date(),
            modifiedBy: "user2"
        )

        let conflict = await changeTracker.detectConflict(
            localEntity: localSnapshot,
            remoteEntity: remoteSnapshot
        )

        #expect(conflict != nil)
        #expect(conflict?.entityType == .location)
    }

    @Test("Three-way merge resolves non-conflicting changes")
    func testThreeWayMerge() throws {
        let base = Location(id: UUID(), name: "Hospital", address: "Old Address")
        let local = Location(id: base.id, name: "Hospital Updated", address: "Old Address")
        let remote = Location(id: base.id, name: "Hospital", address: "New Address")

        let merged = ConflictResolver.mergeLocation(base: base, local: local, remote: remote)

        #expect(merged.name == "Hospital Updated")  // Local change
        #expect(merged.address == "New Address")     // Remote change
    }
}
```

**Deliverable:** Unit tests for sync service with 80%+ coverage

---

### Task 4.5: Multi-Device Integration Testing (4 hours)

**Test Scenarios:**

1. **Happy Path Sync**
   - [ ] Device A creates Location → Device B receives it
   - [ ] Device B edits Location → Device A receives update
   - [ ] Device A deletes Location → Device B removes it
   - [ ] Same tests for ShiftType

2. **Conflict Scenarios**
   - [ ] Simultaneous edit on both devices → Conflict UI appears
   - [ ] User chooses "Keep Local" → Local version syncs
   - [ ] User chooses "Keep Remote" → Remote version syncs
   - [ ] User chooses "Merge" → Merged version syncs

3. **Network Conditions**
   - [ ] Start offline → data cached locally
   - [ ] Go online → automatic sync triggered
   - [ ] Poor connectivity → retry with backoff
   - [ ] Complete network loss → graceful degradation

4. **Edge Cases**
   - [ ] App killed during sync → resumes on relaunch
   - [ ] Location deleted while referenced by ShiftType → cascade handled
   - [ ] Large data set (100+ locations) → pagination works
   - [ ] Rapid sequential edits → all synced correctly

**Deliverable:** Test results documented with screenshots

---

## Phase 5: Polish & Documentation (Optional - 1 week)
**Goal:** Production readiness
**Estimated Effort:** 8-12 hours

### Task 5.1: Add Error Recovery (3 hours)

- [ ] Implement retry logic with exponential backoff
- [ ] Handle CloudKit quota exceeded errors
- [ ] User-friendly error messages
- [ ] Sync error logs for debugging

### Task 5.2: Performance Optimization (3 hours)

- [ ] Batch uploads (upload multiple records in one operation)
- [ ] Delta sync (only fetch changed records since last sync)
- [ ] Background fetch (periodic sync when app in background)
- [ ] Memory optimization (streaming large datasets)

### Task 5.3: Documentation (3 hours)

- [ ] Update CLAUDE.md with sync architecture
- [ ] Add CloudKit setup guide for developers
- [ ] User-facing sync documentation
- [ ] API documentation for SyncServiceProtocol

### Task 5.4: Analytics & Monitoring (3 hours)

- [ ] Log sync success/failure rates
- [ ] Track conflict frequency
- [ ] Monitor CloudKit quota usage
- [ ] Alert on repeated sync failures

---

## Success Metrics

### Functional Requirements
- ✅ Locations sync between devices (upload & download)
- ✅ ShiftTypes sync between devices (upload & download)
- ✅ Conflicts detected and presented to user
- ✅ Three-way merge resolves non-conflicting edits
- ✅ App works perfectly offline (local-first)
- ✅ Sync status visible to user
- ✅ Network transitions handled gracefully

### Performance Requirements
- ✅ Local operations < 100ms (not blocked by sync)
- ✅ Sync completes within 30 seconds for typical dataset
- ✅ Battery impact < 5% per day
- ✅ Network usage < 10MB/day for active user

### Quality Requirements
- ✅ Zero data loss (all changes preserved)
- ✅ No duplicate records after sync
- ✅ Foreign key integrity maintained (Location references)
- ✅ Undo/redo stacks preserved across devices

---

## Risk Mitigation

### Risk 1: CloudKit Service Outage
**Mitigation:** Local files remain authoritative, app fully functional offline

### Risk 2: Data Corruption During Sync
**Mitigation:** Three-way merge with conflict detection, user resolution UI

### Risk 3: Large Data Volume Exceeds Free Tier
**Mitigation:** Monitor usage, implement data cleanup, batch operations

### Risk 4: User Confusion About Sync State
**Mitigation:** Clear UI indicators, last sync timestamp, manual sync button

---

## Rollout Strategy

### Week 1-2: Alpha Testing (Internal)
- Deploy to TestFlight with sync disabled by default
- Enable sync for developer devices only
- Monitor CloudKit logs and error rates

### Week 3-4: Beta Testing (Limited)
- Invite 5-10 beta testers with multiple devices
- Collect feedback on conflict resolution UX
- Fix critical bugs

### Week 5+: General Availability
- Enable sync for all users with opt-in
- Monitor adoption rate and error logs
- Iterate based on user feedback

---

## Dependencies

### External
- CloudKit availability (requires active iCloud account)
- Network connectivity (for sync operations)
- iOS 17+ (for CKSyncEngine, iOS 16 fallback available)

### Internal
- Redux architecture stable (Phase 3 complete)
- Service layer established (Phase 2 complete)
- Local persistence working (Repositories implemented)

---

## Next Steps

1. **Review Plan:** Confirm scope and timeline with stakeholders
2. **Start Phase 1:** Begin with Xcode configuration and CloudKit setup
3. **Set Milestones:** Weekly checkpoints for each phase
4. **Prepare Testing:** Set up TestFlight with multiple test devices

---

**Document Version:** 1.0
**Last Updated:** December 9, 2025
**Next Review:** After Phase 1 completion (Week 1)
