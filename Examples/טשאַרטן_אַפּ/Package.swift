// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "וועטער_אַפּ",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(path: "../.."),
    ],
    targets: [
        .executableTarget(
            name: "וועטער_אַפּ",
            dependencies: [
                .product(name: "ביבליאָטעק", package: "fix-pkg-identity"),
            ],
            path: "Sources",
            plugins: [
                .plugin(name: "גיך_פּלאַגין", package: "fix-pkg-identity"),
            ]
        ),
    ]
)
