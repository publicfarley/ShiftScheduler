#!/usr/bin/env swift

import Foundation

// MARK: - Models (copied from your app)

struct Location: Codable {
    let id: UUID
    let name: String
    let address: String
}

struct HourMinuteTime: Codable {
    let hour: Int
    let minute: Int
}

enum ShiftDuration: Codable {
    case allDay
    case scheduled(from: HourMinuteTime, to: HourMinuteTime)

    enum CodingKeys: String, CodingKey {
        case allDay, scheduled
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .allDay:
            var nestedContainer = container.nestedContainer(keyedBy: EmptyKeys.self, forKey: .allDay)
            _ = nestedContainer
        case .scheduled(let from, let to):
            var nestedContainer = container.nestedContainer(keyedBy: ScheduledKeys.self, forKey: .scheduled)
            try nestedContainer.encode(from, forKey: .from)
            try nestedContainer.encode(to, forKey: .to)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if container.contains(.allDay) {
            self = .allDay
        } else if let nestedContainer = try? container.nestedContainer(keyedBy: ScheduledKeys.self, forKey: .scheduled) {
            let from = try nestedContainer.decode(HourMinuteTime.self, forKey: .from)
            let to = try nestedContainer.decode(HourMinuteTime.self, forKey: .to)
            self = .scheduled(from: from, to: to)
        } else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Invalid duration"))
        }
    }

    private enum EmptyKeys: CodingKey {}
    private enum ScheduledKeys: String, CodingKey {
        case from, to
    }
}

struct ShiftType: Codable {
    let id: UUID
    let symbol: String
    let duration: ShiftDuration
    let title: String
    let shiftDescription: String
    let location: Location
}

// MARK: - Recovery Data from Logs

// UUIDs extracted from your logs:
// A224438B-F8D2-4EF0-8D82-0618A8A5C717 - "Day" / "Day Shift"
// 44F7B08C-7679-4C0C-A021-8A6E9F66C46B - "Off"
// AD3712F1-511E-45A4-9004-6257EDF6E92B - "Generic Weekend Daytime Bench"
// 06078D1A-35B0-438F-BF4C-F2979D8EE5F9 - "Day Bench On Holiday"

// Backup data I found in your old simulator container:
// Locations:
// - CB268486-AF5F-434E-B81B-3A4F14DC91BE: Home (123 Baskets Rd., Bakersville, Ontario L5R T3T)
// - 6DDC216E-FCB1-4BAC-B5A4-84E46E36C401: Work (546 GetErDone Ave., Work Town, Petina 2Y2 U8K)

// ShiftTypes from backup:
// - 0AD4665F-E423-46AD-8145-DF32F4364876: "Off" (X, allDay, Home)
// - A474ADC4-B8D1-4BD7-8FE2-22442996F63B: "My Vacation" (Vacation, allDay, Home)
// - 9F0D7F1C-CA5E-477B-A100-F089D1CC31B3: "Dayi Shift" (d, 08:00-16:00, Work)
// - 7B61519A-0971-4829-9DEC-7CD0E7B71D19: "Night" (n, 23:00-07:00, Work)

let home = Location(
    id: UUID(uuidString: "CB268486-AF5F-434E-B81B-3A4F14DC91BE")!,
    name: "Home",
    address: "123 Baskets Rd.\nBakersville, Ontario\nL5R T3T"
)

let work = Location(
    id: UUID(uuidString: "6DDC216E-FCB1-4BAC-B5A4-84E46E36C401")!,
    name: "Work",
    address: "546 GetErDone Ave.\nWork Town, Petina\n2Y2 U8K"
)

// OPTION 1: Recreate from backup data (recommended)
let shiftTypesFromBackup: [ShiftType] = [
    ShiftType(
        id: UUID(uuidString: "0AD4665F-E423-46AD-8145-DF32F4364876")!,
        symbol: "❌",
        duration: .allDay,
        title: "Off",
        shiftDescription: "",
        location: home
    ),
    ShiftType(
        id: UUID(uuidString: "A474ADC4-B8D1-4BD7-8FE2-22442996F63B")!,
        symbol: "🏖️",
        duration: .allDay,
        title: "My Vacation",
        shiftDescription: "",
        location: home
    ),
    ShiftType(
        id: UUID(uuidString: "9F0D7F1C-CA5E-477B-A100-F089D1CC31B3")!,
        symbol: "☀️",
        duration: .scheduled(
            from: HourMinuteTime(hour: 8, minute: 0),
            to: HourMinuteTime(hour: 16, minute: 0)
        ),
        title: "Dayi Shift",
        shiftDescription: "",
        location: work
    ),
    ShiftType(
        id: UUID(uuidString: "7B61519A-0971-4829-9DEC-7CD0E7B71D19")!,
        symbol: "🌙",
        duration: .scheduled(
            from: HourMinuteTime(hour: 23, minute: 0),
            to: HourMinuteTime(hour: 7, minute: 0)
        ),
        title: "Night",
        shiftDescription: "",
        location: work
    )
]

