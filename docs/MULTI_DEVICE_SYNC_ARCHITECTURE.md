# Multi-Device Synchronization Architecture Decision Document

**Date:** December 9, 2025
**Status:** Decision Pending
**Decision Owner:** [Project Owner]
**Related Issues:** Multi-user, multi-device support

---

## Executive Summary

This document outlines architectural options for enabling multi-user, multi-device data synchronization in ShiftScheduler. Currently, ShiftType and Location data are created and stored locally on individual devices. To support multiple users accessing shared schedule data across different devices, we need a data synchronization solution.

This analysis evaluates five distinct architectural approaches, ranging from zero-cost peer-to-peer solutions to cloud-based backends, with a recommended approach that balances implementation complexity, ongoing costs, and user experience.

---

## Problem Statement

### Current State
- **Local-only storage:** ShiftType and Location data stored as JSON files in DocumentDirectory
- **Device-isolated data:** Each device has its own independent dataset
- **Multi-user gap:** Users on different devices cannot view the same schedule information

### Use Case
- **Primary users:** Family members or small work teams (2-10 people)
- **Devices:** Multiple iOS devices (phones, tablets)
- **Data sharing:** Need to view and manage shared shift schedules
- **Offline requirement:** Critical for shift workers who may not have connectivity

### Key Constraints
- Zero or minimal recurring costs preferred
- Must maintain offline capability
- Must preserve existing architecture (Redux, JSON persistence)
- Minimal disruption to current codebase

---

## Current Architecture Analysis

### Domain Models

**Location** (`Models/Location.swift`)
- Simple value type: `id`, `name`, `address`
- Codable, Sendable
- Low data volume (typically < 100 records, < 10KB total)

**ShiftType** (`Models/ShiftType.swift`)
- Aggregate root containing embedded Location
- Fields: `id`, `symbol`, `duration`, `title`, `description`, `location`
- Moderate data volume (typically < 50 records, < 50KB total)

**ScheduledShift** (`Models/ScheduledShift.swift`)
- Concrete shift instances on specific dates
- Contains reference to ShiftType and EventKit event identifier
- High volume over time (hundreds to thousands of records)
- **Critical:** Currently stored in EventKit calendar (supports iCloud sync via CalDAV)

**ChangeLogEntry** (audit trail)
- User attribution: `userId`, `userDisplayName`
- Change tracking with snapshots
- Already multi-user aware

### Persistence Architecture

**JSON-Based Storage:**
```
/DocumentDirectory/ShiftSchedulerData/
  ├── shiftTypes.json
  ├── locations.json
  ├── changeLog.json
  ├── userProfile.json
  └── undoredo_stacks.json
```

**EventKit Integration:**
- ScheduledShift data stored in device calendar
- App-specific calendar: `functioncraft.ShiftScheduler`
- Prefers iCloud CalDAV source if available

### Redux State Management
- Unidirectional data flow: Action → Reducer → State → UI
- Service layer with protocol-based dependency injection
- Middleware handles all side effects (calendar, persistence, sync)
- All state transitions are pure and testable

### Data Volume Estimates
- **Locations:** ~10-50 records (< 10KB)
- **ShiftTypes:** ~20-100 records (< 50KB)
- **ScheduledShifts:** ~500-5000 records/year (< 5MB)
- **ChangeLog:** ~1000-10000 entries/year (< 10MB)
- **Total yearly data per user:** < 20MB (well within all free tiers)

---

## Architectural Options

### Option 1: iCloud + CloudKit (Apple Native)

**Description:**
Leverage Apple's native iCloud infrastructure for seamless sync across user devices. Use CloudKit for JSON data (ShiftTypes, Locations, ChangeLog) and EventKit with iCloud calendar source for ScheduledShifts.

#### Key Technologies
- CloudKit (CKContainer, CKDatabase, CKRecord)
- NSUbiquitousKeyValueStore for lightweight metadata
- EventKit with iCloud CalDAV source (already partially implemented)
- CloudKit subscriptions for push notifications

#### Implementation Approach

