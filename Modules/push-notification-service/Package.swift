// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "push-notification-service",
  platforms: [.iOS(.v16)],
  products: [
    .library(
      name: "push-notification-service",
      targets: ["push-notification-service"]
    )
  ],
  dependencies: [
    .package(name: "logic-api", path: "../logic-api"),
    .package(name: "logic-business", path: "../logic-business"),
    .package(name: "logic-feature-flags", path: "../logic-feature-flags"),
    .package(name: "logic-test", path: "../logic-test"),
    .package(url: "https://github.com/Swinject/Swinject.git", from: "2.8.4")
  ],
  targets: [
    .target(
      name: "push-notification-service",
      dependencies: [
        "logic-api",
        "logic-business",
        "logic-feature-flags",
        "Swinject"
      ],
      path: "./Sources"
    ),
    .testTarget(
      name: "push-notification-service-tests",
      dependencies: [
        "push-notification-service",
        "logic-test"
      ],
      path: "./Tests"
    )
  ]
)
