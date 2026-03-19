// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "TinyKit",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "TinyKit", targets: ["TinyKit"]),
    ],
    dependencies: [
        .package(path: "../../../Packages/TinyWelcome"),
    ],
    targets: [
        .target(name: "TinyKit", dependencies: ["TinyWelcome"], swiftSettings: [.swiftLanguageMode(.v5)]),
    ]
)