**CloudKit Schema Design:**
- Record types: `Location`, `ShiftType`, `ChangeLogEntry`, `UserProfile`
- Use CKRecord.Reference for ShiftType → Location relationships
- Zone-based sync (custom CKRecordZone for atomic operations)

**Hybrid Storage Strategy:**
- ShiftTypes, Locations → CloudKit Public Database (shared data)
- ScheduledShifts → EventKit + iCloud calendar (already syncing)
- ChangeLog, UserProfile → CloudKit Private Database (user-specific)

**Conflict Resolution:**
- Last-write-wins with server timestamp authority
- CKModifyRecordsOperation with conflict handling blocks
- Merge undo/redo stacks using vector clocks

**Integration Points:**
- Create `CloudKitSyncService: SyncServiceProtocol`
- Middleware: `SyncMiddleware` intercepts CRUD actions
- Background fetch for periodic sync (30-minute intervals)

#### Advantages
- ✅ Zero backend maintenance (Apple handles infrastructure)
- ✅ Free tier: 10GB storage, 2GB/day transfer per user
- ✅ Automatic conflict resolution built-in
- ✅ Native iOS integration, optimized for Apple ecosystem
- ✅ EventKit already using iCloud source (minimal change)
- ✅ Best privacy (end-to-end encryption with CloudKit private database)

#### Disadvantages
- ❌ Apple ecosystem only (no Android/web support)
- ❌ Limited to 1 million users on free tier
- ❌ CloudKit schema changes challenging in production
- ❌ Debugging sync issues can be opaque
- ❌ Requires Apple Developer account with CloudKit entitlements

#### Implementation Complexity
**Medium** - 40-60 hours
- CloudKit API learning curve
- Testing requires multiple devices or simulators with different iCloud accounts
- Schema design and iteration

#### Cost Analysis
- **Free tier:** 10GB storage + 2GB/day transfer (sufficient for most users)
- **Paid tier:** $0.10/GB storage, $0.10/GB transfer beyond free tier
- **Realistic cost:** $0/month for small teams, $5-20/month for active teams

#### iOS-Specific Considerations
- Requires `iCloud` capability in Xcode project
- Add CloudKit container to entitlements
- Development vs. Production CloudKit environments
- NSUbiquitousKeyValueStore has 1MB limit (not suitable for large data)

#### Impact on Current Architecture
Minimal impact - adds new sync service without replacing existing repositories.

```swift
// New service protocol
protocol SyncServiceProtocol: Sendable {
    func syncShiftTypes() async throws -> [ShiftType]
    func syncLocations() async throws -> [Location]
    func uploadLocalChanges() async throws
    func resolveConflicts() async throws
}

// New middleware
func syncMiddleware(...) async {
    // Intercept .shiftTypes(.saved), .locations(.saved)
    // Push to CloudKit after persisting locally
}
```

---

### Option 2: Firebase Firestore

**Description:**
Use Google's Firebase Firestore for real-time, multi-platform cloud sync. Firestore provides automatic synchronization, offline support, and flexible querying.

#### Key Technologies
- Firebase Firestore (NoSQL cloud database)
- Firebase Authentication (user identity)
- Firestore offline persistence (local cache)
- Real-time listeners for live updates

#### Implementation Approach

**Firestore Collection Structure:**
```
/teams/{teamId}/locations/{locationId}
/teams/{teamId}/shiftTypes/{shiftTypeId}
/teams/{teamId}/scheduledShifts/{shiftId}
/teams/{teamId}/changeLog/{entryId}
/users/{userId}/profile
```

**Multi-User Model:**
- Team concept for shared data (family or work group)
- User invitations via email or share code
- Firestore Security Rules for access control

**Sync Strategy:**
- Replace JSON repositories with Firestore listeners
- Real-time updates push to Redux store
- Offline writes queued and synced when online
- ScheduledShifts replicated to both Firestore + EventKit

**Conflict Resolution:**
- Firestore transactions for atomic operations
- Server timestamps for authoritative ordering
- Optimistic UI updates with rollback on conflict

