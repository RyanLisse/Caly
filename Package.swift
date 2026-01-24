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
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", from: "0.10.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.6.0"),
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
                .product(name: "MCP", package: "swift-sdk"),
                .product(name: "Logging", package: "swift-log"),
            ],
            path: "Sources/CLI",
            exclude: ["Info.plist"],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency"),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
            ],
            linkerSettings: [
                .unsafeFlags(["-Xlinker", "-sectcreate", "-Xlinker", "__TEXT", "-Xlinker", "__info_plist", "-Xlinker", "Sources/CLI/Info.plist"])
            ]
        ),
    ]
)
