// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "TinyBoardCore",
    products: [
        .library(
            name: "TinyBoardCore",
            targets: ["TinyBoardCore"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/inseven/diligence.git", from: "2.0.1"),
        .package(url: "https://github.com/inseven/interact.git", from: "3.10.7"),
    ],
    targets: [
        .target(
            name: "TinyBoardCore",
            dependencies: [
                .product(name: "Diligence", package: "diligence"),
                .product(name: "Interact", package: "interact"),
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
