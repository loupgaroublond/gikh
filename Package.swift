// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "גיך",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(name: "גיך", targets: ["גיך"]),
        .library(name: "ביבליאָטעק", targets: ["ביבליאָטעק"]),
    ],
    targets: [
        // CLI transpiler tool
        .executableTarget(
            name: "גיך",
            dependencies: ["ביבליאָטעק"],
            path: "Sources/גיך",
            resources: [
                .copy("../../Dictionaries"),
            ]
        ),

        // Framework wrapper library
        .target(
            name: "ביבליאָטעק",
            path: "Sources/ביבליאָטעק"
        ),

        // Helper tool invoked by the build plugin to transpile .gikh -> .swift
        .executableTarget(
            name: "gikh-transpile",
            path: "Sources/gikh-transpile"
        ),

        // SwiftPM build tool plugin
        .plugin(
            name: "גיך_פּלאַגין",
            capability: .buildTool(),
            dependencies: ["gikh-transpile"],
            path: "Sources/גיך_פּלאַגין"
        ),

        // Transpiler tests
        .testTarget(
            name: "GikhTests",
            dependencies: ["גיך"],
            path: "Tests/GikhTests"
        ),

        // Scan pipeline tests
        .testTarget(
            name: "ScanPipelineTests",
            path: "Tests/ScanPipelineTests"
        ),
    ]
)
