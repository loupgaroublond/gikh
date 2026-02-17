// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Gikh",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "gikh", targets: ["GikhCLI"]),
        .library(name: "GikhCore", targets: ["GikhCore"]),
        .library(name: "Bibliotek", targets: ["Bibliotek"]),
        .library(name: "ScanPipeline", targets: ["ScanPipeline"]),
        .plugin(name: "GikhBuildPlugin", targets: ["GikhBuildPlugin"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.1.0"),
    ],
    targets: [
        // Core transpiler library
        .target(
            name: "GikhCore",
            dependencies: [
                .product(name: "Yams", package: "Yams"),
            ]
        ),

        // CLI executable
        .executableTarget(
            name: "GikhCLI",
            dependencies: [
                "GikhCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),

        // Framework wrapper library
        .target(
            name: "Bibliotek",
            dependencies: []
        ),

        // External codebase scanner
        .target(
            name: "ScanPipeline",
            dependencies: ["GikhCore"]
        ),

        // SwiftPM build plugin
        .plugin(
            name: "GikhBuildPlugin",
            capability: .buildTool(),
            dependencies: ["GikhCLI"],
            path: "Sources/GikhBuildPlugin"
        ),

        // Tests
        .testTarget(
            name: "GikhCoreTests",
            dependencies: ["GikhCore"]
        ),
        .testTarget(
            name: "ScanPipelineTests",
            dependencies: ["ScanPipeline", "GikhCore"]
        ),
    ]
)
