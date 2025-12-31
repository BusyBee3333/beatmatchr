// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AnimationDemo",
    platforms: [
        .macOS(.v12)
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "AnimationDemo",
            dependencies: [],
            resources: [
                .copy("Shaders/Shaders.metal")
            ]
        )
    ]
)











