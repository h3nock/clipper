// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "clipper",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(name: "clipper", targets: ["clipper"]),
        .library(name: "ClipperCore", targets: ["ClipperCore"]),
    ],
    targets: [
        .target(name: "ClipperCore"),
        .executableTarget(
            name: "clipper",
            dependencies: ["ClipperCore"]
        ),
        .testTarget(
            name: "ClipperTests",
            dependencies: ["ClipperCore"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
