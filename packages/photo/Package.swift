// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "UuPhotoPlugin",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "UuPhotoPlugin",
            targets: ["UUPhotoPluginPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "7.0.0")
    ],
    targets: [
        .target(
            name: "UUPhotoPluginPlugin",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm")
            ],
            path: "ios/Sources/UUPhotoPluginPlugin"),
        .testTarget(
            name: "UUPhotoPluginPluginTests",
            dependencies: ["UUPhotoPluginPlugin"],
            path: "ios/Tests/UUPhotoPluginPluginTests")
    ]
)