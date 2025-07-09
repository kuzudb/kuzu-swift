// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "kuzu-swift-get-started",
    platforms: [
        .macOS(.v11),
        .iOS(.v14),
    ],
    dependencies: [
        .package(url: "https://github.com/kuzudb/kuzu-swift/", branch: "main"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "kuzu-swift-get-started",
            dependencies: [
                .product(name: "Kuzu", package: "kuzu-swift"),
            ]
        ),
    ]
)
