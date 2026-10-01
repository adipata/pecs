// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "PictoCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "PictoCore", targets: ["PictoCore"]),
    ],
    targets: [
        .target(name: "PictoCore"),
        .testTarget(name: "PictoCoreTests", dependencies: ["PictoCore"]),
    ]
)
