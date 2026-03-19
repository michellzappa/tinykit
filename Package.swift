// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "TinyKit",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "TinyKit", targets: ["TinyKit"]),
    ],
    targets: [
        .target(name: "TinyKit", swiftSettings: [.swiftLanguageMode(.v5)]),
    ]
)
