// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OukekPay",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "OukekPay",
            targets: ["OukekPay"])
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "7.0.0"),
    ],
    targets: [
        .target(
            name: "OukekPay",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm"),
            ],
            path: "ios/Sources/OukekPay"),
        .testTarget(
            name: "OukekPayTests",
            dependencies: ["OukekPay"],
            path: "ios/Tests/OukekPayTests")
    ]
)