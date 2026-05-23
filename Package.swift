// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TS3iOS",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(name: "TS3Kit", targets: ["TS3Kit"]),
        .executable(name: "TS3iOSApp", targets: ["TS3iOSApp"])
    ],
    dependencies: [
        .package(path: "vendor/CryptoSwift"),
        .package(path: "vendor/swift-sodium"),
        .package(path: "vendor/BigInt"),
        .package(path: "vendor/swift-opus")
    ],
    targets: [
        .target(
            name: "TS3Kit",
            dependencies: [
                .product(name: "CryptoSwift", package: "CryptoSwift"),
                .product(name: "Sodium", package: "swift-sodium"),
                .product(name: "BigInt", package: "BigInt"),
                .product(name: "Opus", package: "swift-opus")
            ],
            path: "Sources/TS3Kit"
        ),
        .executableTarget(
            name: "TS3iOSApp",
            dependencies: ["TS3Kit"],
            path: "Sources/TS3iOSApp"
        )
    ]
)
