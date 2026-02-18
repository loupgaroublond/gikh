// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "קאָד_בליקער",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(path: "../.."),
    ],
    targets: [
        .executableTarget(
            name: "קאָד_בליקער",
            dependencies: [
                .product(name: "ביבליאָטעק", package: "גיך"),
            ],
            path: "Sources",
            plugins: [
                .plugin(name: "גיך_פּלאַגין", package: "גיך"),
            ]
        ),
    ]
)
