// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "TinyBoardCore",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "TinyBoardCore",
            targets: ["TinyBoardCore"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/inseven/diligence.git", from: "2.0.1"),
        .package(url: "https://github.com/inseven/glitter.git", from: "0.1.3"),
        .package(url: "https://github.com/inseven/interact.git", from: "3.10.7"),
        .package(url: "https://github.com/sparkle-project/Sparkle.git", from: "2.7.0"),
    ],
    targets: [
        .target(
            name: "TinyBoardCore",
            dependencies: [
                .product(name: "Diligence", package: "diligence"),
                .product(name: "Glitter", package: "glitter"),
                .product(name: "Interact", package: "interact"),
                .product(name: "Sparkle", package: "Sparkle"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ],
        ),
        .testTarget(
            name: "TinyBoardCoreTests",
            dependencies: ["TinyBoardCore"],
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ],
        ),
    ]
)