#### Advantages
- ✅ Real-time sync (updates appear instantly across devices)
- ✅ Excellent offline support (Firestore caches locally)
- ✅ Multi-platform (iOS, Android, web support)
- ✅ Generous free tier: 1GB storage, 50k reads/day, 20k writes/day
- ✅ Rich querying capabilities (filter, sort, pagination)
- ✅ Firebase Authentication simplifies user management

#### Disadvantages
- ❌ Introduces Google dependency (vendor lock-in)
- ❌ Requires internet for initial setup (no fully offline mode)
- ❌ Firebase SDK increases app size (~10MB)
- ❌ Learning curve for Firestore data modeling
- ❌ Security rules can be complex for multi-user scenarios

#### Implementation Complexity
**Medium-High** - 50-80 hours
- Replace repository layer entirely
- Integrate Firebase Authentication
- Design security rules for team-based access
- Migrate existing local data on first launch

#### Cost Analysis
- **Free tier (Spark plan):** 1GB storage, 50k reads/day, 20k writes/day, 10GB/month transfer
- **Paid tier (Blaze plan):** $0.18/GB storage, $0.06/100k reads, $0.18/100k writes
- **Realistic cost:** $0/month for small teams, $5-15/month for active teams

#### iOS-Specific Considerations
- Add Firebase SDK via Swift Package Manager
- GoogleService-Info.plist required for configuration
- Background fetch limitations on iOS (no true background listeners)
- Use Firebase Cloud Messaging for background sync triggers

#### Impact on Current Architecture
Moderate impact - replaces existing repository implementations entirely.

```swift
// Replace existing repositories
actor FirestoreShiftTypeRepository: ShiftTypeRepository {
    private let db: Firestore
    private let teamId: String

    func fetchAll() async throws -> [ShiftType] {
        let snapshot = try await db.collection("teams/\(teamId)/shiftTypes").getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: ShiftType.self) }
    }
}

// New middleware for real-time listeners
func firestoreListenerMiddleware(...) async {
    // Attach Firestore snapshot listeners on app start
    // Dispatch Redux actions when remote data changes
}
```

---

### Option 3: Custom Swift Backend (Vapor) + PostgreSQL

**Description:**
Build a custom backend API using Vapor (Swift server framework) with PostgreSQL database. Full control over sync logic, conflict resolution, and API design.

