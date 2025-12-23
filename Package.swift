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
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.8.0"),
        .package(url: "https://github.com/jedisct1/swift-sodium.git", from: "0.9.2"),
        .package(url: "https://github.com/attaswift/BigInt.git", from: "5.7.0"),
        .package(url: "https://github.com/alta/swift-opus.git", from: "0.0.2")
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
