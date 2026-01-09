// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Caly",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "CalyCore", targets: ["CalyCore"]),
        .executable(name: "caly", targets: ["CalyCLI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
    ],
    targets: [
        // Core library - framework-agnostic, no CLI dependencies
        .target(
            name: "CalyCore",
            dependencies: [],
            path: "Sources/Core",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency"),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
            ],
            linkerSettings: [
                .linkedFramework("EventKit")
            ]
        ),

        // CLI executable - uses Commander (ArgumentParser)
        .executableTarget(
            name: "CalyCLI",
            dependencies: [
                "CalyCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/CLI",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency"),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
            ]
        ),
    ]
)
