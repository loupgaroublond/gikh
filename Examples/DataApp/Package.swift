// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "DataApp",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(path: "../.."),
    ],
    targets: [
        .executableTarget(
            name: "DataApp",
            dependencies: [
                .product(name: "Bibliotek", package: "Gikh"),
            ],
            path: "Sources",
            sources: ["App.gikh"],
            plugins: [
                .plugin(name: "GikhBuildPlugin", package: "Gikh"),
            ]
        ),
    ]
)
