import Foundation
import SwiftData

// Note: We use ModelContext directly instead of a protocol because:
// 1. ModelContext is already an actor and thread-safe
// 2. Protocol conformance for generic methods is complex in Swift
// 3. For testing, we can use in-memory ModelContainer instead of mocking

// This file is kept for documentation purposes but protocol abstraction is not used
