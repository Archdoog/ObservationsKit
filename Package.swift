// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ObservationKit",
    platforms: [
        .iOS(.v17),
        .macCatalyst(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .visionOS(.v1),
        .watchOS(.v10)
    ],
    products: [
        .library(
            name: "ObservationTesting",
            targets: ["ObservationTesting"]
        ),
        .library(
            name: "ObservationShim",
            targets: ["ObservationShim"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-async-algorithms.git", .upToNextMajor(from: "1.1.2")),
        .package(url: "https://github.com/pointfreeco/swift-concurrency-extras.git", .upToNextMajor(from: "1.3.2")),
        
        // Testing
        // TODO: Make this conditional
        .package(url: "https://github.com/apple/swift-numerics.git", .upToNextMajor(from: "1.1.1"))
    ],
    targets: [
        .target(
            name: "ObservationTesting",
            dependencies: [
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
                .product(name: "ConcurrencyExtras", package: "swift-concurrency-extras")
            ]
        ),
        .target(
            name: "ObservationShim"
        ),
        
        // MARK: Testing
        
        .testTarget(
            name: "ObservationTestingTests",
            dependencies: [
                "ObservationTesting",
                .product(name: "Numerics", package: "swift-numerics")
            ]
        ),
        .testTarget(
            name: "ObservationShimTests",
            dependencies: [
                "ObservationShim",
                "ObservationTesting"
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
