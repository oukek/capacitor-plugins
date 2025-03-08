// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OukekPayPlugin",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "OukekPayPlugin",
            targets: ["OukekPayPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "7.0.0")
    ],
    targets: [
        .target(
            name: "OukekPayPlugin",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm")
            ],
            path: "ios/Sources/OukekPayPlugin"),
        .testTarget(
            name: "OukekPayPluginTests",
            dependencies: ["OukekPayPlugin"],
            path: "ios/Tests/OukekPayPluginTests")
    ]
)