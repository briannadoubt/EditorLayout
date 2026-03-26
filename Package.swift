// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "EditorLayout",
    platforms: [.macOS(.v26)],
    products: [
        .library(
            name: "EditorLayout",
            targets: ["EditorLayout"]
        )
    ],
    targets: [
        .target(
            name: "EditorLayout"
        ),
        .testTarget(
            name: "EditorLayoutTests",
            dependencies: ["EditorLayout"]
        ),
    ]
)
