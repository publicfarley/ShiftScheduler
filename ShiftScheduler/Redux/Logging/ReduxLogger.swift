import Foundation
import OSLog

/// Unified logger for Redux architecture
/// Provides consistent logging across Store, Reducers, Middleware, and Services
/// All logging goes through this single point for centralized control
struct ReduxLogger {
    private nonisolated(unsafe) static let logger = os.Logger(
        subsystem: "com.shiftscheduler.redux",
        category: "Redux"
    )

    /// Logs a debug message with proper MainActor handling
    /// - Parameter message: The message to log (will be logged with public privacy)
    nonisolated static func debug(_ message: String) {
        DispatchQueue.main.async {
            // logger.debug("\(message, privacy: .public)")
        }
    }

    /// Logs an error message with proper MainActor handling
    /// - Parameter message: The error message to log
    nonisolated static func error(_ message: String) {
        DispatchQueue.main.async {
            // logger.error("\(message, privacy: .public)")
        }
    }

    /// Logs a warning message with proper MainActor handling
    /// - Parameter message: The warning message to log
    nonisolated static func warning(_ message: String) {
        DispatchQueue.main.async {
            // logger.warning("\(message, privacy: .public)")
        }
    }

    /// Logs an info message with proper MainActor handling
    /// - Parameter message: The info message to log
    nonisolated static func info(_ message: String) {
        DispatchQueue.main.async {
            // logger.info("\(message, privacy: .public)")
        }
    }
}
