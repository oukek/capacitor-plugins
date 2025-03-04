// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OukekPhotoPlugin",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "OukekPhotoPlugin",
            targets: ["OukekPhotoPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "7.0.0")
    ],
    targets: [
        .target(
            name: "OukekPhotoPlugin",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm")
            ],
            path: "ios/Sources/OukekPhotoPlugin"),
        .testTarget(
            name: "OukekPhotoPluginTests",
            dependencies: ["OukekPhotoPlugin"],
            path: "ios/Tests/OukekPhotoPluginTests")
    ]
)