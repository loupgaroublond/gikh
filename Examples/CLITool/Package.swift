// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "CLITool",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(path: "../.."),
    ],
    targets: [
        .executableTarget(
            name: "CLITool",
            path: "Sources",
            plugins: [
                .plugin(name: "GikhBuildPlugin", package: "Gikh"),
            ]
        ),
    ]
)
