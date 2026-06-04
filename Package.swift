// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ofctl",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(name: "ofctl", targets: ["ofctl"]),
    ],
    targets: [
        .target(
            name: "OFCTLCore"
        ),
        .executableTarget(
            name: "ofctl",
            dependencies: ["OFCTLCore"]
        ),
        .testTarget(
            name: "ofctlTests",
            dependencies: ["OFCTLCore"]
        ),
    ],
)