// OPTION 2: Recreate shift types from calendar events (using UUIDs from logs)
// Note: You'll need to provide the correct symbols and details
let shiftTypesFromLogs: [ShiftType] = [
    ShiftType(
        id: UUID(uuidString: "A224438B-F8D2-4EF0-8D82-0618A8A5C717")!,
        symbol: "☀️",  // CHANGE THIS to your actual symbol
        duration: .scheduled(
            from: HourMinuteTime(hour: 8, minute: 0),
            to: HourMinuteTime(hour: 16, minute: 0)
        ),
        title: "Day Shift",
        shiftDescription: "",
        location: work  // CHANGE if needed
    ),
    ShiftType(
        id: UUID(uuidString: "44F7B08C-7679-4C0C-A021-8A6E9F66C46B")!,
        symbol: "❌",  // CHANGE THIS to your actual symbol
        duration: .allDay,
        title: "Off",
        shiftDescription: "",
        location: home  // CHANGE if needed
    ),
    ShiftType(
        id: UUID(uuidString: "AD3712F1-511E-45A4-9004-6257EDF6E92B")!,
        symbol: "🏢",  // CHANGE THIS to your actual symbol
        duration: .scheduled(
            from: HourMinuteTime(hour: 9, minute: 0),
            to: HourMinuteTime(hour: 17, minute: 0)
        ),
        title: "Generic Weekend Daytime Bench",
        shiftDescription: "",
        location: work  // CHANGE if needed
    ),
    ShiftType(
        id: UUID(uuidString: "06078D1A-35B0-438F-BF4C-F2979D8EE5F9")!,
        symbol: "🎉",  // CHANGE THIS to your actual symbol
        duration: .scheduled(
            from: HourMinuteTime(hour: 9, minute: 0),
            to: HourMinuteTime(hour: 17, minute: 0)
        ),
        title: "Day Bench On Holiday",
        shiftDescription: "",
        location: work  // CHANGE if needed
    )
]

// MARK: - Main Recovery Logic

print("ShiftScheduler Data Recovery Script")
print("====================================\n")

// Find the current app container
let fileManager = FileManager.default
let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
let dataDirectory = documentsPath.appendingPathComponent("ShiftSchedulerData", isDirectory: true)

print("Target directory: \(dataDirectory.path)\n")

// Create directory if it doesn't exist
try fileManager.createDirectory(at: dataDirectory, withIntermediateDirectories: true)

// Choose which data to restore
print("Choose recovery option:")
print("1. Restore from backup data (4 shift types from old container)")
print("2. Restore from calendar logs (4 shift types using UUIDs from logs)")
print("3. Restore both (will merge, keeping unique shift types)")
print("\nEnter 1, 2, or 3: ", terminator: "")

guard let input = readLine(), let choice = Int(input), (1...3).contains(choice) else {
    print("Invalid choice. Exiting.")
    exit(1)
}

var shiftTypesToRestore: [ShiftType] = []

switch choice {
case 1:
    shiftTypesToRestore = shiftTypesFromBackup
    print("\nRestoring from backup data...")
case 2:
    shiftTypesToRestore = shiftTypesFromLogs
    print("\nRestoring from log UUIDs...")
case 3:
    // Merge both, removing duplicates by ID
    var merged = shiftTypesFromBackup
    for logType in shiftTypesFromLogs {
        if !merged.contains(where: { $0.id == logType.id }) {
            merged.append(logType)
        }
    }
    shiftTypesToRestore = merged
    print("\nRestoring both sources (merged)...")
default:
    break
}

// Save Locations
let locations = [home, work]
let locationsURL = dataDirectory.appendingPathComponent("locations.json")
let locationsData = try JSONEncoder().encode(locations)
try locationsData.write(to: locationsURL, options: .atomic)
print("✅ Restored \(locations.count) locations")

// Save ShiftTypes
let shiftTypesURL = dataDirectory.appendingPathComponent("shiftTypes.json")
let shiftTypesData = try JSONEncoder().encode(shiftTypesToRestore)
try shiftTypesData.write(to: shiftTypesURL, options: .atomic)
print("✅ Restored \(shiftTypesToRestore.count) shift types")

print("\n====================================")
print("Recovery Complete!")
print("====================================\n")
print("Restored Locations:")
for location in locations {
    print("  - \(location.name) (\(location.id))")
}
print("\nRestored Shift Types:")
for shiftType in shiftTypesToRestore {
    print("  - \(shiftType.title) (\(shiftType.id)) - Symbol: \(shiftType.symbol)")
}

print("\nNow restart your app to see the restored data.")
print("Your calendar events should now load correctly!")
