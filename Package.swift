// swift-tools-version:5.7.1

import PackageDescription

let package = Package(
    name: "MyProject",
    products: [
        .executable(name: "MyProject", targets: ["MyProject"])
    ],
    dependencies: [
        // Add any project dependencies here.
    ],
    targets: [
        .target(name: "MyProject", dependencies: [])
    ]
)