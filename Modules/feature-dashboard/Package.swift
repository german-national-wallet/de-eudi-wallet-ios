// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "feature-dashboard",
  platforms: [.iOS(.v16)],
  products: [
    .library(
      name: "feature-dashboard",
      targets: ["feature-dashboard"])
  ],
  dependencies: [
    .package(name: "feature-common", path: "../feature-common"),
    .package(name: "feature-issuance", path: "../feature-issuance"),
    .package(name: "feature-startup", path: "../feature-startup"),
    .package(name: "feature-test", path: "../feature-test")
  ],
  targets: [
    .target(
      name: "feature-dashboard",
      dependencies: [
        "feature-common",
        "feature-issuance",
        "feature-startup"
      ],
      path: "./Sources"
    ),
    .testTarget(
      name: "feature-dashboard-tests",
      dependencies: [
        "feature-dashboard",
        "feature-common",
        "feature-issuance",
        "feature-test"
      ],
      path: "./Tests")
  ]
)
