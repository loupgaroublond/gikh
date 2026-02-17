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
            dependencies: [
                .product(name: "Bibliotek", package: "Gikh"),
            ],
            path: "Sources",
            sources: ["main.gikh"],
            plugins: [
                .plugin(name: "GikhBuildPlugin", package: "Gikh"),
            ]
        ),
    ]
)
