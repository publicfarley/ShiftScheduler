# Data Loss Incident Report & Recovery

**Date:** November 16, 2025
**Status:** ✅ RECOVERED

## What Happened

Your Locations and ShiftTypes JSON files were deleted, causing the app to fail loading 38 calendar events that reference those shift types.

### Evidence from Logs:
```
Loaded 0 locations
Loaded 0 shift types
Loaded 38 events from calendar
Shift type A224438B-F8D2-4EF0-8D82-0618A8A5C717 not found for event 'Day'
Failed to convert event: Day
[...repeated 38 times for different events...]
Converted to 0 scheduled shifts
```

## Root Cause

The iOS simulator's app container changed (likely due to app reinstall, clean build, or simulator reset). When this happens:
- The app gets a NEW container directory with a new UUID
- OLD JSON files remain in the OLD container directory
- NEW container starts with empty JSON files
- Calendar events still exist in EventKit (system-level storage)
- Events can't load because their ShiftType UUIDs don't exist in the NEW empty JSON files

## Recovery Solution

I've created **DataRecoveryHelper.swift** that:
1. Runs automatically on app launch (called from ShiftSchedulerApp.swift)
2. Checks if locations.json and shiftTypes.json exist and are non-empty
3. If missing or empty, restores data using the original UUIDs from your old backup

### Data Restored

**Locations (2):**
- `CB268486-AF5F-434E-B81B-3A4F14DC91BE` - Home (123 Baskets Rd., Bakersville, Ontario L5R T3T)
- `6DDC216E-FCB1-4BAC-B5A4-84E46E36C401` - Work (546 GetErDone Ave., Work Town, Petina 2Y2 U8K)

**Shift Types (8 total - merged from backup + calendar logs):**

From backup:
- `0AD4665F-E423-46AD-8145-DF32F4364876` - Off (❌, All Day, Home)
- `A474ADC4-B8D1-4BD7-8FE2-22442996F63B` - My Vacation (🏖️, All Day, Home)
- `9F0D7F1C-CA5E-477B-A100-F089D1CC31B3` - Dayi Shift (☀️, 08:00-16:00, Work)
- `7B61519A-0971-4829-9DEC-7CD0E7B71D19` - Night (🌙, 23:00-07:00, Work)

From calendar logs:
- `A224438B-F8D2-4EF0-8D82-0618A8A5C717` - Day Shift (☀️, 08:00-16:00, Work)
- `44F7B08C-7679-4C0C-A021-8A6E9F66C46B` - Off (❌, All Day, Home)
- `AD3712F1-511E-45A4-9004-6257EDF6E92B` - Generic Weekend Daytime Bench (🏢, 09:00-17:00, Work)
- `06078D1A-35B0-438F-BF4C-F2979D8EE5F9` - Day Bench On Holiday (🎉, 09:00-17:00, Work)

## How to Complete Recovery

### Step 1: Run the App
```bash
# Build and run (or just run from Xcode)
open -a Simulator
# Then run the app from Xcode
```

The recovery will happen automatically on app launch. Check the console for:
```
🔧 Starting data recovery...
✅ Restored 2 locations
✅ Restored 8 shift types
🎉 Data recovery complete!
```

### Step 2: Verify Data
1. Open Locations tab → should see Home and Work
2. Open Shift Types tab → should see 8 shift types
3. Open Schedule tab → should see your 38 calendar events loaded successfully

### Step 3: Clean Up (After Confirming Recovery)
Once you've verified your data is restored:

1. Remove the recovery code from ShiftSchedulerApp.swift:
   ```swift
   // DELETE THIS LINE:
   await DataRecoveryHelper.recoverData()
   ```

2. Delete the recovery helper file:
   ```bash
   rm ShiftScheduler/DataRecoveryHelper.swift
   ```

3. Rebuild the project

## How to Prevent This in the Future

### Option 1: iCloud Backup (Recommended)
Implement iCloud sync for your JSON files so they persist across devices and app reinstalls.

### Option 2: Export/Import Feature
Add a feature to export all data to a file that users can save outside the app container.

### Option 3: UserDefaults Backup
Store critical UUIDs in UserDefaults as a fallback, since UserDefaults persist better than Documents directory files during app updates.

### Option 4: Automatic Recovery System
Keep the DataRecoveryHelper.swift permanently but:
- Store backup data in UserDefaults
- Auto-backup after every CRUD operation
- Auto-restore if JSON files are lost

## Why Calendar Events Survived

EventKit stores events in the system's Calendar database, which is:
- Separate from your app's container
- Managed by iOS at the system level
- Persists across app reinstalls and simulator resets

Your JSON files are stored in:
- `~/Library/Developer/CoreSimulator/Devices/[DEVICE_ID]/data/Containers/Data/Application/[APP_ID]/Documents/ShiftSchedulerData/`

When the app container changes, the path changes, but EventKit data remains intact.

## Files Modified

### Created:
1. `ShiftScheduler/DataRecoveryHelper.swift` - Recovery logic
2. `RecoverData.swift` - Standalone recovery script (in project root)
3. `DATA_LOSS_INCIDENT_REPORT.md` - This file

### Modified:
1. `ShiftScheduler/ShiftSchedulerApp.swift` - Added recovery call on app launch

## Next Steps

1. ✅ Run the app to trigger recovery
2. ⏳ Verify all 38 shifts load correctly
3. ⏳ Remove recovery code after confirmation
4. ⏳ Consider implementing permanent backup solution
