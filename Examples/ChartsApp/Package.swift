// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ChartsApp",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(path: "../.."),
    ],
    targets: [
        .executableTarget(
            name: "ChartsApp",
            path: "Sources",
            plugins: [
                .plugin(name: "GikhBuildPlugin", package: "Gikh"),
            ]
        ),
    ]
)
