import Foundation

struct Location {
    let name: String
    let address: String
}

struct ShiftType {
    struct Symbol {
        let rawValue: String
        
        init?(_ rawValue: String) {
            guard !rawValue.isEmpty,
                  rawValue.count <= 3,
                  rawValue.allSatisfy({ $0.isLetter || $0.isNumber }) else {
                return nil
            }
            self.rawValue = rawValue
        }
    }
    
    let symbol: Symbol
    let startTime: DateComponents
    let endTime: DateComponents
    let title: String
    let description: String
    let location: Location
}

struct ShiftCatalog {
    private var items: [ShiftType] = []
    
    mutating func add(_ shiftType: ShiftType) {
        items.append(shiftType)
    }
    
    func all() -> [ShiftType] {
        items
    }
}

final class InMemoryShiftCatalogRepository {
    private var storage: ShiftCatalog?
    
    func save(_ catalog: ShiftCatalog) throws {
        storage = catalog
    }
    
    func load() throws -> ShiftCatalog {
        if let stored = storage {
            return stored
        } else {
            return ShiftCatalog()
        }
    }
}

struct ScheduledShift {
    let shiftType: ShiftType
    let date: Date
}

struct Schedule {
    enum Error: Swift.Error {
        case duplicateAssignment
    }
    
    private var items: [ScheduledShift] = []
    
    mutating func assign(_ scheduledShift: ScheduledShift) throws {
        for item in items {
            if item.shiftType.symbol.rawValue == scheduledShift.shiftType.symbol.rawValue &&
                Calendar.current.isDate(item.date, inSameDayAs: scheduledShift.date) {
                throw Error.duplicateAssignment
            }
        }
        items.append(scheduledShift)
    }
    
    func all() -> [ScheduledShift] {
        items
    }
}

final class InMemoryScheduleRepository {
    private var storage: [ScheduledShift] = []
    
    func save(_ schedule: Schedule) throws {
        storage = schedule.all()
    }
    
    func load(for interval: DateInterval) throws -> Schedule {
        let filtered = storage.filter { interval.contains($0.date) }
        var schedule = Schedule()
        for shift in filtered {
            _ = try? schedule.assign(shift) // assign won't throw because filtered items are unique by construction
        }
        return schedule
    }
}
