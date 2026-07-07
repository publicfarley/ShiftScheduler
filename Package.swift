// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ShiftScheduler",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "shift-scheduler",
            targets: ["ShiftSchedulerCLI"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-argument-parser.git",
            from: "1.3.0"
        )
    ],
    targets: [
        // Single-module executable: compiles the iOS app's domain, persistence,
        // and service sources together with the CLI sources. The app code has no
        // `public` API surface, so a separate library module would require
        // publicizing dozens of types; one module keeps the app sources unchanged.
        .executableTarget(
            name: "ShiftSchedulerCLI",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: ".",
            exclude: [
                // Test doubles must not ship in the executable
                "ShiftScheduler/Redux/Services/Mocks",
                // App-level DI container; references the mocks and is unused by the CLI
                "ShiftScheduler/Redux/Services/ServiceContainer.swift"
            ],
            sources: [
                // Domain models
                "ShiftScheduler/Models",
                // Domain value objects
                "ShiftScheduler/Domain",
                // Persistence repositories
                "ShiftScheduler/Persistence",
                // Repository protocols
                "ShiftScheduler/Repositories",
                // Foundation protocols (DateProviderProtocol, UserDefaultsProtocol)
                "ShiftScheduler/Protocols",
                // Services: TimeChangeService (guards UIKit via #if canImport)
                "ShiftScheduler/Services",
                // Redux services layer (protocols + implementations)
                "ShiftScheduler/Redux/Services",
                // Redux error types (ScheduleError used by services)
                "ShiftScheduler/Redux/Errors",
                // CLI commands and utilities
                "Sources/ShiftSchedulerCLI"
            ],
            swiftSettings: [
                .define("SWIFT_PACKAGE")
            ]
        )
    ]
)
