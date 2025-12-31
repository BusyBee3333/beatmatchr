// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "YabaiPro",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "YabaiPro", targets: ["YabaiPro"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.57.0")
    ],
    targets: [
        .executableTarget(
            name: "YabaiPro",
            dependencies: [
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio")
            ],
            path: "Sources",
            resources: [
                .copy("../Shaders/Shaders.metal")
            ]
        )
    ]
)
