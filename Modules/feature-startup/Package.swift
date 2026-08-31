// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "feature-startup",
  platforms: [.iOS(.v16)],
  products: [
    .library(
      name: "feature-startup",
      targets: ["feature-startup"]
    )
  ],
  dependencies: [
    .package(name: "feature-common", path: "../feature-common"),
    .package(name: "feature-issuance", path: "../feature-issuance"),
    .package(name: "feature-presentation", path: "../feature-presentation"),
    .package(name: "push-notification-service", path: "../push-notification-service"),
    .package(name: "feature-test", path: "../feature-test")
  ],
  targets: [
    .target(
      name: "feature-startup",
      dependencies: [
        "feature-common",
        "feature-issuance",
        "feature-presentation",
        "push-notification-service"
      ],
      path: "./Sources"
    ),
    .testTarget(
      name: "feature-startup-tests",
      dependencies: [
        "feature-startup",
        "feature-common",
        "feature-test",
        "feature-issuance",
        "feature-presentation",
        "push-notification-service"
      ],
      path: "./Tests"
    )
  ]
)
