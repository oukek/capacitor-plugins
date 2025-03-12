// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OukekPhoto",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "OukekPhoto",
            targets: ["OukekPhoto"])
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "7.0.0")
    ],
    targets: [
        .target(
            name: "OukekPhoto",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm")
            ],
            path: "ios/Sources/OukekPhoto"),
        .testTarget(
            name: "OukekPhotoTests",
            dependencies: ["OukekPhoto"],
            path: "ios/Tests/OukekPhotoTests")
    ]
)