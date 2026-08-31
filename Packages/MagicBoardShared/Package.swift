// swift-tools-version: 6.0
// 定义主应用与键盘共享模块
import PackageDescription

let package = Package(
    name: "MagicBoardShared",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
    ],
    products: [
        .library(name: "MagicBoardShared", targets: ["MagicBoardShared"]),
    ],
    targets: [
        .target(name: "MagicBoardShared"),
        .testTarget(name: "MagicBoardSharedTests", dependencies: ["MagicBoardShared"]),
    ]
)
