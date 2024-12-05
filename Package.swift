// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "rapidsnark",
    platforms: [
        .iOS(.v12),
        .macOS(.v10_14),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "rapidsnark",
            targets: ["rapidsnark"]),
    ],
    dependencies: [
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", .upToNextMajor(from: "0.9.0")),
        .package(path: "../circom-witnesscalc-swift"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "rapidsnark",
            dependencies: ["rapidsnarkC"],
            path: "Sources/rapidsnark",
            sources: ["rapidsnark.swift"]
        ),
        .target(
            name: "rapidsnarkC",
            dependencies: ["Rapidsnark"],
            path: "Sources/rapidsnarkC"),
        .binaryTarget(
            name: "Rapidsnark",
            path: "Libs/Rapidsnark.xcframework"),
        .testTarget(
            name: "rapidsnarkTests",
            dependencies: [
                "rapidsnark",
                "ZIPFoundation",
                .product(
                    name: "CircomWitnesscalc",
                    package: "circom-witnesscalc-swift"
                )
            ])
    ]
)
