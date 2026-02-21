// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "באַניצער_פֿלאַך_אַפּ",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(path: "../.."),
    ],
    targets: [
        .executableTarget(
            name: "באַניצער_פֿלאַך_אַפּ",
            dependencies: [
                .product(name: "ביבליאָטעק", package: "gikh"),
            ],
            path: "Sources",
            plugins: [
                .plugin(name: "גיך_פּלאַגין", package: "gikh"),
            ]
        ),
    ]
)
