// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NetworkClient",
    platforms: [
      .iOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "NetworkClient",
            targets: ["NetworkClient"]),
        .library(
              name: "NetworkClientTestUtilities",
              targets: ["NetworkClientTestUtilities"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "NetworkClient",
            dependencies: []),
        .target(
            name: "NetworkClientTestUtilities",
            dependencies: ["NetworkClient"]),
        .testTarget(
            name: "NetworkClientTests",
            dependencies: ["NetworkClient", "NetworkClientTestUtilities"]),
    ]
)