#### Key Technologies
- Vapor 4 (Swift web framework)
- PostgreSQL (relational database)
- Fluent ORM (Vapor's database toolkit)
- WebSockets for real-time updates (optional)
- JWT authentication

#### Implementation Approach

**Backend API Design:**
- RESTful endpoints: `POST /api/shiftTypes`, `GET /api/locations`, etc.
- GraphQL alternative for flexible querying
- WebSocket endpoint for live updates

**Database Schema:**
- PostgreSQL tables: `locations`, `shift_types`, `scheduled_shifts`, `users`, `teams`
- Foreign key constraints for referential integrity
- Triggers for change log tracking

**Sync Protocol:**
- Pull-based: Client requests data with `lastSyncTimestamp`
- Push-based: Client uploads local changes with conflict detection
- Vector clocks or Lamport timestamps for causality

**Deployment Options:**
- Heroku (easiest, $5/month hobby dyno + $9/month Postgres)
- AWS Lightsail or DigitalOcean ($10-20/month VPS)
- Fly.io (excellent for Vapor apps, generous free tier)

#### Advantages
- ✅ Full control over sync logic and conflict resolution
- ✅ No vendor lock-in (platform-agnostic)
- ✅ Can add advanced features (analytics, admin dashboard, webhooks)
- ✅ Swift on server and client (code sharing, type safety)
- ✅ Relational database for complex queries and data integrity

#### Disadvantages
- ❌ Requires backend development, deployment, and maintenance
- ❌ No free tier (minimum $5-15/month hosting)
- ❌ Must handle server uptime, scaling, backups
- ❌ Security responsibility (authentication, HTTPS, SQL injection prevention)
- ❌ Significantly more development effort

#### Implementation Complexity
**High** - 100-150 hours
- Backend API development: 60 hours
- Client integration: 40 hours
- Deployment, monitoring, CI/CD: 20 hours
- Testing across devices: 20 hours

#### Cost Analysis
- **Development:** Significant upfront engineering time
- **Hosting:** $5-20/month (Heroku Hobby, DigitalOcean, AWS Lightsail)
- **Database:** $9-50/month (Heroku Postgres, AWS RDS)
- **Realistic total:** $15-70/month depending on scale

#### iOS-Specific Considerations
- URLSession for HTTP requests (async/await networking)
- Keychain for secure token storage
- Background URLSession for background sync
- Combine for WebSocket real-time updates (optional)

#### Impact on Current Architecture
Significant impact - introduces network layer and changes how data flows.

```swift
// New networking service
protocol NetworkServiceProtocol: Sendable {
    func fetchShiftTypes(since: Date?) async throws -> [ShiftType]
    func uploadShiftType(_ shiftType: ShiftType) async throws
}

// Modified repositories to use network service
actor NetworkBackedShiftTypeRepository: ShiftTypeRepository {
    private let networkService: NetworkServiceProtocol
    private let localCache: LocalShiftTypeRepository

    func fetchAll() async throws -> [ShiftType] {
        do {
            let remote = try await networkService.fetchShiftTypes(since: lastSyncDate)
            try await localCache.saveAll(remote)
            return remote
        } catch {
            return try await localCache.fetchAll()
        }
    }
}
```

---

### Option 4: Peer-to-Peer Sync (MultipeerConnectivity)

**Description:**
Use Apple's MultipeerConnectivity framework for local, device-to-device synchronization without internet. Devices discover each other via Bluetooth/WiFi and exchange data directly.

#### Key Technologies
- MultipeerConnectivity (Bonjour discovery, peer-to-peer networking)
- Codable for message serialization
- CRDT (Conflict-free Replicated Data Types) for eventual consistency

#### Implementation Approach

**Peer Discovery:**
- MCNearbyServiceAdvertiser (broadcast availability)
- MCNearbyServiceBrowser (discover nearby devices)
- MCSession for bidirectional communication

**Sync Protocol:**
- Exchange full state on connection (initial sync)
- Delta updates for incremental changes
- CRDTs or logical clocks for conflict-free merges

**Data Model:**
- Replace `id: UUID` with CRDT-friendly IDs (Lamport timestamps + device ID)
- Use LWW (Last-Write-Wins) registers for simple fields
- Operation-based CRDTs for collections

**User Experience:**
- Manual "Sync with nearby device" button
- Automatic background sync when devices are nearby
- Visual indicator of sync status

#### Advantages
- ✅ Zero ongoing costs (no server required)
- ✅ Works fully offline (no internet dependency)
- ✅ Privacy-first (data never leaves local network)
- ✅ Native iOS framework (no third-party dependencies)
- ✅ Excellent for families/small teams in same location

#### Disadvantages
- ❌ Requires devices to be physically nearby (Bluetooth range ~30ft, WiFi ~100ft)
- ❌ No cloud backup (data only on synced devices)
- ❌ Complex conflict resolution (must implement CRDTs or similar)
- ❌ Not scalable beyond 8-10 simultaneous devices
- ❌ Can't sync when users are in different locations

#### Implementation Complexity
**High** - 80-120 hours
- MultipeerConnectivity integration: 30 hours
- CRDT implementation or library integration: 40 hours
- Conflict resolution testing: 30 hours
- UI for peer management: 20 hours

#### Cost Analysis
- **Zero recurring costs** (no servers, no subscriptions)
- **Development cost only** (one-time engineering effort)

#### iOS-Specific Considerations
- Requires `Bonjour services` entitlement
- Background modes limited (connection drops in background)
- Privacy prompt for local network access (iOS 14+)
- MCSession can be flaky (reconnection logic required)

#### Impact on Current Architecture
Significant impact - adds peer sync layer alongside local storage.

```swift
// New peer sync service
actor MultipeerSyncService: Sendable {
    private let session: MCSession

    func broadcastChange(_ change: SyncMessage) async throws
    func requestFullSync(from peer: MCPeerID) async throws
    func mergeIncomingData(_ data: SyncMessage) async throws
}

// CRDT-based models
struct CRDTShiftType: Codable, Sendable {
    let id: UUID
    var symbol: LWWRegister<String>
    var title: LWWRegister<String>

    mutating func merge(with other: CRDTShiftType) {
        symbol.merge(with: other.symbol)
        title.merge(with: other.title)
    }
}
```

---

### Option 5: Hybrid iCloud + Local-First (Recommended) ⭐

**Description:**
Combine iCloud CloudKit for convenient cloud sync with robust local-first architecture. Use CloudKit as an eventual-consistency sync layer while maintaining full offline capability. This is the recommended approach for ShiftScheduler.

#### Key Technologies
- CloudKit for cloud storage and sync
- Local JSON files as primary source of truth
- CKSyncEngine (iOS 17+) for automated sync
- EventKit with iCloud calendar (already in place)

#### Implementation Approach

**Local-First Philosophy:**
- All reads/writes happen against local JSON files (fast, offline)
- CloudKit runs as background sync process
- UI never blocks on network operations

**Sync Engine Design:**
- Use CKSyncEngine (iOS 17+) for automatic scheduling
- Fallback to manual CKFetchRecordZoneChangesOperation (iOS 16)
- Upload queue for local changes
- Conflict resolution: three-way merge with common ancestor

**Data Flow:**
```
User Action → Redux → Local Repository (immediate) → CloudKit (async)
CloudKit Change → Sync Middleware → Merge → Redux → UI Update
```

**Conflict Resolution:**
- Detect conflicts via CKRecord.modificationDate
- Fetch common ancestor from server history
- Three-way merge algorithm (base, local, remote)
- User override for unresolvable conflicts

#### Advantages
- ✅ **Best of both worlds:** Instant local UX + cloud backup
- ✅ **Zero-cost cloud sync** (CloudKit free tier)
- ✅ **Works perfectly offline** (local files are authoritative)
- ✅ **Gradual rollout** (can ship without CloudKit, add later)
- ✅ **Leverages existing iCloud calendar sync** for ScheduledShifts
- ✅ **Minimal architectural changes** (doesn't replace existing repositories)
- ✅ **Proven pattern** (used by Apple's own apps - Notes, Reminders)

#### Disadvantages
- ❌ Apple ecosystem only (no Android/web support)
- ❌ More complex than pure cloud solution
- ❌ Must handle sync state management carefully
- ❌ Requires iOS 17+ for best sync engine APIs (iOS 16 fallback available)

#### Implementation Complexity
**Medium** - 50-70 hours
- CKSyncEngine integration: 25 hours
- Conflict resolution logic: 20 hours
- Testing multi-device scenarios: 15 hours
- Migration from local-only: 10 hours

#### Cost Analysis
- **CloudKit free tier:** 10GB storage, 2GB/day transfer
- **Zero monthly cost** for typical usage
- **Paid tier:** Only if scaling beyond free tier limits

#### iOS-Specific Considerations
- iOS 17+ recommended for CKSyncEngine (best experience)
- iOS 16 fallback with manual fetch operations
- iCloud capability required in Xcode entitlements
- Background refresh for periodic sync
- Already using iCloud calendar infrastructure

#### Impact on Current Architecture
Minimal impact - adds sync service without replacing existing code.

```swift
// Minimal changes to existing code
// Add sync status to state
struct AppState: Equatable {
    var syncStatus: SyncStatus = .synced
    var lastSyncDate: Date? = nil
}

// New sync service (doesn't replace existing repositories)
actor CloudKitSyncService: Sendable {
    func uploadPendingChanges() async throws
    func downloadRemoteChanges() async throws
    func resolveConflict(local: ShiftType, remote: ShiftType, base: ShiftType?) -> ShiftType
}

// Lightweight middleware
func cloudKitSyncMiddleware(...) async {
    case .shiftTypes(.saved):
        await cloudKitSyncService.uploadPendingChanges()
    case .app(.didEnterForeground):
        await cloudKitSyncService.downloadRemoteChanges()
}
```

---

## Comparison Matrix

| Criteria | Option 1: CloudKit | Option 2: Firebase | Option 3: Custom Backend | Option 4: P2P | Option 5: Hybrid (Recommended) |
|----------|-------------------|-------------------|-------------------------|---------------|-------------------------------|
| **Implementation Time** | 40-60 hrs | 50-80 hrs | 100-150 hrs | 80-120 hrs | 50-70 hrs |
| **Monthly Cost** | $0-20 | $0-15 | $15-70 | $0 | $0 |
| **Offline Support** | Good | Excellent | Depends | Excellent | **Excellent** |
| **Real-time Sync** | Good | Excellent | Good | Good | Good |
| **Multi-platform** | Apple only | iOS/Android/Web | iOS/Android/Web | Apple only | Apple only |
| **Vendor Lock-in** | High | High | None | None | High |
| **Infrastructure Maintenance** | None | None | High | None | None |
| **Complexity** | Medium | Medium-High | High | High | **Medium** |
| **iOS Integration** | Native | SDK | Custom | Native | Native |
| **Scalability** | Excellent | Excellent | Varies | Limited (8-10 devices) | Excellent |
| **Backend Required** | No | No | **Yes** | No | No |
| **Recommended For** | Apple-only, simple | Multi-platform, teams | Enterprise, custom needs | Same location, offline | **All ShiftScheduler users** |

---

## Conflict Resolution Scenarios

### Scenario 1: Same ShiftType Edited Simultaneously
**Problem:** User A changes shift duration while User B changes shift title simultaneously.

**Resolution (Hybrid Option 5):**
- Local writes happen immediately
- CloudKit server detects conflict (timestamp check)
- Three-way merge: compare local, remote, and common ancestor
- Merge both changes if non-conflicting fields
- Present UI if true conflict (same field edited differently)

### Scenario 2: Same Location Referenced by Multiple ShiftTypes
**Problem:** Location is deleted while ShiftTypes still reference it.

**Resolution:**
- Cascade update: ShiftTypes change location reference to null or default
- Already implemented in PersistenceService (lines 48-76)
- Sync sends updated ShiftTypes to CloudKit

### Scenario 3: Location Created on Device A, Referenced on Device B
**Problem:** Device B tries to reference Location that doesn't exist locally yet.

**Resolution:**
- Sync middleware fetches missing Location from CloudKit
- Resolves reference before applying ShiftType
- Queues operation if Location still unavailable

---

## Recommended Approach: Option 5 (Hybrid iCloud + Local-First)

### Why This Option?

**For ShiftScheduler's use case:**
1. **Family/small team size** (2-10 users) - doesn't need enterprise features
2. **Shift workers need offline access** - local-first critical
3. **Already using iCloud** (CalDAV for EventKit) - consistent UX
4. **Zero ongoing costs** - CloudKit free tier sufficient
5. **Minimal architectural disruption** - doesn't replace existing code
6. **iOS-focused app** - Apple ecosystem optimization acceptable
7. **Can ship incrementally** - local app works now, CloudKit adds later

### Implementation Phases

#### Phase 1: CloudKit Foundation (2 weeks)
- Add CloudKit entitlements to Xcode project
- Create CloudKitSyncService with basic upload/download
- Add ShiftType and Location sync for 2-device scenario
- Test with simulator and physical device

#### Phase 2: Conflict Resolution (1 week)
- Implement three-way merge algorithm
- Add conflict detection via timestamps
- Create conflict resolution UI (Sheet showing local vs. remote)
- Handle unresolvable conflicts with user choice

#### Phase 3: User Experience (1 week)
- Add sync status indicator in navigation bar
- Show "Syncing..." during operations
- Display last sync timestamp
- Handle sync errors with user-friendly messages

#### Phase 4: Testing & Polish (1 week)
- Test with 3+ devices simultaneously
- Test offline/online transitions
- Test with poor connectivity (throttle network)
- Verify undo/redo stacks sync correctly

---

## Implementation Roadmap (Option 5)

### Week 1: Foundation
- [ ] Create `CloudKitSyncService.swift` with basic structure
- [ ] Create `SyncStatus` enum in AppState
- [ ] Create `SyncAction` cases in AppReducer
- [ ] Create sync middleware (initially empty)

### Week 2: Upload & Download
- [ ] Implement `uploadShiftTypes()` and `uploadLocations()`
- [ ] Implement `downloadShiftTypes()` and `downloadLocations()`
- [ ] Handle CKRecord serialization for Codable models
- [ ] Test with two devices

### Week 3: Conflict Resolution
- [ ] Implement three-way merge algorithm
- [ ] Create `ConflictResolutionView`
- [ ] Detect conflicts via timestamps and checksums
- [ ] User selection between local/remote/merged versions

### Week 4: Polish
- [ ] Sync status indicator in UI
- [ ] Last sync timestamp display
- [ ] Error handling and retry logic
- [ ] Documentation and deployment

---

## Alternative: Starting with Option 1 (Pure CloudKit)

If you prefer **not** to maintain local JSON files alongside CloudKit:

- Simpler data model (single source of truth in CloudKit)
- Offline experience degraded (cached data only)
- Implementation: 40-50 hours
- Use `CKSyncEngine` to manage all state
- Cost: Still free tier sufficient

---

## Security & Privacy Considerations

### Authentication
- Use CloudKit User Record for multi-user scenarios
- Associate shifts with user IDs
- Implement team-based access control

### Data Protection
- CloudKit encrypts data in transit (HTTPS)
- CloudKit encrypts data at rest on Apple servers
- Local JSON files: use FileManager with protection classes

### User Privacy
- CloudKit stores user identifiers on Apple servers
- Consider privacy implications for family sharing
- Users can delete account and data from iCloud Settings

### Audit Trail
- ChangeLogEntry already tracks `userId` and `userDisplayName`
- Sync all change log entries to CloudKit
- Maintain history of who changed what when

---

## Risks & Mitigation

### Risk 1: CloudKit Service Outage
**Impact:** Users can't sync new data
**Mitigation:** Local files remain authoritative, app works offline

### Risk 2: Data Corruption During Sync
**Impact:** Conflicting versions of truth
**Mitigation:** Three-way merge, version numbers, rollback capability

### Risk 3: User Confusion About Sync State
**Impact:** Users don't know if changes are safe
**Mitigation:** Clear sync status UI, last sync timestamp display

### Risk 4: Large Data Volume Exceeds Free Tier
**Impact:** Sync slowdown or paid charges
**Mitigation:** Monitor usage, implement data cleanup for old shifts

---

## Next Steps

1. **Prototype Phase 1** (CloudKit Foundation)
   - Create basic sync service
   - Test with 2 devices
   - Validate merge logic

2. **Gather Feedback**
   - Test with actual users
   - Measure sync performance
   - Identify edge cases

3. **Decide on Multi-User Experience**
   - User invitations via email/code
   - Team vs. individual shift management
   - Permission model (view-only vs. edit)

4. **Plan Phase 4B-4D Testing** (from CLAUDE.md)
   - Unit tests for CloudKit sync service
   - Integration tests for multi-device scenarios
   - View interaction tests for sync UI

---

## Related Documentation

- **Redux Architecture:** See CLAUDE.md (Phase 3: Redux Foundation)
- **Service Layer:** See ServiceContainer.swift
- **Testing Strategy:** See TEST_QUALITY_REVIEW.md
- **Project Roadmap:** See TCA_PHASE2B_TASK_CHECKLIST.md

---

## Decision

**Recommended Option:** Option 5 - Hybrid iCloud + Local-First

**Justification:**
- Best balance of UX, cost, and implementation complexity
- Minimal disruption to current architecture
- Leverages existing EventKit + iCloud integration
- Can be shipped incrementally
- Proven pattern used by Apple's own productivity apps

**Expected Timeline:** 4 weeks (50-70 hours)

**Next Action:** Prototype Phase 1 (CloudKit Foundation) with 2-device testing

---

**Document Version:** 1.0
**Last Updated:** December 9, 2025
**Next Review:** After Option 5 Phase 1 prototype completion
