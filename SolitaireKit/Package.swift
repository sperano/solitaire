// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SolitaireKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SolitaireKit", targets: ["SolitaireKit"]),
    ],
    targets: [
        .target(name: "SolitaireKit"),
        .testTarget(name: "SolitaireKitTests", dependencies: ["SolitaireKit"]),
    ]
)
