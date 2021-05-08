// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "sugar_web_library",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "sugar_web_library",
            targets: ["sugar_web_library"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(name: "AWSSDKSwift", url: "https://github.com/swift-aws/aws-sdk-swift.git", from: "4.0.0"),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.0.0"),
        .package(name: "swift-crypto", url: "https://github.com/apple/swift-crypto.git", .exact("1.1.2")),
        .package(name: "sugar_utils", url: "https://github.com/gestrich/sugar_utils.git", .branch("master")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "sugar_web_library",
            dependencies: [
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "sugar_utils", package: "sugar_utils"),
                .product(name: "DynamoDB", package: "AWSSDKSwift"),
            ]),
        .testTarget(
            name: "sugar_web_libraryTests",
            dependencies: ["sugar_web_library"]),
    ]
)

