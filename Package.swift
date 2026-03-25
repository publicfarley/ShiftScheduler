// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ShiftScheduler",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "ShiftSchedulerCore",
            targets: ["ShiftSchedulerCore"]
        ),
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
        // Core library: domain models, persistence, repositories, services
        // References existing iOS source files directly via path
        .target(
            name: "ShiftSchedulerCore",
            dependencies: [],
            path: "ShiftScheduler",
            sources: [
                // Domain models
                "Models",
                // Domain value objects
                "Domain",
                // Persistence repositories
                "Persistence",
                // Repository protocols
                "Repositories",
                // Foundation protocols (DateProviderProtocol, UserDefaultsProtocol)
                "Protocols",
                // Services: TimeChangeService (guards UIKit via #if canImport)
                "Services",
                // Redux services layer (protocols + implementations)
                "Redux/Services",
                // Redux error types (ScheduleError used by services)
                "Redux/Errors"
            ],
            swiftSettings: [
                .define("SWIFT_PACKAGE")
            ]
        ),
        // CLI executable
        .executableTarget(
            name: "ShiftSchedulerCLI",
            dependencies: [
                "ShiftSchedulerCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "Sources/ShiftSchedulerCLI"
        )
    ]
)
