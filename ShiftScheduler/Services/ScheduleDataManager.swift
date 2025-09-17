import Foundation
import SwiftUI
import Observation

/// High-performance data manager for schedule data with predictive caching and flash-free UI updates
@Observable
class ScheduleDataManager {
    static let shared = ScheduleDataManager()

    // MARK: - Core State
    private let calendarService = CalendarService.shared
    private var shiftTypes: [ShiftType] = []

    // MARK: - Cache Management
    private var dateCache: [Date: [ScheduledShift]] = [:]
    private var cacheTimestamps: [Date: Date] = [:]
    private var loadingDates: Set<Date> = []
    private let cacheExpiryInterval: TimeInterval = 300 // 5 minutes

    // MARK: - Pre-fetching Strategy
    private var prefetchQueue = Set<Date>()
    private let prefetchRadius = 7 // Days to prefetch around current date

    // MARK: - Published State
    var currentShifts: [ScheduledShift] = []
    var selectedDate = Date() {
        didSet {
            handleDateSelection(selectedDate)
        }
    }
    var errorMessage: String?
    var scheduledDates: Set<Date> = []

    // Track if we're showing data for the current selected date
    private var currentShiftsDate: Date?
    var isShowingStaleData: Bool {
        guard let currentShiftsDate = currentShiftsDate else { return false }
        return !Calendar.current.isDate(currentShiftsDate, inSameDayAs: selectedDate)
    }

    // Internal state tracking - not published to UI
    private var backgroundLoadingDates: Set<Date> = []

    private init() {
        // Initialize with current date
        handleDateSelection(Date())

        // Start background scheduled dates loading
        loadScheduledDatesInBackground()
    }

    // MARK: - Public Interface

    /// Updates shift types and invalidates cache if needed
    func updateShiftTypes(_ types: [ShiftType]) {
        let oldTypes = shiftTypes
        shiftTypes = types

        // If this is the first time setting shift types, we need to reload data
        // to ensure shifts get proper shiftType associations
        if oldTypes.isEmpty && !types.isEmpty {
            // Clear everything and force a fresh load with shift types available
            invalidateAllCache()
            currentShifts = []
            currentShiftsDate = nil

            // Immediately trigger a fresh load of the current date
            Task { @MainActor in
                await loadShiftsForInitialDisplay()
            }
        } else if oldTypes.count != types.count {
            // Shift types changed, invalidate and refresh
            invalidateAllCache()
            refreshCurrentDate()
        } else {
            // Minor updates, just invalidate cache
            invalidateAllCache()
        }
    }

    /// Loads shifts for initial display when shift types first become available
    @MainActor
    private func loadShiftsForInitialDisplay() async {
        guard calendarService.isAuthorized else { return }

        let targetDate = normalizeDate(selectedDate)

        do {
            let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: targetDate) ?? targetDate
            let shiftData = try await calendarService.fetchShifts(from: targetDate, to: endOfDay)

            // Convert to ScheduledShift objects with proper shift types
            let shifts = shiftData.map { data in
                let shiftType = shiftTypes.first { $0.id == data.shiftTypeId }
                return ScheduledShift(from: data, shiftType: shiftType)
            }

            // Update UI state immediately
            currentShifts = shifts
            currentShiftsDate = targetDate
            cacheShifts(shifts, for: targetDate)
            errorMessage = nil

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Forces refresh of current date data
    func refreshCurrentDate() {
        let date = normalizeDate(selectedDate)
        invalidateCache(for: date)
        handleDateSelection(selectedDate)
    }

    /// Clears all cached data
    func clearCache() {
        dateCache.removeAll()
        cacheTimestamps.removeAll()
        loadingDates.removeAll()
        prefetchQueue.removeAll()
    }

    // MARK: - Flash-Free Loading Logic

    private func handleDateSelection(_ date: Date) {
        let normalizedDate = normalizeDate(date)

        // Check if we have cached data for the new date
        if let cachedShifts = getCachedShifts(for: normalizedDate) {
            // We have cached data - update immediately
            currentShifts = cachedShifts
            currentShiftsDate = normalizedDate
            errorMessage = nil
        } else {
            // No cached data - keep showing previous content while loading
            // This prevents the flash by never showing empty state prematurely

            // Only clear if this is the very first load (no previous content)
            if currentShiftsDate == nil {
                currentShifts = []
                // Don't set currentShiftsDate until we have data to prevent hasDataForSelectedDate issues
            }
            // Otherwise keep showing previous content while loading new data

            errorMessage = nil
            // Start background load immediately
            loadShifts(for: normalizedDate)
        }

        // Always trigger background prefetch for adjacent dates
        schedulePrefetch(around: normalizedDate)
    }

    private func loadShifts(for date: Date) {
        guard calendarService.isAuthorized else { return }

        let normalizedDate = normalizeDate(date)

        // Prevent duplicate loads using background tracking
        guard !backgroundLoadingDates.contains(normalizedDate) else { return }

        backgroundLoadingDates.insert(normalizedDate)

        Task {
            do {
                // Fetch data from calendar service
                let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: normalizedDate) ?? normalizedDate
                let shiftData = try await calendarService.fetchShifts(from: normalizedDate, to: endOfDay)

                // Convert to ScheduledShift objects
                let shifts = shiftData.map { data in
                    let shiftType = shiftTypes.first { $0.id == data.shiftTypeId }
                    return ScheduledShift(from: data, shiftType: shiftType)
                }

                await MainActor.run {
                    // Update cache
                    self.cacheShifts(shifts, for: normalizedDate)

                    // Update UI only if this is still the selected date
                    if Calendar.current.isDate(normalizedDate, inSameDayAs: self.selectedDate) {
                        self.currentShifts = shifts
                        self.currentShiftsDate = normalizedDate
                        self.errorMessage = nil
                    }

                    self.backgroundLoadingDates.remove(normalizedDate)
                }

            } catch {
                await MainActor.run {
                    // Only update error state if this is still the selected date
                    if Calendar.current.isDate(normalizedDate, inSameDayAs: self.selectedDate) {
                        self.errorMessage = error.localizedDescription
                    }

                    self.backgroundLoadingDates.remove(normalizedDate)
                }
            }
        }
    }

