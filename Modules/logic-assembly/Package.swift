// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "logic-assembly",
  platforms: [.iOS(.v16)],
  products: [
    .library(
      name: "logic-assembly",
      targets: ["logic-assembly"]
    )
  ],
  dependencies: [
    .package(name: "feature-common", path: "../feature-common"),
    .package(name: "feature-startup", path: "../feature-startup"),
    .package(name: "feature-dashboard", path: "../feature-dashboard"),
    .package(name: "feature-presentation", path: "../feature-presentation"),
    .package(name: "feature-issuance", path: "../feature-issuance"),
    .package(name: "feature-proximity", path: "../feature-proximity"),
    .package(name: "logic-feature-flags", path: "../logic-feature-flags"),
    .package(name: "wallet-backend", path: "../wallet-backend"),
    .package(name: "push-notification-service", path: "../push-notification-service")
  ],
  targets: [
    .target(
      name: "logic-assembly",
      dependencies: [
        "feature-common",
        "feature-startup",
        "feature-dashboard",
        "feature-presentation",
        "feature-issuance",
        "feature-proximity",
        "logic-feature-flags",
        "wallet-backend",
        "push-notification-service"
      ],
      path: "./Sources"
    )
  ]
)
