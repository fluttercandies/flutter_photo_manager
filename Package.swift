// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "photo_manager",
    platforms: [
        .iOS(.v12),
        .macOS(.v10_15)
    ],
    products: [
        .library(name: "photo-manager", targets: ["photo_manager"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "photo_manager",
            dependencies: [],
            resources: [
                .process("Resources")
            ],
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("."),
                .define("SWIFT_PACKAGE")
            ],
            linkerSettings: [
                .linkedFramework("Photos"),
                .linkedFramework("PhotosUI")
            ]
        )
    ]
)