    // MARK: - Cache Management

    private func cacheShifts(_ shifts: [ScheduledShift], for date: Date) {
        let normalizedDate = normalizeDate(date)
        dateCache[normalizedDate] = shifts
        cacheTimestamps[normalizedDate] = Date()
    }

    private func getCachedShifts(for date: Date) -> [ScheduledShift]? {
        let normalizedDate = normalizeDate(date)

        guard let timestamp = cacheTimestamps[normalizedDate],
              Date().timeIntervalSince(timestamp) < cacheExpiryInterval,
              let shifts = dateCache[normalizedDate] else {
            return nil
        }

        return shifts
    }

    private func invalidateCache(for date: Date) {
        let normalizedDate = normalizeDate(date)
        dateCache.removeValue(forKey: normalizedDate)
        cacheTimestamps.removeValue(forKey: normalizedDate)
    }

    private func invalidateAllCache() {
        dateCache.removeAll()
        cacheTimestamps.removeAll()
    }

    // MARK: - Predictive Prefetching

    private func schedulePrefetch(around date: Date) {
        let calendar = Calendar.current

        // Generate dates to prefetch
        var datesToPrefetch: [Date] = []

        for offset in -prefetchRadius...prefetchRadius {
            if let targetDate = calendar.date(byAdding: .day, value: offset, to: date) {
                let normalizedDate = normalizeDate(targetDate)

                // Only prefetch if not already cached or loading
                if getCachedShifts(for: normalizedDate) == nil && !backgroundLoadingDates.contains(normalizedDate) {
                    datesToPrefetch.append(normalizedDate)
                }
            }
        }

        // Prefetch in background with delay to avoid overwhelming the system
        Task {
            for (index, dateToLoad) in datesToPrefetch.enumerated() {
                // Small delay between prefetch requests
                try? await Task.sleep(nanoseconds: UInt64(index * 100_000_000)) // 100ms delay
                loadShifts(for: dateToLoad)
            }
        }
    }

    // MARK: - Scheduled Dates Loading

    private func loadScheduledDatesInBackground() {
        guard calendarService.isAuthorized else { return }

        Task {
            do {
                // Load wider range for calendar highlighting
                let startDate = Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
                let endDate = Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()

                let allShiftData = try await calendarService.fetchShifts(from: startDate, to: endDate)
                let uniqueDates = Set(allShiftData.map { normalizeDate($0.date) })

                await MainActor.run {
                    self.scheduledDates = uniqueDates
                }
            } catch {
                // Silently fail for scheduled dates
                print("Failed to load scheduled dates: \(error)")
            }
        }
    }

    // MARK: - Deletion with Cache Update

    func deleteShift(_ shift: ScheduledShift) async throws {
        try await calendarService.deleteShift(withIdentifier: shift.eventIdentifier)

        // Update cache immediately
        let date = normalizeDate(shift.date)
        if var cachedShifts = dateCache[date] {
            cachedShifts.removeAll { $0.eventIdentifier == shift.eventIdentifier }
            cacheShifts(cachedShifts, for: date)

            // Update current shifts if this date is selected
            await MainActor.run {
                if Calendar.current.isDate(date, inSameDayAs: self.selectedDate) {
                    self.currentShifts = cachedShifts
                }
            }
        }

        // Refresh scheduled dates
        loadScheduledDatesInBackground()
    }

    // MARK: - Utilities

    private func normalizeDate(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }
}

// MARK: - Extensions for Convenience

extension ScheduleDataManager {
    var shiftsForSelectedDate: [ScheduledShift] {
        // Always return the current shifts filtered for the selected date
        // This prevents flashing by keeping previous content visible
        return currentShifts.filter { shift in
            Calendar.current.isDate(shift.date, inSameDayAs: selectedDate)
        }
    }

    var hasDataForSelectedDate: Bool {
        // We have data if currentShiftsDate matches selectedDate
        guard let currentShiftsDate = currentShiftsDate else { return false }
        return Calendar.current.isDate(currentShiftsDate, inSameDayAs: selectedDate)
    }
}