import Foundation
import Testing
@testable import ShiftScheduling

struct ShiftSchedulingTests {
    
    @Test
    func addShiftTypeToCatalog() throws {
        var catalog = ShiftCatalog()
        
        let location = Location(name: "Bakery", address: "123 Main St")
        let symbol = try #require(ShiftType.Symbol("A1"))
        
        let shiftType = ShiftType(
            symbol: symbol,
            startTime: DateComponents(hour: 9, minute: 0),
            endTime: DateComponents(hour: 17, minute: 0),
            title: "Morning Shift",
            description: "Covers bakery morning hours",
            location: location
        )
        
        catalog.add(shiftType)
        
        let repo = InMemoryShiftCatalogRepository()
        try repo.save(catalog)
        
        let loaded = try repo.load()
        #expect(loaded.all().count == 1)
        #expect(loaded.all().first?.title == "Morning Shift")
    }
    
    @Test
    func assignScheduledShift() throws {
        var schedule = Schedule()
        
        let location = Location(name: "Warehouse", address: "456 Side St")
        let symbol = try #require(ShiftType.Symbol("N1"))
        
        let shiftType = ShiftType(
            symbol: symbol,
            startTime: DateComponents(hour: 22, minute: 0),
            endTime: DateComponents(hour: 23, minute: 59),
            title: "Night Shift",
            description: "Overnight work",
            location: location
        )
        
        let scheduledShift = ScheduledShift(
            shiftType: shiftType,
            date: Calendar.current.startOfDay(for: Date())
        )
        
        schedule.assign(scheduledShift)
        
        let repo = InMemoryScheduleRepository()
        try repo.save(schedule)
        
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let interval = DateInterval(start: Date(), end: tomorrow)
        let loaded = try repo.load(for: interval)
        
        #expect(loaded.all().count == 1)
        #expect(loaded.all().first?.shiftType.title == "Night Shift")
    }
    
    @Test
    func preventDuplicateShiftOnSameDay() throws {
        var schedule = Schedule()
        
        let location = Location(name: "Office", address: "789 Work Rd")
        let symbol = try #require(ShiftType.Symbol("D1"))
        
        let shiftType = ShiftType(
            symbol: symbol,
            startTime: DateComponents(hour: 8, minute: 0),
            endTime: DateComponents(hour: 16, minute: 0),
            title: "Day Shift",
            description: "Regular daytime work",
            location: location
        )
        
        let today = Calendar.current.startOfDay(for: Date())
        
        let s1 = ScheduledShift(shiftType: shiftType, date: today)
        schedule.assign(s1)
        
        let s2 = ScheduledShift(shiftType: shiftType, date: today)
        
        #expect(throws: Error.self) {
            schedule.assign(s2)
        }
    }
}
