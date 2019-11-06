// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "Timber",
    products: [
        .library(
            name: "Timber",
            targets: ["Timber"]
        )
    ],
    targets: [
        .target(
            name: "Timber"            
        ),
        .testTarget(
            name: "TimberTests",
            dependencies: [
                "Timber"
            ]
        )
    ]
)
