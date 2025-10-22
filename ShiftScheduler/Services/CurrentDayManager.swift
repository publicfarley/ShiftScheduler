import Foundation
import UIKit
import SwiftUI

class CurrentDayManager {
    static let shared = CurrentDayManager()

    // MARK: - Public Properties
    private(set) var currentDate: Date {
        didSet {
            if !Calendar.current.isDate(oldValue, inSameDayAs: currentDate) {
                notifyDayChanged()
            }
        }
    }

    var today: Date {
        Calendar.current.startOfDay(for: currentDate)
    }

    var tomorrow: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today
    }

    var yesterday: Date {
        Calendar.current.date(byAdding: .day, value: -1, to: today) ?? today
    }

    // MARK: - Initialization
    private init() {
        currentDate = Date()
        setupTimeChangeNotifications()
    }

    deinit {
        removeTimeChangeNotifications()
    }

    // MARK: - Notification Management
    private func setupTimeChangeNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(significantTimeChanged),
            name: UIApplication.significantTimeChangeNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(dayChanged),
            name: .NSCalendarDayChanged,
            object: nil
        )
    }

    private func removeTimeChangeNotifications() {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func significantTimeChanged() {
        DispatchQueue.main.async { [weak self] in
            self?.refreshCurrentDate()
        }
    }

    @objc private func dayChanged() {
        DispatchQueue.main.async { [weak self] in
            self?.refreshCurrentDate()
        }
    }

    // MARK: - Date Management
    private func refreshCurrentDate() {
        let newDate = Date()
        currentDate = newDate
    }

    private func notifyDayChanged() {
        NotificationCenter.default.post(
            name: .currentDayChanged,
            object: self,
            userInfo: [
                "previousDate": Calendar.current.date(byAdding: .day, value: -1, to: today) ?? today,
                "currentDate": today
            ]
        )
    }

    // MARK: - Utility Methods
    func isToday(_ date: Date) -> Bool {
        Calendar.current.isDate(date, inSameDayAs: today)
    }

    func isTomorrow(_ date: Date) -> Bool {
        Calendar.current.isDate(date, inSameDayAs: tomorrow)
    }

    func isYesterday(_ date: Date) -> Bool {
        Calendar.current.isDate(date, inSameDayAs: yesterday)
    }

    func daysBetween(from startDate: Date, to endDate: Date) -> Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }

    // For testing - allows manual date override
    #if DEBUG
    func setTestDate(_ date: Date) {
        currentDate = date
    }
    #endif
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let currentDayChanged = Notification.Name("CurrentDayChanged")
}

// MARK: - Protocol for Day Change Notifications
protocol CurrentDayObserver: AnyObject {
    func currentDayDidChange(from previousDate: Date, to currentDate: Date)
}

// Helper for easier observation management
class CurrentDayObserverManager {
    private var observers: [WeakReference<AnyObject>] = []

    static let shared = CurrentDayObserverManager()
    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(dayChanged(_:)),
            name: .currentDayChanged,
            object: nil
        )
    }

    func addObserver(_ observer: any CurrentDayObserver) {
        observers.append(WeakReference(observer))
        cleanupObservers()
    }

    func removeObserver(_ observer: any CurrentDayObserver) {
        observers.removeAll { $0.value === observer }
    }

    @objc private func dayChanged(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let previousDate = userInfo["previousDate"] as? Date,
              let currentDate = userInfo["currentDate"] as? Date else { return }

        cleanupObservers()
        observers.forEach { observer in
            (observer.value as? CurrentDayObserver)?.currentDayDidChange(from: previousDate, to: currentDate)
        }
    }

    private func cleanupObservers() {
        observers.removeAll { $0.value == nil }
    }
}

private struct WeakReference<T: AnyObject> {
    weak var value: T?

    init(_ value: T) {
        self.value = value
    }
}

// MARK: - SwiftUI View Modifier for Day Change Observation
struct CurrentDayChangeObserver: ViewModifier {
    let onDayChange: (Date, Date) -> Void

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .currentDayChanged)) { notification in
                guard let userInfo = notification.userInfo,
                      let previousDate = userInfo["previousDate"] as? Date,
                      let currentDate = userInfo["currentDate"] as? Date else { return }

                onDayChange(previousDate, currentDate)
            }
    }
}

extension View {
    func onCurrentDayChange(perform action: @escaping (Date, Date) -> Void) -> some View {
        modifier(CurrentDayChangeObserver(onDayChange: action))
    }
}
