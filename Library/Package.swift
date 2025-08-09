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
    
  ],
  targets: [
    .target(name: "AppFeature"),
    .target(name: "Models")
  ]
)
