// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Library",
  platforms: [.iOS(.v26)],
  products: [
    .library(name: "AppFeature", targets: ["AppFeature"]),
    .library(name: "Models", targets: ["Models"])
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/sharing-grdb.git", from: "0.5.0"),
    .package(url: "https://github.com/pointfreeco/swift-dependencies.git", from: "1.9.0")
  ],
  targets: [
    .target(name: "AppFeature"),
    .target(
      name: "Models",
      dependencies: [
        .product(name: "SharingGRDB", package: "sharing-grdb"),
        .product(name: "Dependencies", package: "swift-dependencies"),
      ]
    )
  ]
)
