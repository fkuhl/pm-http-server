// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "pm-http-server",
    platforms: [
        .macOS(.v10_13),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/http.git", from: "3.0.0"),
        .package(url: "https://github.com/mongodb/mongo-swift-driver.git", from: "0.2.0"),
        .package(url: "file:///Users/fkuhl/Documents/workspace/pm-http/pm-data-types/PMDataTypes", from: "2.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "pm-http-server",
            dependencies: ["HTTP", "MongoSwift", "PMDataTypes"]),
        .testTarget(
            name: "pm-http-serverTests",
            dependencies: ["pm-http-server"]),
    ]
)
