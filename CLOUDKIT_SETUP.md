# CloudKit Schema Setup Guide for ShiftScheduler

## Overview

ShiftScheduler uses CloudKit Public Database to sync shift types and locations across different iCloud accounts. The CloudKit schema must be created manually via the CloudKit Dashboard.

## Prerequisites

- Apple Developer account with CloudKit access
- ShiftScheduler container: `iCloud.com.functioncraft.ShiftScheduler`
- Access to iCloud CloudKit Dashboard

---

## Setup Steps

### 1. Access CloudKit Dashboard

1. Visit: [https://icloud.developer.apple.com/dashboard](https://icloud.developer.apple.com/dashboard)
2. Sign in with your Apple Developer account
3. Select container: `iCloud.com.functioncraft.ShiftScheduler`
4. Switch to **Development** environment (for initial testing)

### 2. Create ShiftType Record Type

1. Navigate to: **Schema → Record Types**
2. Click: **Add Record Type** (+)
3. Record Type Name: `ShiftType`
4. Add the following fields:

| Field Name | Type | Indexed | Sortable | Notes |
|------------|------|---------|----------|-------|
| `recordID` | String | ✅ QUERYABLE | - | Maps to ShiftType.id |
| `symbol` | String | - | - | Shift symbol emoji |
| `title` | String | ✅ QUERYABLE | ✅ | For sorting and searching |
| `shiftDescription` | String | - | - | Shift description text |
| `locationID` | String | ✅ QUERYABLE | - | Reference to Location record |
| `locationName` | String | - | - | Denormalized location name |
| `locationAddress` | String | - | - | Denormalized location address |
| `durationData` | Bytes | - | - | Encoded ShiftDuration enum |
| `modifiedAt` | Date/Time | ✅ QUERYABLE | ✅ | For conflict resolution |

5. Click **Save**

### 3. Create Location Record Type

1. Navigate to: **Schema → Record Types**
2. Click: **Add Record Type** (+)
3. Record Type Name: `Location`
4. Add the following fields:

| Field Name | Type | Indexed | Sortable | Notes |
|------------|------|---------|----------|-------|
| `recordID` | String | ✅ QUERYABLE | - | Maps to Location.id |
| `name` | String | ✅ QUERYABLE | ✅ | For sorting and searching |
| `address` | String | - | - | Location address |
| `modifiedAt` | Date/Time | ✅ QUERYABLE | ✅ | For conflict resolution |

5. Click **Save**

### 4. Verify Schema in Development

1. Build and run ShiftScheduler on a simulator or development device
2. Create a test shift type and location
3. Check CloudKit Dashboard → Data → Public Database
4. Verify records appear in `ShiftType` and `Location` tables

### 5. Deploy Schema to Production

⚠️ **IMPORTANT:** Only deploy to production after thorough testing in development.

1. Navigate to: **Schema → Deploy Schema Changes**
2. Review all changes (should show ShiftType and Location record types)
3. Click **Deploy to Production**
4. **This is one-way** - Production schema changes cannot be undone

### 6. Test Production Sync

1. Build app in Release configuration
2. Install on two different devices with different iCloud accounts
3. Create shift types on Device A
4. Wait 30 seconds
5. Verify shift types appear on Device B

---

## Troubleshooting

### "Did not find record type" errors

**Cause:** Schema not deployed to the environment you're running in.

**Solution:**
- Development: Schema should auto-create on first save, or manually create via Dashboard
- Production: Must manually deploy schema via CloudKit Dashboard (Step 5 above)

### Records not syncing between devices

**Checklist:**
- ✅ Schema deployed to production (if using production environment)
- ✅ Both devices signed into iCloud
- ✅ iCloud Drive enabled in Settings
- ✅ ShiftScheduler has iCloud permission
- ✅ Network connection available
- ✅ Check CloudKit Dashboard → Data → verify records exist

### Query performance is slow

**Solution:** Verify indexes are created:
- `ShiftType.title` - QUERYABLE
- `ShiftType.modifiedAt` - QUERYABLE
- `Location.name` - QUERYABLE
- `Location.modifiedAt` - QUERYABLE

---

## Schema Version

**Current Version:** 1.0
**Last Updated:** 2026-02-13
**Record Types:** ShiftType, Location
**Container:** iCloud.com.functioncraft.ShiftScheduler
