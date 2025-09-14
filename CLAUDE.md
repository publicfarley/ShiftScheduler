# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Testing
```bash
# Run all tests (when Xcode project is set up)
xcodebuild -project ShiftScheduler.xcodeproj -scheme ShiftScheduler -destination 'platform=iOS Simulator,id=490A490A-C97A-43EE-978E-148A74A72499' test

# Run tests with xcpretty for cleaner output (if installed)
xcodebuild test -project ShiftScheduler.xcodeproj -scheme ShiftScheduler -destination 'platform=iOS Simulator,id=490A490A-C97A-43EE-978E-148A74A72499' | xcpretty
```

### Building
```bash
# Build for iOS Simulator
xcodebuild -project ShiftScheduler.xcodeproj -scheme ShiftScheduler -destination 'platform=iOS Simulator,id=490A490A-C97A-43EE-978E-148A74A72499' build

# Build for release
xcodebuild -project ShiftScheduler.xcodeproj -scheme ShiftScheduler -configuration Release -destination 'platform=iOS Simulator,id=490A490A-C97A-43EE-978E-148A74A72499' build

# List available simulators
xcrun simctl list devices
```

## Architecture

This is an iOS Swift/SwiftUI application for shift scheduling, implementing Domain-Driven Design (DDD) principles. The app will provide a user interface for managing work shifts and schedules.

### Core Domain Components

- **Domain.swift**: Contains the core value objects and entities
  - `Location`: Represents physical/virtual locations where shifts occur
  - `ShiftType`: Template definition for shifts with symbol, times, and location
  - `ScheduledShift`: Concrete instance of a shift on a specific date

### Aggregate Roots

- **Aggregates.swift**: Contains the aggregate roots that enforce business rules
  - `ShiftCatalog`: Manages all defined shift templates
  - `Schedule`: Manages scheduled shifts and prevents duplicates on the same day

### Repository Pattern

- **Repositories.swift**: Defines protocol interfaces for data persistence
  - `ShiftCatalogRepository`: Interface for loading/saving shift catalogs
  - `ScheduleRepository`: Interface for loading/saving schedules

- **InMemoryRepositories.swift**: In-memory implementations of the repository protocols

### Testing

Tests use Swift's Testing framework (not XCTest) with the `@Test` macro and `#expect` assertions.